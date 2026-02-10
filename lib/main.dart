import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/scale_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/zoom_toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: const Size(1024, 768),
    minimumSize: const Size(900, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          title: 'Xaneo PC',
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
          routes: {
            '/onboarding': (context) => const ZoomScope(child: OnboardingScreen()),
            '/login': (context) => const ZoomScope(child: LoginScreen()),
          },
        );
      },
    );
  }
}
