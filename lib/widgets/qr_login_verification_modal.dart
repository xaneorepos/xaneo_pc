import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'base_custom_modal.dart';

class QrLoginVerificationModal extends BaseCustomModal {
  const QrLoginVerificationModal({super.key, required this.verificationCode});

  final String verificationCode;

  static Future<void> show({
    required BuildContext context,
    required GlobalKey modalKey,
    required String verificationCode,
  }) {
    return BaseCustomModal.show<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'QrLoginVerification',
      modal: QrLoginVerificationModal(
        key: modalKey,
        verificationCode: verificationCode,
      ),
    );
  }

  @override
  State<QrLoginVerificationModal> createState() =>
      _QrLoginVerificationModalState();
}

class _QrLoginVerificationModalState
    extends BaseCustomModalState<QrLoginVerificationModal> {
  @override
  double get modalWidth => 430;

  @override
  double get modalHeightFactor => 0.62;

  @override
  String getModalTitle(BuildContext context) =>
      AppLocalizations.of(context)!.qrApprovalTitle.toUpperCase();

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final foreground = isDark ? Colors.white : const Color(0xFF18181B);
    final muted = foreground.withValues(alpha: 0.58);
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.055)
        : const Color(0xFFF4F4F5);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : const Color(0xFFE4E4E7);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20 * scale,
        8 * scale,
        20 * scale,
        22 * scale,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.qrApprovalDesc,
            style: TextStyle(color: muted, fontSize: 14 * scale, height: 1.45),
          ),
          SizedBox(height: 20 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 18 * scale,
              vertical: 16 * scale,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Text(
                  l10n.qrVerificationCodeLabel.toUpperCase(),
                  style: TextStyle(
                    color: muted,
                    fontSize: 10.5 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.25 * scale,
                  ),
                ),
                SizedBox(height: 9 * scale),
                SelectableText(
                  widget.verificationCode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 28 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6 * scale,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14 * scale),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 17 * scale, color: muted),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  l10n.qrVerificationCodeHint,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12.5 * scale,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
