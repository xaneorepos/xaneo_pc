import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
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
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Xaneo PC'**
  String get appTitle;

  /// Welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Xaneo'**
  String get welcomeTitle;

  /// Welcome description
  ///
  /// In en, this message translates to:
  /// **'Xaneo is now on your computer! Maximum performance and convenience.'**
  String get welcomeDescription;

  /// Get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton;

  /// Privacy screen title
  ///
  /// In en, this message translates to:
  /// **'All your data is secure'**
  String get privacyTitle;

  /// Privacy description
  ///
  /// In en, this message translates to:
  /// **'All messages in Xaneo are protected by end-to-end encryption. Xaneo never knows their content.'**
  String get privacyDescription;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Data storage screen title
  ///
  /// In en, this message translates to:
  /// **'All Xaneo data centers are located in Russia'**
  String get dataStorageTitle;

  /// Data storage description
  ///
  /// In en, this message translates to:
  /// **'Your data never leaves the country and is stored in secure data centers.'**
  String get dataStorageDescription;

  /// Finish button
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// Setup completed message
  ///
  /// In en, this message translates to:
  /// **'Setup completed!'**
  String get setupCompleted;

  /// Login form title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginFormTitle;

  /// Login field hint
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginFieldHint;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldHint;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No account link
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get noAccount;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Fill all fields message
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// Logging in message
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// Welcome user message
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}!'**
  String welcomeUser(String username);

  /// Invalid credentials message
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please check your username and password.'**
  String get invalidCredentials;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet connection.'**
  String get connectionError;

  /// Settings title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Notifications setting name
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notifications setting description
  ///
  /// In en, this message translates to:
  /// **'Enable or disable notifications'**
  String get notificationsDescription;

  /// Dark theme setting name
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// Dark theme setting description
  ///
  /// In en, this message translates to:
  /// **'Enable or disable dark theme'**
  String get darkThemeDescription;

  /// Font size setting
  ///
  /// In en, this message translates to:
  /// **'Font size: {size}'**
  String fontSize(int size);

  /// Language setting name
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language setting description
  ///
  /// In en, this message translates to:
  /// **'Select interface language'**
  String get languageDescription;

  /// Select language title
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// App version setting name
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
