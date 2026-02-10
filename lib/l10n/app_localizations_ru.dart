import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([Locale locale = const Locale('ru')]) : super(locale);

  @override
  String get appTitle => 'Xaneo PC';

  @override
  String get welcomeTitle => 'Добро пожаловать в Xaneo';

  @override
  String get welcomeDescription =>
      'Xaneo - теперь и на вашем компьютере! Максимальная производительность и удобство.';

  @override
  String get getStartedButton => 'Начать';

  @override
  String get privacyTitle => 'Все ваши данные в безопасности';

  @override
  String get privacyDescription =>
      'Все сообщения в Xaneo защищены сквозным шифрованием. Ни в один момент Xaneo не знает об их содержимом.';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get dataStorageTitle =>
      'Все дата-центры Xaneo находятся в России';

  @override
  String get dataStorageDescription =>
      'Ваши данные не покидают территорию страны и хранятся в безопасных дата-центрах.';

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
  String welcomeUser(String username) => 'Добро пожаловать, $username!';

  @override
  String get invalidCredentials =>
      'Неверные учётные данные. Проверьте имя пользователя и пароль.';

  @override
  String get serverError => 'Ошибка сервера. Попробуйте позже.';

  @override
  String get connectionError =>
      'Ошибка подключения. Проверьте интернет-соединение.';
}
