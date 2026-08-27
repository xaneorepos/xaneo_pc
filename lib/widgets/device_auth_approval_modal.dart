import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'base_custom_modal.dart';

class DeviceAuthApprovalModal extends BaseCustomModal {
  const DeviceAuthApprovalModal({
    super.key,
    required this.deviceName,
    required this.clientName,
    required this.ipAddress,
  }) : super(modalTag: '');

  final String deviceName;
  final String clientName;
  final String ipAddress;

  static Future<bool> confirm({
    required BuildContext context,
    required String deviceName,
    required String clientName,
    required String ipAddress,
  }) async {
    return await BaseCustomModal.show<bool>(
          context: context,
          barrierDismissible: false,
          barrierLabel: 'DeviceAuthApproval',
          modal: DeviceAuthApprovalModal(
            deviceName: deviceName,
            clientName: clientName,
            ipAddress: ipAddress,
          ),
        ) ??
        false;
  }

  @override
  State<DeviceAuthApprovalModal> createState() =>
      _DeviceAuthApprovalModalState();
}

class _DeviceAuthApprovalModalState
    extends BaseCustomModalState<DeviceAuthApprovalModal> {
  @override
  double get modalWidth => 440;

  @override
  double get modalHeightFactor => 0.78;

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final l10n = AppLocalizations.of(context);
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
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 44 * scale,
              height: 44 * scale,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(color: border),
              ),
              child: Icon(
                Icons.verified_user_outlined,
                size: 22 * scale,
                color: foreground,
              ),
            ),
          ),
          SizedBox(height: 17 * scale),
          Text(
            l10n?.confirmOnDeviceStatus ?? 'Подтвердите вход',
            style: TextStyle(
              color: foreground,
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          SizedBox(height: 9 * scale),
          Text(
            l10n?.confirmOnDeviceSub ?? 'Код верный. Разрешите вход, только если этот запрос создали вы.',
            style: TextStyle(color: muted, fontSize: 14 * scale, height: 1.45),
          ),
          SizedBox(height: 19 * scale),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _FactRow(
                  label: l10n?.platform ?? 'Устройство',
                  value: widget.deviceName,
                  foreground: foreground,
                  scale: scale,
                ),
                Divider(height: 1, indent: 14 * scale, endIndent: 14 * scale),
                _FactRow(
                  label: l10n?.appInfo ?? 'Приложение',
                  value: widget.clientName,
                  foreground: foreground,
                  scale: scale,
                ),
                Divider(height: 1, indent: 14 * scale, endIndent: 14 * scale),
                _FactRow(
                  label: 'IP',
                  value: widget.ipAddress,
                  foreground: foreground,
                  scale: scale,
                ),
              ],
            ),
          ),
          SizedBox(height: 13 * scale),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.key_outlined, size: 17 * scale, color: muted),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  l10n?.confirmDeviceRequestText ?? 'Ключи чатов будут переданы на новое устройство в зашифрованном виде.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12.5 * scale,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 22 * scale),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n?.otklonit_8b0d ?? 'Отклонить'),
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF18181B),
                    foregroundColor: isDark
                        ? const Color(0xFF18181B)
                        : Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n?.loginApproved ?? 'Разрешить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.value,
    required this.foreground,
    required this.scale,
  });

  final String label;
  final String value;
  final Color foreground;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 11 * scale,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104 * scale,
            child: Text(
              label,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.5),
                fontSize: 12.5 * scale,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: foreground,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
