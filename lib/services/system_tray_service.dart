import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../l10n/app_localizations.dart';

class SystemTrayService with TrayListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  bool _initialized = false;
  VoidCallback? _onOpenSettings;

  Future<void> init({VoidCallback? onOpenSettings}) async {
    _onOpenSettings = onOpenSettings;
    if (_initialized) return;
    _initialized = true;

    trayManager.addListener(this);

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await trayManager.setIcon('assets/logo.png');
        await trayManager.setToolTip('Xaneo PC');
      } catch (e) {
        debugPrint('Failed to set system tray icon: $e');
      }
    }
  }

  void setOpenSettingsCallback(VoidCallback? callback) {
    _onOpenSettings = callback;
  }

  Future<void> updateContextMenu(BuildContext context) async {
    if (!kIsWeb && !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    final l10n = AppLocalizations.of(context);
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: l10n?.showWindow ?? 'Показать Xaneo',
        ),
        MenuItem(
          key: 'settings',
          label: l10n?.settings ?? 'Настройки',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: l10n?.exitApp ?? 'Выйти из Xaneo',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  Future<void> destroy() async {
    try {
      trayManager.removeListener(this);
      await trayManager.destroy();
    } catch (_) {}
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
    windowManager.setSkipTaskbar(false);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
      windowManager.setSkipTaskbar(false);
    } else if (menuItem.key == 'settings') {
      windowManager.show();
      windowManager.focus();
      windowManager.setSkipTaskbar(false);
      _onOpenSettings?.call();
    } else if (menuItem.key == 'exit_app') {
      destroy();
      windowManager.destroy();
      exit(0);
    }
  }
}
