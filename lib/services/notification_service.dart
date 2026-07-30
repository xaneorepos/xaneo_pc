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

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  LocalNotification? _activeCallNotification;
  int? _activeCallOverlayWindowId;

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
    if (kIsWeb) return false;
    if (Platform.isMacOS) {
      // macOS строго регулирует окна и док-панели, нативные уведомления предпочтительнее
      return false;
    }
    if (Platform.isLinux) {
      // На Linux Wayland позиционирование безрамочных окон не поддерживается Mutter/Wayland
      final sessionType = Platform.environment['XDG_SESSION_TYPE']?.toLowerCase();
      final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];
      if (sessionType == 'wayland' || waylandDisplay != null) {
        return false;
      }
    }
    return true;
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
        WindowController.fromWindowId(_activeCallOverlayWindowId!).close();
      } catch (e) {
        debugPrint('NotificationService: error closing custom overlay window: $e');
      }
      _activeCallOverlayWindowId = null;
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
      ],
    );

    notification.onClick = () {
      debugPrint('Notification clicked: open chat $chatId');
      windowManager.show();
      windowManager.focus();
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
    final double x = visiblePosition.dx + visibleSize.width - width - 20;
    final double y = visiblePosition.dy + visibleSize.height - height - 20;

    final payload = {
      'type': 'notification',
      'chat_id': chatId,
      'title': title,
      'body': body,
      'avatar': avatar,
      'gradient': gradient,
    };

    // Создаем второе окно через desktop_multi_window
    final window = await DesktopMultiWindow.createWindow(jsonEncode(payload));
    await window.setTitle('');
    
    // Настраиваем положение и рамки
    // Окно будет показано из NotificationOverlayScreen после настройки skipTaskbar/frameless
    await window.setFrame(Rect.fromLTWH(x, y, width, height));
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

    final double x = visiblePosition.dx + visibleSize.width - width - 20;
    final double y = visiblePosition.dy + visibleSize.height - height - 20;

    final payload = {
      'type': 'call_incoming',
      'call_id': callId,
      'title': 'Входящий вызов',
      'body': callerName,
      'call_type': callType,
      'avatar': avatar,
      'gradient': gradient,
    };

    final window = await DesktopMultiWindow.createWindow(jsonEncode(payload));
    _activeCallOverlayWindowId = window.windowId;
    await window.setTitle('');

    // Окно будет показано из NotificationOverlayScreen после настройки skipTaskbar/frameless
    await window.setFrame(Rect.fromLTWH(x, y, width, height));
  }
}
