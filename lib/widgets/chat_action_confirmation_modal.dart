import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'base_custom_modal.dart';

class ChatActionConfirmationModal extends BaseCustomModal {
  const ChatActionConfirmationModal({
    super.key,
    required this.modalTitle,
    required this.message,
    required this.confirmLabel,
  });

  final String modalTitle;
  final String message;
  final String confirmLabel;

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await BaseCustomModal.show<bool>(
          context: context,
          modal: ChatActionConfirmationModal(
            modalTitle: title,
            message: message,
            confirmLabel: confirmLabel,
          ),
          barrierLabel: 'ChatActionConfirmation',
        ) ??
        false;
  }

  @override
  State<ChatActionConfirmationModal> createState() =>
      _ChatActionConfirmationModalState();
}

class _ChatActionConfirmationModalState
    extends BaseCustomModalState<ChatActionConfirmationModal> {
  @override
  double get modalWidth => 430;

  @override
  double get modalHeightFactor => 0.55;

  @override
  String getModalTitle(BuildContext context) => widget.modalTitle.toUpperCase();

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final foreground = isDark ? Colors.white : const Color(0xFF161616);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20 * scale,
        12 * scale,
        20 * scale,
        20 * scale,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.message,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.68),
              fontSize: 14 * scale,
              height: 1.45,
            ),
          ),
          SizedBox(height: 22 * scale),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(widget.confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
