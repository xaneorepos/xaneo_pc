// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Xaneo PC';

  @override
  String get welcomeTitle => 'Welcome to Xaneo';

  @override
  String get welcomeDescription => 'Xaneo is now on your computer! Maximum performance and convenience.';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get privacyTitle => 'All your data is secure';

  @override
  String get privacyDescription => 'All messages in Xaneo are protected by end-to-end encryption. Xaneo never knows their content.';

  @override
  String get continueButton => 'Continue';

  @override
  String get dataStorageTitle => 'All Xaneo data centers are located in Russia';

  @override
  String get dataStorageDescription => 'Your data never leaves the country and is stored in secure data centers.';

  @override
  String get finishButton => 'Finish';

  @override
  String get setupCompleted => 'Setup completed!';

  @override
  String get loginFormTitle => 'Login';

  @override
  String get loginFieldHint => 'Login';

  @override
  String get passwordFieldHint => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get noAccount => 'No account?';

  @override
  String get registerButton => 'Register';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String welcomeUser(String username) {
    return 'Welcome, $username!';
  }

  @override
  String get invalidCredentials => 'Invalid credentials. Please check your username and password.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get connectionError => 'Connection error. Please check your internet connection.';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDescription => 'Enable or disable notifications';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get darkThemeDescription => 'Enable or disable dark theme';

  @override
  String fontSize(int size) {
    return 'Font size: $size';
  }

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Select interface language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get appVersion => 'App version';
}
