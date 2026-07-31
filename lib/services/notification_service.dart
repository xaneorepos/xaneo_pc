import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'package:xaneo/main.dart';
import 'package:xaneo/services/webrtc/call_manager.dart';
import 'package:xaneo/screens/webrtc/active_call_screen.dart';
import 'package:xaneo/utils/win32_overlay_helper.dart';
import 'api_service.dart';
import '../l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  String? _lastNotifiedChatId;
  String? _lastNotifiedBody;
  DateTime? _lastNotifiedTime;

  LocalNotification? _activeCallNotification;
  int? _activeCallOverlayWindowId;
  int? _overlayWindowId;

  /// Инициализация сервиса уведомлений
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (!kIsWeb && Platform.isWindows) {
        await localNotifier.setup(
          appName: 'Xaneo',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } else {
        await localNotifier.setup(
          appName: 'Xaneo',
        );
      }
    } catch (e) {
      debugPrint('NotificationService: localNotifier setup error: $e');
    }

    _initialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Проверяет, поддерживается ли кастомный оверлей на текущей платформе и сессии.
  /// На macOS и Linux Wayland кастомные оверлеи не поддерживаются из-за ограничений позиционирования окон.
  static bool isCustomOverlaySupported() {
    // Отключаем кастомные уведомления полностью из-за нестабильности плагина desktop_multi_window
    // Теперь приложение будет всегда использовать стабильные нативные toast-уведомления (через local_notifier)
    return false;
  }

  /// Показать уведомление о новом сообщении
  Future<void> showMessageNotification({
    required String chatId,
    required String title,
    required String body,
    String? avatar,
    String? gradient,
  }) async {
    final now = DateTime.now();
    if (_lastNotifiedChatId == chatId &&
        _lastNotifiedBody == body &&
        _lastNotifiedTime != null &&
        now.difference(_lastNotifiedTime!).inSeconds < 3) {
      debugPrint('🔔 [DEDUPLICATED] Skipping duplicate notification for chatId: $chatId');
      return;
    }
    _lastNotifiedChatId = chatId;
    _lastNotifiedBody = body;
    _lastNotifiedTime = now;

    final prefs = await SharedPreferences.getInstance();
    // По умолчанию кастомный оверлей включен, если он поддерживается
    final useCustomNotifications = isCustomOverlaySupported() && 
        (prefs.getBool('use_custom_notifications') ?? true);

    if (useCustomNotifications) {
      try {
        await _showCustomOverlay(
          chatId: chatId,
          title: title,
          body: body,
          avatar: avatar,
          gradient: gradient,
        );
        return;
      } catch (e) {
        debugPrint('NotificationService: Failed to show custom overlay, falling back to native: $e');
      }
    }

    // Если кастомный оверлей выключен, не поддерживается или упал, используем нативное уведомление ОС
    await _showNativeNotification(
      chatId: chatId,
      title: title,
      body: body,
    );
  }

  /// Показать уведомление о входящем звонке с кнопками
  Future<void> showCallNotification({
    required String callId,
    required String callerName,
    required String callType,
    String? avatar,
    String? gradient,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final useCustomNotifications = isCustomOverlaySupported() && 
        (prefs.getBool('use_custom_notifications') ?? true);

    if (useCustomNotifications) {
      try {
        await _showCustomCallOverlay(
          callId: callId,
          callerName: callerName,
          callType: callType,
          avatar: avatar,
          gradient: gradient,
        );
        return;
      } catch (e) {
        debugPrint('NotificationService: Failed to show custom call overlay, falling back to native: $e');
      }
    }

    await _showNativeCallNotification(
      callId: callId,
      callerName: callerName,
      callType: callType,
    );
  }

  /// Закрыть / скрыть активное уведомление звонка
  Future<void> dismissCallNotification() async {
    if (_activeCallNotification != null) {
      try {
        await _activeCallNotification!.close();
      } catch (e) {
        debugPrint('NotificationService: error closing native notification: $e');
      }
      _activeCallNotification = null;
    }

    if (_activeCallOverlayWindowId != null) {
      try {
        WindowController.fromWindowId(_activeCallOverlayWindowId!).hide();
      } catch (e) {
        debugPrint('NotificationService: error hiding custom overlay window: $e');
      }
      // Do not set _activeCallOverlayWindowId to null because the window is reused
    }
  }

  /// Отображение системного нативного баннера сообщения
  Future<void> _showNativeNotification({
    required String chatId,
    required String title,
    required String body,
  }) async {
    final context = navigatorKey.currentContext;
    final l10n = context != null ? AppLocalizations.of(context) : null;
    final openText = l10n?.openChat ?? 'Открыть чат';
    final readText = l10n?.markAsRead ?? 'Прочитано';

    if (!kIsWeb && Platform.isLinux) {
      try {
        final res = await Process.run('notify-send', [
          '--action=open=$openText',
          '--action=read=$readText',
          '-a',
          'Xaneo',
          '-i',
          'dialog-information',
          title,
          body,
        ]);

        final clickedAction = res.stdout.toString().trim();
        debugPrint('NotificationService: Linux notify-send clicked action: "$clickedAction"');

        if (clickedAction == 'open') {
          await windowManager.show();
          await windowManager.focus();
        } else if (clickedAction == 'read') {
          try {
            await ApiService().markMessagesAsRead(chatId);
          } catch (e) {
            debugPrint('Mark as read error: $e');
          }
        }
        return;
      } catch (e) {
        debugPrint('NotificationService: notify-send failed: $e');
      }
    }

    try {
      final notification = LocalNotification(
        title: title,
        body: body,
        actions: [
          LocalNotificationAction(text: openText),
          LocalNotificationAction(text: readText),
        ],
      );

      notification.onClick = () {
        debugPrint('Notification clicked: open chat $chatId');
        windowManager.show();
        windowManager.focus();
      };

      notification.onClickAction = (actionIndex) async {
        if (actionIndex == 0) {
          // Открыть чат
          debugPrint('Button clicked: open chat $chatId');
          await windowManager.show();
          await windowManager.focus();
        } else if (actionIndex == 1) {
          // Отметить как прочитанное
          debugPrint('Button clicked: mark as read $chatId');
          try {
            final res = await ApiService().markMessagesAsRead(chatId);
            debugPrint('Mark as read result: ${res.success} for chat $chatId');
          } catch (e) {
            debugPrint('Mark as read error: $e');
          }
        }
      };

      await notification.show();
    } catch (e) {
      debugPrint('NotificationService: Error showing local_notification: $e');
    }
  }

  /// Отображение системного нативного баннера звонка с кнопками
  Future<void> _showNativeCallNotification({
    required String callId,
    required String callerName,
    required String callType,
  }) async {
    await dismissCallNotification();

    final context = navigatorKey.currentContext;
    final l10n = context != null ? AppLocalizations.of(context) : null;
    final typeText = callType == 'video'
        ? (l10n?.videozvonok_dd18 ?? 'видеозвонок')
        : (l10n?.golosovoyZvonok_5410 ?? 'аудиозвонок');
    final acceptText = l10n?.otvetit_e568 ?? 'Ответить';
    final declineText = l10n?.otklonit_8b0d ?? 'Отклонить';
    final titleText = l10n?.vhodyaschiyVyzov_905e ?? 'Входящий вызов';
    final bodyText = '$callerName ($typeText)';

    if (!kIsWeb && Platform.isLinux) {
      try {
        final res = await Process.run('notify-send', [
          '--action=accept=$acceptText',
          '--action=decline=$declineText',
          '-a',
          'Xaneo',
          '-u',
          'critical',
          '-i',
          'call-start',
          titleText,
          bodyText,
        ]);

        final clickedAction = res.stdout.toString().trim();
        debugPrint('NotificationService: Linux call notify-send action: "$clickedAction"');

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          final callManager = ctx.read<CallManager>();
          if (clickedAction == 'accept') {
            await callManager.acceptIncomingCall();
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (context) => const ActiveCallScreen(),
              ),
            );
            await windowManager.show();
            await windowManager.focus();
          } else if (clickedAction == 'decline') {
            callManager.rejectIncomingCall();
          }
        }
        return;
      } catch (e) {
        debugPrint('NotificationService: notify-send for call failed: $e');
      }
    }

    try {
      final notification = LocalNotification(
        title: titleText,
        body: bodyText,
        actions: [
          LocalNotificationAction(text: acceptText),
          LocalNotificationAction(text: declineText),
        ],
      );

      notification.onClick = () async {
        await windowManager.show();
        await windowManager.focus();
      };

      notification.onClickAction = (actionIndex) async {
        final context = navigatorKey.currentContext;
        if (context != null) {
          final callManager = context.read<CallManager>();
          if (actionIndex == 0) {
            // Ответить
            await callManager.acceptIncomingCall();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ActiveCallScreen(),
              ),
            );
            await windowManager.show();
            await windowManager.focus();
          } else {
            // Отклонить
            callManager.rejectIncomingCall();
          }
        }
        await dismissCallNotification();
      };

      _activeCallNotification = notification;
      await notification.show();
    } catch (e) {
      debugPrint('NotificationService: Error showing call notification: $e');
    }
  }

  /// Отображение кастомного анимированного оверлейного окна сообщения
  Future<void> _showCustomOverlay({
    required String chatId,
    required String title,
    required String body,
    String? avatar,
    String? gradient,
  }) async {
    final primaryDisplay = await ScreenRetriever.instance.getPrimaryDisplay();
    final visibleSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
    final visiblePosition = primaryDisplay.visiblePosition ?? const Offset(0, 0);

    const double width = 360;
    const double height = 130;

    // Вычисляем координаты: правый нижний угол экрана с отступами
    final uniqueTitle = 'xaneo_overlay_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'type': 'notification',
      'chat_id': chatId,
      'title': title,
      'body': body,
      'avatar': avatar,
      'gradient': gradient,
      'unique_title': uniqueTitle,
    };

    if (_overlayWindowId != null) {
      // Re-use existing window to prevent FlutterEngine destruction crashes
      await DesktopMultiWindow.invokeMethod(_overlayWindowId!, 'update_notification', jsonEncode(payload));
      final window = WindowController.fromWindowId(_overlayWindowId!);
      await window.show();
      // Ensure the Win32 styles are reapplied just in case (e.g. if it lost topmost status)
      int? existingHwnd = findWindowByTitle(uniqueTitle);
      if (existingHwnd != null) applyOverlayStyleWin32ToHwnd(existingHwnd, show: true);
      return;
    }

    // Создаем второе окно через desktop_multi_window
    final window = await DesktopMultiWindow.createWindow(jsonEncode(payload));
    _overlayWindowId = window.windowId;
    await window.setTitle(uniqueTitle);
    
    // Ждем установки заголовка на уровне Win32 (обычно мгновенно)
    int? newHwnd;
    for (int i = 0; i < 20; i++) {
      newHwnd = findWindowByTitle(uniqueTitle);
      if (newHwnd != null) break;
      await Future.delayed(const Duration(milliseconds: 5));
    }

    if (newHwnd != null) {
      // Моментально прячем и применяем стили Win32 еще ДО того как Flutter начнет рендер!
      // Это полностью устраняет белую вспышку и гарантирует правильное позиционирование относительно рабочего стола.
      applyOverlayStyleWin32ToHwnd(newHwnd, show: false);
    }
  }

  /// Отображение кастомного анимированного оверлейного окна входящего звонка
  Future<void> _showCustomCallOverlay({
    required String callId,
    required String callerName,
    required String callType,
    String? avatar,
    String? gradient,
  }) async {
    await dismissCallNotification();

    final primaryDisplay = await ScreenRetriever.instance.getPrimaryDisplay();
    final visibleSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
    final visiblePosition = primaryDisplay.visiblePosition ?? const Offset(0, 0);

    const double width = 360;
    const double height = 145; // Слегка выше для красивого размещения кнопок звонка

    final uniqueTitle = 'xaneo_call_overlay_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'type': 'call_incoming',
      'call_id': callId,
      'title': 'Входящий вызов',
      'body': callerName,
      'call_type': callType,
      'avatar': avatar,
      'gradient': gradient,
      'unique_title': uniqueTitle,
    };
    
    if (_overlayWindowId != null) {
      _activeCallOverlayWindowId = _overlayWindowId;
      await DesktopMultiWindow.invokeMethod(_overlayWindowId!, 'update_notification', jsonEncode(payload));
      final window = WindowController.fromWindowId(_overlayWindowId!);
      await window.show();
      int? existingHwnd = findWindowByTitle(uniqueTitle);
      if (existingHwnd != null) applyOverlayStyleWin32ToHwnd(existingHwnd, show: true);
      return;
    }

    final window = await DesktopMultiWindow.createWindow(jsonEncode(payload));
    _overlayWindowId = window.windowId;
    _activeCallOverlayWindowId = _overlayWindowId;
    await window.setTitle(uniqueTitle);

    int? newHwnd;
    for (int i = 0; i < 20; i++) {
      newHwnd = findWindowByTitle(uniqueTitle);
      if (newHwnd != null) break;
      await Future.delayed(const Duration(milliseconds: 5));
    }

    if (newHwnd != null) {
      applyOverlayStyleWin32ToHwnd(newHwnd, show: false);
    }
  }
}
