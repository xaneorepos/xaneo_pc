import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/xnx_theme.dart';
import '../services/xnx_font_loader.dart';

/// Провайдер для управления темой приложения
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // По умолчанию тёмная тема (чёрно-белая)
  XnxTheme? _xnxTheme;
  String? _customFontFamily;
  static const _xnxKey = 'imported_xnx_theme';

  XnxTheme? get xnxTheme => _xnxTheme;
  String get fontFamily => _customFontFamily ?? _xnxTheme?.fontFamily ?? 'Inter';
  Color? xnxColor(String key) => _xnxTheme?.color(key, _isDarkMode);

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData {
    final base = _isDarkMode ? _darkTheme : _lightTheme;
    final theme = _xnxTheme;
    if (theme == null) return base;
    Color color(String key, Color fallback) =>
        theme.color(key, _isDarkMode) ?? fallback;
    final scheme = base.colorScheme;
    final bg = color('bg', base.scaffoldBackgroundColor);
    final surface = color('surface', base.cardColor);
    final foreground = color('text', scheme.onSurface);
    final accent = color('accent', scheme.primary);
    final radius = theme.radius.toDouble();
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: color('border', base.dividerColor),
      primaryColor: accent,
      colorScheme: scheme.copyWith(
        primary: accent,
        onPrimary: color('btn-primary-text', scheme.onPrimary),
        secondary: color('text-secondary', scheme.secondary),
        surface: surface,
        surfaceContainerHigh: color('surface-hover', scheme.surfaceContainerHigh),
        onSurface: foreground,
        outline: color('border', scheme.outline),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
        fontFamily: fontFamily,
        fontFamilyFallback: const ['Inter'],
      ),
      appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: foreground),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: color('btn-primary-bg', accent),
          foregroundColor: color('btn-primary-text', scheme.onPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: color('bg-secondary', surface),
        hintStyle: TextStyle(color: color('text-muted', scheme.secondary)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey.shade900,
    fontFamily: 'Inter',
    focusColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent, // Disable hover effect color
    // This removes the focus color globally
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ), 
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.grey,
      surface: Colors.black,
      error: Colors.red,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
  );

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey.shade100,
    fontFamily: 'Inter',
    focusColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent, // Disable hover effect color
    // This removes the focus color globally
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.grey,
      surface: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.black,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: Colors.black,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF757575),
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
  );

  static const String _prefsKey = 'app_theme_preference';

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedXnx = prefs.getString(_xnxKey);
    if (savedXnx != null) {
      try { _xnxTheme = XnxTheme.parse(savedXnx); } catch (_) { await prefs.remove(_xnxKey); }
    }
    final isDark = prefs.getBool(_prefsKey);
    if (isDark != null) {
      _isDarkMode = isDark;
    }
    notifyListeners();
    final currentTheme = _xnxTheme;
    if (currentTheme != null) _loadSavedFont(currentTheme);
  }

  Future<void> _loadSavedFont(XnxTheme theme) async {
    try {
      final loaded = await XnxFontLoader.load(theme);
      if (identical(_xnxTheme, theme)) {
        _customFontFamily = loaded;
        notifyListeners();
      }
    } catch (error) {
      debugPrint('XNX font could not be restored: $error');
    }
  }

  Future<void> importXnx(String source) async {
    final parsed = XnxTheme.parse(source);
    final loadedFont = await XnxFontLoader.load(parsed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_xnxKey, source);
    _xnxTheme = parsed;
    _customFontFamily = loadedFont;
    _isDarkMode = parsed.defaultMode == 'dark';
    await prefs.setBool(_prefsKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> clearXnx() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_xnxKey);
    _xnxTheme = null;
    _customFontFamily = null;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDarkMode);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    _saveTheme();
    notifyListeners();
  }
}

extension XnxColorContext on BuildContext {
  Color? xnxColor(String key) =>
      Provider.of<ThemeProvider>(this, listen: false).xnxColor(key);
}
