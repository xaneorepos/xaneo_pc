// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Xaneo PC';

  @override
  String get welcomeTitle => 'Добро пожаловать в Xaneo';

  @override
  String get welcomeDescription => 'Xaneo - теперь и на вашем компьютере! Максимальная производительность и удобство.';

  @override
  String get getStartedButton => 'Начать';

  @override
  String get privacyTitle => 'Все ваши данные в безопасности';

  @override
  String get privacyDescription => 'Все сообщения в Xaneo защищены сквозным шифрованием. Ни в один момент Xaneo не знает об их содержимом.';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get dataStorageTitle => 'Все дата-центры Xaneo находятся в России';

  @override
  String get dataStorageDescription => 'Ваши данные не покидают территорию страны и хранятся в безопасных дата-центрах.';

  @override
  String get finishButton => 'Завершить';

  @override
  String get setupCompleted => 'Настройка завершена!';

  @override
  String get loginFormTitle => 'Вход в систему';

  @override
  String get loginFieldHint => 'Логин';

  @override
  String get passwordFieldHint => 'Пароль';

  @override
  String get loginButton => 'Войти';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get fillAllFields => 'Заполните все поля';

  @override
  String get loggingIn => 'Выполняется вход...';

  @override
  String welcomeUser(String username) {
    return 'Добро пожаловать, $username!';
  }

  @override
  String get invalidCredentials => 'Неверные учётные данные. Проверьте имя пользователя и пароль.';

  @override
  String get serverError => 'Ошибка сервера. Попробуйте позже.';

  @override
  String get connectionError => 'Ошибка подключения. Проверьте интернет-соединение.';

  @override
  String get settings => 'Настройки';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsDescription => 'Включить или отключить уведомления';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get darkThemeDescription => 'Включить или отключить тёмную тему';

  @override
  String fontSize(int size) {
    return 'Размер шрифта: $size';
  }

  @override
  String get language => 'Язык';

  @override
  String get languageDescription => 'Выберите язык интерфейса';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerStep0Title => 'Как вас зовут?';

  @override
  String get registerStep0Subtitle => 'Введите ваше настоящее имя';

  @override
  String get registerStep1Title => 'Когда вы родились?';

  @override
  String get registerStep1Subtitle => 'Вам должно быть не менее 14 лет';

  @override
  String get registerStep2Title => 'Придумайте никнейм';

  @override
  String get registerStep2Subtitle => 'Никнейм должен быть уникальным';

  @override
  String get registerStep3Title => 'Ваш email';

  @override
  String get registerStep3Subtitle => 'Мы отправим код подтверждения';

  @override
  String get registerStep4Title => 'Создайте пароль';

  @override
  String get registerStep4Subtitle => 'Придумайте надёжный пароль';

  @override
  String get registerStep5Title => 'Добавьте фото';

  @override
  String get registerStep5Subtitle => 'Это необязательно, но приятно';

  @override
  String get registerStep6Title => 'Последний шаг';

  @override
  String get registerStep6Subtitle => 'Примите условия использования';

  @override
  String get yourName => 'Ваше имя';

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get nickname => 'Никнейм';

  @override
  String get checkingNickname => 'Проверка доступности...';

  @override
  String get nicknameAvailable => 'Никнейм доступен';

  @override
  String get nicknameTaken => 'Никнейм занят';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get addPhoto => 'Нажмите, чтобы добавить фото';

  @override
  String get removePhoto => 'Удалить фото';

  @override
  String get acceptTerms => 'Я принимаю условия использования';

  @override
  String get acceptDataProcessing => 'Я согласен на обработку персональных данных';

  @override
  String get back => 'Назад';

  @override
  String get next => 'Далее';

  @override
  String get finish => 'Завершить';

  @override
  String get backToLogin => 'Назад ко входу';

  @override
  String get registrationSuccess => 'Регистрация успешна!';

  @override
  String get registrationError => 'Ошибка регистрации';

  @override
  String get enterVerificationCode => 'Введите код подтверждения';

  @override
  String get invalidVerificationCode => 'Неверный код подтверждения';

  @override
  String get codeSent => 'Код подтверждения отправлен на email';

  @override
  String get sendCodeError => 'Ошибка отправки кода';

  @override
  String get confirmEmail => 'Подтвердите e-mail';

  @override
  String codeSentToEmail(String email) {
    return 'Мы отправили код подтверждения на\n$email';
  }

  @override
  String get verify => 'Проверить';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String resendIn(int count) {
    return 'Отправить повторно через $count сек';
  }

  @override
  String get acceptTermsRequired => 'Необходимо принять условия и согласие на обработку данных';

  @override
  String get about => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get aboutDescription => 'Современное приложение для управления и контроля систем.';

  @override
  String get close => 'Закрыть';

  @override
  String get technicalInfo => 'Техническая информация';

  @override
  String get platform => 'Платформа';

  @override
  String get architecture => 'Архитектура процессора';

  @override
  String get flutter => 'Flutter';

  @override
  String get viewOnGitHub => 'Посмотреть на GitHub';
}
