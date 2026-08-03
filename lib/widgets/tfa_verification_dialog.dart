import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'base_custom_modal.dart';

class TfaVerificationDialog extends BaseCustomModal {
  const TfaVerificationDialog({
    super.key,
    required this.token,
    required this.apiService,
    this.emailMasked,
  });

  final String token;
  final ApiService apiService;
  final String? emailMasked;

  static Future<bool?> show({
    required BuildContext context,
    required String token,
    required ApiService apiService,
    String? emailMasked,
  }) {
    return BaseCustomModal.show<bool>(
      context: context,
      modal: TfaVerificationDialog(
        token: token,
        apiService: apiService,
        emailMasked: emailMasked,
      ),
      barrierLabel: 'TwoFactorAuthentication',
      barrierDismissible: false,
    );
  }

  @override
  State<TfaVerificationDialog> createState() => _TfaVerificationDialogState();
}

class _TfaVerificationDialogState
    extends BaseCustomModalState<TfaVerificationDialog> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  @override
  double get modalWidth => 430;

  @override
  double get modalHeightFactor => 0.72;

  @override
  String getModalTitle(BuildContext context) {
    return AppLocalizations.of(context)!.twoFactorAuth.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.length != 6 || _isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await widget.apiService.verifyTfaCode(
      widget.token,
      _codeController.text,
    );
    if (!mounted) return;
    if (response.success && response.data?['success'] == true) {
      Navigator.of(context).pop(response.data?['_jwt_issued'] == true);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = false;
      _error =
          response.error ??
          response.data?['message'] as String? ??
          l10n.invalidVerificationCode;
    });
    _codeController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _resend() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final response = await widget.apiService.sendTfaCode(widget.token);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = false;
      if (!response.success || response.data?['success'] != true) {
        _error =
            response.error ??
            response.data?['message'] as String? ??
            l10n.sendCodeError;
      }
    });
    if (_error == null) {
      _codeController.clear();
      _focusNode.requestFocus();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.codeSent)));
    }
  }

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final foreground = isDark ? Colors.white : const Color(0xFF161616);
    final muted = isDark ? Colors.white54 : Colors.black54;
    final fieldColor = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFF5F5F5);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE1E1E1);
    final canSubmit = _codeController.text.length == 6 && !_isLoading;

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46 * scale,
                height: 46 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: borderColor),
                ),
                child: FaIcon(
                  FontAwesomeIcons.shieldHalved,
                  size: 19 * scale,
                  color: foreground,
                ),
              ),
              SizedBox(width: 14 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.twoFactorAuth,
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    SizedBox(height: 3 * scale),
                    Text(
                      l10n.twoFactorAuthDesc,
                      style: TextStyle(fontSize: 12 * scale, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 22 * scale),
          Text(
            widget.emailMasked?.isNotEmpty == true
                ? l10n.codeSentToEmail(widget.emailMasked!)
                : l10n.codeSent,
            style: TextStyle(fontSize: 14 * scale, color: muted, height: 1.4),
          ),
          SizedBox(height: 18 * scale),
          Text(
            l10n.enterVerificationCode,
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          SizedBox(height: 8 * scale),
          TextField(
            controller: _codeController,
            focusNode: _focusNode,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 12 * scale,
              color: foreground,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              filled: true,
              fillColor: fieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scale),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scale),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scale),
                borderSide: BorderSide(color: foreground, width: 1.4),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...[
            SizedBox(height: 10 * scale),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12 * scale,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          SizedBox(height: 18 * scale),
          SizedBox(
            width: double.infinity,
            height: 46 * scale,
            child: FilledButton(
              onPressed: canSubmit ? _verify : null,
              child: _isLoading
                  ? SizedBox(
                      width: 18 * scale,
                      height: 18 * scale,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.continueButton),
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: _isLoading ? null : _resend,
                child: Text(l10n.resendCode),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
