import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/message_color_presets.dart';
import '../l10n/app_localizations.dart';
import 'base_custom_modal.dart';

/// Base reusable custom-color picker modal, built on [BaseCustomModal] so it
/// shares the app's standard modal chrome (rounded dark card, fade+scale
/// transition, header/close button) instead of a generic Material dialog.
/// A visual Paint-style picker (saturation/value square + hue ring + hex
/// input) rather than a bare hex text field, so people don't have to guess
/// hex combinations by hand.
class ColorPickerModal extends BaseCustomModal {
  const ColorPickerModal({
    super.key,
    required this.modalTitle,
    required this.initialColor,
  });

  final String modalTitle;
  final Color initialColor;

  static Future<Color?> pick({
    required BuildContext context,
    required Color initial,
    String? title,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return BaseCustomModal.show<Color>(
      context: context,
      modal: ColorPickerModal(
        modalTitle: title ?? l10n.customColor,
        initialColor: initial,
      ),
      barrierLabel: 'ColorPicker',
    );
  }

  @override
  State<ColorPickerModal> createState() => _ColorPickerModalState();
}

class _ColorPickerModalState extends BaseCustomModalState<ColorPickerModal> {
  late Color _selected = widget.initialColor;

  @override
  double get modalWidth => 440;

  @override
  double get modalHeightFactor => 0.78;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            // flutter_colorpicker's landscape layout is 600 px wide:
            // 260 px for the palette and 340 px for the indicator/slider.
            // Give it that natural width, then scale the complete control down
            // when the modal has less room so the slider and Hex input are not
            // clipped.
            width: 600,
            child: ColorPicker(
              pickerColor: widget.initialColor,
              onColorChanged: (c) => _selected = c,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              hexInputBar: true,
              labelTypes: const [],
              colorPickerWidth: 260,
            ),
          ),
        ),
        SizedBox(height: 16 * scale),
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
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Base reusable custom-gradient picker modal (same [BaseCustomModal] chrome
/// as [ColorPickerModal]); each of its two color stops opens
/// [ColorPickerModal] itself, so the whole "custom color" flow shares one
/// visual picker end to end.
class GradientPickerModal extends BaseCustomModal {
  const GradientPickerModal({super.key, required this.initial});

  final GradientSpec initial;

  static Future<GradientSpec?> pick({
    required BuildContext context,
    required GradientSpec initial,
  }) {
    return BaseCustomModal.show<GradientSpec>(
      context: context,
      modal: GradientPickerModal(initial: initial),
      barrierLabel: 'GradientPicker',
    );
  }

  @override
  State<GradientPickerModal> createState() => _GradientPickerModalState();
}

class _GradientPickerModalState
    extends BaseCustomModalState<GradientPickerModal> {
  late Color _c1 = widget.initial.color1;
  late Color _c2 = widget.initial.color2;
  late GradientDirection _direction = widget.initial.direction;

  @override
  double get modalWidth => 440;

  @override
  double get modalHeightFactor => 0.78;

  @override
  String getModalTitle(BuildContext context) =>
      AppLocalizations.of(context)!.customGradient.toUpperCase();

  Future<void> _pickStop(bool isFirst) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await ColorPickerModal.pick(
      context: context,
      initial: isFirst ? _c1 : _c2,
      title: isFirst ? l10n.colorOne : l10n.colorTwo,
    );
    if (picked != null) {
      setState(() {
        if (isFirst) {
          _c1 = picked;
        } else {
          _c2 = picked;
        }
      });
    }
  }

  Widget _stopButton({
    required String label,
    required Color color,
    required bool isDark,
    required double scale,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 8 * scale,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16 * scale,
                height: 16 * scale,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48 * scale,
          decoration: BoxDecoration(
            gradient: GradientSpec(
              color1: _c1,
              color2: _c2,
              direction: _direction,
            ).toLinearGradient(),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
        ),
        SizedBox(height: 14 * scale),
        Row(
          children: [
            Expanded(
              child: _stopButton(
                label: l10n.colorOne,
                color: _c1,
                isDark: isDark,
                scale: scale,
                onTap: () => _pickStop(true),
              ),
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: _stopButton(
                label: l10n.colorTwo,
                color: _c2,
                isDark: isDark,
                scale: scale,
                onTap: () => _pickStop(false),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * scale),
        DropdownButtonFormField<GradientDirection>(
          initialValue: _direction,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: GradientDirection.diagonal,
              child: Text(l10n.diagonal),
            ),
            DropdownMenuItem(
              value: GradientDirection.vertical,
              child: Text(l10n.vertical),
            ),
            DropdownMenuItem(
              value: GradientDirection.horizontal,
              child: Text(l10n.horizontal),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _direction = v);
          },
        ),
        SizedBox(height: 16 * scale),
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
                onPressed: () => Navigator.of(context).pop(
                  GradientSpec(color1: _c1, color2: _c2, direction: _direction),
                ),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
