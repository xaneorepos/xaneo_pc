import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:media_kit/media_kit.dart';
import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/scale_provider.dart';
import 'providers/playback_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/messenger_screen.dart';
import 'widgets/zoom_toast.dart';
import 'widgets/custom_title_bar.dart';
import 'widgets/settings_modal.dart';
import 'services/logger_service.dart';
import 'utils/local_proxy.dart';
import 'services/webrtc/webrtc_signaling_service.dart';
import 'services/webrtc/call_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/notification_overlay_screen.dart';
import 'services/notification_service.dart';

// Глобальный ключ для доступа к Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = args[2].isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    runApp(NotificationOverlayApp(windowId: windowId, arguments: arguments));
    return;
  }

  // Intercept and ignore harmless platform/formatting exceptions to keep console clean
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exception.toString();
    if (exceptionStr.contains('No active stream to cancel') || 
        exceptionStr.contains('DiagnosticsProperty')) {
      return;
    }
    originalOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    if (errorStr.contains('No active stream to cancel') || 
        errorStr.contains('DiagnosticsProperty')) {
      return true; // marked as handled
    }
    return false;
  };

  await NotificationService().init();
  await Logger.init();
  Logger.info('Main', 'App main() entry point reached.');

  // Initialize media_kit & just_audio_media_kit backends for Linux/Windows/macOS
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    MediaKit.ensureInitialized();
    JustAudioMediaKit.ensureInitialized();
  }

  // Start the local HTTP proxy for streaming media
  await LocalProxy.start();

  HttpOverrides.global = MyHttpOverrides();
  
  // Initialize window manager
  await windowManager.ensureInitialized();

  // Load saved window options
  final prefs = await SharedPreferences.getInstance();
  final isMaximized = prefs.getBool('window_maximized') ?? false;
  final width = prefs.getDouble('window_width') ?? 1024.0;
  final height = prefs.getDouble('window_height') ?? 768.0;

  WindowOptions windowOptions = WindowOptions(
    size: Size(width, height),
    minimumSize: const Size(900, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (isMaximized) {
      await windowManager.maximize();
    }
    await windowManager.show();
    await windowManager.focus();
  });
  
  // Устанавливаем предпочтительную ориентацию
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ScaleProvider()),
        ChangeNotifierProvider(create: (context) => PlaybackProvider()),
        Provider<WebRTCSignalingService>(
          create: (context) => WebRTCSignalingService(),
          dispose: (context, service) => service.dispose(),
        ),
        ChangeNotifierProvider<CallManager>(
          create: (context) {
            final signaling = context.read<WebRTCSignalingService>();
            return CallManager(signalingService: signaling);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResize() {
    _saveWindowState();
  }

  @override
  void onWindowMaximize() {
    _saveWindowState();
  }

  @override
  void onWindowUnmaximize() {
    _saveWindowState();
  }

  Future<void> _saveWindowState() async {
    try {
      final isMaximized = await windowManager.isMaximized();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('window_maximized', isMaximized);
      if (!isMaximized) {
        final size = await windowManager.getSize();
        await prefs.setDouble('window_width', size.width);
        await prefs.setDouble('window_height', size.height);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
        // Обновляем системные цвета в зависимости от темы
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
          systemNavigationBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Xaneo',
          locale: localeProvider.locale ?? const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: themeProvider.themeData.copyWith(
            textTheme: themeProvider.themeData.textTheme.apply(
              fontFamily: 'Inter',
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const ZoomScope(child: OnboardingScreen()),
          debugShowCheckedModeBanner: false,
          builder: (context, child) => Stack(
            children: [
              child!,
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 40,
                  child: CustomTitleBar(),
                ),
              ),
            ],
          ),
          routes: {
            '/onboarding': (context) => const ZoomScope(child: OnboardingScreen()),
            '/login': (context) => const ZoomScope(child: LoginScreen()),
            '/register': (context) => const ZoomScope(child: RegisterScreen()),
            '/messenger': (context) => const ZoomScope(child: MessengerScreen()),
          },
        );
      },
    );
  }
}

/// Custom HttpOverrides to bypass bad certificate issues (e.g. self-signed certificates or IP mismatches)
/// and set a global User-Agent header for the application.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'XaneoPC/1.0 xaneo-app'
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class NotificationOverlayApp extends StatelessWidget {
  final int windowId;
  final Map<String, dynamic> arguments;

  const NotificationOverlayApp({
    super.key,
    required this.windowId,
    required this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationOverlayScreen(
        windowId: windowId,
        arguments: arguments,
      ),
    );
  }
}
