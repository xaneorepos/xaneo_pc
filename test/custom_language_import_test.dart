import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xaneo/l10n/app_localizations.dart';
import 'package:xaneo/services/language_pack_validator.dart';
import 'package:xaneo/services/runtime_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> manifest;

  setUpAll(() async {
    final manifestFile = File('assets/manifest.v1.json');
    final manifestRaw = await manifestFile.readAsString();
    manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PC Custom Language Pack Integration Tests', () {
    test('Valid minimal pack validates, installs, and resolves strings', () async {
      const minimalJson = '''
      {
        "schema_version": 1,
        "locale": "ru-pirate",
        "name": "Пиратский",
        "native_name": "Пиратский диалект",
        "direction": "ltr",
        "fallback_locale": "ru",
        "strings": {
          "header.home": "Главная палуба",
          "header.login": "Свистать всех наверх"
        }
      }
      ''';

      final validation = LanguagePackValidator.validate(minimalJson, manifest);
      expect(validation.isValid, isTrue);
      expect(validation.normalizedPack, isNotNull);

      final normalized = validation.normalizedPack!;
      RuntimeTranslations.instance.setActivePack(normalized);

      expect(RuntimeTranslations.instance.hasActiveCustomPack, isTrue);
      expect(RuntimeTranslations.instance.get('header.home'), equals('Главная палуба'));
      expect(RuntimeTranslations.instance.get('header.login'), equals('Свистать всех наверх'));

      // Missing custom key falls back to default
      expect(
        RuntimeTranslations.instance.get('unknown.custom.key', fallback: 'Резерв'),
        equals('Резерв'),
      );
    });

    test('Real test packs (tsukishiro & dorevolyucionnyj) validate cleanly', () async {
      final tsukishiroFile = File('/home/xaneodev/tsukishiro_agent_lang.json');
      if (await tsukishiroFile.exists()) {
        final content = await tsukishiroFile.readAsString();
        final res = LanguagePackValidator.validate(content, manifest);
        expect(res.isValid, isTrue, reason: 'tsukishiro_agent_lang.json should be valid: ${res.errors}');
      }

      final dorevFile = File('/home/xaneodev/dorevolyucionnyj_lang.json');
      if (await dorevFile.exists()) {
        final content = await dorevFile.readAsString();
        final res = LanguagePackValidator.validate(content, manifest);
        expect(res.isValid, isTrue, reason: 'dorevolyucionnyj_lang.json should be valid: ${res.errors}');
      }
    });

    test('RTL pack sets correct direction', () async {
      const rtlJson = '''
      {
        "schema_version": 1,
        "locale": "ar-custom",
        "name": "Custom Arabic",
        "native_name": "عربي مخصص",
        "direction": "rtl",
        "fallback_locale": "ar",
        "strings": {
          "header.home": "الرئيسية المخصصة"
        }
      }
      ''';

      final validation = LanguagePackValidator.validate(rtlJson, manifest);
      expect(validation.isValid, isTrue);

      RuntimeTranslations.instance.setActivePack(validation.normalizedPack);
      expect(RuntimeTranslations.instance.direction, equals('rtl'));
      expect(RuntimeTranslations.instance.get('header.home'), equals('الرئيسية المخصصة'));
    });

    test('DynamicAppLocalizations overrides getters when custom pack is active', () async {
      final tsukishiroFile = File('/home/xaneodev/tsukishiro_agent_lang.json');
      if (await tsukishiroFile.exists()) {
        final content = await tsukishiroFile.readAsString();
        final validation = LanguagePackValidator.validate(content, manifest);
        expect(validation.isValid, isTrue);

        RuntimeTranslations.instance.setActivePack(validation.normalizedPack);
        
        final l10n = lookupAppLocalizations(const Locale('ru'));
        // messenger.chats is in tsukishiro
        expect(l10n.chats, isNot(equals('Чаты')));
        expect(l10n.chats, equals('Секретные каналы'));
        
        // messenger.search is in tsukishiro
        expect(l10n.search, equals('Поиск по базам данных...'));

        // messenger.reply is in tsukishiro
        expect(l10n.reply, equals('Ответить объекту'));

        // messenger.settings.title is in tsukishiro
        expect(l10n.settings, equals('Конфигурация ядра'));

        // messenger.settings.personalTitle is in tsukishiro
        expect(l10n.lichnyeDannye_be85, equals('Профиль оперативника'));

        // messenger.system.joinedChat is in tsukishiro
        expect(l10n.joinedChat, equals('подключился к матрице'));
        expect(l10n.prisoedinilsyaKChatu_f623, equals('подключился к матрице'));

        // messenger.system.leftChat is in tsukishiro
        expect(l10n.leftChat, equals('покинул сектор'));
        expect(l10n.pokinulChat_d567, equals('покинул сектор'));

        // messenger.system.user is in tsukishiro
        expect(l10n.polzovatel_f154, equals('неопознанный смертный'));
        expect(l10n.polzovatelya_1083, equals('неопознанный смертный'));

        // messenger.system.invited is in tsukishiro
        expect(l10n.invited, equals('завербовал в сектор'));
        expect(l10n.priglasil_47ae, equals('завербовал в сектор'));

        // Section header correctly takes generalTitle ('Параметры симуляции')
        expect(l10n.interface, equals('Параметры симуляции'));

        // Sub-items must NOT be duplicated with generalTitle
        expect(l10n.appearance, equals('Оформление терминала'));
        expect(l10n.language, equals('Диалект ИИ-ассистента'));
        expect(l10n.closeActionTitle, equals('Действие при закрытии окна'));

        // Empty chat placeholders
        expect(l10n.noMessagesTitle, equals('Тишина в радиоэфире...'));
        expect(l10n.noMessagesSubtitle, equals('Отправь первый байт информации прямо сейчас!'));
        expect(l10n.groupWelcome, equals('Добро пожаловать в штаб группировки! Координируйте операции и делитесь файлами.'));
        expect(l10n.channelWelcome, equals('Канал вещания активен! Здесь публикуются указы руководства.'));

        // Online / Offline / Bot / Typing statuses
        expect(l10n.online, equals('в матрице'));
        expect(l10n.offline, equals('был в матрице в прошлую эпоху'));
        expect(l10n.lastSeenRecently, equals('был в матрице в прошлую эпоху'));
        expect(l10n.bot_2712, equals('ИИ-агент'));
        expect(l10n.isTyping, equals('генерирует ответ...'));
        expect(l10n.isRecordingVoice, equals('записывает аудиолог...'));

        // Create Chat options
        expect(l10n.lichnyyChat_cbec, equals('Связаться с объектом'));
        expect(l10n.nachatObschenieSPolzovatelem_0578, equals('Установить защищённый контакт с человеком'));
        expect(l10n.sozdatGruppu_459f, equals('Основать тайную ячейку'));
        expect(l10n.gruppovoyChatDlyaObscheniyaS_01ba, equals('Собрать группу сообщников для захвата дивана'));
        expect(l10n.sozdatKanal_9022, equals('Запустить канал вещания'));
        expect(l10n.kanalDlyaShirokoyAuditorii_9dba, equals('Вещать свои мысли на весь мир'));
      }
    });

    test('Default built-in languages have separate onboarding and settings privacy titles', () {
      RuntimeTranslations.instance.clearActivePack();

      // Settings section title (privatnost_0899)
      expect(lookupAppLocalizations(const Locale('ru')).privatnost_0899, equals('Конфиденциальность'));
      expect(lookupAppLocalizations(const Locale('en')).privatnost_0899, equals('Privacy'));
      expect(lookupAppLocalizations(const Locale('ja')).privatnost_0899, equals('プライバシー'));
      expect(lookupAppLocalizations(const Locale('zh')).privatnost_0899, equals('隐私设置'));
      expect(lookupAppLocalizations(const Locale('fr')).privatnost_0899, equals('Confidentialité'));
      expect(lookupAppLocalizations(const Locale('ko')).privatnost_0899, equals('개인정보 보호'));
      expect(lookupAppLocalizations(const Locale('es')).privatnost_0899, equals('Privacidad'));
      expect(lookupAppLocalizations(const Locale('ar')).privatnost_0899, equals('الخصوصية'));

      // Onboarding screen title (privacyTitle)
      expect(lookupAppLocalizations(const Locale('ru')).privacyTitle, equals('Все ваши данные в безопасности'));
      expect(lookupAppLocalizations(const Locale('en')).privacyTitle, equals('All your data is secure'));
      expect(lookupAppLocalizations(const Locale('ja')).privacyTitle, equals('すべてのデータは安全です'));
    });
  });
}
