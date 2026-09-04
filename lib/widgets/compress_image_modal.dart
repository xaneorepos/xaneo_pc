import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'base_custom_modal.dart';

/// Выбирает только способ отображения: фото или файл.
/// Исходное изображение не пережимается.
class CompressImageModal extends BaseCustomModal {
  const CompressImageModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return BaseCustomModal.show<bool>(
      context: context,
      modal: const CompressImageModal(),
      barrierLabel: 'CompressImage',
    );
  }

  @override
  State<CompressImageModal> createState() => _CompressImageModalState();
}

class _CompressImageModalState
    extends BaseCustomModalState<CompressImageModal> {
  bool _compress = true;

  @override
  double get modalWidth => 420;

  @override
  double get modalHeightFactor => 0.5;

  @override
  String getModalTitle(BuildContext context) => 'Отправка фото';

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
      padding: EdgeInsets.fromLTRB(0, 4 * scale, 0, 8 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10 * scale),
            onTap: () => setState(() => _compress = !_compress),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6 * scale),
              child: Row(
                children: [
                  Checkbox(
                    value: _compress,
                    onChanged: (v) => setState(() => _compress = v ?? true),
                  ),
                  SizedBox(width: 4 * scale),
                  Expanded(
                    child: Text(
                      'Показывать как фото (без потери качества)',
                      style: TextStyle(color: foreground, fontSize: 14 * scale),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20 * scale),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_compress),
                  child: const Text('Отправить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
