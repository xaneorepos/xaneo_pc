import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate` in their app's
/// `localizationsDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// See [internationalization guide](https://flutter.dev/docs/development/accessibility-and-internationalization/internationalization)
/// for more information.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
  ];

  /// `AppLocalizations` strings for `en` locale.
  static AppLocalizationsEn get en => AppLocalizationsEn();

  /// `AppLocalizations` strings for `ru` locale.
  static AppLocalizationsRu get ru => AppLocalizationsRu();

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Xaneo PC'**
  String get appTitle => _localizedValues[locale.languageCode]!.appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Xaneo'**
  String get welcomeTitle => _localizedValues[locale.languageCode]!.welcomeTitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Xaneo is now on your computer! Maximum performance and convenience.'**
  String get welcomeDescription =>
      _localizedValues[locale.languageCode]!.welcomeDescription;

  /// No description provided for @getStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton =>
      _localizedValues[locale.languageCode]!.getStartedButton;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'All your data is secure'**
  String get privacyTitle => _localizedValues[locale.languageCode]!.privacyTitle;

  /// No description provided for @privacyDescription.
  ///
  /// In en, this message translates to:
  /// **'All messages in Xaneo are protected by end-to-end encryption. Xaneo never knows their content.'**
  String get privacyDescription =>
      _localizedValues[locale.languageCode]!.privacyDescription;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton =>
      _localizedValues[locale.languageCode]!.continueButton;

  /// No description provided for @dataStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'All Xaneo data centers are located in Russia'**
  String get dataStorageTitle =>
      _localizedValues[locale.languageCode]!.dataStorageTitle;

  /// No description provided for @dataStorageDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data never leaves the country and is stored in secure data centers.'**
  String get dataStorageDescription =>
      _localizedValues[locale.languageCode]!.dataStorageDescription;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton => _localizedValues[locale.languageCode]!.finishButton;

  /// No description provided for @setupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Setup completed!'**
  String get setupCompleted =>
      _localizedValues[locale.languageCode]!.setupCompleted;

  /// No description provided for @loginFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginFormTitle =>
      _localizedValues[locale.languageCode]!.loginFormTitle;

  /// No description provided for @loginFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginFieldHint =>
      _localizedValues[locale.languageCode]!.loginFieldHint;

  /// No description provided for @passwordFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldHint =>
      _localizedValues[locale.languageCode]!.passwordFieldHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton => _localizedValues[locale.languageCode]!.loginButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get noAccount => _localizedValues[locale.languageCode]!.noAccount;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton =>
      _localizedValues[locale.languageCode]!.registerButton;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields =>
      _localizedValues[locale.languageCode]!.fillAllFields;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn => _localizedValues[locale.languageCode]!.loggingIn;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}!'**
  String welcomeUser(String username) {
    return _localizedValues[locale.languageCode]!.welcomeUser(username);
  }

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please check your username and password.'**
  String get invalidCredentials =>
      _localizedValues[locale.languageCode]!.invalidCredentials;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError => _localizedValues[locale.languageCode]!.serverError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet connection.'**
  String get connectionError =>
      _localizedValues[locale.languageCode]!.connectionError;

  static final Map<String, AppLocalizations> _localizedValues = {
    'en': AppLocalizationsEn(),
    'ru': AppLocalizationsRu(),
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations._localizedValues.containsKey(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
