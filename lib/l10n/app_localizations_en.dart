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

  @override
  String get registerTitle => 'Registration';

  @override
  String get registerStep0Title => 'What\'s your name?';

  @override
  String get registerStep0Subtitle => 'Enter your real name';

  @override
  String get registerStep1Title => 'When were you born?';

  @override
  String get registerStep1Subtitle => 'You must be at least 14 years old';

  @override
  String get registerStep2Title => 'Choose a nickname';

  @override
  String get registerStep2Subtitle => 'Nickname must be unique';

  @override
  String get registerStep3Title => 'Your email';

  @override
  String get registerStep3Subtitle => 'We\'ll send a verification code';

  @override
  String get registerStep4Title => 'Create a password';

  @override
  String get registerStep4Subtitle => 'Create a strong password';

  @override
  String get registerStep5Title => 'Add a photo';

  @override
  String get registerStep5Subtitle => 'This is optional, but nice';

  @override
  String get registerStep6Title => 'Last step';

  @override
  String get registerStep6Subtitle => 'Accept the terms of use';

  @override
  String get yourName => 'Your name';

  @override
  String get birthDate => 'Birth date';

  @override
  String get nickname => 'Nickname';

  @override
  String get checkingNickname => 'Checking availability...';

  @override
  String get nicknameAvailable => 'Nickname available';

  @override
  String get nicknameTaken => 'Nickname taken';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get addPhoto => 'Tap to add a photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get acceptTerms => 'I accept the terms of use';

  @override
  String get acceptDataProcessing => 'I agree to the processing of personal data';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get registrationSuccess => 'Registration successful!';

  @override
  String get registrationError => 'Registration error';

  @override
  String get enterVerificationCode => 'Enter verification code';

  @override
  String get invalidVerificationCode => 'Invalid verification code';

  @override
  String get codeSent => 'Verification code sent to email';

  @override
  String get sendCodeError => 'Error sending code';

  @override
  String get confirmEmail => 'Confirm e-mail';

  @override
  String codeSentToEmail(String email) {
    return 'We sent a verification code to\n$email';
  }

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int count) {
    return 'Resend in $count sec';
  }

  @override
  String get acceptTermsRequired => 'You must accept the terms and data processing consent';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get aboutDescription => 'A modern application for managing and controlling systems.';

  @override
  String get close => 'Close';

  @override
  String get technicalInfo => 'Technical Information';

  @override
  String get platform => 'Platform';

  @override
  String get architecture => 'Processor Architecture';

  @override
  String get flutter => 'Flutter';

  @override
  String get viewOnGitHub => 'View on GitHub';
}
