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
import 'package:xaneo/services/grpc_service.dart';
import 'package:xaneo/services/account_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  LocalNotification? _activeCallNotification;
  int? _activeCallOverlayWindowId;
  int? _overlayWindowId;

  /// Инициализация сервиса уведомлений
  Future<void> init() async {
    if (_initialized) return;

    // Инициализируем локальный системный нотификатор
    await localNotifier.setup(
      appName: 'Xaneo',
      // shortcutPolicy на Windows автоматически создаст ярлык в Пуске для корректной работы тостов
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );

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
    final notification = LocalNotification(
      title: title,
      body: body,
      actions: [
        LocalNotificationAction(text: 'Открыть чат'),
        LocalNotificationAction(text: 'Прочитано'),
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
          final accounts = await AccountService().getAccounts();
          if (accounts.isNotEmpty) {
            final userId = accounts.first.userId.toString();
            final success = await GrpcService().markAsRead(chatId, userId);
            debugPrint('Mark as read result: $success for chat $chatId');
          } else {
            debugPrint('Mark as read: no active account found');
          }
        } catch (e) {
          debugPrint('Mark as read error: $e');
        }
      }
    };

    await notification.show();
  }

  /// Отображение системного нативного баннера звонка с кнопками
  Future<void> _showNativeCallNotification({
    required String callId,
    required String callerName,
    required String callType,
  }) async {
    await dismissCallNotification();

    final typeText = callType == 'video' ? 'видеозвонок' : 'аудиозвонок';
    final notification = LocalNotification(
      title: 'Входящий вызов',
      body: '$callerName вызывает вас ($typeText)',
      actions: [
        LocalNotificationAction(text: 'Ответить'),
        LocalNotificationAction(text: 'Отклонить'),
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
