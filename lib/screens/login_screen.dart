import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_text_form_field.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/account_service.dart';
import '../services/logger_service.dart';
import '../utils/ssl_helper.dart';
import '../widgets/settings_modal.dart';
import '../widgets/custom_toast.dart';
import '../widgets/qr_login_verification_modal.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Экран входа в систему с продвинутыми 3D эффектами
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  late final Future<int?> _loginOriginUserId;

  bool _hasAccounts = false;
  int _currentStep = 0; // 0: login/username, 1: password or code
  bool _isQrMode = true;
  bool _isLoading = false;

  Timer? _qrTimer;
  Timer? _qrReconnectTimer;
  WebSocket? _qrSocket;
  StreamSubscription<dynamic>? _qrSocketSubscription;
  bool _qrStatusRequestInFlight = false;
  bool _qrStatusCheckQueued = false;
  Uint8List? _qrImageBytes;
  crypto.SimpleKeyPair? _qrEphemeralKeyPair;
  String? _qrPollSecret;
  String? _qrWebPublicKey;
  String? _qrToken;
  String? _qrPayloadString;
  bool _isQrApproved = false;
  bool _isQrAwaitingApproval = false;
  bool _isQrVerificationModalOpen = false;
  final GlobalKey _qrVerificationModalKey = GlobalKey();

  // Code mode (Notification login) state
  crypto.SimpleKeyPair? _codeKeyPair;
  String? _codePublicKey;
  String? _codeChallengeId;
  String? _codePollSecret;
  Timer? _codePollTimer;
  int _codeStep = 0;
  bool _isCodeLoading = false;
  String? _codeError;
  bool _allowEmailFallback = false;
  bool _emailFallbackSent = false;
  bool _isRequestingEmailFallback = false;
  bool _emailToastShown = false;
  int _emailFallbackSeconds = 60;
  int _passwordFallbackSeconds = 120;
  bool _allowPasswordFallback = false;
  bool _isPasswordMode = false;
  Timer? _emailFallbackTimer;
  String? _maskedEmail;
  final TextEditingController _codeTextController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  final TextEditingController _codePasswordController = TextEditingController();
  final FocusNode _codePasswordFocus = FocusNode();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FocusNode _loginFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loginOriginUserId = AccountService().getActiveUserId();
    _checkAccounts();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    _startQrSession();
  }

  Future<void> _rollbackFailedLogin() async {
    final previousUserId = await _loginOriginUserId;
    await _apiService.logout();
    await CryptoService().clearKeys();
    await AccountService().restoreAccount(previousUserId);
  }

  Future<void> _startQrSession() async {
    try {
      final previousToken = _qrToken;
      final previousPollSecret = _qrPollSecret;
      _stopQrRealtime();
      _qrToken = null;
      _qrPollSecret = null;
      _qrImageBytes = null;
      _qrPayloadString = null;
      _isQrAwaitingApproval = false;
      _dismissQrVerificationModal();
      if (mounted) setState(() {});
      if (previousToken != null && previousPollSecret != null) {
        await _apiService.cancelQrSession(previousToken, previousPollSecret);
      }

      final algorithm = crypto.X25519();
      _qrEphemeralKeyPair = await algorithm.newKeyPair();
      final pubKey = await _qrEphemeralKeyPair!.extractPublicKey();
      final pubKeyBytes = Uint8List.fromList(pubKey.bytes);
      final webPubHex = pubKeyBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      _qrWebPublicKey = webPubHex;

      final res = await _apiService.createQrSession(webPubHex);
      if (res.success && res.data != null && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        _qrToken = data['token']?.toString();
        _qrPollSecret = data['poll_secret']?.toString();

        if (data['qr_image'] != null &&
            data['qr_image'].toString().startsWith('data:image/')) {
          try {
            final b64Str = data['qr_image'].toString().split(',').last;
            _qrImageBytes = base64Decode(b64Str);
          } catch (_) {}
        }

        final qrDataMap = {
          'type': 'xaneo_qr_login',
          'version': 2,
          'token': _qrToken,
          'web_pub': webPubHex,
        };
        _qrPayloadString = jsonEncode(qrDataMap);
        if (mounted) setState(() {});
        _startQrPolling();
      }
    } catch (e) {
      Logger.error('LoginScreen', 'Error in _startQrSession: $e', e);
    }
  }

  void _startQrPolling() {
    unawaited(_connectQrStatusSocket());
    _scheduleQrStatusCheck(const Duration(seconds: 30));
  }

  void _scheduleQrStatusCheck(Duration delay) {
    _qrTimer?.cancel();
    if (!mounted || _isQrApproved || _qrToken == null) return;
    _qrTimer = Timer(delay, () => unawaited(_checkQrStatus()));
  }

  Future<void> _connectQrStatusSocket() async {
    final token = _qrToken;
    final pollSecret = _qrPollSecret;
    if (!mounted || _isQrApproved || token == null || pollSecret == null) {
      return;
    }

    try {
      final client = HttpClient();
      client.badCertificateCallback = validateSslCertificate;
      final socket = await WebSocket.connect(
        ApiService.getQrLoginWebSocketUrl(),
        customClient: client,
      ).timeout(const Duration(seconds: 10));
      if (!mounted || _qrToken != token || _isQrApproved) {
        await socket.close();
        return;
      }

      await _qrSocketSubscription?.cancel();
      await _qrSocket?.close();
      _qrSocket = socket;
      _qrSocketSubscription = socket.listen(
        (raw) {
          if (_qrSocket != socket || _qrToken != token || raw is! String) {
            return;
          }
          try {
            final message = jsonDecode(raw);
            if (message is! Map || message['type'] != 'qr_status') return;
            final status = message['status']?.toString();
            if (status == 'pending') {
              if (_isQrAwaitingApproval && mounted) {
                setState(() => _isQrAwaitingApproval = false);
                _dismissQrVerificationModal();
              }
            } else if (status == 'scanned') {
              if (!_isQrAwaitingApproval && mounted) {
                setState(() => _isQrAwaitingApproval = true);
                _showQrVerificationModal();
              }
            } else if (status == 'approved') {
              unawaited(_checkQrStatus(forceAfterCurrent: true));
            } else if (status == 'expired' ||
                status == 'cancelled' ||
                status == 'consumed') {
              _stopQrRealtime();
              unawaited(_startQrSession());
            }
          } catch (e) {
            Logger.warning('LoginScreen', 'Invalid QR WebSocket event: $e');
          }
        },
        onError: (_) {
          if (_qrSocket == socket) {
            _scheduleQrReconnect(token);
          }
        },
        onDone: () {
          if (_qrSocket == socket) {
            _scheduleQrReconnect(token);
          }
        },
        cancelOnError: true,
      );
      socket.add(jsonEncode({'token': token, 'poll_secret': pollSecret}));
    } catch (e) {
      Logger.warning('LoginScreen', 'QR WebSocket unavailable: $e');
      _scheduleQrReconnect(token);
      _scheduleQrStatusCheck(const Duration(seconds: 3));
    }
  }

  void _scheduleQrReconnect(String token) {
    if (!mounted || _isQrApproved || _qrToken != token) return;
    _qrReconnectTimer?.cancel();
    _qrReconnectTimer = Timer(
      const Duration(seconds: 3),
      () => unawaited(_connectQrStatusSocket()),
    );
  }

  Future<void> _checkQrStatus({bool forceAfterCurrent = false}) async {
    final token = _qrToken;
    final pollSecret = _qrPollSecret;
    if (!mounted || _isQrApproved || token == null || pollSecret == null) {
      return;
    }
    if (_qrStatusRequestInFlight) {
      if (forceAfterCurrent) _qrStatusCheckQueued = true;
      return;
    }

    _qrStatusRequestInFlight = true;
    try {
      final res = await _apiService.getQrStatus(token, pollSecret);
      if (!mounted || _qrToken != token) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final status = data['status']?.toString();
        if (status == 'scanned') {
          if (!_isQrAwaitingApproval) {
            setState(() => _isQrAwaitingApproval = true);
            _showQrVerificationModal();
          }
        } else if (status == 'pending') {
          if (_isQrAwaitingApproval) {
            setState(() => _isQrAwaitingApproval = false);
            _dismissQrVerificationModal();
          }
        } else if (status == 'approved' && !_isQrApproved) {
          _isQrApproved = true;
          _stopQrRealtime();
          _dismissQrVerificationModal();
          await _handleQrApproved(data);
        } else if (status == 'expired' ||
            status == 'cancelled' ||
            status == 'consumed') {
          _stopQrRealtime();
          _dismissQrVerificationModal();
          unawaited(_startQrSession());
        }
      } else if (res.statusCode == 404 || res.statusCode == 410) {
        _stopQrRealtime();
        unawaited(_startQrSession());
      }
    } finally {
      _qrStatusRequestInFlight = false;
      if (_qrStatusCheckQueued &&
          mounted &&
          _qrToken == token &&
          !_isQrApproved) {
        _qrStatusCheckQueued = false;
        unawaited(_checkQrStatus());
      } else if (mounted && _qrToken == token && !_isQrApproved) {
        _scheduleQrStatusCheck(const Duration(seconds: 30));
      }
    }
  }

  void _stopQrRealtime() {
    _qrTimer?.cancel();
    _qrReconnectTimer?.cancel();
    _qrTimer = null;
    _qrReconnectTimer = null;
    _qrStatusCheckQueued = false;
    final subscription = _qrSocketSubscription;
    final socket = _qrSocket;
    _qrSocketSubscription = null;
    _qrSocket = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (socket != null) unawaited(socket.close());
  }

  void _showQrVerificationModal() {
    final token = _qrToken;
    if (!mounted || _isQrVerificationModalOpen || token == null) return;
    _isQrVerificationModalOpen = true;
    final code = token.substring(token.length - 6).toUpperCase();
    unawaited(
      QrLoginVerificationModal.show(
        context: context,
        modalKey: _qrVerificationModalKey,
        verificationCode: code,
      ).whenComplete(() => _isQrVerificationModalOpen = false),
    );
  }

  void _dismissQrVerificationModal() {
    if (!_isQrVerificationModalOpen) return;
    final modalContext = _qrVerificationModalKey.currentContext;
    final route = modalContext == null ? null : ModalRoute.of(modalContext);
    if (modalContext != null && route?.isCurrent == true) {
      Navigator.of(modalContext).pop();
    }
  }

  Future<void> _importQrKeys({
    required dynamic transferPayload,
    required crypto.SimpleKeyPair? keyPair,
    required String? token,
    required String? publicKey,
  }) async {
    if (transferPayload is! Map ||
        keyPair == null ||
        token == null ||
        publicKey == null) {
      throw StateError('Сервер не передал ключи шифрования');
    }

    final decryptedKeys = await CryptoService().decryptQrTransferPayload(
      transferPayload: Map<String, dynamic>.from(transferPayload),
      ephemeralKeyPair: keyPair,
      token: token,
      recipientPublicKeyHex: publicKey,
    );
    if (decryptedKeys == null ||
        !await CryptoService().importUserKeysFromPayload(decryptedKeys)) {
      throw StateError('Не удалось перенести ключи шифрования');
    }
    Logger.info('E2EE-DIAG', 'QR keys ready before opening messenger');
  }

  Future<void> _handleQrApproved(Map<String, dynamic> data) async {
    try {
      Logger.info(
        'LoginScreen',
        'QR login approved by mobile app! Processing tokens & keys...',
      );
      if (mounted) setState(() => _isLoading = true);

      final accessToken = data['access']?.toString();
      final refreshToken = data['refresh']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await _apiService.saveAccessToken(accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiService.saveRefreshToken(refreshToken);
      }

      await _importQrKeys(
        transferPayload: data['transfer_payload'],
        keyPair: _qrEphemeralKeyPair,
        token: _qrToken,
        publicKey: _qrWebPublicKey,
      );

      final profileRes = await _apiService.getProfile();
      final saved = profileRes.success && profileRes.data != null
          ? await AccountService().saveCurrentAccount(profileRes.data!)
          : false;
      if (!saved) throw StateError('ACCOUNT_COMMIT_FAILED');

      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.show(
          context,
          AppLocalizations.of(context)?.loginApproved ?? 'Вход выполнен',
          type: ToastType.success,
        );
        Navigator.of(context).pushReplacementNamed('/messenger');
      }
    } catch (e) {
      Logger.error('LoginScreen', 'Error in _handleQrApproved: $e', e);
      await _rollbackFailedLogin();
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.show(
          context,
          AppLocalizations.of(
                context,
              )?.oshibkaVosstanovleniyaKlyucheyNeUdalos_fe7b ??
              'Не удалось перенести ключи шифрования',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    final token = _qrToken;
    final pollSecret = _qrPollSecret;
    if (token != null && pollSecret != null && !_isQrApproved) {
      unawaited(_apiService.cancelQrSession(token, pollSecret));
    }
    _fadeController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    _codePollTimer?.cancel();
    _emailFallbackTimer?.cancel();
    _codeTextController.dispose();
    _codeFocus.dispose();
    _codePasswordController.dispose();
    _codePasswordFocus.dispose();
    _qrTimer?.cancel();
    _stopQrRealtime();
    super.dispose();
  }

  // API сервис
  final _apiService = ApiService();

  // --- Notification / Code Login handlers ---
  Future<void> _requestCodeLogin() async {
    final l10n = AppLocalizations.of(context);
    final identifier = _loginController.text.trim();
    if (identifier.isEmpty) {
      setState(() {
        _codeError =
            l10n?.enterUsernameErr ?? 'Введите имя пользователя или email';
      });
      return;
    }

    setState(() {
      _isCodeLoading = true;
      _codeError = null;
    });

    try {
      final keyPair = await crypto.X25519().newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final publicHex = Uint8List.fromList(
        publicKey.bytes,
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

      final response = await _apiService.requestNotificationLogin(
        identifier: identifier,
        recipientPublicKey: publicHex,
      );

      if (!mounted) return;

      final data = response.data;
      if (response.success && data != null) {
        _codeKeyPair = keyPair;
        _codePublicKey = publicHex;
        _codeChallengeId = data['challenge_id']?.toString();
        _codePollSecret = data['poll_secret']?.toString();
        setState(() {
          _isCodeLoading = false;
          _codeStep = 1;
          _allowEmailFallback = false;
          _allowPasswordFallback = false;
          _emailFallbackSent = false;
          _maskedEmail = null;
          _emailFallbackSeconds = 60;
          _passwordFallbackSeconds = 120;
          _isPasswordMode = false;
          _codePasswordController.clear();
        });
        _codePollTimer?.cancel();
        _codePollTimer = Timer.periodic(
          const Duration(milliseconds: 1500),
          (_) => _pollCodeLoginStatus(),
        );
        _pollCodeLoginStatus();

        _emailFallbackTimer?.cancel();
        _emailFallbackTimer = Timer.periodic(const Duration(seconds: 1), (
          timer,
        ) {
          if (!mounted) return;
          setState(() {
            if (_emailFallbackSeconds > 0) {
              _emailFallbackSeconds--;
              if (_emailFallbackSeconds == 0) _allowEmailFallback = true;
            } else {
              _allowEmailFallback = true;
            }

            if (_passwordFallbackSeconds > 0) {
              _passwordFallbackSeconds--;
              if (_passwordFallbackSeconds == 0) _allowPasswordFallback = true;
            } else {
              _allowPasswordFallback = true;
            }

            if (_allowEmailFallback && _allowPasswordFallback) {
              timer.cancel();
            }
          });
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          _codeFocus.requestFocus();
        });
        CustomToast.show(
          context,
          l10n?.codeSentToBot ?? 'Код отправлен в чат «Уведомления Xaneo».',
          type: ToastType.success,
        );
      } else {
        setState(() {
          _isCodeLoading = false;
          _codeError =
              response.error ??
              response.data?['message'] as String? ??
              l10n?.sendCodeFailedErr ??
              'Не удалось отправить код';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCodeLoading = false;
          _codeError =
              '${l10n?.sendCodeFailedErr ?? "Не удалось отправить код"}: $e';
        });
      }
    }
  }

  Future<void> _verifyCodeLogin() async {
    final l10n = AppLocalizations.of(context);
    final code = _codeTextController.text.trim();
    if (code.length != 6 ||
        _codeChallengeId == null ||
        _codePollSecret == null) {
      setState(() {
        _codeError = l10n?.enterAllDigitsErr ?? 'Введите 6-значный код';
      });
      return;
    }

    setState(() {
      _isCodeLoading = true;
      _codeError = null;
    });

    try {
      final response = await _apiService.verifyNotificationLogin(
        challengeId: _codeChallengeId!,
        pollSecret: _codePollSecret!,
        code: code,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _isCodeLoading = false;
          _codeStep = 2;
        });
        CustomToast.show(
          context,
          l10n?.confirmOnDeviceStatus ??
              'Продолжите на уже авторизованном устройстве.',
          type: ToastType.success,
        );
        _codePollTimer?.cancel();
        _codePollTimer = Timer.periodic(
          const Duration(milliseconds: 1500),
          (_) => _pollCodeLoginStatus(),
        );
        await _pollCodeLoginStatus();
      } else {
        setState(() {
          _isCodeLoading = false;
          _codeError =
              response.error ??
              response.data?['message'] as String? ??
              l10n?.invalidCodeErr ??
              'Неверный или просроченный код';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCodeLoading = false;
          _codeError =
              '${l10n?.invalidCodeErr ?? "Неверный или просроченный код"}: $e';
        });
      }
    }
  }

  Future<void> _verifyCodePasswordLogin() async {
    final l10n = AppLocalizations.of(context);
    final password = _codePasswordController.text.trim();
    if (password.isEmpty ||
        _codeChallengeId == null ||
        _codePollSecret == null) {
      setState(() {
        _codeError = l10n?.enterPasswordErr ?? 'Введите ваш пароль';
      });
      return;
    }

    _codePollTimer?.cancel();

    setState(() {
      _isCodeLoading = true;
      _codeError = null;
    });

    try {
      final response = await _apiService.verifyNotificationLoginPassword(
        challengeId: _codeChallengeId!,
        pollSecret: _codePollSecret!,
        password: password,
      );

      if (!mounted) return;

      if (response.success) {
        final access = response.data?['access']?.toString();
        final refresh = response.data?['refresh']?.toString();
        if (access != null && refresh != null) {
          await _apiService.saveAccessToken(access);
          await _apiService.saveRefreshToken(refresh);
        }

        bool cryptoSetupSuccess = false;
        try {
          final keysResponse = await _apiService.getMyKeys();
          if (keysResponse.success &&
              keysResponse.data != null &&
              keysResponse.data!['xsec2'] != null) {
            final xsec2 = keysResponse.data!['xsec2'] as Map<String, dynamic>;
            final encryptedBlob =
                xsec2['encrypted_blob'] as Map<String, dynamic>;
            cryptoSetupSuccess = await CryptoService().unlockFromBlob(
              encryptedBlob,
              password,
            );
          } else if (keysResponse.statusCode == 404 ||
              keysResponse.data?['code'] == 'KEYS_NOT_FOUND') {
            final newBlob = await CryptoService().generateAndStoreKeys(
              password,
            );
            final upload = await _apiService.uploadKeys(
              x25519PublicKey: newBlob['pub']['x25519'] as String,
              ed25519PublicKey: newBlob['pub']['ed25519'] as String,
              encryptedBlob: newBlob,
            );
            cryptoSetupSuccess = upload.success;
          }
        } catch (e) {
          Logger.error(
            'LoginScreen',
            'Key setup during password login failed: $e',
            e,
          );
        }

        if (!cryptoSetupSuccess) {
          await _rollbackFailedLogin();
          if (mounted) {
            setState(() => _isCodeLoading = false);
            CustomToast.show(
              context,
              l10n?.oshibkaVosstanovleniyaKlyucheyNeUdalos_fe7b ??
                  'Не удалось разблокировать ключи шифрования',
              type: ToastType.error,
            );
          }
          return;
        }

        final profileRes = await _apiService.getProfile();
        final saved = profileRes.success && profileRes.data != null
            ? await AccountService().saveCurrentAccount(profileRes.data!)
            : false;
        if (!saved) {
          await _rollbackFailedLogin();
          if (mounted) setState(() => _isCodeLoading = false);
          return;
        }

        if (mounted) {
          setState(() => _isCodeLoading = false);
          CustomToast.show(
            context,
            l10n?.loginApproved ?? 'Вход успешно выполнен!',
            type: ToastType.success,
          );
          Navigator.of(context).pushReplacementNamed('/messenger');
        }
      } else {
        if (_codeChallengeId != null && _codePollSecret != null) {
          _codePollTimer = Timer.periodic(
            const Duration(milliseconds: 1500),
            (_) => _pollCodeLoginStatus(),
          );
        }
        final errCode = response.data?['code']?.toString();
        final errMsg = response.data?['message']?.toString();
        setState(() {
          _isCodeLoading = false;
          if (errCode == 'INVALID_PASSWORD' ||
              errCode == 'INVALID_CREDENTIALS') {
            _codeError = l10n?.invalidPasswordErr ?? 'Неверный пароль';
          } else if (errCode == 'PASSWORD_LOGIN_NOT_AVAILABLE_YET') {
            _codeError =
                l10n?.passwordTooSoonErr ?? 'Вход по паролю пока недоступен';
          } else if (errCode == 'RATE_LIMITED' || response.statusCode == 429) {
            _codeError =
                l10n?.rateLimitedErr ??
                'Слишком много запросов. Повторите позже.';
          } else {
            _codeError =
                response.error ??
                errMsg ??
                l10n?.invalidCodeErr ??
                'Ошибка проверки пароля';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCodeLoading = false;
          _codeError =
              '${l10n?.invalidCodeErr ?? "Ошибка проверки пароля"}: $e';
        });
      }
    }
  }

  Future<void> _pollCodeLoginStatus() async {
    final l10n = AppLocalizations.of(context);
    final challenge = _codeChallengeId;
    final secret = _codePollSecret;
    if (challenge == null || secret == null) return;
    var receivedTokens = false;

    try {
      final response = await _apiService.getNotificationLoginStatus(
        challenge,
        secret,
      );
      if (!mounted) return;

      final status = response.data?['status']?.toString();
      if (response.data != null) {
        final allowFallback = response.data!['allow_email_fallback'] == true;
        final allowPassFallback =
            response.data!['allow_password_fallback'] == true;
        final fallbackSent = response.data!['email_fallback_sent'] == true;
        final maskedEmail = response.data!['email_masked']?.toString();
        if (mounted) {
          setState(() {
            if (allowFallback) {
              _allowEmailFallback = true;
              _emailFallbackSeconds = 0;
            }
            if (allowPassFallback) {
              _allowPasswordFallback = true;
              _passwordFallbackSeconds = 0;
            }
            if (allowFallback && allowPassFallback) {
              _emailFallbackTimer?.cancel();
            }
            if (fallbackSent) _emailFallbackSent = true;
            if (maskedEmail != null && maskedEmail.isNotEmpty) {
              _maskedEmail = maskedEmail;
            }
          });
          if (fallbackSent && !_emailToastShown) {
            _emailToastShown = true;
            CustomToast.show(
              context,
              l10n?.emailCodeSent(_maskedEmail ?? '') ??
                  'Код отправлен на почту',
              type: ToastType.success,
            );
          }
        }
      }

      if (response.success && status == 'approved') {
        _codePollTimer?.cancel();
        setState(() => _isCodeLoading = true);

        final access = response.data?['access']?.toString();
        final refresh = response.data?['refresh']?.toString();
        if (access == null || refresh == null) {
          throw StateError('Токены авторизации не получены');
        }

        await _apiService.saveAccessToken(access);
        await _apiService.saveRefreshToken(refresh);
        receivedTokens = true;

        await _importQrKeys(
          transferPayload: response.data?['transfer_payload'],
          keyPair: _codeKeyPair,
          token: challenge,
          publicKey: _codePublicKey,
        );

        final profileRes = await _apiService.getProfile();
        final saved = profileRes.success && profileRes.data != null
            ? await AccountService().saveCurrentAccount(profileRes.data!)
            : false;
        if (!saved) throw StateError('ACCOUNT_COMMIT_FAILED');

        if (mounted) {
          setState(() => _isCodeLoading = false);
          CustomToast.show(
            context,
            l10n?.loginApproved ?? 'Вход успешно выполнен!',
            type: ToastType.success,
          );
          Navigator.of(context).pushReplacementNamed('/messenger');
        }
      } else if (status == 'rejected' ||
          status == 'expired' ||
          status == 'cancelled') {
        _codePollTimer?.cancel();
        setState(() {
          _isCodeLoading = false;
          _codeStep = 1;
          _codeError =
              l10n?.requestExpiredErr ??
              (status == 'rejected' ? 'Запрос отклонён' : 'Сессия истекла');
        });
      }
    } catch (e) {
      Logger.error('LoginScreen', 'Error polling code login status: $e', e);
      if (receivedTokens) {
        await _rollbackFailedLogin();
      }
      if (mounted && receivedTokens) {
        setState(() {
          _isCodeLoading = false;
          _codeError =
              l10n?.oshibkaVosstanovleniyaKlyucheyNeUdalos_fe7b ??
              'Не удалось перенести ключи шифрования';
        });
      }
    }
  }

  Future<void> _requestEmailFallbackCode() async {
    final l10n = AppLocalizations.of(context);
    final challenge = _codeChallengeId;
    final secret = _codePollSecret;
    if (challenge == null || secret == null) return;

    setState(() {
      _isRequestingEmailFallback = true;
      _codeError = null;
    });

    try {
      final response = await _apiService.requestNotificationEmailFallback(
        challengeId: challenge,
        pollSecret: secret,
      );

      if (!mounted) return;

      if (response.success) {
        final dataMap = response.data is Map ? (response.data as Map) : {};
        final emailMasked = dataMap['email_masked']?.toString();
        setState(() {
          _isRequestingEmailFallback = false;
          _emailFallbackSent = true;
          if (emailMasked != null && emailMasked.isNotEmpty) {
            _maskedEmail = emailMasked;
          }
          _codeStep = 1;
        });
        if (!_emailToastShown) {
          _emailToastShown = true;
          CustomToast.show(
            context,
            l10n?.emailCodeSent(_maskedEmail ?? '') ?? 'Код отправлен на почту',
            type: ToastType.success,
          );
        }
      } else {
        final dataMap = response.data is Map ? (response.data as Map) : null;
        final errorMsg =
            response.error ??
            dataMap?['message']?.toString() ??
            l10n?.emailCodeFailed ??
            'Не удалось отправить код на email';
        setState(() {
          _isRequestingEmailFallback = false;
          _codeError = errorMsg;
        });
        CustomToast.show(context, errorMsg, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg =
            '${l10n?.emailCodeFailed ?? "Не удалось отправить код на email"}: $e';
        setState(() {
          _isRequestingEmailFallback = false;
          _codeError = errorMsg;
        });
        CustomToast.show(context, errorMsg, type: ToastType.error);
      }
    }
  }

  void _cancelCodeLogin() {
    _codePollTimer?.cancel();
    _emailFallbackTimer?.cancel();
    if (_codeChallengeId != null && _codePollSecret != null) {
      unawaited(
        _apiService.cancelNotificationLogin(
          _codeChallengeId!,
          _codePollSecret!,
        ),
      );
    }
    setState(() {
      _codeStep = 0;
      _codeChallengeId = null;
      _codePollSecret = null;
      _codeError = null;
      _allowEmailFallback = false;
      _allowPasswordFallback = false;
      _emailFallbackSent = false;
      _isRequestingEmailFallback = false;
      _emailFallbackSeconds = 60;
      _passwordFallbackSeconds = 120;
      _isPasswordMode = false;
      _codePasswordController.clear();
      _maskedEmail = null;
      _isCodeLoading = false;
      _codeTextController.clear();
    });
  }

  Future<void> _checkAccounts() async {
    final accounts = await AccountService().getAccounts();
    if (mounted) {
      setState(() {
        _hasAccounts = accounts.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final showRightPanel = screenWidth > 750;
    final canGoBack = Navigator.of(context).canPop() || _hasAccounts;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF070707)
          : const Color(0xFFFAF9FB),
      body: Stack(
        children: [
          // Main Split Screen Layout
          Row(
            children: [
              // Left Column: The Form
              Expanded(
                flex: showRightPanel ? 5 : 10,
                child: Container(
                  color: isDark
                      ? const Color(0xFF0C0C0C)
                      : const Color(0xFFFFFFFF),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 48,
                        ),
                        child: _ScaledContent(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _fadeAnimation,
                              _slideAnimation,
                            ]),
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildAuthV2LeftContent(
                                    l10n!,
                                    isDark,
                                    showRightPanel,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Right Column: Minimal Branding Panel (only shown on wider screens)
              if (showRightPanel)
                Expanded(
                  flex: 6,
                  child: _ScaledContent(
                    child: _buildAuthV2RightContent(l10n!, isDark),
                  ),
                ),
            ],
          ),

          // Settings button trigger
          const Positioned.fill(child: SettingsButton()),

          // Back button to return to messenger
          if (canGoBack)
            Positioned(
              top: 50,
              left: 20,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep = 0;
                      });
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _loginFocus.requestFocus();
                      });
                    } else {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else if (_hasAccounts) {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed('/messenger');
                      }
                    }
                  },
                  child: Tooltip(
                    message:
                        (AppLocalizations.of(
                          context,
                        )?.nazadKMessendzheru_de29 ??
                        'Fallback'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.03),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginField(AppLocalizations? l10n, bool isDark) {
    return CustomTextFormField(
      controller: _loginController,
      focusNode: _loginFocus,
      labelText: l10n!.loginFieldHint,
      icon: FontAwesomeIcons.user,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.fillAllFields;
        }
        return null;
      },
    );
  }

  Widget _buildAuthV2LeftContent(
    AppLocalizations l10n,
    bool isDark,
    bool showRightPanel,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 44,
            height: 44,
            color: isDark ? Colors.white : Colors.black,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey<bool>(_isQrMode),
              child: _isQrMode
                  ? _buildQrModeInstructions(l10n, isDark, showRightPanel)
                  : _buildCodeModeForm(l10n, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrModeInstructions(
    AppLocalizations l10n,
    bool isDark,
    bool showRightPanel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.qrLoginTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.qrLoginSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            height: 1.5,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.qrScanInstructionTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(l10n.qrStep1, isDark),
              const SizedBox(height: 8),
              _buildInstructionStep(l10n.qrStep2, isDark),
              const SizedBox(height: 8),
              _buildInstructionStep(l10n.qrStep3, isDark),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // If on mobile (no right panel), show QR code inline
        if (!showRightPanel) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildQrAuthorizationContent(
                l10n: l10n,
                size: 200,
                preferServerImage: false,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isQrMode = false;
                _currentStep = 0;
              });
            },
            icon: Icon(
              Icons.password,
              color: isDark ? Colors.black : Colors.white,
            ),
            label: Text(
              l10n.qrCodeLoginBtn,
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
        height: 1.5,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildCodeModeForm(AppLocalizations l10n, bool isDark) {
    String subtitleText;
    if (_codeStep == 0) {
      subtitleText = l10n.codeLoginSubtitle;
    } else if (_codeStep == 1) {
      subtitleText = l10n.sixDigitCodeSentSub;
    } else {
      subtitleText = l10n.confirmOnDeviceSub;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.codeLoginTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitleText,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 24),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey<int>(_codeStep),
            child: _codeStep == 0
                ? _buildLoginField(l10n, isDark)
                : _codeStep == 1
                ? (_isPasswordMode
                      ? CustomTextFormField(
                          controller: _codePasswordController,
                          focusNode: _codePasswordFocus,
                          labelText: l10n.password,
                          icon: FontAwesomeIcons.lock,
                          isPasswordField: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.enterPasswordErr;
                            }
                            return null;
                          },
                        )
                      : CustomTextFormField(
                          controller: _codeTextController,
                          focusNode: _codeFocus,
                          labelText: l10n.sixDigitCodeLabel,
                          icon: FontAwesomeIcons.key,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.fillAllFields;
                            }
                            if (value.trim().length != 6) {
                              return l10n.mustBeSixDigits;
                            }
                            return null;
                          },
                        ))
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            l10n.awaitingDeviceApproval,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),

        if (_codeError != null) ...[
          const SizedBox(height: 12),
          Text(
            _codeError!,
            style: const TextStyle(color: Color(0xFFE57373), fontSize: 13),
          ),
        ],

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.codeInstructionTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeStep == 0
                    ? l10n.codeInstructionText
                    : _codeStep == 1
                    ? (_emailFallbackSent
                          ? l10n.emailCodeSent(_maskedEmail ?? '')
                          : l10n.codeSentToBot)
                    : l10n.confirmDeviceRequestText,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  height: 1.5,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),

        if (_codeStep == 1) ...[
          const SizedBox(height: 16),
          Center(
            child:
                (!_allowEmailFallback &&
                    _emailFallbackSeconds > 0 &&
                    !_emailFallbackSent)
                ? Text(
                    l10n.requestCodeViaEmailIn(_emailFallbackSeconds),
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  )
                : MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isRequestingEmailFallback
                          ? null
                          : _requestEmailFallbackCode,
                      child: Text(
                        _emailFallbackSent
                            ? l10n.resendCodeToEmail
                            : l10n.cantLoginSendToEmail,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
          ),
        ],

        if (_codeStep == 1 && !_isPasswordMode) ...[
          const SizedBox(height: 8),
          Center(
            child: (!_allowPasswordFallback && _passwordFallbackSeconds > 0)
                ? Text(
                    l10n.requestCodeViaPasswordIn(
                      _allowEmailFallback
                          ? (_passwordFallbackSeconds > 60
                                ? _passwordFallbackSeconds - 60
                                : _passwordFallbackSeconds)
                          : _passwordFallbackSeconds,
                    ),
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  )
                : MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordMode = true;
                        });
                        _codePasswordFocus.requestFocus();
                      },
                      child: Text(
                        l10n.loginWithPasswordLink,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
          ),
        ],

        const SizedBox(height: 32),
        if (_codeStep < 2)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCodeLoading
                  ? null
                  : (_codeStep == 0
                        ? _requestCodeLogin
                        : (_isPasswordMode
                              ? _verifyCodePasswordLogin
                              : _verifyCodeLogin)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCodeLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    )
                  : Text(
                      _codeStep == 0
                          ? l10n.getCodeBtn
                          : (_isPasswordMode
                                ? l10n.submitCodeBtn
                                : l10n.continueBtn),
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (_codeStep > 0) {
                _cancelCodeLogin();
              } else {
                setState(() {
                  _isQrMode = true;
                  _currentStep = 0;
                });
              }
            },
            icon: Icon(
              _codeStep > 0 ? Icons.arrow_back : Icons.qr_code,
              color: isDark ? Colors.white : Colors.black,
            ),
            label: Text(
              _codeStep > 0 ? l10n.backBtn : l10n.backToQrBtn,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        if (_currentStep > 0)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: Text(
                    l10n.back,
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAuthV2RightContent(AppLocalizations l10n, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF5F5F5),
        border: Border(
          left: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: _buildQrAuthorizationContent(
                l10n: l10n,
                size: 280,
                preferServerImage: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrAuthorizationContent({
    required AppLocalizations l10n,
    required double size,
    required bool preferServerImage,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: _isQrAwaitingApproval
          ? SizedBox(
              key: const ValueKey('qr-awaiting-approval'),
              width: size,
              height: size,
              child: Padding(
                padding: EdgeInsets.all(size >= 260 ? 30 : 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: size >= 260 ? 56 : 48,
                      height: size >= 260 ? 56 : 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                      ),
                      child: Icon(
                        Icons.phonelink_lock_rounded,
                        color: const Color(0xFF27272A),
                        size: size >= 260 ? 28 : 24,
                      ),
                    ),
                    SizedBox(height: size >= 260 ? 18 : 14),
                    Text(
                      l10n.qrApprovalTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF18181B),
                        fontSize: size >= 260 ? 18 : 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.qrApprovalDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF71717A),
                        fontSize: size >= 260 ? 13 : 11.5,
                        height: 1.4,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey('qr-code'),
              width: size,
              height: size,
              child: _buildQrImage(size, preferServerImage),
            ),
    );
  }

  Widget _buildQrImage(double size, bool preferServerImage) {
    if (preferServerImage && _qrImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _qrImageBytes!,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }
    if (_qrPayloadString != null && _qrPayloadString!.isNotEmpty) {
      return QrImageView(
        data: _qrPayloadString!,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
      );
    }
    return const Center(child: CircularProgressIndicator(color: Colors.black));
  }
}

/// Виджет для применения масштаба к контенту
class _ScaledContent extends StatelessWidget {
  final Widget child;

  const _ScaledContent({required this.child});

  @override
  Widget build(BuildContext context) {
    final scaleProvider = context.watch<ScaleProvider?>();
    final scale = scaleProvider?.scale ?? 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: child,
    );
  }
}
