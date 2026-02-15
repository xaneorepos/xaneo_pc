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

  /// Registration screen title
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registerTitle;

  /// Registration step 0 title
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get registerStep0Title;

  /// Registration step 0 subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your real name'**
  String get registerStep0Subtitle;

  /// Registration step 1 title
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get registerStep1Title;

  /// Registration step 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'You must be at least 14 years old'**
  String get registerStep1Subtitle;

  /// Registration step 2 title
  ///
  /// In en, this message translates to:
  /// **'Choose a nickname'**
  String get registerStep2Title;

  /// Registration step 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Nickname must be unique'**
  String get registerStep2Subtitle;

  /// Registration step 3 title
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get registerStep3Title;

  /// Registration step 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code'**
  String get registerStep3Subtitle;

  /// Registration step 4 title
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get registerStep4Title;

  /// Registration step 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get registerStep4Subtitle;

  /// Registration step 5 title
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get registerStep5Title;

  /// Registration step 5 subtitle
  ///
  /// In en, this message translates to:
  /// **'This is optional, but nice'**
  String get registerStep5Subtitle;

  /// Registration step 6 title
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get registerStep6Title;

  /// Registration step 6 subtitle
  ///
  /// In en, this message translates to:
  /// **'Accept the terms of use'**
  String get registerStep6Subtitle;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// Birth date field label
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get birthDate;

  /// Nickname field label
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// Checking nickname message
  ///
  /// In en, this message translates to:
  /// **'Checking availability...'**
  String get checkingNickname;

  /// Nickname available message
  ///
  /// In en, this message translates to:
  /// **'Nickname available'**
  String get nicknameAvailable;

  /// Nickname taken message
  ///
  /// In en, this message translates to:
  /// **'Nickname taken'**
  String get nicknameTaken;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Add photo hint
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo'**
  String get addPhoto;

  /// Remove photo button
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// Accept terms checkbox
  ///
  /// In en, this message translates to:
  /// **'I accept the terms of use'**
  String get acceptTerms;

  /// Accept data processing checkbox
  ///
  /// In en, this message translates to:
  /// **'I agree to the processing of personal data'**
  String get acceptDataProcessing;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Finish button
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Back to login button
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// Registration success message
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccess;

  /// Registration error message
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registrationError;

  /// Enter verification code message
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterVerificationCode;

  /// Invalid verification code message
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidVerificationCode;

  /// Code sent message
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to email'**
  String get codeSent;

  /// Send code error message
  ///
  /// In en, this message translates to:
  /// **'Error sending code'**
  String get sendCodeError;

  /// Confirm email modal title
  ///
  /// In en, this message translates to:
  /// **'Confirm e-mail'**
  String get confirmEmail;

  /// Code sent to email message
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to\n{email}'**
  String codeSentToEmail(String email);

  /// Verify button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Resend code button
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// Resend countdown
  ///
  /// In en, this message translates to:
  /// **'Resend in {count} sec'**
  String resendIn(int count);

  /// Accept terms required message
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and data processing consent'**
  String get acceptTermsRequired;

  /// About app menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// About app description
  ///
  /// In en, this message translates to:
  /// **'A modern application for managing and controlling systems.'**
  String get aboutDescription;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Technical information section header
  ///
  /// In en, this message translates to:
  /// **'Technical Information'**
  String get technicalInfo;

  /// Platform label
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// Processor architecture label
  ///
  /// In en, this message translates to:
  /// **'Processor Architecture'**
  String get architecture;

  /// Flutter framework label
  ///
  /// In en, this message translates to:
  /// **'Flutter'**
  String get flutter;

  /// View on GitHub link text
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGitHub;
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
