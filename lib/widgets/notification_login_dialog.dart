import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/account_service.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';

class NotificationLoginDialog extends StatefulWidget {
  const NotificationLoginDialog({super.key, this.initialIdentifier});

  final String? initialIdentifier;

  static Future<bool> show(
    BuildContext context, {
    String? initialIdentifier,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              NotificationLoginDialog(initialIdentifier: initialIdentifier),
        ) ??
        false;
  }

  @override
  State<NotificationLoginDialog> createState() =>
      _NotificationLoginDialogState();
}

class _NotificationLoginDialogState extends State<NotificationLoginDialog> {
  final ApiService _api = ApiService();
  final CryptoService _crypto = CryptoService();
  late final TextEditingController _identifier;
  final TextEditingController _code = TextEditingController();
  crypto.SimpleKeyPair? _keyPair;
  String? _publicKey;
  String? _challengeId;
  String? _pollSecret;
  Timer? _pollTimer;
  int _step = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _identifier = TextEditingController(text: widget.initialIdentifier ?? '');
  }

  Future<void> _requestCode() async {
    final identifier = _identifier.text.trim();
    if (identifier.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final keyPair = await crypto.X25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final publicHex = Uint8List.fromList(
      publicKey.bytes,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final response = await _api.requestNotificationLogin(
      identifier: identifier,
      recipientPublicKey: publicHex,
    );
    if (!mounted) return;
    final data = response.data;
    if (response.success && data != null) {
      _keyPair = keyPair;
      _publicKey = publicHex;
      _challengeId = data['challenge_id']?.toString();
      _pollSecret = data['poll_secret']?.toString();
      setState(() {
        _busy = false;
        _step = 1;
      });
    } else {
      setState(() {
        _busy = false;
        _error = response.error ?? 'Не удалось отправить код';
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_code.text.length != 6 || _challengeId == null || _pollSecret == null)
      return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final response = await _api.verifyNotificationLogin(
      challengeId: _challengeId!,
      pollSecret: _pollSecret!,
      code: _code.text,
    );
    if (!mounted) return;
    if (response.success) {
      setState(() {
        _busy = false;
        _step = 2;
      });
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _poll(),
      );
      await _poll();
    } else {
      setState(() {
        _busy = false;
        _error = 'Неверный или просроченный код';
      });
    }
  }

  Future<void> _poll() async {
    final challenge = _challengeId;
    final secret = _pollSecret;
    if (_busy || challenge == null || secret == null) return;
    final response = await _api.getNotificationLoginStatus(challenge, secret);
    if (!mounted) return;
    final status = response.data?['status']?.toString();
    if (response.success && status == 'approved') {
      _pollTimer?.cancel();
      setState(() => _busy = true);
      try {
        final access = response.data?['access']?.toString();
        final refresh = response.data?['refresh']?.toString();
        if (access == null || refresh == null)
          throw StateError('Токены не получены');
        await _api.saveAccessToken(access);
        await _api.saveRefreshToken(refresh);
        final transfer = response.data?['transfer_payload'];
        if (transfer is! Map || _keyPair == null || _publicKey == null) {
          throw StateError('Сервер не передал ключи шифрования');
        }
        final keys = await _crypto.decryptQrTransferPayload(
          transferPayload: Map<String, dynamic>.from(transfer),
          ephemeralKeyPair: _keyPair!,
          token: challenge,
          recipientPublicKeyHex: _publicKey!,
        );
        if (keys == null || !await _crypto.importUserKeysFromPayload(keys)) {
          throw StateError('Не удалось перенести ключи шифрования');
        }
        final profile = await _api.getProfile();
        if (profile.success && profile.data != null) {
          await AccountService().saveCurrentAccount(profile.data!);
        }
        if (mounted) Navigator.of(context).pop(true);
      } catch (error) {
        await _api.logout();
        await _crypto.clearKeys();
        if (mounted)
          setState(() {
            _busy = false;
            _error = error.toString();
          });
      }
    } else if (status == 'rejected' ||
        status == 'expired' ||
        status == 'cancelled') {
      _pollTimer?.cancel();
      setState(() {
        _step = 1;
        _error = status == 'rejected' ? 'Запрос отклонён' : 'Сессия истекла';
      });
    }
  }

  Future<void> _close() async {
    _pollTimer?.cancel();
    if (_challengeId != null && _pollSecret != null) {
      await _api.cancelNotificationLogin(_challengeId!, _pollSecret!);
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _identifier.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = _step == 0
        ? (l10n?.codeLoginTitle ?? 'Вход по коду')
        : _step == 1
        ? (l10n?.enterAllDigitsErr ?? 'Введите код')
        : (l10n?.confirmOnDeviceStatus ?? 'Подтвердите вход');
    final description = _step == 0
        ? (l10n?.codeSentToBot ??
              'Шестизначный код придёт в чат с xaneo_notifications_bot.')
        : _step == 1
        ? (l10n?.sixDigitCodeSentSub ?? 'Код действует 5 минут.')
        : (l10n?.confirmOnDeviceSub ??
              'На уже авторизованном устройстве появится запрос на передачу ключей.');
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: dark ? const Color(0xFF151515) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  color: dark ? Colors.white60 : Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              if (_step == 0)
                TextField(
                  controller: _identifier,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n?.loginFieldHint ?? 'Никнейм или почта',
                  ),
                  onSubmitted: (_) => _requestCode(),
                ),
              if (_step == 1)
                TextField(
                  controller: _code,
                  autofocus: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n?.sixDigitCodeLabel ?? 'Шестизначный код',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verifyCode(),
                ),
              if (_step == 2)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFE57373)),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _close,
            child: Text(l10n?.cancel ?? 'Отмена'),
          ),
          if (_step < 2)
            FilledButton(
              onPressed: _busy
                  ? null
                  : (_step == 0 ? _requestCode : _verifyCode),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _step == 0
                          ? (l10n?.getCodeBtn ?? 'Получить код')
                          : (l10n?.continueBtn ?? 'Продолжить'),
                    ),
            ),
        ],
      ),
    );
  }
}
