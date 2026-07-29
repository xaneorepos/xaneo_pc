import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер для управления локализацией приложения
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  static const String _prefsKey = 'app_locale_preference';

  LocaleProvider() {
    _loadLocale();
  }

  Locale? get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('ru'),
    Locale('en'),
    Locale('fr'),
    Locale('es'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('ar'),
  ];

  static const List<Map<String, String>> availableLanguages = [
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
    {'code': 'ar', 'name': 'العربية'},
  ];

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_prefsKey);
    if (langCode != null) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> _saveLocale(String? langCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (langCode != null) {
      await prefs.setString(_prefsKey, langCode);
    } else {
      await prefs.remove(_prefsKey);
    }
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _saveLocale(locale.languageCode);
    notifyListeners();
  }

  void clearLocale() {
    _locale = null;
    _saveLocale(null);
    notifyListeners();
  }
}
