// GENERATED BOILERPLATE ADAPTER FROM CANONICAL MANIFEST
// 100% COMPLETE MANIFEST COVERAGE FOR XANEO PC
import 'app_localizations.dart';
import '../services/runtime_translations.dart';

class DynamicAppLocalizations extends AppLocalizations {
  final AppLocalizations base;
  final RuntimeTranslations _rt = RuntimeTranslations.instance;

  DynamicAppLocalizations(this.base, String locale) : super(locale);

  String _resolve(List<String> keys, String fallback) {
    if (!_rt.hasActiveCustomPack) return fallback;
    for (final key in keys) {
      final val = _rt.get(key);
      if (val != key) return val;
    }
    return _rt.resolveByText(fallback);
  }

  @override
  String get appTitle => _resolve(const ['appTitle', 'pc.appTitle'], base.appTitle);

  @override
  String get welcomeTitle => _resolve(const ['pc.dobroPozhalovatVXaneo_66d0', 'dobroPozhalovatVXaneo_66d0', 'welcomeTitle', 'pc.welcomeTitle'], base.welcomeTitle);

  @override
  String get welcomeDescription => _resolve(const ['welcomeDescription', 'pc.welcomeDescription'], base.welcomeDescription);

  @override
  String get getStartedButton => _resolve(const ['getStartedButton', 'pc.getStartedButton'], base.getStartedButton);

  @override
  String get privacyTitle => _resolve(const ['messenger.settings.privacyTitle', 'messenger.settings.privacy', 'privacyTitle', 'pc.privacyTitle'], base.privacyTitle);

  @override
  String get privacyDescription => _resolve(const ['privacyDescription', 'pc.privacyDescription'], base.privacyDescription);

  @override
  String get continueButton => _resolve(const ['pc.prodolzhit_e9c3', 'prodolzhit_e9c3', 'continueBtn', 'continueButton', 'pc.continueButton'], base.continueButton);

  @override
  String get dataStorageTitle => _resolve(const ['dataStorageTitle', 'pc.dataStorageTitle'], base.dataStorageTitle);

  @override
  String get dataStorageDescription => _resolve(const ['dataStorageDescription', 'pc.dataStorageDescription'], base.dataStorageDescription);

  @override
  String get finishButton => _resolve(const ['pc.zavershit_b0e3', 'zavershit_b0e3', 'finishButton', 'pc.finishButton'], base.finishButton);

  @override
  String get setupCompleted => _resolve(const ['setupCompleted', 'pc.setupCompleted'], base.setupCompleted);

  @override
  String get loginFormTitle => _resolve(const ['loginFormTitle', 'pc.loginFormTitle'], base.loginFormTitle);

  @override
  String get loginFieldHint => _resolve(const ['loginFieldHint', 'pc.loginFieldHint'], base.loginFieldHint);

  @override
  String get passwordFieldHint => _resolve(const ['pc.parol_5ebe', 'parol_5ebe', 'passwordFieldHint', 'pc.passwordFieldHint'], base.passwordFieldHint);

  @override
  String get loginButton => _resolve(const ['pc.voyti_63a7', 'voyti_63a7', 'submitCodeBtn', 'loginButton', 'pc.loginButton'], base.loginButton);

  @override
  String get noAccount => _resolve(const ['noAccount', 'pc.noAccount'], base.noAccount);

  @override
  String get registerButton => _resolve(const ['registerButton', 'pc.registerButton'], base.registerButton);

  @override
  String get fillAllFields => _resolve(const ['fillAllFields', 'pc.fillAllFields'], base.fillAllFields);

  @override
  String get loggingIn => _resolve(const ['loggingIn', 'pc.loggingIn'], base.loggingIn);

  @override
  String get invalidCredentials => _resolve(const ['invalidCredentials', 'pc.invalidCredentials'], base.invalidCredentials);

  @override
  String get serverError => _resolve(const ['serverError', 'pc.serverError'], base.serverError);

  @override
  String get connectionError => _resolve(const ['connectionError', 'pc.connectionError'], base.connectionError);

  @override
  String get settings => _resolve(const ['messenger.settings.title', 'header.settings', 'settings.title', 'pc.nastroyki_c919', 'nastroyki_c919', 'settings', 'pc.settings'], base.settings);

  @override
  String get notifications => _resolve(const ['messenger.settings.chatsTitle', 'messenger.settings.notificationsTitle', 'settings.notifications', 'pc.uvedomleniya_d2ed', 'uvedomleniya_d2ed', 'notifications', 'pc.notifications'], base.notifications);

  @override
  String get notificationsDescription => _resolve(const ['messenger.settings.chatsDesc', 'messenger.settings.notificationsDesc', 'settings.notificationsDescription', 'notificationsDescription', 'pc.notificationsDescription'], base.notificationsDescription);

  @override
  String get darkTheme => _resolve(const ['messenger.chatSettings.appearance', 'common.darkTheme', 'pc.temnayaTema_cb48', 'temnayaTema_cb48', 'darkTheme', 'pc.darkTheme'], base.darkTheme);

  @override
  String get darkThemeDescription => _resolve(const ['darkThemeDescription', 'pc.darkThemeDescription'], base.darkThemeDescription);

  @override
  String get language => _resolve(const ['messenger.settings.languageTitle', 'messenger.generalSettings.language', 'settings.language', 'common.language', 'pc.yazyk_0577', 'yazyk_0577', 'language', 'pc.language'], base.language);

  @override
  String get languageDescription => _resolve(const ['messenger.settings.languageDesc', 'messenger.generalSettings.languageDesc', 'settings.languageDescription', 'languageDescription', 'pc.languageDescription', 'yazykInterfeysaKlienta_2ad3'], base.languageDescription);

  @override
  String get selectLanguage => _resolve(const ['selectLanguage', 'pc.selectLanguage'], base.selectLanguage);

  @override
  String get appVersion => _resolve(const ['appVersion', 'pc.appVersion'], base.appVersion);

  @override
  String get registerTitle => _resolve(const ['pc.registratsiya_0b93', 'registratsiya_0b93', 'registerTitle', 'pc.registerTitle'], base.registerTitle);

  @override
  String get registerStep0Title => _resolve(const ['pc.kakVasZovut_68b7', 'kakVasZovut_68b7', 'registerStep0Title', 'pc.registerStep0Title'], base.registerStep0Title);

  @override
  String get registerStep0Subtitle => _resolve(const ['messenger.personal.namePlaceholder', 'pc.vvediteVasheNastoyascheeImya_e656', 'vvediteVasheNastoyascheeImya_e656', 'registerStep0Subtitle', 'pc.registerStep0Subtitle'], base.registerStep0Subtitle);

  @override
  String get registerStep1Title => _resolve(const ['pc.kogdaVyRodilis_26f2', 'kogdaVyRodilis_26f2', 'registerStep1Title', 'pc.registerStep1Title'], base.registerStep1Title);

  @override
  String get registerStep1Subtitle => _resolve(const ['registerStep1Subtitle', 'pc.registerStep1Subtitle'], base.registerStep1Subtitle);

  @override
  String get registerStep2Title => _resolve(const ['pc.pridumayteNikneym_221b', 'pridumayteNikneym_221b', 'registerStep2Title', 'pc.registerStep2Title'], base.registerStep2Title);

  @override
  String get registerStep2Subtitle => _resolve(const ['pc.nikneymDolzhenBytUnikalnym_952d', 'nikneymDolzhenBytUnikalnym_952d', 'registerStep2Subtitle', 'pc.registerStep2Subtitle'], base.registerStep2Subtitle);

  @override
  String get registerStep3Title => _resolve(const ['pc.vashEmail_8bbd', 'vashEmail_8bbd', 'vashEmail_879d', 'registerStep3Title', 'pc.registerStep3Title'], base.registerStep3Title);

  @override
  String get registerStep3Subtitle => _resolve(const ['registerStep3Subtitle', 'pc.registerStep3Subtitle'], base.registerStep3Subtitle);

  @override
  String get registerStep4Title => _resolve(const ['pc.sozdayteParol_5f4c', 'sozdayteParol_5f4c', 'registerStep4Title', 'pc.registerStep4Title'], base.registerStep4Title);

  @override
  String get registerStep4Subtitle => _resolve(const ['registerStep4Subtitle', 'pc.registerStep4Subtitle'], base.registerStep4Subtitle);

  @override
  String get registerStep5Title => _resolve(const ['pc.dobavteFoto_25eb', 'dobavteFoto_25eb', 'registerStep5Title', 'pc.registerStep5Title'], base.registerStep5Title);

  @override
  String get registerStep5Subtitle => _resolve(const ['registerStep5Subtitle', 'pc.registerStep5Subtitle'], base.registerStep5Subtitle);

  @override
  String get registerStep6Title => _resolve(const ['pc.posledniyShag_e0c5', 'posledniyShag_e0c5', 'registerStep6Title', 'pc.registerStep6Title'], base.registerStep6Title);

  @override
  String get registerStep6Subtitle => _resolve(const ['registerStep6Subtitle', 'pc.registerStep6Subtitle'], base.registerStep6Subtitle);

  @override
  String get yourName => _resolve(const ['messenger.personal.name', 'profile.profile.displayName', 'pc.vasheImya_51eb', 'vasheImya_51eb', 'yourName', 'pc.yourName'], base.yourName);

  @override
  String get birthDate => _resolve(const ['pc.dataRozhdeniya_505e', 'dataRozhdeniya_505e', 'birthDate', 'pc.birthDate'], base.birthDate);

  @override
  String get nickname => _resolve(const ['messenger.personal.nickname', 'profile.profile.username', 'pc.nikneym_3fea', 'nikneym_3fea', 'nickname', 'pc.nickname'], base.nickname);

  @override
  String get checkingNickname => _resolve(const ['pc.proverkaDostupnosti_da13', 'proverkaDostupnosti_da13', 'checkingNickname', 'pc.checkingNickname'], base.checkingNickname);

  @override
  String get nicknameAvailable => _resolve(const ['pc.nikneymDostupen_3fc9', 'nikneymDostupen_3fc9', 'nicknameAvailable', 'pc.nicknameAvailable'], base.nicknameAvailable);

  @override
  String get nicknameTaken => _resolve(const ['pc.nikneymZanyat_8a5f', 'nikneymZanyat_8a5f', 'nicknameTaken', 'pc.nicknameTaken'], base.nicknameTaken);

  @override
  String get email => _resolve(const ['email', 'pc.email'], base.email);

  @override
  String get password => _resolve(const ['pc.parol_5ebe', 'parol_5ebe', 'password', 'pc.password'], base.password);

  @override
  String get confirmPassword => _resolve(const ['pc.podtverditeParol_e3e3', 'podtverditeParol_e3e3', 'confirmPassword', 'pc.confirmPassword'], base.confirmPassword);

  @override
  String get addPhoto => _resolve(const ['pc.nazhmiteChtobyDobavitFoto_d6e8', 'nazhmiteChtobyDobavitFoto_d6e8', 'addPhoto', 'pc.addPhoto'], base.addPhoto);

  @override
  String get removePhoto => _resolve(const ['pc.udalitFoto_3426', 'udalitFoto_3426', 'removePhoto', 'pc.removePhoto'], base.removePhoto);

  @override
  String get acceptTerms => _resolve(const ['pc.yaPrinimayuUsloviyaIspolzovaniya_391a', 'yaPrinimayuUsloviyaIspolzovaniya_391a', 'acceptTerms', 'pc.acceptTerms'], base.acceptTerms);

  @override
  String get acceptDataProcessing => _resolve(const ['pc.yaSoglasenNaObrabotkuPersonalnyh_f2a8', 'yaSoglasenNaObrabotkuPersonalnyh_f2a8', 'acceptDataProcessing', 'pc.acceptDataProcessing'], base.acceptDataProcessing);

  @override
  String get back => _resolve(const ['pc.nazad_2b0b', 'nazad_2b0b', 'backBtn', 'back', 'pc.back'], base.back);

  @override
  String get next => _resolve(const ['pc.dalee_c453', 'dalee_c453', 'next', 'pc.next'], base.next);

  @override
  String get finish => _resolve(const ['pc.zavershit_b0e3', 'zavershit_b0e3', 'finish', 'pc.finish'], base.finish);

  @override
  String get backToLogin => _resolve(const ['backToLogin', 'pc.backToLogin'], base.backToLogin);

  @override
  String get registrationSuccess => _resolve(const ['pc.registratsiyaUspeshna_9d5c', 'registratsiyaUspeshna_9d5c', 'registrationSuccess', 'pc.registrationSuccess'], base.registrationSuccess);

  @override
  String get registrationError => _resolve(const ['pc.oshibkaRegistratsii_b9f2', 'oshibkaRegistratsii_b9f2', 'registrationError', 'pc.registrationError'], base.registrationError);

  @override
  String get enterVerificationCode => _resolve(const ['pc.vvediteKodPodtverzhdeniya_61af', 'vvediteKodPodtverzhdeniya_61af', 'enterVerificationCode', 'pc.enterVerificationCode'], base.enterVerificationCode);

  @override
  String get invalidVerificationCode => _resolve(const ['pc.nevernyyKodPodtverzhdeniya_7762', 'nevernyyKodPodtverzhdeniya_7762', 'invalidVerificationCode', 'pc.invalidVerificationCode'], base.invalidVerificationCode);

  @override
  String get codeSent => _resolve(const ['codeSent', 'pc.codeSent'], base.codeSent);

  @override
  String get sendCodeError => _resolve(const ['pc.oshibkaOtpravkiKoda_a42a', 'oshibkaOtpravkiKoda_a42a', 'sendCodeError', 'pc.sendCodeError'], base.sendCodeError);

  @override
  String get confirmEmail => _resolve(const ['pc.podtverditeEMail_4bd4', 'podtverditeEMail_4bd4', 'confirmEmail', 'pc.confirmEmail'], base.confirmEmail);

  @override
  String get verify => _resolve(const ['pc.proverit_340b', 'proverit_340b', 'verify', 'pc.verify'], base.verify);

  @override
  String get resendCode => _resolve(const ['pc.otpravitKodPovtorno_7703', 'otpravitKodPovtorno_7703', 'resendCode', 'pc.resendCode'], base.resendCode);

  @override
  String get acceptTermsRequired => _resolve(const ['pc.neobhodimoPrinyatUsloviyaISoglasie_e31e', 'neobhodimoPrinyatUsloviyaISoglasie_e31e', 'acceptTermsRequired', 'pc.acceptTermsRequired'], base.acceptTermsRequired);

  @override
  String get about => _resolve(const ['messenger.settings.aboutTitle', 'messenger.settings.title', 'settings.about', 'pc.oPrilozhenii_322e', 'oPrilozhenii_322e', 'about', 'pc.about'], base.about);

  @override
  String get version => _resolve(const ['pc.versiya_3725', 'versiya_3725', 'version', 'pc.version'], base.version);

  @override
  String get aboutDescription => _resolve(const ['messenger.settings.aboutDesc', 'messenger.settings.title', 'settings.aboutDescription', 'aboutDescription', 'pc.aboutDescription'], base.aboutDescription);

  @override
  String get close => _resolve(const ['pc.zakryt_dd94', 'zakryt_dd94', 'close', 'pc.close'], base.close);

  @override
  String get technicalInfo => _resolve(const ['pc.tehnicheskayaInformatsiya_ba0f', 'tehnicheskayaInformatsiya_ba0f', 'technicalInfo', 'pc.technicalInfo'], base.technicalInfo);

  @override
  String get platform => _resolve(const ['pc.platforma_8848', 'platforma_8848', 'platform', 'pc.platform'], base.platform);

  @override
  String get architecture => _resolve(const ['pc.arhitekturaProtsessora_c079', 'arhitekturaProtsessora_c079', 'architecture', 'pc.architecture'], base.architecture);

  @override
  String get flutter => _resolve(const ['flutter', 'pc.flutter'], base.flutter);

  @override
  String get viewOnGitHub => _resolve(const ['pc.posmotretNaGithub_5238', 'posmotretNaGithub_5238', 'viewOnGitHub', 'pc.viewOnGitHub'], base.viewOnGitHub);

  @override
  String get chats => _resolve(const ['messenger.chats', 'messenger.settings.chatsTitle', 'pc.chats', 'chats', 'chaty_19ad', 'pc.mart_d766', 'mart_d766'], base.chats);

  @override
  String get search => _resolve(const ['messenger.search', 'common.search', 'header.search', 'settings.search', 'pc.search', 'search', 'poisk_bfc9'], base.search);

  @override
  String get searchPlaceholder => _resolve(const ['messenger.searchPlaceholder', 'messenger.search', 'common.search', 'pc.searchPlaceholder', 'searchPlaceholder'], base.searchPlaceholder);

  @override
  String get savedMessages => _resolve(const ['messenger.favorites.title', 'messenger.savedMessages', 'header.savedMessages', 'pc.savedMessages', 'savedMessages', 'izbrannoe_2fc4'], base.savedMessages);

  @override
  String get online => _resolve(const ['messenger.status.online', 'pc.online', 'online', 'vSeti_d902'], base.online);

  @override
  String get offline => _resolve(const ['messenger.status.lastSeenRecently', 'messenger.status.offline', 'pc.offline', 'offline', 'neVSeti_ee01'], base.offline);

  @override
  String get lastSeenRecently => _resolve(const ['messenger.status.lastSeenRecently', 'pc.lastSeenRecently', 'lastSeenRecently', 'pc.bylANedavno_168d', 'bylANedavno_168d'], base.lastSeenRecently);

  @override
  String get musicPlaylist => _resolve(const ['pc.musicPlaylist', 'musicPlaylist', 'spisokMuzyki_57d0'], base.musicPlaylist);

  @override
  String get reply => _resolve(const ['messenger.reply', 'messenger.message.reply', 'pc.reply', 'reply', 'otvetit_e568'], base.reply);

  @override
  String get edit => _resolve(const ['messenger.edit', 'messenger.chat.edit', 'messenger.message.edit', 'pc.edit', 'edit'], base.edit);

  @override
  String get copy => _resolve(const ['messenger.copy', 'messenger.message.copy', 'pc.copy', 'copy'], base.copy);

  @override
  String get pin => _resolve(const ['messenger.pin', 'messenger.pinned.title', 'pc.pin', 'pin', 'pinChat'], base.pin);

  @override
  String get unpin => _resolve(const ['messenger.unpin', 'messenger.pinned.unpin', 'pc.unpin', 'unpin', 'unpinChat'], base.unpin);

  @override
  String get delete => _resolve(const ['messenger.buttons.delete', 'messenger.delete.buttons.delete', 'messenger.moderation.deleteAction', 'messenger.delete', 'messenger.message.delete', 'messenger.chat.delete', 'pc.delete', 'delete', 'udalit_ed2b'], base.delete);

  @override
  String get forward => _resolve(const ['messenger.forward', 'messenger.message.forward', 'pc.forward', 'forward'], base.forward);

  @override
  String get members => _resolve(const ['pc.members', 'members'], base.members);

  @override
  String get noMessages => _resolve(const ['pc.noMessages', 'noMessages'], base.noMessages);

  @override
  String get joinedChat => _resolve(const ['messenger.system.joinedChat', 'messenger.system.joinedShort', 'pc.joinedChat', 'joinedChat', 'prisoedinilsyaKChatu_f623'], base.joinedChat);

  @override
  String get leftChat => _resolve(const ['messenger.system.leftChat', 'messenger.system.leftShort', 'pc.leftChat', 'leftChat', 'pokinulChat_d567'], base.leftChat);

  @override
  String get subscribedChannel => _resolve(const ['messenger.system.subscribedChannel', 'pc.subscribedChannel', 'subscribedChannel', 'podpisalsyaNaKanal_0673'], base.subscribedChannel);

  @override
  String get unsubscribedChannel => _resolve(const ['messenger.system.unsubscribedChannel', 'pc.unsubscribedChannel', 'unsubscribedChannel', 'otpisalsyaOtKanala_fa13'], base.unsubscribedChannel);

  @override
  String get invited => _resolve(const ['messenger.system.invited', 'messenger.system.invitedSentence', 'pc.invited', 'invited', 'priglasil_47ae'], base.invited);

  @override
  String get systemMessage => _resolve(const ['messenger.system.systemMessage', 'pc.systemMessage', 'systemMessage', 'sistemnoeSoobschenie_d2bd'], base.systemMessage);

  @override
  String get selectChatToStart => _resolve(const ['pc.selectChatToStart', 'selectChatToStart', 'vyberiteChatDlyaNachalaObscheniya_36a5'], base.selectChatToStart);

  @override
  String get toArchive => _resolve(const ['messenger.context.archiveChat', 'messenger.chat.archive', 'messenger.archive', 'pc.toArchive', 'toArchive', 'vArhiv_ce22'], base.toArchive);

  @override
  String get unarchive => _resolve(const ['messenger.context.unarchiveChat', 'messenger.chat.unarchive', 'messenger.unarchive', 'pc.unarchive', 'unarchive', 'razarhivirovat_416b'], base.unarchive);

  @override
  String get archive => _resolve(const ['pc.archive', 'archive', 'arhiv_56aa'], base.archive);

  @override
  String get archiveEmpty => _resolve(const ['pc.archiveEmpty', 'archiveEmpty', 'arhivPust_3e22'], base.archiveEmpty);

  @override
  String get voiceMessage => _resolve(const ['pc.voiceMessage', 'voiceMessage', 'golosovoeSoobschenie_33d5'], base.voiceMessage);

  @override
  String get videoMessage => _resolve(const ['pc.videoMessage', 'videoMessage', 'videosoobschenie_2951'], base.videoMessage);

  @override
  String get personalData => _resolve(const ['messenger.settings.personalTitle', 'messenger.settings.personal', 'pc.personalData', 'personalData', 'lichnyeDannye_be85'], base.personalData);

  @override
  String get personalDataDesc => _resolve(const ['messenger.settings.personalDesc', 'pc.personalDataDesc', 'personalDataDesc', 'imyaNikneymFotoProfilya_28ac'], base.personalDataDesc);

  @override
  String get privacyDesc => _resolve(const ['messenger.settings.privacyDesc', 'pc.privacyDesc', 'privacyDesc', 'ktoMozhetPisatZvonitVidet_1789'], base.privacyDesc);

  @override
  String get chatsSettings => _resolve(const ['messenger.settings.chatsTitle', 'messenger.settings.chats', 'pc.chatsSettings', 'chatsSettings', 'nastroykiChatov_7ca8'], base.chatsSettings);

  @override
  String get chatsSettingsDesc => _resolve(const ['messenger.settings.chatsDesc', 'pc.chatsSettingsDesc', 'chatsSettingsDesc', 'uvedomleniyaTemyIstoriya_51da'], base.chatsSettingsDesc);

  @override
  String get contacts => _resolve(const ['messenger.settings.contactsTitle', 'messenger.contacts.title', 'messenger.contacts', 'pc.contacts', 'contacts', 'kontakty_7576'], base.contacts);

  @override
  String get contactsDesc => _resolve(const ['messenger.settings.contactsDesc', 'pc.contactsDesc', 'contactsDesc', 'vashiSohranennyeKontakty_a641'], base.contactsDesc);

  @override
  String get security => _resolve(const ['messenger.settings.securityTitle', 'messenger.settings.security', 'pc.security', 'security', 'bezopasnost_3677'], base.security);

  @override
  String get securityDesc => _resolve(const ['messenger.settings.securityDesc', 'pc.securityDesc', 'securityDesc', 'sessiiParolAutentifikatsiya_73f5'], base.securityDesc);

  @override
  String get appearance => _resolve(const ['messenger.chatSettings.appearance', 'messenger.settings.appearanceTitle', 'messenger.settings.appearance', 'settings.appearance', 'pc.appearance', 'appearance', 'vneshniyVid_6873'], base.appearance);

  @override
  String get appearanceDesc => _resolve(const ['messenger.chatSettings.appearanceDesc', 'messenger.settings.appearanceDesc', 'pc.appearanceDesc', 'appearanceDesc', 'temaShriftMasshtab_d8c9'], base.appearanceDesc);

  @override
  String get energySaving => _resolve(const ['messenger.settings.energyTitle', 'messenger.energy.mainSettings', 'messenger.energy.title', 'pc.energySaving', 'energySaving', 'energosberezhenie_0b19'], base.energySaving);

  @override
  String get energySavingDesc => _resolve(const ['messenger.settings.energyDesc', 'messenger.energy.mainSettings', 'pc.energySavingDesc', 'energySavingDesc', 'animatsiiIProizvoditelnost_fba8'], base.energySavingDesc);

  @override
  String get account => _resolve(const ['messenger.settings.personalTitle', 'messenger.settings.personal', 'profile.title', 'header.profile', 'pc.account', 'account', 'akkaunt_38ac', 'pc.profil_c62a', 'profil_c62a'], base.account);

  @override
  String get interface => _resolve(const ['messenger.settings.generalTitle', 'settings.appearance', 'pc.interface', 'interface', 'interfeys_49be', 'pc.chtoNovogo_74e2', 'pc.nastroyki_b01b', 'pc.izbrannoe_b637', 'chtoNovogo_74e2', 'nastroyki_b01b', 'izbrannoe_b637'], base.interface);

  @override
  String get logout => _resolve(const ['messenger.delete.buttons.leave', 'auth.logout', 'common.logout', 'pc.logout', 'logout', 'vyytiIzAkkaunta_6d41'], base.logout);

  @override
  String get basicInfo => _resolve(const ['messenger.personal.sectionTitle', 'messenger.settings.personalTitle', 'pc.basicInfo', 'basicInfo', 'osnovnayaInformatsiya_6fec'], base.basicInfo);

  @override
  String get nicknameCannotBeChanged => _resolve(const ['messenger.personal.nicknameCannotBeChanged', 'pc.nicknameCannotBeChanged', 'nicknameCannotBeChanged', 'nikneymNelzyaIzmenitVPrilozhenii_75d0'], base.nicknameCannotBeChanged);

  @override
  String get aboutMe => _resolve(const ['messenger.personal.bio', 'profile.profile.bio', 'pc.aboutMe', 'aboutMe', 'oSebe_0b3b', 'bio'], base.aboutMe);

  @override
  String get aboutMeHint => _resolve(const ['messenger.personal.bioPlaceholder', 'pc.aboutMeHint', 'aboutMeHint', 'rasskazhiteOSebe_1c37'], base.aboutMeHint);

  @override
  String get save => _resolve(const ['messenger.buttons.save', 'messenger.createGroup.createButton', 'common.save', 'profile.profile.save', 'pc.save', 'save', 'sohranit_74ea'], base.save);

  @override
  String get saving => _resolve(const ['common.saving', 'pc.saving', 'saving', 'sohranenie_c15f'], base.saving);

  @override
  String get communications => _resolve(const ['messenger.privacy.communications', 'pc.communications', 'communications', 'kommunikatsii_1242'], base.communications);

  @override
  String get whoCanMessage => _resolve(const ['messenger.privacy.whoCanMessage', 'pc.whoCanMessage', 'whoCanMessage', 'ktoMozhetPisatSoobscheniya_4645'], base.whoCanMessage);

  @override
  String get whoCanCall => _resolve(const ['messenger.privacy.whoCanCall', 'pc.whoCanCall', 'whoCanCall', 'ktoMozhetZvonit_c427'], base.whoCanCall);

  @override
  String get whoCanRecordVoice => _resolve(const ['messenger.privacy.whoCanRecordVoice', 'pc.whoCanRecordVoice', 'whoCanRecordVoice', 'ktoMozhetZapisyvatGolosovye_c69a'], base.whoCanRecordVoice);

  @override
  String get whoCanSendFiles => _resolve(const ['messenger.privacy.whoCanSendFiles', 'pc.whoCanSendFiles', 'whoCanSendFiles', 'ktoMozhetOtpravlyatFayly_2e40'], base.whoCanSendFiles);

  @override
  String get whoCanInvite => _resolve(const ['messenger.privacy.whoCanInvite', 'pc.whoCanInvite', 'whoCanInvite', 'ktoMozhetPriglashatVGruppy_cdc0'], base.whoCanInvite);

  @override
  String get profileVisibility => _resolve(const ['messenger.privacy.profileVisibility', 'pc.profileVisibility', 'profileVisibility', 'vidimostProfilya_34bf'], base.profileVisibility);

  @override
  String get whoSeesNickname => _resolve(const ['messenger.privacy.whoSeesNickname', 'pc.whoSeesNickname', 'whoSeesNickname', 'ktoViditMoyNikneym_54b8'], base.whoSeesNickname);

  @override
  String get everyone => _resolve(const ['messenger.privacy.all', 'common.all', 'pc.everyone', 'everyone', 'vse_984b'], base.everyone);

  @override
  String get contactsOnly => _resolve(const ['messenger.privacy.contactsOnly', 'pc.contactsOnly', 'contactsOnly', 'tolkoKontakty_a559'], base.contactsOnly);

  @override
  String get nobody => _resolve(const ['messenger.privacy.nobody', 'pc.nobody', 'nobody', 'nikto_ba19'], base.nobody);

  @override
  String get addContact => _resolve(const ['messenger.contacts.createTitle', 'common.add', 'pc.addContact', 'addContact', 'dobavit_5eba'], base.addContact);

  @override
  String get addContactTitle => _resolve(const ['pc.addContactTitle', 'addContactTitle', 'dobavitKontakt_4278'], base.addContactTitle);

  @override
  String get userNicknameHint => _resolve(const ['pc.userNicknameHint', 'userNicknameHint', 'nikneymPolzovatelya_5610'], base.userNicknameHint);

  @override
  String get displayNameOptional => _resolve(const ['pc.displayNameOptional', 'displayNameOptional', 'otobrazhaemoeImyaOptsionalno_bbd1'], base.displayNameOptional);

  @override
  String get noContactsYet => _resolve(const ['messenger.contacts.empty', 'pc.noContactsYet', 'noContactsYet', 'uVasPokaNetSohranennyh_b64b'], base.noContactsYet);

  @override
  String get appInfo => _resolve(const ['messenger.settings.aboutTitle', 'messenger.settings.about', 'pc.appInfo', 'appInfo', 'informatsiyaOPrilozhenii_00c4'], base.appInfo);

  @override
  String get checkUpdates => _resolve(const ['messenger.settings.greeting', 'header.checkForUpdates', 'common.checkUpdates', 'pc.checkUpdates', 'checkUpdates', 'proveritObnovleniya_ab45'], base.checkUpdates);

  @override
  String get checkingUpdates => _resolve(const ['header.checkingForUpdates', 'pc.checkingUpdates', 'checkingUpdates', 'proverkaObnovleniy_f3e0'], base.checkingUpdates);

  @override
  String get cancel => _resolve(const ['pc.cancel', 'cancel', 'otmena_987b'], base.cancel);

  @override
  String get obnovlenie_7e32 => _resolve(const ['pc.obnovlenie_7e32', 'obnovlenie_7e32', 'pc.vneshniyVid_5a0f', 'pc.prilozhenie_38aa', 'vneshniyVid_5a0f', 'prilozhenie_38aa'], base.obnovlenie_7e32);

  @override
  String get obnovleniePrilozheniya_b6c3 => _resolve(const ['pc.obnovleniePrilozheniya_b6c3', 'obnovleniePrilozheniya_b6c3'], base.obnovleniePrilozheniya_b6c3);

  @override
  String get podgotovkaKZagruzke_a5c7 => _resolve(const ['pc.podgotovkaKZagruzke_a5c7', 'podgotovkaKZagruzke_a5c7', 'preparingDownload'], base.podgotovkaKZagruzke_a5c7);

  @override
  String get ustanovkaZapuschena_d378 => _resolve(const ['pc.ustanovkaZapuschena_d378', 'ustanovkaZapuschena_d378', 'pc.installationStarted', 'installationStarted'], base.ustanovkaZapuschena_d378);

  @override
  String get dostupnaNovayaVersiyaPrilozheniya_eeae => _resolve(const ['pc.dostupnaNovayaVersiyaPrilozheniya_eeae', 'dostupnaNovayaVersiyaPrilozheniya_eeae', 'newVersionAvailable'], base.dostupnaNovayaVersiyaPrilozheniya_eeae);

  @override
  String get chtoNovogo_74e2 => _resolve(const ['pc.chtoNovogo_74e2', 'chtoNovogo_74e2', 'pc.interface', 'pc.nastroyki_b01b', 'pc.izbrannoe_b637', 'interface', 'nastroyki_b01b', 'interfeys_49be', 'izbrannoe_b637'], base.chtoNovogo_74e2);

  @override
  String get ofitsialnoeOpisanieRelizaDostupnoNa_3ea3 => _resolve(const ['pc.ofitsialnoeOpisanieRelizaDostupnoNa_3ea3', 'ofitsialnoeOpisanieRelizaDostupnoNa_3ea3'], base.ofitsialnoeOpisanieRelizaDostupnoNa_3ea3);

  @override
  String get istochnikZagruzki_0e6e => _resolve(const ['pc.istochnikZagruzki_0e6e', 'istochnikZagruzki_0e6e', 'pc.vidimostProfilya_448f', 'vidimostProfilya_448f'], base.istochnikZagruzki_0e6e);

  @override
  String get pryamayaUstanovkaVPrilozhenii_16f5 => _resolve(const ['pc.pryamayaUstanovkaVPrilozhenii_16f5', 'pryamayaUstanovkaVPrilozhenii_16f5', 'directInAppInstall'], base.pryamayaUstanovkaVPrilozhenii_16f5);

  @override
  String get avtomaticheskoeSkachivanieIZapusk_9a3f => _resolve(const ['pc.avtomaticheskoeSkachivanieIZapusk_9a3f', 'avtomaticheskoeSkachivanieIZapusk_9a3f', 'autoDownloadAndRun'], base.avtomaticheskoeSkachivanieIZapusk_9a3f);

  @override
  String get stranitsaRelizaNaGithub_1531 => _resolve(const ['pc.stranitsaRelizaNaGithub_1531', 'stranitsaRelizaNaGithub_1531', 'githubReleasePage'], base.stranitsaRelizaNaGithub_1531);

  @override
  String get propustit_03ee => _resolve(const ['pc.propustit_03ee', 'propustit_03ee', 'skip'], base.propustit_03ee);

  @override
  String get ustanovka_516d => _resolve(const ['pc.ustanovka_516d', 'ustanovka_516d', 'installAction'], base.ustanovka_516d);

  @override
  String get obnovit_dbe5 => _resolve(const ['pc.obnovit_dbe5', 'obnovit_dbe5', 'updateAction'], base.obnovit_dbe5);

  @override
  String get lichnyeDannye_be85 => _resolve(const ['messenger.settings.personalTitle', 'messenger.settings.personal', 'pc.personalData', 'personalData', 'lichnyeDannye_be85', 'pc.lichnyeDannye_be85'], base.lichnyeDannye_be85);

  @override
  String get imyaNikneymFotoProfilya_28ac => _resolve(const ['pc.personalDataDesc', 'personalDataDesc', 'imyaNikneymFotoProfilya_28ac', 'pc.imyaNikneymFotoProfilya_28ac'], base.imyaNikneymFotoProfilya_28ac);

  @override
  String get privatnost_0899 => _resolve(const ['messenger.settings.privacyTitle', 'messenger.settings.privacy', 'pc.privatnost_0899', 'privatnost_0899'], base.privatnost_0899);

  @override
  String get ktoMozhetPisatZvonitVidet_1789 => _resolve(const ['pc.privacyDesc', 'privacyDesc', 'ktoMozhetPisatZvonitVidet_1789', 'pc.ktoMozhetPisatZvonitVidet_1789'], base.ktoMozhetPisatZvonitVidet_1789);

  @override
  String get nastroykiChatov_7ca8 => _resolve(const ['pc.chatsSettings', 'chatsSettings', 'nastroykiChatov_7ca8', 'pc.nastroykiChatov_7ca8'], base.nastroykiChatov_7ca8);

  @override
  String get uvedomleniyaTemyIstoriya_51da => _resolve(const ['pc.chatsSettingsDesc', 'chatsSettingsDesc', 'uvedomleniyaTemyIstoriya_51da', 'pc.uvedomleniyaTemyIstoriya_51da'], base.uvedomleniyaTemyIstoriya_51da);

  @override
  String get kontakty_7576 => _resolve(const ['messenger.settings.contactsTitle', 'messenger.contacts.title', 'messenger.contacts', 'pc.contacts', 'contacts', 'kontakty_7576', 'pc.kontakty_7576'], base.kontakty_7576);

  @override
  String get vashiSohranennyeKontakty_a641 => _resolve(const ['messenger.settings.contactsDesc', 'messenger.contacts.empty', 'pc.contactsDesc', 'contactsDesc', 'vashiSohranennyeKontakty_a641', 'pc.vashiSohranennyeKontakty_a641'], base.vashiSohranennyeKontakty_a641);

  @override
  String get bezopasnost_3677 => _resolve(const ['pc.security', 'security', 'bezopasnost_3677', 'pc.bezopasnost_3677'], base.bezopasnost_3677);

  @override
  String get sessiiParolAutentifikatsiya_73f5 => _resolve(const ['messenger.settings.securityDesc', 'pc.securityDesc', 'securityDesc', 'sessiiParolAutentifikatsiya_73f5', 'pc.sessiiParolAutentifikatsiya_73f5'], base.sessiiParolAutentifikatsiya_73f5);

  @override
  String get vneshniyVid_6873 => _resolve(const ['pc.appearance', 'appearance', 'vneshniyVid_6873', 'pc.vneshniyVid_6873'], base.vneshniyVid_6873);

  @override
  String get temaShriftMasshtab_d8c9 => _resolve(const ['messenger.chatSettings.appearanceDesc', 'messenger.settings.appearanceDesc', 'pc.appearanceDesc', 'appearanceDesc', 'temaShriftMasshtab_d8c9', 'pc.temaShriftMasshtab_d8c9'], base.temaShriftMasshtab_d8c9);

  @override
  String get yazyk_0577 => _resolve(const ['messenger.settings.languageTitle', 'messenger.generalSettings.language', 'pc.yazyk_0577', 'yazyk_0577'], base.yazyk_0577);

  @override
  String get yazykInterfeysaKlienta_2ad3 => _resolve(const ['messenger.settings.languageDesc', 'messenger.generalSettings.languageDesc', 'settings.languageDescription', 'languageDescription', 'pc.languageDescription', 'yazykInterfeysaKlienta_2ad3', 'pc.yazykInterfeysaKlienta_2ad3'], base.yazykInterfeysaKlienta_2ad3);

  @override
  String get uvedomleniya_d2ed => _resolve(const ['pc.uvedomleniya_d2ed', 'uvedomleniya_d2ed'], base.uvedomleniya_d2ed);

  @override
  String get zvukiBannery_1b60 => _resolve(const ['messenger.settings.chatsDesc', 'messenger.settings.notificationsDesc', 'pc.zvukiBannery_1b60', 'zvukiBannery_1b60'], base.zvukiBannery_1b60);

  @override
  String get energosberezhenie_0b19 => _resolve(const ['pc.energySaving', 'energySaving', 'energosberezhenie_0b19', 'pc.energosberezhenie_0b19'], base.energosberezhenie_0b19);

  @override
  String get animatsiiIProizvoditelnost_fba8 => _resolve(const ['messenger.settings.energyDesc', 'pc.energySavingDesc', 'energySavingDesc', 'animatsiiIProizvoditelnost_fba8', 'pc.animatsiiIProizvoditelnost_fba8'], base.animatsiiIProizvoditelnost_fba8);

  @override
  String get oPrilozhenii_322e => _resolve(const ['pc.oPrilozhenii_322e', 'oPrilozhenii_322e'], base.oPrilozhenii_322e);

  @override
  String get versiyaProverkaObnovleniySsylki_6efc => _resolve(const ['messenger.settings.aboutDesc', 'messenger.settings.title', 'pc.versiyaProverkaObnovleniySsylki_6efc', 'versiyaProverkaObnovleniySsylki_6efc'], base.versiyaProverkaObnovleniySsylki_6efc);

  @override
  String get nastroyki_b01b => _resolve(const ['pc.nastroyki_b01b', 'nastroyki_b01b', 'pc.interface', 'pc.chtoNovogo_74e2', 'pc.izbrannoe_b637', 'interface', 'chtoNovogo_74e2', 'interfeys_49be', 'izbrannoe_b637'], base.nastroyki_b01b);

  @override
  String get nastroyki_c919 => _resolve(const ['pc.nastroyki_c919', 'nastroyki_c919'], base.nastroyki_c919);

  @override
  String get proverkaObnovleniy_f3e0 => _resolve(const ['pc.checkingUpdates', 'checkingUpdates', 'proverkaObnovleniy_f3e0', 'pc.proverkaObnovleniy_f3e0'], base.proverkaObnovleniy_f3e0);

  @override
  String get neUdalosZagruzitNastroyki_f753 => _resolve(const ['pc.neUdalosZagruzitNastroyki_f753', 'neUdalosZagruzitNastroyki_f753'], base.neUdalosZagruzitNastroyki_f753);

  @override
  String get oshibkaSohraneniya_0387 => _resolve(const ['pc.oshibkaSohraneniya_0387', 'oshibkaSohraneniya_0387'], base.oshibkaSohraneniya_0387);

  @override
  String get dannyeSohraneny_fd62 => _resolve(const ['pc.dannyeSohraneny_fd62', 'dannyeSohraneny_fd62'], base.dannyeSohraneny_fd62);

  @override
  String get gost_9618 => _resolve(const ['pc.gost_9618', 'gost_9618'], base.gost_9618);

  @override
  String get akkaunt_38ac => _resolve(const ['messenger.settings.personalTitle', 'profile.title', 'pc.account', 'account', 'akkaunt_38ac', 'pc.profil_c62a', 'profil_c62a', 'pc.akkaunt_38ac'], base.akkaunt_38ac);

  @override
  String get interfeys_49be => _resolve(const ['messenger.settings.generalTitle', 'settings.appearance', 'pc.interface', 'interface', 'interfeys_49be', 'pc.chtoNovogo_74e2', 'pc.nastroyki_b01b', 'pc.izbrannoe_b637', 'chtoNovogo_74e2', 'nastroyki_b01b', 'izbrannoe_b637', 'pc.interfeys_49be'], base.interfeys_49be);

  @override
  String get vyytiIzAkkaunta_6d41 => _resolve(const ['messenger.delete.buttons.leave', 'auth.logout', 'common.logout', 'pc.logout', 'logout', 'vyytiIzAkkaunta_6d41', 'pc.vyytiIzAkkaunta_6d41'], base.vyytiIzAkkaunta_6d41);

  @override
  String get informatsiyaOPrilozhenii_00c4 => _resolve(const ['pc.appInfo', 'appInfo', 'informatsiyaOPrilozhenii_00c4', 'pc.informatsiyaOPrilozhenii_00c4'], base.informatsiyaOPrilozhenii_00c4);

  @override
  String get versiya1001LinuxWindowsMacos_ff6c => _resolve(const ['pc.versiya1001LinuxWindowsMacos_ff6c', 'versiya1001LinuxWindowsMacos_ff6c'], base.versiya1001LinuxWindowsMacos_ff6c);

  @override
  String get proverka_13bc => _resolve(const ['pc.proverka_13bc', 'proverka_13bc'], base.proverka_13bc);

  @override
  String get proveritObnovleniya_ab45 => _resolve(const ['pc.checkUpdates', 'checkUpdates', 'proveritObnovleniya_ab45', 'pc.proveritObnovleniya_ab45'], base.proveritObnovleniya_ab45);

  @override
  String get osnovnayaInformatsiya_6fec => _resolve(const ['messenger.personal.sectionTitle', 'messenger.settings.personalTitle', 'pc.basicInfo', 'basicInfo', 'osnovnayaInformatsiya_6fec', 'pc.osnovnayaInformatsiya_6fec'], base.osnovnayaInformatsiya_6fec);

  @override
  String get imya_d38d => _resolve(const ['messenger.personal.name', 'profile.profile.displayName', 'pc.imya_d38d', 'imya_d38d'], base.imya_d38d);

  @override
  String get vvediteVasheImya_751e => _resolve(const ['messenger.personal.namePlaceholder', 'pc.vvediteVasheImya_751e', 'vvediteVasheImya_751e'], base.vvediteVasheImya_751e);

  @override
  String get nikneym_3fea => _resolve(const ['messenger.personal.nickname', 'profile.profile.username', 'pc.nikneym_3fea', 'nikneym_3fea'], base.nikneym_3fea);

  @override
  String get nikneymNelzyaIzmenitVPrilozhenii_75d0 => _resolve(const ['messenger.personal.nicknameCannotBeChanged', 'pc.nicknameCannotBeChanged', 'nicknameCannotBeChanged', 'nikneymNelzyaIzmenitVPrilozhenii_75d0', 'pc.nikneymNelzyaIzmenitVPrilozhenii_75d0'], base.nikneymNelzyaIzmenitVPrilozhenii_75d0);

  @override
  String get oSebe_0b3b => _resolve(const ['messenger.personal.bio', 'profile.profile.bio', 'pc.aboutMe', 'aboutMe', 'oSebe_0b3b', 'bio', 'pc.oSebe_0b3b'], base.oSebe_0b3b);

  @override
  String get rasskazhiteOSebe_1c37 => _resolve(const ['messenger.personal.bioPlaceholder', 'pc.aboutMeHint', 'aboutMeHint', 'rasskazhiteOSebe_1c37', 'pc.rasskazhiteOSebe_1c37'], base.rasskazhiteOSebe_1c37);

  @override
  String get sohranenie_c15f => _resolve(const ['common.saving', 'pc.saving', 'saving', 'sohranenie_c15f', 'pc.sohranenie_c15f'], base.sohranenie_c15f);

  @override
  String get sohranit_74ea => _resolve(const ['messenger.buttons.save', 'messenger.createGroup.createButton', 'common.save', 'profile.profile.save', 'pc.save', 'save', 'sohranit_74ea', 'pc.sohranit_74ea'], base.sohranit_74ea);

  @override
  String get vse_984b => _resolve(const ['messenger.privacy.all', 'common.all', 'pc.everyone', 'everyone', 'vse_984b', 'pc.vse_984b'], base.vse_984b);

  @override
  String get tolkoKontakty_a559 => _resolve(const ['messenger.privacy.contactsOnly', 'pc.contactsOnly', 'contactsOnly', 'tolkoKontakty_a559', 'pc.tolkoKontakty_a559'], base.tolkoKontakty_a559);

  @override
  String get nikto_ba19 => _resolve(const ['messenger.privacy.nobody', 'pc.nobody', 'nobody', 'nikto_ba19', 'pc.nikto_ba19'], base.nikto_ba19);

  @override
  String get kommunikatsii_1242 => _resolve(const ['messenger.privacy.communications', 'pc.communications', 'communications', 'kommunikatsii_1242', 'pc.kommunikatsii_1242'], base.kommunikatsii_1242);

  @override
  String get ktoMozhetPisatSoobscheniya_4645 => _resolve(const ['messenger.privacy.whoCanMessage', 'pc.whoCanMessage', 'whoCanMessage', 'ktoMozhetPisatSoobscheniya_4645', 'pc.ktoMozhetPisatSoobscheniya_4645'], base.ktoMozhetPisatSoobscheniya_4645);

  @override
  String get ktoMozhetZvonit_c427 => _resolve(const ['messenger.privacy.whoCanCall', 'pc.whoCanCall', 'whoCanCall', 'ktoMozhetZvonit_c427', 'pc.ktoMozhetZvonit_c427'], base.ktoMozhetZvonit_c427);

  @override
  String get ktoMozhetZapisyvatGolosovye_c69a => _resolve(const ['messenger.privacy.whoCanRecordVoice', 'pc.whoCanRecordVoice', 'whoCanRecordVoice', 'ktoMozhetZapisyvatGolosovye_c69a', 'pc.ktoMozhetZapisyvatGolosovye_c69a'], base.ktoMozhetZapisyvatGolosovye_c69a);

  @override
  String get ktoMozhetOtpravlyatFayly_2e40 => _resolve(const ['messenger.privacy.whoCanSendFiles', 'pc.whoCanSendFiles', 'whoCanSendFiles', 'ktoMozhetOtpravlyatFayly_2e40', 'pc.ktoMozhetOtpravlyatFayly_2e40'], base.ktoMozhetOtpravlyatFayly_2e40);

  @override
  String get ktoMozhetPriglashatVGruppy_cdc0 => _resolve(const ['messenger.privacy.whoCanInvite', 'pc.whoCanInvite', 'whoCanInvite', 'ktoMozhetPriglashatVGruppy_cdc0', 'pc.ktoMozhetPriglashatVGruppy_cdc0'], base.ktoMozhetPriglashatVGruppy_cdc0);

  @override
  String get vidimostProfilya_34bf => _resolve(const ['messenger.privacy.profileVisibility', 'pc.profileVisibility', 'profileVisibility', 'vidimostProfilya_34bf', 'pc.vidimostProfilya_34bf'], base.vidimostProfilya_34bf);

  @override
  String get ktoViditMoyNikneym_54b8 => _resolve(const ['messenger.privacy.whoSeesNickname', 'pc.whoSeesNickname', 'whoSeesNickname', 'ktoViditMoyNikneym_54b8', 'pc.ktoViditMoyNikneym_54b8'], base.ktoViditMoyNikneym_54b8);

  @override
  String get ktoViditMoyAvatar_e9f6 => _resolve(const ['pc.ktoViditMoyAvatar_e9f6', 'ktoViditMoyAvatar_e9f6', 'whoSeesAvatar'], base.ktoViditMoyAvatar_e9f6);

  @override
  String get ktoViditMoyDenRozhdeniya_ccc7 => _resolve(const ['pc.ktoViditMoyDenRozhdeniya_ccc7', 'ktoViditMoyDenRozhdeniya_ccc7', 'whoSeesBirthday'], base.ktoViditMoyDenRozhdeniya_ccc7);

  @override
  String get ktoViditVremyaMoeyAktivnosti_4349 => _resolve(const ['pc.ktoViditVremyaMoeyAktivnosti_4349', 'ktoViditVremyaMoeyAktivnosti_4349', 'whoSeesOnlineTime'], base.ktoViditVremyaMoeyAktivnosti_4349);

  @override
  String get neUdalosZagruzitKontakty_02a3 => _resolve(const ['pc.neUdalosZagruzitKontakty_02a3', 'neUdalosZagruzitKontakty_02a3'], base.neUdalosZagruzitKontakty_02a3);

  @override
  String get dobavitKontakt_4278 => _resolve(const ['messenger.contacts.createTitle', 'common.add', 'pc.addContactTitle', 'addContactTitle', 'dobavitKontakt_4278', 'pc.dobavitKontakt_4278'], base.dobavitKontakt_4278);

  @override
  String get nikneymPolzovatelya_5610 => _resolve(const ['pc.userNicknameHint', 'userNicknameHint', 'nikneymPolzovatelya_5610', 'pc.nikneymPolzovatelya_5610'], base.nikneymPolzovatelya_5610);

  @override
  String get otobrazhaemoeImyaOptsionalno_bbd1 => _resolve(const ['pc.displayNameOptional', 'displayNameOptional', 'otobrazhaemoeImyaOptsionalno_bbd1', 'pc.otobrazhaemoeImyaOptsionalno_bbd1'], base.otobrazhaemoeImyaOptsionalno_bbd1);

  @override
  String get otmena_987b => _resolve(const ['pc.cancel', 'cancel', 'otmena_987b', 'pc.otmena_987b'], base.otmena_987b);

  @override
  String get dobavit_5eba => _resolve(const ['messenger.contacts.createTitle', 'common.add', 'pc.addContact', 'addContact', 'dobavit_5eba', 'pc.dobavit_5eba'], base.dobavit_5eba);

  @override
  String get uVasPokaNetSohranennyh_b64b => _resolve(const ['pc.noContactsYet', 'noContactsYet', 'uVasPokaNetSohranennyh_b64b', 'pc.uVasPokaNetSohranennyh_b64b'], base.uVasPokaNetSohranennyh_b64b);

  @override
  String get pozvonit_ccfa => _resolve(const ['pc.pozvonit_ccfa', 'pozvonit_ccfa', 'call'], base.pozvonit_ccfa);

  @override
  String get napisat_0144 => _resolve(const ['pc.napisat_0144', 'napisat_0144', 'sendMessage'], base.napisat_0144);

  @override
  String get udalitKontakt_065d => _resolve(const ['pc.udalitKontakt_065d', 'udalitKontakt_065d', 'deleteContact'], base.udalitKontakt_065d);

  @override
  String get soobscheniya_7e26 => _resolve(const ['pc.soobscheniya_7e26', 'soobscheniya_7e26', 'messages'], base.soobscheniya_7e26);

  @override
  String get animatsiiSoobscheniy_bc8b => _resolve(const ['pc.animatsiiSoobscheniy_bc8b', 'animatsiiSoobscheniy_bc8b', 'messageAnimations'], base.animatsiiSoobscheniy_bc8b);

  @override
  String get pokazyvatAnimatsiiPriOtpravkeI_d663 => _resolve(const ['pc.pokazyvatAnimatsiiPriOtpravkeI_d663', 'pokazyvatAnimatsiiPriOtpravkeI_d663', 'messageAnimationsDesc'], base.pokazyvatAnimatsiiPriOtpravkeI_d663);

  @override
  String get arhivirovannyeChaty_d990 => _resolve(const ['pc.arhivirovannyeChaty_d990', 'arhivirovannyeChaty_d990', 'archivedChats'], base.arhivirovannyeChaty_d990);

  @override
  String get upravlenieArhivom_e843 => _resolve(const ['pc.upravlenieArhivom_e843', 'upravlenieArhivom_e843', 'archiveManagement'], base.upravlenieArhivom_e843);

  @override
  String get ochistitIstoriyu_837a => _resolve(const ['pc.ochistitIstoriyu_837a', 'ochistitIstoriyu_837a', 'clearHistory'], base.ochistitIstoriyu_837a);

  @override
  String get udalitVseSoobscheniyaLokalno_fbbd => _resolve(const ['pc.udalitVseSoobscheniyaLokalno_fbbd', 'udalitVseSoobscheniyaLokalno_fbbd', 'clearHistoryDesc'], base.udalitVseSoobscheniyaLokalno_fbbd);

  @override
  String get aktivnyeSessii_5c96 => _resolve(const ['pc.aktivnyeSessii_5c96', 'aktivnyeSessii_5c96', 'activeSessions'], base.aktivnyeSessii_5c96);

  @override
  String get etoUstroystvo_26f6 => _resolve(const ['pc.etoUstroystvo_26f6', 'etoUstroystvo_26f6', 'thisDevice'], base.etoUstroystvo_26f6);

  @override
  String get xaneoPcAktivnoSeychas_25b4 => _resolve(const ['pc.xaneoPcAktivnoSeychas_25b4', 'xaneoPcAktivnoSeychas_25b4', 'xaneoPcActiveNow'], base.xaneoPcAktivnoSeychas_25b4);

  @override
  String get aktivno_87a4 => _resolve(const ['pc.aktivno_87a4', 'aktivno_87a4', 'activeNow'], base.aktivno_87a4);

  @override
  String get dvoynayaAutentifikatsiya_66ae => _resolve(const ['pc.dvoynayaAutentifikatsiya_66ae', 'dvoynayaAutentifikatsiya_66ae'], base.dvoynayaAutentifikatsiya_66ae);

  @override
  String get zaschitaAkkauntaOdnorazovymParolem_e9f1 => _resolve(const ['pc.zaschitaAkkauntaOdnorazovymParolem_e9f1', 'zaschitaAkkauntaOdnorazovymParolem_e9f1', 'twoFactorAuthDesc'], base.zaschitaAkkauntaOdnorazovymParolem_e9f1);

  @override
  String get opasnayaZona_25bc => _resolve(const ['pc.opasnayaZona_25bc', 'opasnayaZona_25bc', 'dangerZone'], base.opasnayaZona_25bc);

  @override
  String get udalitAkkaunt_05c7 => _resolve(const ['pc.udalitAkkaunt_05c7', 'udalitAkkaunt_05c7', 'deleteAccount'], base.udalitAkkaunt_05c7);

  @override
  String get neobratimoeDeystvie_7232 => _resolve(const ['pc.neobratimoeDeystvie_7232', 'neobratimoeDeystvie_7232', 'irreversibleAction'], base.neobratimoeDeystvie_7232);

  @override
  String get tema_9e26 => _resolve(const ['pc.tema_9e26', 'tema_9e26', 'theme'], base.tema_9e26);

  @override
  String get temnayaTema_cb48 => _resolve(const ['pc.temnayaTema_cb48', 'temnayaTema_cb48'], base.temnayaTema_cb48);

  @override
  String get pereklyuchitMezhduTemnymISvetlym_5415 => _resolve(const ['pc.pereklyuchitMezhduTemnymISvetlym_5415', 'pereklyuchitMezhduTemnymISvetlym_5415'], base.pereklyuchitMezhduTemnymISvetlym_5415);

  @override
  String get razmerShrifta_1155 => _resolve(const ['pc.razmerShrifta_1155', 'razmerShrifta_1155', 'fontSizeText'], base.razmerShrifta_1155);

  @override
  String get a_87a0 => _resolve(const ['pc.a_87a0', 'a_87a0', 'pc.b_3b67', 'pc.ya_feef', 'b_3b67', 'ya_feef'], base.a_87a0);

  @override
  String get pokazyvatVsplyvayuschieUvedomleniya_754e => _resolve(const ['pc.pokazyvatVsplyvayuschieUvedomleniya_754e', 'pokazyvatVsplyvayuschieUvedomleniya_754e', 'showPopups'], base.pokazyvatVsplyvayuschieUvedomleniya_754e);

  @override
  String get zvuk_9329 => _resolve(const ['pc.zvuk_9329', 'zvuk_9329', 'sound'], base.zvuk_9329);

  @override
  String get vosproizvoditZvukPriNovomSoobschenii_47cc => _resolve(const ['pc.vosproizvoditZvukPriNovomSoobschenii_47cc', 'vosproizvoditZvukPriNovomSoobschenii_47cc', 'soundDesc'], base.vosproizvoditZvukPriNovomSoobschenii_47cc);

  @override
  String get osnovnyeNastroyki_231c => _resolve(const ['pc.osnovnyeNastroyki_231c', 'osnovnyeNastroyki_231c', 'mainSettings'], base.osnovnyeNastroyki_231c);

  @override
  String get rezhimEkonomiiEnergii_edfc => _resolve(const ['pc.rezhimEkonomiiEnergii_edfc', 'rezhimEkonomiiEnergii_edfc', 'energySavingMode'], base.rezhimEkonomiiEnergii_edfc);

  @override
  String get optimiziruetRabotuPrilozheniyaDlyaEkonomii_d9eb => _resolve(const ['pc.optimiziruetRabotuPrilozheniyaDlyaEkonomii_d9eb', 'optimiziruetRabotuPrilozheniyaDlyaEkonomii_d9eb'], base.optimiziruetRabotuPrilozheniyaDlyaEkonomii_d9eb);

  @override
  String get avtomaticheskiySpyaschiyRezhim_5955 => _resolve(const ['pc.avtomaticheskiySpyaschiyRezhim_5955', 'avtomaticheskiySpyaschiyRezhim_5955', 'autoSleep'], base.avtomaticheskiySpyaschiyRezhim_5955);

  @override
  String get perevoditPrilozhenieVSpyaschiyRezhim_1c07 => _resolve(const ['pc.perevoditPrilozhenieVSpyaschiyRezhim_1c07', 'perevoditPrilozhenieVSpyaschiyRezhim_1c07', 'autoSleepDesc'], base.perevoditPrilozhenieVSpyaschiyRezhim_1c07);

  @override
  String get animatsii_05c7 => _resolve(const ['pc.animatsii_05c7', 'animatsii_05c7', 'animations'], base.animatsii_05c7);

  @override
  String get uproschennyeAnimatsii_3a13 => _resolve(const ['pc.uproschennyeAnimatsii_3a13', 'uproschennyeAnimatsii_3a13', 'reducedMotion'], base.uproschennyeAnimatsii_3a13);

  @override
  String get umenshaetKolichestvoAnimatsiyInterfeysa_6bf1 => _resolve(const ['pc.umenshaetKolichestvoAnimatsiyInterfeysa_6bf1', 'umenshaetKolichestvoAnimatsiyInterfeysa_6bf1', 'reducedMotionDesc'], base.umenshaetKolichestvoAnimatsiyInterfeysa_6bf1);

  @override
  String get skoroBudetDostupno_de07 => _resolve(const ['pc.skoroBudetDostupno_de07', 'skoroBudetDostupno_de07', 'comingSoon'], base.skoroBudetDostupno_de07);

  @override
  String get gostevoyRezhim_6d82 => _resolve(const ['pc.gostevoyRezhim_6d82', 'gostevoyRezhim_6d82'], base.gostevoyRezhim_6d82);

  @override
  String get voyditeDlyaDostupaKAkkauntu_a5c8 => _resolve(const ['pc.voyditeDlyaDostupaKAkkauntu_a5c8', 'voyditeDlyaDostupaKAkkauntu_a5c8'], base.voyditeDlyaDostupaKAkkauntu_a5c8);

  @override
  String get nazhmiteDlyaProsmotraIzmeneniy_0255 => _resolve(const ['pc.nazhmiteDlyaProsmotraIzmeneniy_0255', 'nazhmiteDlyaProsmotraIzmeneniy_0255', 'clickToViewChanges'], base.nazhmiteDlyaProsmotraIzmeneniy_0255);

  @override
  String get vvediteKodPodtverzhdeniya_61af => _resolve(const ['pc.vvediteKodPodtverzhdeniya_61af', 'vvediteKodPodtverzhdeniya_61af'], base.vvediteKodPodtverzhdeniya_61af);

  @override
  String get nevernyyKodPodtverzhdeniya_7762 => _resolve(const ['pc.nevernyyKodPodtverzhdeniya_7762', 'nevernyyKodPodtverzhdeniya_7762'], base.nevernyyKodPodtverzhdeniya_7762);

  @override
  String get podtverditeEMail_4bd4 => _resolve(const ['pc.podtverditeEMail_4bd4', 'podtverditeEMail_4bd4'], base.podtverditeEMail_4bd4);

  @override
  String get proverit_340b => _resolve(const ['pc.proverit_340b', 'proverit_340b'], base.proverit_340b);

  @override
  String get otpravitKodPovtorno_7703 => _resolve(const ['pc.otpravitKodPovtorno_7703', 'otpravitKodPovtorno_7703'], base.otpravitKodPovtorno_7703);

  @override
  String get sovremennoeDesktopnoePrilozheniensKrasivymInterfeysom_8a4e => _resolve(const ['pc.sovremennoeDesktopnoePrilozheniensKrasivymInterfeysom_8a4e', 'sovremennoeDesktopnoePrilozheniensKrasivymInterfeysom_8a4e'], base.sovremennoeDesktopnoePrilozheniensKrasivymInterfeysom_8a4e);

  @override
  String get tehnologii_6332 => _resolve(const ['pc.tehnologii_6332', 'tehnologii_6332'], base.tehnologii_6332);

  @override
  String get vyNashliPashalku_1a57 => _resolve(const ['pc.vyNashliPashalku_1a57', 'vyNashliPashalku_1a57'], base.vyNashliPashalku_1a57);

  @override
  String get spasiboZaIspolzovanieXaneo_d079 => _resolve(const ['pc.spasiboZaIspolzovanieXaneo_d079', 'spasiboZaIspolzovanieXaneo_d079'], base.spasiboZaIspolzovanieXaneo_d079);

  @override
  String get globalnyyPoisk_77bf => _resolve(const ['pc.globalnyyPoisk_77bf', 'globalnyyPoisk_77bf', 'pc.dobavitKontakt_2903', 'dobavitKontakt_2903'], base.globalnyyPoisk_77bf);

  @override
  String get poiskKontaktovChatovKanalovBotov_db66 => _resolve(const ['pc.poiskKontaktovChatovKanalovBotov_db66', 'poiskKontaktovChatovKanalovBotov_db66'], base.poiskKontaktovChatovKanalovBotov_db66);

  @override
  String get lyudi_c7ae => _resolve(const ['pc.lyudi_c7ae', 'lyudi_c7ae'], base.lyudi_c7ae);

  @override
  String get gruppy_ebc4 => _resolve(const ['pc.gruppy_ebc4', 'gruppy_ebc4'], base.gruppy_ebc4);

  @override
  String get kanaly_0c11 => _resolve(const ['pc.kanaly_0c11', 'kanaly_0c11'], base.kanaly_0c11);

  @override
  String get boty_d6e4 => _resolve(const ['pc.boty_d6e4', 'boty_d6e4'], base.boty_d6e4);

  @override
  String get izbrannoe_2fc4 => _resolve(const ['pc.savedMessages', 'savedMessages', 'izbrannoe_2fc4', 'pc.izbrannoe_2fc4'], base.izbrannoe_2fc4);

  @override
  String get vvediteZaprosDlyaPoiskaPo_9955 => _resolve(const ['pc.vvediteZaprosDlyaPoiskaPo_9955', 'vvediteZaprosDlyaPoiskaPo_9955'], base.vvediteZaprosDlyaPoiskaPo_9955);

  @override
  String get nichegoNeNaydeno_8767 => _resolve(const ['pc.nichegoNeNaydeno_8767', 'nichegoNeNaydeno_8767'], base.nichegoNeNaydeno_8767);

  @override
  String get izbrannoe_b637 => _resolve(const ['pc.izbrannoe_b637', 'izbrannoe_b637', 'pc.interface', 'pc.chtoNovogo_74e2', 'pc.nastroyki_b01b', 'interface', 'chtoNovogo_74e2', 'nastroyki_b01b', 'interfeys_49be'], base.izbrannoe_b637);

  @override
  String get boty_800d => _resolve(const ['pc.boty_800d', 'boty_800d'], base.boty_800d);

  @override
  String get kanaly_ccec => _resolve(const ['pc.kanaly_ccec', 'kanaly_ccec', 'pc.gruppy_cfd6', 'gruppy_cfd6'], base.kanaly_ccec);

  @override
  String get gruppy_cfd6 => _resolve(const ['pc.gruppy_cfd6', 'gruppy_cfd6', 'pc.kanaly_ccec', 'kanaly_ccec'], base.gruppy_cfd6);

  @override
  String get polzovateli_e0ec => _resolve(const ['pc.polzovateli_e0ec', 'polzovateli_e0ec', 'pc.spisokMuzyki_d477', 'pc.nachatZvonok_3d26', 'pc.sozdatOpros_4b9e', 'pc.lichnyeDannye_10a7', 'pc.kommunikatsii_e9b8', 'pc.bezopasnost_fcbc', 'spisokMuzyki_d477', 'nachatZvonok_3d26', 'sozdatOpros_4b9e', 'lichnyeDannye_10a7', 'kommunikatsii_e9b8', 'bezopasnost_fcbc', 'createPoll'], base.polzovateli_e0ec);

  @override
  String get sohranennyeSoobscheniya_6b62 => _resolve(const ['pc.sohranennyeSoobscheniya_6b62', 'sohranennyeSoobscheniya_6b62'], base.sohranennyeSoobscheniya_6b62);

  @override
  String get bot_0ae1 => _resolve(const ['pc.bot_0ae1', 'bot_0ae1', 'pc.bot_2712', 'bot_2712'], base.bot_0ae1);

  @override
  String get bot_0f46 => _resolve(const ['pc.bot_0f46', 'bot_0f46'], base.bot_0f46);

  @override
  String get gruppa_99d9 => _resolve(const ['pc.gruppa_99d9', 'gruppa_99d9', 'group'], base.gruppa_99d9);

  @override
  String get kanal_2710 => _resolve(const ['pc.kanal_2710', 'kanal_2710', 'channel'], base.kanal_2710);

  @override
  String get versiya_3725 => _resolve(const ['pc.versiya_3725', 'versiya_3725'], base.versiya_3725);

  @override
  String get tehnicheskayaInformatsiya_ba0f => _resolve(const ['pc.tehnicheskayaInformatsiya_ba0f', 'tehnicheskayaInformatsiya_ba0f'], base.tehnicheskayaInformatsiya_ba0f);

  @override
  String get platforma_8848 => _resolve(const ['pc.platforma_8848', 'platforma_8848'], base.platforma_8848);

  @override
  String get arhitekturaProtsessora_c079 => _resolve(const ['pc.arhitekturaProtsessora_c079', 'arhitekturaProtsessora_c079'], base.arhitekturaProtsessora_c079);

  @override
  String get posmotretNaGithub_5238 => _resolve(const ['pc.posmotretNaGithub_5238', 'posmotretNaGithub_5238'], base.posmotretNaGithub_5238);

  @override
  String get zakryt_dd94 => _resolve(const ['pc.zakryt_dd94', 'zakryt_dd94'], base.zakryt_dd94);

  @override
  String get vklyuchitTemnuyuTemu_ed17 => _resolve(const ['pc.vklyuchitTemnuyuTemu_ed17', 'vklyuchitTemnuyuTemu_ed17'], base.vklyuchitTemnuyuTemu_ed17);

  @override
  String get vklyuchitUvedomleniya_d311 => _resolve(const ['pc.vklyuchitUvedomleniya_d311', 'vklyuchitUvedomleniya_d311', 'unmuteNotifications'], base.vklyuchitUvedomleniya_d311);

  @override
  String get kastomnyyOverleyXaneo_7d39 => _resolve(const ['pc.kastomnyyOverleyXaneo_7d39', 'kastomnyyOverleyXaneo_7d39'], base.kastomnyyOverleyXaneo_7d39);

  @override
  String get animirovannyeUvedomleniyaSBystrymOtvetom_a25d => _resolve(const ['pc.animirovannyeUvedomleniyaSBystrymOtvetom_a25d', 'animirovannyeUvedomleniyaSBystrymOtvetom_a25d'], base.animirovannyeUvedomleniyaSBystrymOtvetom_a25d);

  @override
  String get aaBbVv_1c6b => _resolve(const ['pc.aaBbVv_1c6b', 'aaBbVv_1c6b'], base.aaBbVv_1c6b);

  @override
  String get pleylist_a04c => _resolve(const ['pc.pleylist_a04c', 'pleylist_a04c', 'pc.akkaunty_80b5', 'pc.ddmmgggg_3524', 'akkaunty_80b5', 'ddmmgggg_3524', 'accountsTitle'], base.pleylist_a04c);

  @override
  String get spisokMuzyki_d477 => _resolve(const ['pc.spisokMuzyki_d477', 'spisokMuzyki_d477', 'pc.polzovateli_e0ec', 'pc.nachatZvonok_3d26', 'pc.sozdatOpros_4b9e', 'pc.lichnyeDannye_10a7', 'pc.kommunikatsii_e9b8', 'pc.bezopasnost_fcbc', 'polzovateli_e0ec', 'nachatZvonok_3d26', 'sozdatOpros_4b9e', 'lichnyeDannye_10a7', 'kommunikatsii_e9b8', 'bezopasnost_fcbc', 'createPoll'], base.spisokMuzyki_d477);

  @override
  String get loc_0B_5a4d => _resolve(const ['pc.loc_0B_5a4d', 'loc_0B_5a4d'], base.loc_0B_5a4d);

  @override
  String get b_3b67 => _resolve(const ['pc.b_3b67', 'b_3b67', 'pc.a_87a0', 'pc.ya_feef', 'a_87a0', 'ya_feef'], base.b_3b67);

  @override
  String get kb_419d => _resolve(const ['pc.kb_419d', 'kb_419d', 'pc.mb_b808', 'pc.gb_e572', 'pc.sb_3a4b', 'pc.vy_479c', 'pc.tb_0e05', 'mb_b808', 'gb_e572', 'sb_3a4b', 'vy_479c', 'tb_0e05'], base.kb_419d);

  @override
  String get mb_b808 => _resolve(const ['pc.mb_b808', 'mb_b808', 'pc.kb_419d', 'pc.gb_e572', 'pc.sb_3a4b', 'pc.vy_479c', 'pc.tb_0e05', 'kb_419d', 'gb_e572', 'sb_3a4b', 'vy_479c', 'tb_0e05'], base.mb_b808);

  @override
  String get gb_e572 => _resolve(const ['pc.gb_e572', 'gb_e572', 'pc.kb_419d', 'pc.mb_b808', 'pc.sb_3a4b', 'pc.vy_479c', 'pc.tb_0e05', 'kb_419d', 'mb_b808', 'sb_3a4b', 'vy_479c', 'tb_0e05'], base.gb_e572);

  @override
  String get audiozapis_867d => _resolve(const ['pc.audiozapis_867d', 'audiozapis_867d'], base.audiozapis_867d);

  @override
  String get muzykalnyyTrek_b15d => _resolve(const ['pc.muzykalnyyTrek_b15d', 'muzykalnyyTrek_b15d'], base.muzykalnyyTrek_b15d);

  @override
  String get muzykalnyeTrekiOtsutstvuyut_3301 => _resolve(const ['pc.muzykalnyeTrekiOtsutstvuyut_3301', 'muzykalnyeTrekiOtsutstvuyut_3301'], base.muzykalnyeTrekiOtsutstvuyut_3301);

  @override
  String get nikneymUzheZanyat_59aa => _resolve(const ['pc.nikneymUzheZanyat_59aa', 'nikneymUzheZanyat_59aa'], base.nikneymUzheZanyat_59aa);

  @override
  String get oshibkaProverki_2ab0 => _resolve(const ['pc.oshibkaProverki_2ab0', 'oshibkaProverki_2ab0'], base.oshibkaProverki_2ab0);

  @override
  String get emailUzheZanyat_17e1 => _resolve(const ['pc.emailUzheZanyat_17e1', 'emailUzheZanyat_17e1'], base.emailUzheZanyat_17e1);

  @override
  String get oshibkaOtpravkiKoda_a42a => _resolve(const ['pc.oshibkaOtpravkiKoda_a42a', 'oshibkaOtpravkiKoda_a42a'], base.oshibkaOtpravkiKoda_a42a);

  @override
  String get neobhodimoPrinyatUsloviyaISoglasie_e31e => _resolve(const ['pc.neobhodimoPrinyatUsloviyaISoglasie_e31e', 'neobhodimoPrinyatUsloviyaISoglasie_e31e'], base.neobhodimoPrinyatUsloviyaISoglasie_e31e);

  @override
  String get registratsiyaUspeshna_9d5c => _resolve(const ['pc.registratsiyaUspeshna_9d5c', 'registratsiyaUspeshna_9d5c'], base.registratsiyaUspeshna_9d5c);

  @override
  String get oshibkaRegistratsii_b9f2 => _resolve(const ['pc.oshibkaRegistratsii_b9f2', 'oshibkaRegistratsii_b9f2'], base.oshibkaRegistratsii_b9f2);

  @override
  String get nazad_2b0b => _resolve(const ['pc.nazad_2b0b', 'nazad_2b0b', 'backBtn'], base.nazad_2b0b);

  @override
  String get kakVasZovut_68b7 => _resolve(const ['pc.kakVasZovut_68b7', 'kakVasZovut_68b7'], base.kakVasZovut_68b7);

  @override
  String get kogdaVyRodilis_26f2 => _resolve(const ['pc.kogdaVyRodilis_26f2', 'kogdaVyRodilis_26f2'], base.kogdaVyRodilis_26f2);

  @override
  String get pridumayteNikneym_221b => _resolve(const ['pc.pridumayteNikneym_221b', 'pridumayteNikneym_221b'], base.pridumayteNikneym_221b);

  @override
  String get vashEmail_8bbd => _resolve(const ['pc.vashEmail_8bbd', 'vashEmail_8bbd', 'vashEmail_879d'], base.vashEmail_8bbd);

  @override
  String get podtverzhdenieEmail_281f => _resolve(const ['pc.podtverzhdenieEmail_281f', 'podtverzhdenieEmail_281f'], base.podtverzhdenieEmail_281f);

  @override
  String get sozdayteParol_5f4c => _resolve(const ['pc.sozdayteParol_5f4c', 'sozdayteParol_5f4c'], base.sozdayteParol_5f4c);

  @override
  String get podtverzhdenieParolya_ebc2 => _resolve(const ['pc.podtverzhdenieParolya_ebc2', 'podtverzhdenieParolya_ebc2'], base.podtverzhdenieParolya_ebc2);

  @override
  String get dobavteFoto_25eb => _resolve(const ['pc.dobavteFoto_25eb', 'dobavteFoto_25eb'], base.dobavteFoto_25eb);

  @override
  String get posledniyShag_e0c5 => _resolve(const ['pc.posledniyShag_e0c5', 'posledniyShag_e0c5'], base.posledniyShag_e0c5);

  @override
  String get vvediteVasheNastoyascheeImya_e656 => _resolve(const ['pc.vvediteVasheNastoyascheeImya_e656', 'vvediteVasheNastoyascheeImya_e656'], base.vvediteVasheNastoyascheeImya_e656);

  @override
  String get vamDolzhnoBytNeMenee_1111 => _resolve(const ['pc.vamDolzhnoBytNeMenee_1111', 'vamDolzhnoBytNeMenee_1111'], base.vamDolzhnoBytNeMenee_1111);

  @override
  String get nikneymDolzhenBytUnikalnym_952d => _resolve(const ['pc.nikneymDolzhenBytUnikalnym_952d', 'nikneymDolzhenBytUnikalnym_952d'], base.nikneymDolzhenBytUnikalnym_952d);

  @override
  String get myOtpravimKodPodtverzhdeniya_fc71 => _resolve(const ['pc.myOtpravimKodPodtverzhdeniya_fc71', 'myOtpravimKodPodtverzhdeniya_fc71'], base.myOtpravimKodPodtverzhdeniya_fc71);

  @override
  String get vvedite6ZnachnyyKodIz_f22f => _resolve(const ['pc.vvedite6ZnachnyyKodIz_f22f', 'vvedite6ZnachnyyKodIz_f22f'], base.vvedite6ZnachnyyKodIz_f22f);

  @override
  String get pridumayteNadezhnyyParol_2312 => _resolve(const ['pc.pridumayteNadezhnyyParol_2312', 'pridumayteNadezhnyyParol_2312'], base.pridumayteNadezhnyyParol_2312);

  @override
  String get povtoriteParolEscheRaz_6723 => _resolve(const ['pc.povtoriteParolEscheRaz_6723', 'povtoriteParolEscheRaz_6723'], base.povtoriteParolEscheRaz_6723);

  @override
  String get etoNeobyazatelnoNoPriyatno_b6a3 => _resolve(const ['pc.etoNeobyazatelnoNoPriyatno_b6a3', 'etoNeobyazatelnoNoPriyatno_b6a3'], base.etoNeobyazatelnoNoPriyatno_b6a3);

  @override
  String get proverteVashiDannyeIPrimite_3121 => _resolve(const ['pc.proverteVashiDannyeIPrimite_3121', 'proverteVashiDannyeIPrimite_3121'], base.proverteVashiDannyeIPrimite_3121);

  @override
  String get registratsiya_0b93 => _resolve(const ['pc.registratsiya_0b93', 'registratsiya_0b93'], base.registratsiya_0b93);

  @override
  String get vasheImya_51eb => _resolve(const ['pc.vasheImya_51eb', 'vasheImya_51eb'], base.vasheImya_51eb);

  @override
  String get proverkaDostupnosti_da13 => _resolve(const ['pc.proverkaDostupnosti_da13', 'proverkaDostupnosti_da13'], base.proverkaDostupnosti_da13);

  @override
  String get nikneymDostupen_3fc9 => _resolve(const ['pc.nikneymDostupen_3fc9', 'nikneymDostupen_3fc9'], base.nikneymDostupen_3fc9);

  @override
  String get nikneymZanyat_8a5f => _resolve(const ['pc.nikneymZanyat_8a5f', 'nikneymZanyat_8a5f'], base.nikneymZanyat_8a5f);

  @override
  String get emailDostupen_e903 => _resolve(const ['pc.emailDostupen_e903', 'emailDostupen_e903'], base.emailDostupen_e903);

  @override
  String get emailZanyat_fb40 => _resolve(const ['pc.emailZanyat_fb40', 'emailZanyat_fb40'], base.emailZanyat_fb40);

  @override
  String get kodPodtverzhdeniya_1c9d => _resolve(const ['pc.kodPodtverzhdeniya_1c9d', 'kodPodtverzhdeniya_1c9d'], base.kodPodtverzhdeniya_1c9d);

  @override
  String get parol_5ebe => _resolve(const ['pc.parol_5ebe', 'parol_5ebe'], base.parol_5ebe);

  @override
  String get podtverditeParol_e3e3 => _resolve(const ['pc.podtverditeParol_e3e3', 'podtverditeParol_e3e3'], base.podtverditeParol_e3e3);

  @override
  String get nazhmiteChtobyDobavitFoto_d6e8 => _resolve(const ['pc.nazhmiteChtobyDobavitFoto_d6e8', 'nazhmiteChtobyDobavitFoto_d6e8'], base.nazhmiteChtobyDobavitFoto_d6e8);

  @override
  String get udalitFoto_3426 => _resolve(const ['pc.udalitFoto_3426', 'udalitFoto_3426'], base.udalitFoto_3426);

  @override
  String get yaPrinimayuUsloviyaIspolzovaniya_391a => _resolve(const ['pc.yaPrinimayuUsloviyaIspolzovaniya_391a', 'yaPrinimayuUsloviyaIspolzovaniya_391a'], base.yaPrinimayuUsloviyaIspolzovaniya_391a);

  @override
  String get yaSoglasenNaObrabotkuPersonalnyh_f2a8 => _resolve(const ['pc.yaSoglasenNaObrabotkuPersonalnyh_f2a8', 'yaSoglasenNaObrabotkuPersonalnyh_f2a8'], base.yaSoglasenNaObrabotkuPersonalnyh_f2a8);

  @override
  String get zavershit_b0e3 => _resolve(const ['pc.zavershit_b0e3', 'zavershit_b0e3'], base.zavershit_b0e3);

  @override
  String get dalee_c453 => _resolve(const ['pc.dalee_c453', 'dalee_c453'], base.dalee_c453);

  @override
  String get dataRozhdeniya_505e => _resolve(const ['pc.dataRozhdeniya_505e', 'dataRozhdeniya_505e'], base.dataRozhdeniya_505e);

  @override
  String get vklyuchitTemnuyuTemuOformleniya_86c4 => _resolve(const ['pc.vklyuchitTemnuyuTemuOformleniya_86c4', 'vklyuchitTemnuyuTemuOformleniya_86c4'], base.vklyuchitTemnuyuTemuOformleniya_86c4);

  @override
  String get yanvar_ee86 => _resolve(const ['pc.yanvar_ee86', 'yanvar_ee86'], base.yanvar_ee86);

  @override
  String get fevral_28ff => _resolve(const ['pc.fevral_28ff', 'fevral_28ff'], base.fevral_28ff);

  @override
  String get mart_d766 => _resolve(const ['pc.mart_d766', 'mart_d766', 'pc.chats', 'chats', 'chaty_19ad'], base.mart_d766);

  @override
  String get aprel_03e9 => _resolve(const ['pc.aprel_03e9', 'aprel_03e9', 'pc.aprelya_2b5a', 'aprelya_2b5a', 'monthApr'], base.aprel_03e9);

  @override
  String get may_2e53 => _resolve(const ['pc.may_2e53', 'may_2e53'], base.may_2e53);

  @override
  String get iyun_cfcb => _resolve(const ['pc.iyun_cfcb', 'iyun_cfcb', 'pc.iyunya_adcb', 'iyunya_adcb', 'monthJun'], base.iyun_cfcb);

  @override
  String get iyul_89fb => _resolve(const ['pc.iyul_89fb', 'iyul_89fb', 'pc.iyulya_3236', 'iyulya_3236', 'monthJul'], base.iyul_89fb);

  @override
  String get avgust_de5a => _resolve(const ['pc.avgust_de5a', 'avgust_de5a'], base.avgust_de5a);

  @override
  String get sentyabr_ebfb => _resolve(const ['pc.sentyabr_ebfb', 'sentyabr_ebfb'], base.sentyabr_ebfb);

  @override
  String get oktyabr_1720 => _resolve(const ['pc.oktyabr_1720', 'oktyabr_1720'], base.oktyabr_1720);

  @override
  String get noyabr_66fb => _resolve(const ['pc.noyabr_66fb', 'noyabr_66fb'], base.noyabr_66fb);

  @override
  String get dekabr_39b3 => _resolve(const ['pc.dekabr_39b3', 'dekabr_39b3', 'pc.dekabrya_29cc', 'dekabrya_29cc', 'monthDec'], base.dekabr_39b3);

  @override
  String get pn_2c1e => _resolve(const ['pc.pn_2c1e', 'pn_2c1e'], base.pn_2c1e);

  @override
  String get vt_7145 => _resolve(const ['pc.vt_7145', 'vt_7145', 'pc.sr_c6e4', 'pc.cht_a51f', 'pc.pt_0123', 'pc.vs_4ad9', 'pc.vy_0101', 'sr_c6e4', 'cht_a51f', 'pt_0123', 'vs_4ad9', 'vy_0101'], base.vt_7145);

  @override
  String get sr_c6e4 => _resolve(const ['pc.sr_c6e4', 'sr_c6e4', 'pc.vt_7145', 'pc.cht_a51f', 'pc.pt_0123', 'pc.vs_4ad9', 'pc.vy_0101', 'vt_7145', 'cht_a51f', 'pt_0123', 'vs_4ad9', 'vy_0101'], base.sr_c6e4);

  @override
  String get cht_a51f => _resolve(const ['pc.cht_a51f', 'cht_a51f', 'pc.vt_7145', 'pc.sr_c6e4', 'pc.pt_0123', 'pc.vs_4ad9', 'pc.vy_0101', 'vt_7145', 'sr_c6e4', 'pt_0123', 'vs_4ad9', 'vy_0101'], base.cht_a51f);

  @override
  String get pt_0123 => _resolve(const ['pc.pt_0123', 'pt_0123', 'pc.vt_7145', 'pc.sr_c6e4', 'pc.cht_a51f', 'pc.vs_4ad9', 'pc.vy_0101', 'vt_7145', 'sr_c6e4', 'cht_a51f', 'vs_4ad9', 'vy_0101'], base.pt_0123);

  @override
  String get sb_3a4b => _resolve(const ['pc.sb_3a4b', 'sb_3a4b', 'pc.kb_419d', 'pc.mb_b808', 'pc.gb_e572', 'pc.vy_479c', 'pc.tb_0e05', 'kb_419d', 'mb_b808', 'gb_e572', 'vy_479c', 'tb_0e05'], base.sb_3a4b);

  @override
  String get vs_4ad9 => _resolve(const ['pc.vs_4ad9', 'vs_4ad9', 'pc.vt_7145', 'pc.sr_c6e4', 'pc.cht_a51f', 'pc.pt_0123', 'pc.vy_0101', 'vt_7145', 'sr_c6e4', 'cht_a51f', 'pt_0123', 'vy_0101'], base.vs_4ad9);

  @override
  String get gotovo_34e1 => _resolve(const ['pc.gotovo_34e1', 'gotovo_34e1'], base.gotovo_34e1);

  @override
  String get oshibkaVosstanovleniyaKlyucheyNeUdalos_fe7b => _resolve(const ['pc.oshibkaVosstanovleniyaKlyucheyNeUdalos_fe7b', 'oshibkaVosstanovleniyaKlyucheyNeUdalos_fe7b'], base.oshibkaVosstanovleniyaKlyucheyNeUdalos_fe7b);

  @override
  String get kriticheskayaOshibkaPriPeresozdaniiKlyuchey_b6d7 => _resolve(const ['pc.kriticheskayaOshibkaPriPeresozdaniiKlyuchey_b6d7', 'kriticheskayaOshibkaPriPeresozdaniiKlyuchey_b6d7'], base.kriticheskayaOshibkaPriPeresozdaniiKlyuchey_b6d7);

  @override
  String get oshibkaZagruzkiKlyucheyNaServer_ff9b => _resolve(const ['pc.oshibkaZagruzkiKlyucheyNaServer_ff9b', 'oshibkaZagruzkiKlyucheyNaServer_ff9b'], base.oshibkaZagruzkiKlyucheyNaServer_ff9b);

  @override
  String get oshibkaPriPolucheniiKlyucheyShifrovaniya_9bb4 => _resolve(const ['pc.oshibkaPriPolucheniiKlyucheyShifrovaniya_9bb4', 'oshibkaPriPolucheniiKlyucheyShifrovaniya_9bb4'], base.oshibkaPriPolucheniiKlyucheyShifrovaniya_9bb4);

  @override
  String get prevyshenLimitV5Akkauntov_a6a9 => _resolve(const ['pc.prevyshenLimitV5Akkauntov_a6a9', 'prevyshenLimitV5Akkauntov_a6a9'], base.prevyshenLimitV5Akkauntov_a6a9);

  @override
  String get oshibkaAvtorizatsii_9f5c => _resolve(const ['pc.oshibkaAvtorizatsii_9f5c', 'oshibkaAvtorizatsii_9f5c'], base.oshibkaAvtorizatsii_9f5c);

  @override
  String get oshibkaPodklyucheniyaKServeru_8b96 => _resolve(const ['pc.oshibkaPodklyucheniyaKServeru_8b96', 'oshibkaPodklyucheniyaKServeru_8b96'], base.oshibkaPodklyucheniyaKServeru_8b96);

  @override
  String get nazadKMessendzheru_de29 => _resolve(const ['pc.nazadKMessendzheru_de29', 'nazadKMessendzheru_de29'], base.nazadKMessendzheru_de29);

  @override
  String get voytiVAkkaunt_c439 => _resolve(const ['pc.voytiVAkkaunt_c439', 'voytiVAkkaunt_c439'], base.voytiVAkkaunt_c439);

  @override
  String get vvediteParol_1370 => _resolve(const ['pc.vvediteParol_1370', 'vvediteParol_1370'], base.vvediteParol_1370);

  @override
  String get vvediteSvoiDannyeDlyaDostupa_319e => _resolve(const ['pc.vvediteSvoiDannyeDlyaDostupa_319e', 'vvediteSvoiDannyeDlyaDostupa_319e'], base.vvediteSvoiDannyeDlyaDostupa_319e);

  @override
  String get voyti_63a7 => _resolve(const ['pc.voyti_63a7', 'voyti_63a7', 'submitCodeBtn'], base.voyti_63a7);

  @override
  String get sobesednik_7025 => _resolve(const ['messenger.call.contact', 'messenger.chatInfo.user', 'common.peer', 'pc.sobesednik_7025', 'sobesednik_7025'], base.sobesednik_7025);

  @override
  String get vy_0101 => _resolve(const ['messenger.chatInfo.you', 'common.you', 'pc.vy_0101', 'vy_0101', 'pc.vt_7145', 'pc.sr_c6e4', 'pc.cht_a51f', 'pc.pt_0123', 'pc.vs_4ad9', 'vt_7145', 'sr_c6e4', 'cht_a51f', 'pt_0123', 'vs_4ad9'], base.vy_0101);

  @override
  String get vyDelitesSvoimEkranom_16b1 => _resolve(const ['pc.vyDelitesSvoimEkranom_16b1', 'vyDelitesSvoimEkranom_16b1'], base.vyDelitesSvoimEkranom_16b1);

  @override
  String get polzovatel_f154 => _resolve(const ['messenger.system.user', 'pc.polzovatel_f154', 'polzovatel_f154', 'pc.polzovatelya_1083', 'polzovatelya_1083'], base.polzovatel_f154);

  @override
  String get ishodyaschiyVyzov_650b => _resolve(const ['pc.ishodyaschiyVyzov_650b', 'ishodyaschiyVyzov_650b'], base.ishodyaschiyVyzov_650b);

  @override
  String get vhodyaschiyVyzov_19ff => _resolve(const ['pc.vhodyaschiyVyzov_19ff', 'vhodyaschiyVyzov_19ff', 'pc.vhodyaschiyVyzov_d2f3', 'vhodyaschiyVyzov_d2f3'], base.vhodyaschiyVyzov_19ff);

  @override
  String get podklyucheno_d022 => _resolve(const ['pc.podklyucheno_d022', 'podklyucheno_d022'], base.podklyucheno_d022);

  @override
  String get ozhidanieOtveta_a984 => _resolve(const ['pc.ozhidanieOtveta_a984', 'ozhidanieOtveta_a984'], base.ozhidanieOtveta_a984);

  @override
  String get razgovorPoAudiosvyazi_3ed7 => _resolve(const ['pc.razgovorPoAudiosvyazi_3ed7', 'razgovorPoAudiosvyazi_3ed7'], base.razgovorPoAudiosvyazi_3ed7);

  @override
  String get translyatsiyaVashegoEkranaZapuschena_575a => _resolve(const ['pc.translyatsiyaVashegoEkranaZapuschena_575a', 'translyatsiyaVashegoEkranaZapuschena_575a'], base.translyatsiyaVashegoEkranaZapuschena_575a);

  @override
  String get sobesednikViditVseChtoProishodit_c759 => _resolve(const ['pc.sobesednikViditVseChtoProishodit_c759', 'sobesednikViditVseChtoProishodit_c759'], base.sobesednikViditVseChtoProishodit_c759);

  @override
  String get vhodyaschiyVyzov_905e => _resolve(const ['messenger.call.incoming', 'messenger.calls.incoming', 'pc.vhodyaschiyVyzov_905e', 'vhodyaschiyVyzov_905e'], base.vhodyaschiyVyzov_905e);

  @override
  String get neizvestnyy_be89 => _resolve(const ['messenger.system.unknownUser', 'common.unknown', 'pc.neizvestnyy_be89', 'neizvestnyy_be89'], base.neizvestnyy_be89);

  @override
  String get videozvonok_dd18 => _resolve(const ['messenger.callType.video', 'messenger.call.videoCall', 'messenger.calls.video', 'pc.videozvonok_dd18', 'videozvonok_dd18', 'pc.videozvonok_8142', 'videozvonok_8142', 'videoCall'], base.videozvonok_dd18);

  @override
  String get golosovoyZvonok_5410 => _resolve(const ['messenger.callType.audio', 'messenger.calls.audio', 'pc.golosovoyZvonok_5410', 'golosovoyZvonok_5410', 'pc.golosovoyZvonok_b615', 'golosovoyZvonok_b615', 'audioCall'], base.golosovoyZvonok_5410);

  @override
  String get otklonit_8b0d => _resolve(const ['messenger.call.decline', 'messenger.call.drop', 'messenger.calls.decline', 'messenger.delete.buttons.cancel', 'pc.otklonit_8b0d', 'otklonit_8b0d'], base.otklonit_8b0d);

  @override
  String get otvetit_e568 => _resolve(const ['messenger.call.accept', 'messenger.call.answer', 'messenger.calls.answer', 'messenger.message.reply', 'pc.reply', 'reply', 'otvetit_e568', 'pc.otvetit_e568'], base.otvetit_e568);

  @override
  String get gruppovoyZvonok_dac1 => _resolve(const ['messenger.createGroup.calls', 'messenger.editChat.groupCalls', 'common.groupCall', 'pc.gruppovoyZvonok_dac1', 'gruppovoyZvonok_dac1'], base.gruppovoyZvonok_dac1);

  @override
  String get podklyuchenieKZvonku_e2cf => _resolve(const ['messenger.call.waiting', 'messenger.call.outgoingStatus', 'pc.podklyuchenieKZvonku_e2cf', 'podklyuchenieKZvonku_e2cf'], base.podklyuchenieKZvonku_e2cf);

  @override
  String get podklyuchenieKVeschaniyu_038b => _resolve(const ['messenger.call.waiting', 'messenger.call.outgoingStatus', 'pc.podklyuchenieKVeschaniyu_038b', 'podklyuchenieKVeschaniyu_038b'], base.podklyuchenieKVeschaniyu_038b);

  @override
  String get uchastnik_cffb => _resolve(const ['pc.uchastnik_cffb', 'uchastnik_cffb'], base.uchastnik_cffb);

  @override
  String get vy_479c => _resolve(const ['pc.vy_479c', 'vy_479c', 'pc.kb_419d', 'pc.mb_b808', 'pc.gb_e572', 'pc.sb_3a4b', 'pc.tb_0e05', 'kb_419d', 'mb_b808', 'gb_e572', 'sb_3a4b', 'tb_0e05'], base.vy_479c);

  @override
  String get svernut_ca9f => _resolve(const ['messenger.call.minimize', 'common.minimize', 'pc.svernut_ca9f', 'svernut_ca9f'], base.svernut_ca9f);

  @override
  String get vhodyaschiyVyzov_d2f3 => _resolve(const ['pc.vhodyaschiyVyzov_d2f3', 'vhodyaschiyVyzov_d2f3', 'pc.vhodyaschiyVyzov_19ff', 'vhodyaschiyVyzov_19ff'], base.vhodyaschiyVyzov_d2f3);

  @override
  String get novoeSoobschenie_1d49 => _resolve(const ['pc.novoeSoobschenie_1d49', 'novoeSoobschenie_1d49'], base.novoeSoobschenie_1d49);

  @override
  String get vashOtvet_40c2 => _resolve(const ['pc.vashOtvet_40c2', 'vashOtvet_40c2'], base.vashOtvet_40c2);

  @override
  String get videovyzov_3353 => _resolve(const ['pc.videovyzov_3353', 'videovyzov_3353'], base.videovyzov_3353);

  @override
  String get audiovyzov_bbb5 => _resolve(const ['pc.audiovyzov_bbb5', 'audiovyzov_bbb5'], base.audiovyzov_bbb5);

  @override
  String get nachatZvonok_3d26 => _resolve(const ['messenger.callType.title', 'messenger.calls.start', 'messenger.calls.startCall', 'pc.nachatZvonok_3d26', 'nachatZvonok_3d26', 'pc.polzovateli_e0ec', 'pc.spisokMuzyki_d477', 'pc.sozdatOpros_4b9e', 'pc.lichnyeDannye_10a7', 'pc.kommunikatsii_e9b8', 'pc.bezopasnost_fcbc', 'polzovateli_e0ec', 'spisokMuzyki_d477', 'sozdatOpros_4b9e', 'lichnyeDannye_10a7', 'kommunikatsii_e9b8', 'bezopasnost_fcbc', 'createPoll'], base.nachatZvonok_3d26);

  @override
  String get golosovoyZvonok_b615 => _resolve(const ['messenger.callType.audio', 'messenger.calls.audio', 'pc.golosovoyZvonok_b615', 'golosovoyZvonok_b615', 'audioCall', 'pc.golosovoyZvonok_5410', 'golosovoyZvonok_5410'], base.golosovoyZvonok_b615);

  @override
  String get pozvonitPoGolosovoySvyazi_4069 => _resolve(const ['messenger.callType.audioDesc', 'pc.pozvonitPoGolosovoySvyazi_4069', 'pozvonitPoGolosovoySvyazi_4069', 'audioCallDesc'], base.pozvonitPoGolosovoySvyazi_4069);

  @override
  String get videozvonok_8142 => _resolve(const ['messenger.callType.video', 'messenger.call.videoCall', 'messenger.calls.video', 'pc.videozvonok_8142', 'videozvonok_8142', 'videoCall', 'pc.videozvonok_dd18', 'videozvonok_dd18'], base.videozvonok_8142);

  @override
  String get pozvonitSVklyuchennoyKameroy_fb05 => _resolve(const ['messenger.callType.videoDesc', 'pc.pozvonitSVklyuchennoyKameroy_fb05', 'pozvonitSVklyuchennoyKameroy_fb05', 'videoCallDesc'], base.pozvonitSVklyuchennoyKameroy_fb05);

  @override
  String get zashifrovannoeSoobschenie_ca35 => _resolve(const ['pc.zashifrovannoeSoobschenie_ca35', 'zashifrovannoeSoobschenie_ca35', 'pc.zashifrovannoeSoobschenie_c9ab', 'zashifrovannoeSoobschenie_c9ab'], base.zashifrovannoeSoobschenie_ca35);

  @override
  String get golosovoeSoobschenie_4a85 => _resolve(const ['pc.golosovoeSoobschenie_4a85', 'golosovoeSoobschenie_4a85'], base.golosovoeSoobschenie_4a85);

  @override
  String get videosoobschenie_d687 => _resolve(const ['pc.videosoobschenie_d687', 'videosoobschenie_d687'], base.videosoobschenie_d687);

  @override
  String get fayl_826d => _resolve(const ['pc.fayl_826d', 'fayl_826d'], base.fayl_826d);

  @override
  String get zvonok_e8d5 => _resolve(const ['pc.zvonok_e8d5', 'zvonok_e8d5'], base.zvonok_e8d5);

  @override
  String get oshibkaDeshifrovaniya_4146 => _resolve(const ['pc.oshibkaDeshifrovaniya_4146', 'oshibkaDeshifrovaniya_4146'], base.oshibkaDeshifrovaniya_4146);

  @override
  String get zapisyvaetGolosovoe_2a5c => _resolve(const ['pc.zapisyvaetGolosovoe_2a5c', 'zapisyvaetGolosovoe_2a5c', 'isRecordingVoice'], base.zapisyvaetGolosovoe_2a5c);

  @override
  String get pechataet_812c => _resolve(const ['pc.pechataet_812c', 'pechataet_812c', 'isTyping'], base.pechataet_812c);

  @override
  String get neUdalosArhivirovatChat_ab89 => _resolve(const ['pc.neUdalosArhivirovatChat_ab89', 'neUdalosArhivirovatChat_ab89'], base.neUdalosArhivirovatChat_ab89);

  @override
  String get neUdalosRazarhivirovatChat_f0d7 => _resolve(const ['pc.neUdalosRazarhivirovatChat_f0d7', 'neUdalosRazarhivirovatChat_f0d7'], base.neUdalosRazarhivirovatChat_f0d7);

  @override
  String get arhiv_56aa => _resolve(const ['pc.archive', 'archive', 'arhiv_56aa', 'pc.arhiv_56aa'], base.arhiv_56aa);

  @override
  String get netUserid_634a => _resolve(const ['pc.netUserid_634a', 'netUserid_634a'], base.netUserid_634a);

  @override
  String get netKlyucha_337b => _resolve(const ['pc.netKlyucha_337b', 'netKlyucha_337b'], base.netKlyucha_337b);

  @override
  String get neizvestnyyTipChata_2617 => _resolve(const ['pc.neizvestnyyTipChata_2617', 'neizvestnyyTipChata_2617'], base.neizvestnyyTipChata_2617);

  @override
  String get neUdalosPoluchitKlyuchShifrovaniya_b953 => _resolve(const ['pc.neUdalosPoluchitKlyuchShifrovaniya_b953', 'neUdalosPoluchitKlyuchShifrovaniya_b953'], base.neUdalosPoluchitKlyuchShifrovaniya_b953);

  @override
  String get gruppa_19c2 => _resolve(const ['pc.gruppa_19c2', 'gruppa_19c2'], base.gruppa_19c2);

  @override
  String get uchastnik_5bce => _resolve(const ['pc.uchastnik_5bce', 'uchastnik_5bce'], base.uchastnik_5bce);

  @override
  String get uchastnika_92d9 => _resolve(const ['pc.uchastnika_92d9', 'uchastnika_92d9'], base.uchastnika_92d9);

  @override
  String get uchastnikov_5d6b => _resolve(const ['pc.uchastnikov_5d6b', 'uchastnikov_5d6b'], base.uchastnikov_5d6b);

  @override
  String get kanal_64ec => _resolve(const ['pc.kanal_64ec', 'kanal_64ec'], base.kanal_64ec);

  @override
  String get podpischik_695a => _resolve(const ['pc.podpischik_695a', 'podpischik_695a'], base.podpischik_695a);

  @override
  String get podpischika_b490 => _resolve(const ['pc.podpischika_b490', 'podpischika_b490'], base.podpischika_b490);

  @override
  String get podpischikov_ba39 => _resolve(const ['pc.podpischikov_ba39', 'podpischikov_ba39'], base.podpischikov_ba39);

  @override
  String get segodnya_9626 => _resolve(const ['pc.segodnya_9626', 'segodnya_9626', 'today'], base.segodnya_9626);

  @override
  String get vchera_61d4 => _resolve(const ['pc.vchera_61d4', 'vchera_61d4', 'yesterday'], base.vchera_61d4);

  @override
  String get yanvarya_d861 => _resolve(const ['pc.yanvarya_d861', 'yanvarya_d861', 'monthJan'], base.yanvarya_d861);

  @override
  String get fevralya_fcf9 => _resolve(const ['pc.fevralya_fcf9', 'fevralya_fcf9', 'monthFeb'], base.fevralya_fcf9);

  @override
  String get marta_bb77 => _resolve(const ['pc.marta_bb77', 'marta_bb77', 'monthMar'], base.marta_bb77);

  @override
  String get aprelya_2b5a => _resolve(const ['pc.aprelya_2b5a', 'aprelya_2b5a', 'monthApr', 'pc.aprel_03e9', 'aprel_03e9'], base.aprelya_2b5a);

  @override
  String get maya_4dbb => _resolve(const ['pc.maya_4dbb', 'maya_4dbb', 'monthMay'], base.maya_4dbb);

  @override
  String get iyunya_adcb => _resolve(const ['pc.iyunya_adcb', 'iyunya_adcb', 'monthJun', 'pc.iyun_cfcb', 'iyun_cfcb'], base.iyunya_adcb);

  @override
  String get iyulya_3236 => _resolve(const ['pc.iyulya_3236', 'iyulya_3236', 'monthJul', 'pc.iyul_89fb', 'iyul_89fb'], base.iyulya_3236);

  @override
  String get avgusta_e3aa => _resolve(const ['pc.avgusta_e3aa', 'avgusta_e3aa', 'monthAug'], base.avgusta_e3aa);

  @override
  String get sentyabrya_a146 => _resolve(const ['pc.sentyabrya_a146', 'sentyabrya_a146', 'monthSep'], base.sentyabrya_a146);

  @override
  String get oktyabrya_7abd => _resolve(const ['pc.oktyabrya_7abd', 'oktyabrya_7abd', 'monthOct'], base.oktyabrya_7abd);

  @override
  String get noyabrya_6e78 => _resolve(const ['pc.noyabrya_6e78', 'noyabrya_6e78', 'monthNov'], base.noyabrya_6e78);

  @override
  String get dekabrya_29cc => _resolve(const ['pc.dekabrya_29cc', 'dekabrya_29cc', 'monthDec', 'pc.dekabr_39b3', 'dekabr_39b3'], base.dekabrya_29cc);

  @override
  String get vyPodpisalisNaKanal_b2b3 => _resolve(const ['pc.vyPodpisalisNaKanal_b2b3', 'vyPodpisalisNaKanal_b2b3'], base.vyPodpisalisNaKanal_b2b3);

  @override
  String get vyPrisoedinilisKGruppe_07bd => _resolve(const ['pc.vyPrisoedinilisKGruppe_07bd', 'vyPrisoedinilisKGruppe_07bd'], base.vyPrisoedinilisKGruppe_07bd);

  @override
  String get neUdalosPrisoedinitsya_31e6 => _resolve(const ['pc.neUdalosPrisoedinitsya_31e6', 'neUdalosPrisoedinitsya_31e6'], base.neUdalosPrisoedinitsya_31e6);

  @override
  String get vyOtpisalisOtKanala_7698 => _resolve(const ['pc.vyOtpisalisOtKanala_7698', 'vyOtpisalisOtKanala_7698'], base.vyOtpisalisOtKanala_7698);

  @override
  String get vyPokinuliGruppu_5a52 => _resolve(const ['pc.vyPokinuliGruppu_5a52', 'vyPokinuliGruppu_5a52'], base.vyPokinuliGruppu_5a52);

  @override
  String get neUdalosVypolnitDeystvie_3cfd => _resolve(const ['pc.neUdalosVypolnitDeystvie_3cfd', 'neUdalosVypolnitDeystvie_3cfd'], base.neUdalosVypolnitDeystvie_3cfd);

  @override
  String get neUdalosPereklyuchitAkkaunt_968b => _resolve(const ['pc.neUdalosPereklyuchitAkkaunt_968b', 'neUdalosPereklyuchitAkkaunt_968b'], base.neUdalosPereklyuchitAkkaunt_968b);

  @override
  String get media_c247 => _resolve(const ['pc.media_c247', 'media_c247', 'media'], base.media_c247);

  @override
  String get fayly_200c => _resolve(const ['pc.fayly_200c', 'fayly_200c', 'files'], base.fayly_200c);

  @override
  String get golos_2d89 => _resolve(const ['pc.golos_2d89', 'golos_2d89'], base.golos_2d89);

  @override
  String get ssylki_9f58 => _resolve(const ['pc.ssylki_9f58', 'ssylki_9f58', 'links'], base.ssylki_9f58);

  @override
  String get profil_c62a => _resolve(const ['pc.profil_c62a', 'profil_c62a', 'pc.account', 'account', 'akkaunt_38ac'], base.profil_c62a);

  @override
  String get imyaPolzovatelya_6fd4 => _resolve(const ['pc.imyaPolzovatelya_6fd4', 'imyaPolzovatelya_6fd4', 'username'], base.imyaPolzovatelya_6fd4);

  @override
  String get denRozhdeniya_e41d => _resolve(const ['pc.denRozhdeniya_e41d', 'denRozhdeniya_e41d', 'birthday'], base.denRozhdeniya_e41d);

  @override
  String get polzovatelSkrylInformatsiyuOSebe_f416 => _resolve(const ['pc.polzovatelSkrylInformatsiyuOSebe_f416', 'polzovatelSkrylInformatsiyuOSebe_f416', 'userHidInfo'], base.polzovatelSkrylInformatsiyuOSebe_f416);

  @override
  String get god_6270 => _resolve(const ['pc.god_6270', 'god_6270'], base.god_6270);

  @override
  String get goda_7443 => _resolve(const ['pc.goda_7443', 'goda_7443'], base.goda_7443);

  @override
  String get let_257a => _resolve(const ['pc.let_257a', 'let_257a'], base.let_257a);

  @override
  String get skopirovano_f70b => _resolve(const ['pc.skopirovano_f70b', 'skopirovano_f70b', 'copied'], base.skopirovano_f70b);

  @override
  String get akkaunty_80b5 => _resolve(const ['pc.akkaunty_80b5', 'akkaunty_80b5', 'accountsTitle', 'pc.pleylist_a04c', 'pc.ddmmgggg_3524', 'pleylist_a04c', 'ddmmgggg_3524'], base.akkaunty_80b5);

  @override
  String get dobavitAkkaunt_5253 => _resolve(const ['pc.dobavitAkkaunt_5253', 'dobavitAkkaunt_5253', 'addAccount'], base.dobavitAkkaunt_5253);

  @override
  String get limit5Akkauntov_fdb7 => _resolve(const ['pc.limit5Akkauntov_fdb7', 'limit5Akkauntov_fdb7', 'pc.accountLimitNotice', 'accountLimitNotice'], base.limit5Akkauntov_fdb7);

  @override
  String get nazadKChatam_7edb => _resolve(const ['pc.nazadKChatam_7edb', 'nazadKChatam_7edb', 'backToChats'], base.nazadKChatam_7edb);

  @override
  String get chaty_19ad => _resolve(const ['pc.chats', 'chats', 'chaty_19ad', 'pc.mart_d766', 'mart_d766', 'pc.chaty_19ad'], base.chaty_19ad);

  @override
  String get globalnyyPoisk_7ff2 => _resolve(const ['pc.globalnyyPoisk_7ff2', 'globalnyyPoisk_7ff2', 'globalSearch'], base.globalnyyPoisk_7ff2);

  @override
  String get arhivPust_3e22 => _resolve(const ['pc.archiveEmpty', 'archiveEmpty', 'arhivPust_3e22', 'pc.arhivPust_3e22'], base.arhivPust_3e22);

  @override
  String get netSoobscheniy_29d4 => _resolve(const ['pc.netSoobscheniy_29d4', 'netSoobscheniy_29d4', 'noMessagesTitle'], base.netSoobscheniy_29d4);

  @override
  String get toDoList_27e1 => _resolve(const ['pc.toDoList_27e1', 'toDoList_27e1'], base.toDoList_27e1);

  @override
  String get opros_6ff1 => _resolve(const ['pc.opros_6ff1', 'opros_6ff1'], base.opros_6ff1);

  @override
  String get fotografiya_5709 => _resolve(const ['pc.fotografiya_5709', 'fotografiya_5709'], base.fotografiya_5709);

  @override
  String get razarhivirovat_416b => _resolve(const ['pc.unarchive', 'unarchive', 'razarhivirovat_416b', 'pc.razarhivirovat_416b'], base.razarhivirovat_416b);

  @override
  String get vArhiv_ce22 => _resolve(const ['pc.toArchive', 'toArchive', 'vArhiv_ce22', 'pc.vArhiv_ce22'], base.vArhiv_ce22);

  @override
  String get chat_c52b => _resolve(const ['pc.chat_c52b', 'chat_c52b'], base.chat_c52b);

  @override
  String get vyberiteChatDlyaNachalaObscheniya_36a5 => _resolve(const ['pc.selectChatToStart', 'selectChatToStart', 'vyberiteChatDlyaNachalaObscheniya_36a5', 'pc.vyberiteChatDlyaNachalaObscheniya_36a5'], base.vyberiteChatDlyaNachalaObscheniya_36a5);

  @override
  String get bot_2712 => _resolve(const ['messenger.status.bot', 'common.bot', 'pc.bot_2712', 'bot_2712', 'pc.bot_0ae1', 'bot_0ae1'], base.bot_2712);

  @override
  String get vSeti_d902 => _resolve(const ['messenger.status.online', 'pc.online', 'online', 'vSeti_d902', 'pc.vSeti_d902'], base.vSeti_d902);

  @override
  String get neVSeti_ee01 => _resolve(const ['messenger.status.lastSeenRecently', 'messenger.status.offline', 'pc.offline', 'offline', 'neVSeti_ee01', 'pc.neVSeti_ee01'], base.neVSeti_ee01);

  @override
  String get nastroykiChata_1e0d => _resolve(const ['pc.nastroykiChata_1e0d', 'nastroykiChata_1e0d', 'chatSettings'], base.nastroykiChata_1e0d);

  @override
  String get pokinutGruppu_e6ce => _resolve(const ['pc.pokinutGruppu_e6ce', 'pokinutGruppu_e6ce', 'leaveGroup'], base.pokinutGruppu_e6ce);

  @override
  String get prisoedinitsyaKGruppe_eb45 => _resolve(const ['pc.prisoedinitsyaKGruppe_eb45', 'prisoedinitsyaKGruppe_eb45', 'joinGroup'], base.prisoedinitsyaKGruppe_eb45);

  @override
  String get otpisatsyaOtKanala_fdbc => _resolve(const ['pc.otpisatsyaOtKanala_fdbc', 'otpisatsyaOtKanala_fdbc', 'unsubscribeChannel'], base.otpisatsyaOtKanala_fdbc);

  @override
  String get podpisatsyaNaKanal_2dad => _resolve(const ['pc.podpisatsyaNaKanal_2dad', 'podpisatsyaNaKanal_2dad', 'subscribeChannel'], base.podpisatsyaNaKanal_2dad);

  @override
  String get netSoobscheniyNapishiteChtoNibud_2bf4 => _resolve(const ['pc.netSoobscheniyNapishiteChtoNibud_2bf4', 'netSoobscheniyNapishiteChtoNibud_2bf4'], base.netSoobscheniyNapishiteChtoNibud_2bf4);

  @override
  String get prisoedinilsyaKChatu_f623 => _resolve(const ['messenger.system.joinedChat', 'messenger.system.joinedShort', 'pc.joinedChat', 'joinedChat', 'prisoedinilsyaKChatu_f623', 'pc.prisoedinilsyaKChatu_f623'], base.prisoedinilsyaKChatu_f623);

  @override
  String get pokinulChat_d567 => _resolve(const ['messenger.system.leftChat', 'messenger.system.leftShort', 'pc.leftChat', 'leftChat', 'pokinulChat_d567', 'pc.pokinulChat_d567'], base.pokinulChat_d567);

  @override
  String get podpisalsyaNaKanal_0673 => _resolve(const ['messenger.system.subscribedChannel', 'pc.subscribedChannel', 'subscribedChannel', 'podpisalsyaNaKanal_0673', 'pc.podpisalsyaNaKanal_0673'], base.podpisalsyaNaKanal_0673);

  @override
  String get otpisalsyaOtKanala_fa13 => _resolve(const ['messenger.system.unsubscribedChannel', 'pc.unsubscribedChannel', 'unsubscribedChannel', 'otpisalsyaOtKanala_fa13', 'pc.otpisalsyaOtKanala_fa13'], base.otpisalsyaOtKanala_fa13);

  @override
  String get polzovatelya_1083 => _resolve(const ['messenger.system.user', 'pc.polzovatelya_1083', 'polzovatelya_1083', 'pc.polzovatel_f154', 'polzovatel_f154'], base.polzovatelya_1083);

  @override
  String get priglasil_47ae => _resolve(const ['messenger.system.invited', 'messenger.system.invitedSentence', 'pc.invited', 'invited', 'priglasil_47ae', 'pc.priglasil_47ae'], base.priglasil_47ae);

  @override
  String get rasshifrovka_e47f => _resolve(const ['pc.rasshifrovka_e47f', 'rasshifrovka_e47f'], base.rasshifrovka_e47f);

  @override
  String get sistemnoeSoobschenie_d2bd => _resolve(const ['messenger.system.systemMessage', 'pc.systemMessage', 'systemMessage', 'sistemnoeSoobschenie_d2bd', 'pc.sistemnoeSoobschenie_d2bd'], base.sistemnoeSoobschenie_d2bd);

  @override
  String get soobschenie_3715 => _resolve(const ['pc.soobschenie_3715', 'soobschenie_3715', 'pc.soobschenie_8b9b', 'soobschenie_8b9b'], base.soobschenie_3715);

  @override
  String get videosoobschenie_57f1 => _resolve(const ['pc.videosoobschenie_57f1', 'videosoobschenie_57f1'], base.videosoobschenie_57f1);

  @override
  String get spisokZadach_cfa4 => _resolve(const ['pc.spisokZadach_cfa4', 'spisokZadach_cfa4'], base.spisokZadach_cfa4);

  @override
  String get opros_5902 => _resolve(const ['pc.opros_5902', 'opros_5902'], base.opros_5902);

  @override
  String get vlozhenie_ef44 => _resolve(const ['pc.vlozhenie_ef44', 'vlozhenie_ef44'], base.vlozhenie_ef44);

  @override
  String get fayl_2d46 => _resolve(const ['pc.fayl_2d46', 'fayl_2d46', 'file'], base.fayl_2d46);

  @override
  String get zagruzkaFayla_f817 => _resolve(const ['pc.zagruzkaFayla_f817', 'zagruzkaFayla_f817'], base.zagruzkaFayla_f817);

  @override
  String get ishodyaschiyZvonok_8381 => _resolve(const ['messenger.calls.outgoing', 'pc.ishodyaschiyZvonok_8381', 'ishodyaschiyZvonok_8381'], base.ishodyaschiyZvonok_8381);

  @override
  String get razgovorNeSostoyalsya_67fb => _resolve(const ['messenger.calls.unanswered', 'pc.razgovorNeSostoyalsya_67fb', 'razgovorNeSostoyalsya_67fb'], base.razgovorNeSostoyalsya_67fb);

  @override
  String get vhodyaschiyZvonok_5ce9 => _resolve(const ['messenger.calls.incoming', 'pc.vhodyaschiyZvonok_5ce9', 'vhodyaschiyZvonok_5ce9'], base.vhodyaschiyZvonok_5ce9);

  @override
  String get otklonennyyZvonok_d499 => _resolve(const ['messenger.calls.rejected', 'pc.otklonennyyZvonok_d499', 'otklonennyyZvonok_d499'], base.otklonennyyZvonok_d499);

  @override
  String get vyOtkloniliVyzov_8d1d => _resolve(const ['messenger.calls.declined', 'pc.vyOtkloniliVyzov_8d1d', 'vyOtkloniliVyzov_8d1d'], base.vyOtkloniliVyzov_8d1d);

  @override
  String get propuschennyyZvonok_e98d => _resolve(const ['messenger.calls.missed', 'pc.propuschennyyZvonok_e98d', 'propuschennyyZvonok_e98d'], base.propuschennyyZvonok_e98d);

  @override
  String get vyPropustiliVyzov_f17a => _resolve(const ['messenger.calls.missedByYou', 'pc.vyPropustiliVyzov_f17a', 'vyPropustiliVyzov_f17a'], base.vyPropustiliVyzov_f17a);

  @override
  String get vlozhenie_2474 => _resolve(const ['pc.vlozhenie_2474', 'vlozhenie_2474'], base.vlozhenie_2474);

  @override
  String get tb_0e05 => _resolve(const ['pc.tb_0e05', 'tb_0e05', 'pc.kb_419d', 'pc.mb_b808', 'pc.gb_e572', 'pc.sb_3a4b', 'pc.vy_479c', 'kb_419d', 'mb_b808', 'gb_e572', 'sb_3a4b', 'vy_479c'], base.tb_0e05);

  @override
  String get zapisGolosovogo_9c91 => _resolve(const ['pc.zapisGolosovogo_9c91', 'zapisGolosovogo_9c91', 'recordingVoice'], base.zapisGolosovogo_9c91);

  @override
  String get zapisVideo_dd2a => _resolve(const ['pc.zapisVideo_dd2a', 'zapisVideo_dd2a', 'recordingVideo'], base.zapisVideo_dd2a);

  @override
  String get otpustiteDlyaOtpravki_ea7b => _resolve(const ['pc.otpustiteDlyaOtpravki_ea7b', 'otpustiteDlyaOtpravki_ea7b', 'releaseToSend'], base.otpustiteDlyaOtpravki_ea7b);

  @override
  String get emodzi_f822 => _resolve(const ['pc.emodzi_f822', 'emodzi_f822', 'emoji'], base.emodzi_f822);

  @override
  String get panelEmodziVRazrabotke_b6ce => _resolve(const ['pc.panelEmodziVRazrabotke_b6ce', 'panelEmodziVRazrabotke_b6ce', 'emojiPanelInDev'], base.panelEmodziVRazrabotke_b6ce);

  @override
  String get napisatSoobschenie_62d4 => _resolve(const ['pc.napisatSoobschenie_62d4', 'napisatSoobschenie_62d4', 'typeMessage'], base.napisatSoobschenie_62d4);

  @override
  String get dobavitVlozhenie_769b => _resolve(const ['pc.dobavitVlozhenie_769b', 'dobavitVlozhenie_769b', 'addAttachment'], base.dobavitVlozhenie_769b);

  @override
  String get spisokZadach_1852 => _resolve(const ['pc.spisokZadach_1852', 'spisokZadach_1852', 'todoList'], base.spisokZadach_1852);

  @override
  String get opros_9f36 => _resolve(const ['pc.opros_9f36', 'opros_9f36', 'poll'], base.opros_9f36);

  @override
  String get zapisGolosovogoGs_db4e => _resolve(const ['pc.zapisGolosovogoGs_db4e', 'zapisGolosovogoGs_db4e', 'voiceRecordTitle'], base.zapisGolosovogoGs_db4e);

  @override
  String get zapisVideoVs_9676 => _resolve(const ['pc.zapisVideoVs_9676', 'zapisVideoVs_9676'], base.zapisVideoVs_9676);

  @override
  String get uderzhivayteKnopkuDlyaZapisinNazhmite_3ab3 => _resolve(const ['pc.uderzhivayteKnopkuDlyaZapisinNazhmite_3ab3', 'uderzhivayteKnopkuDlyaZapisinNazhmite_3ab3'], base.uderzhivayteKnopkuDlyaZapisinNazhmite_3ab3);

  @override
  String get novyyChat_f775 => _resolve(const ['pc.novyyChat_f775', 'novyyChat_f775'], base.novyyChat_f775);

  @override
  String get imyaPolzovatelyaMin5Simvolov_1232 => _resolve(const ['pc.imyaPolzovatelyaMin5Simvolov_1232', 'imyaPolzovatelyaMin5Simvolov_1232'], base.imyaPolzovatelyaMin5Simvolov_1232);

  @override
  String get vvedite5IliBoleeSimvolov_f983 => _resolve(const ['pc.vvedite5IliBoleeSimvolov_f983', 'vvedite5IliBoleeSimvolov_f983'], base.vvedite5IliBoleeSimvolov_f983);

  @override
  String get polzovateliNeNaydeny_c01a => _resolve(const ['pc.polzovateliNeNaydeny_c01a', 'polzovateliNeNaydeny_c01a'], base.polzovateliNeNaydeny_c01a);

  @override
  String get mnozhestvennyyVybor_9b60 => _resolve(const ['pc.mnozhestvennyyVybor_9b60', 'mnozhestvennyyVybor_9b60'], base.mnozhestvennyyVybor_9b60);

  @override
  String get odinochnyyVybor_d920 => _resolve(const ['pc.odinochnyyVybor_d920', 'odinochnyyVybor_d920', 'singleChoice'], base.odinochnyyVybor_d920);

  @override
  String get netGolosov_17d0 => _resolve(const ['pc.netGolosov_17d0', 'netGolosov_17d0'], base.netGolosov_17d0);

  @override
  String get golos_6b94 => _resolve(const ['pc.golos_6b94', 'golos_6b94'], base.golos_6b94);

  @override
  String get golosa_bb8d => _resolve(const ['pc.golosa_bb8d', 'golosa_bb8d'], base.golosa_bb8d);

  @override
  String get golosov_7f51 => _resolve(const ['pc.golosov_7f51', 'golosov_7f51'], base.golosov_7f51);

  @override
  String get nePoluchenIdFaylaOt_86c8 => _resolve(const ['pc.nePoluchenIdFaylaOt_86c8', 'nePoluchenIdFaylaOt_86c8'], base.nePoluchenIdFaylaOt_86c8);

  @override
  String get faylZagruzhenIPrikreplen_dc24 => _resolve(const ['pc.faylZagruzhenIPrikreplen_dc24', 'faylZagruzhenIPrikreplen_dc24'], base.faylZagruzhenIPrikreplen_dc24);

  @override
  String get neizvestnayaOshibkaZagruzki_68cb => _resolve(const ['pc.neizvestnayaOshibkaZagruzki_68cb', 'neizvestnayaOshibkaZagruzki_68cb'], base.neizvestnayaOshibkaZagruzki_68cb);

  @override
  String get oshibkaZagruzkiFayla_86e5 => _resolve(const ['pc.oshibkaZagruzkiFayla_86e5', 'oshibkaZagruzkiFayla_86e5'], base.oshibkaZagruzkiFayla_86e5);

  @override
  String get sohranitFaylKak_0f93 => _resolve(const ['pc.sohranitFaylKak_0f93', 'sohranitFaylKak_0f93'], base.sohranitFaylKak_0f93);

  @override
  String get oshibkaSkachivaniyaFayla_34ac => _resolve(const ['pc.oshibkaSkachivaniyaFayla_34ac', 'oshibkaSkachivaniyaFayla_34ac'], base.oshibkaSkachivaniyaFayla_34ac);

  @override
  String get bezNazvaniya_6584 => _resolve(const ['pc.bezNazvaniya_6584', 'bezNazvaniya_6584'], base.bezNazvaniya_6584);

  @override
  String get bezVoprosa_d390 => _resolve(const ['pc.bezVoprosa_d390', 'bezVoprosa_d390'], base.bezVoprosa_d390);

  @override
  String get netDostupaKMikrofonu_a4ef => _resolve(const ['pc.netDostupaKMikrofonu_a4ef', 'netDostupaKMikrofonu_a4ef'], base.netDostupaKMikrofonu_a4ef);

  @override
  String get zapisVideoCherezPlaginCamera_b9dd => _resolve(const ['pc.zapisVideoCherezPlaginCamera_b9dd', 'zapisVideoCherezPlaginCamera_b9dd'], base.zapisVideoCherezPlaginCamera_b9dd);

  @override
  String get kameraNeInitsializirovanaNaEtoy_21e0 => _resolve(const ['pc.kameraNeInitsializirovanaNaEtoy_21e0', 'kameraNeInitsializirovanaNaEtoy_21e0'], base.kameraNeInitsializirovanaNaEtoy_21e0);

  @override
  String get kameraNeGotova_9f09 => _resolve(const ['pc.kameraNeGotova_9f09', 'kameraNeGotova_9f09'], base.kameraNeGotova_9f09);

  @override
  String get zapisVideosoobscheniyaNaEtoyPlatforme_a561 => _resolve(const ['pc.zapisVideosoobscheniyaNaEtoyPlatforme_a561', 'zapisVideosoobscheniyaNaEtoyPlatforme_a561'], base.zapisVideosoobscheniyaNaEtoyPlatforme_a561);

  @override
  String get arecordOstanovlen_edf2 => _resolve(const ['pc.arecordOstanovlen_edf2', 'arecordOstanovlen_edf2'], base.arecordOstanovlen_edf2);

  @override
  String get ffmpegOstanovlen_63a0 => _resolve(const ['pc.ffmpegOstanovlen_63a0', 'ffmpegOstanovlen_63a0'], base.ffmpegOstanovlen_63a0);

  @override
  String get zapisSlishkomKorotkaya_5cda => _resolve(const ['pc.zapisSlishkomKorotkaya_5cda', 'zapisSlishkomKorotkaya_5cda'], base.zapisSlishkomKorotkaya_5cda);

  @override
  String get oshibkaZapisiFaylPust_106b => _resolve(const ['pc.oshibkaZapisiFaylPust_106b', 'oshibkaZapisiFaylPust_106b'], base.oshibkaZapisiFaylPust_106b);

  @override
  String get videosoobschenieOtpravlenoSimulyatsiya_fb29 => _resolve(const ['pc.videosoobschenieOtpravlenoSimulyatsiya_fb29', 'videosoobschenieOtpravlenoSimulyatsiya_fb29'], base.videosoobschenieOtpravlenoSimulyatsiya_fb29);

  @override
  String get zapisOtmenena_1609 => _resolve(const ['pc.zapisOtmenena_1609', 'zapisOtmenena_1609'], base.zapisOtmenena_1609);

  @override
  String get otpravitGolosovoeSoobschenie_2481 => _resolve(const ['pc.otpravitGolosovoeSoobschenie_2481', 'otpravitGolosovoeSoobschenie_2481'], base.otpravitGolosovoeSoobschenie_2481);

  @override
  String get imitatsiyaZapisiGolosovogoSoobscheniya_81e7 => _resolve(const ['pc.imitatsiyaZapisiGolosovogoSoobscheniya_81e7', 'imitatsiyaZapisiGolosovogoSoobscheniya_81e7'], base.imitatsiyaZapisiGolosovogoSoobscheniya_81e7);

  @override
  String get otpravit_6da0 => _resolve(const ['pc.otpravit_6da0', 'otpravit_6da0'], base.otpravit_6da0);

  @override
  String get sozdatToDo_8c92 => _resolve(const ['pc.sozdatToDo_8c92', 'sozdatToDo_8c92', 'createTodo'], base.sozdatToDo_8c92);

  @override
  String get nazvanieSpiska_c3cc => _resolve(const ['pc.nazvanieSpiska_c3cc', 'nazvanieSpiska_c3cc', 'listName'], base.nazvanieSpiska_c3cc);

  @override
  String get punkty_0481 => _resolve(const ['pc.punkty_0481', 'punkty_0481', 'pc.todoItems', 'todoItems'], base.punkty_0481);

  @override
  String get dobavitPunkt_930c => _resolve(const ['pc.dobavitPunkt_930c', 'dobavitPunkt_930c', 'pc.addTodoItem', 'addTodoItem'], base.dobavitPunkt_930c);

  @override
  String get sozdat_b059 => _resolve(const ['pc.sozdat_b059', 'sozdat_b059'], base.sozdat_b059);

  @override
  String get sozdatOpros_4b9e => _resolve(const ['pc.sozdatOpros_4b9e', 'sozdatOpros_4b9e', 'createPoll', 'pc.polzovateli_e0ec', 'pc.spisokMuzyki_d477', 'pc.nachatZvonok_3d26', 'pc.lichnyeDannye_10a7', 'pc.kommunikatsii_e9b8', 'pc.bezopasnost_fcbc', 'polzovateli_e0ec', 'spisokMuzyki_d477', 'nachatZvonok_3d26', 'lichnyeDannye_10a7', 'kommunikatsii_e9b8', 'bezopasnost_fcbc'], base.sozdatOpros_4b9e);

  @override
  String get vopros_0911 => _resolve(const ['pc.vopros_0911', 'vopros_0911', 'pollQuestion'], base.vopros_0911);

  @override
  String get variantyOtveta_ef4e => _resolve(const ['pc.variantyOtveta_ef4e', 'variantyOtveta_ef4e', 'pc.pollOptions', 'pollOptions'], base.variantyOtveta_ef4e);

  @override
  String get dobavitVariant_76be => _resolve(const ['pc.dobavitVariant_76be', 'dobavitVariant_76be', 'pc.addPollOption', 'addPollOption'], base.dobavitVariant_76be);

  @override
  String get golosovoeSoobschenie_33d5 => _resolve(const ['pc.voiceMessage', 'voiceMessage', 'golosovoeSoobschenie_33d5', 'pc.golosovoeSoobschenie_33d5'], base.golosovoeSoobschenie_33d5);

  @override
  String get videosoobschenie_2951 => _resolve(const ['pc.videoMessage', 'videoMessage', 'videosoobschenie_2951', 'pc.videosoobschenie_2951'], base.videosoobschenie_2951);

  @override
  String get video_a095 => _resolve(const ['pc.video_a095', 'video_a095'], base.video_a095);

  @override
  String get neUdalosZagruzitIzobrazhenie_3fa0 => _resolve(const ['pc.neUdalosZagruzitIzobrazhenie_3fa0', 'neUdalosZagruzitIzobrazhenie_3fa0'], base.neUdalosZagruzitIzobrazhenie_3fa0);

  @override
  String get muzyka_0660 => _resolve(const ['pc.muzyka_0660', 'muzyka_0660', 'music'], base.muzyka_0660);

  @override
  String get netDannyh_dee9 => _resolve(const ['pc.netDannyh_dee9', 'netDannyh_dee9'], base.netDannyh_dee9);

  @override
  String get istoriyaSoobscheniyPustaIliChat_2d07 => _resolve(const ['pc.istoriyaSoobscheniyPustaIliChat_2d07', 'istoriyaSoobscheniyPustaIliChat_2d07'], base.istoriyaSoobscheniyPustaIliChat_2d07);

  @override
  String get obschieMaterialy_11e4 => _resolve(const ['pc.obschieMaterialy_11e4', 'obschieMaterialy_11e4'], base.obschieMaterialy_11e4);

  @override
  String get netMediafaylov_08d2 => _resolve(const ['pc.netMediafaylov_08d2', 'netMediafaylov_08d2', 'noSharedMedia'], base.netMediafaylov_08d2);

  @override
  String get zdesBudutOtobrazhatsyaObschieFoto_9bc7 => _resolve(const ['pc.zdesBudutOtobrazhatsyaObschieFoto_9bc7', 'zdesBudutOtobrazhatsyaObschieFoto_9bc7'], base.zdesBudutOtobrazhatsyaObschieFoto_9bc7);

  @override
  String get netFaylov_e95e => _resolve(const ['pc.netFaylov_e95e', 'netFaylov_e95e', 'noSharedFiles'], base.netFaylov_e95e);

  @override
  String get zdesBudutOtobrazhatsyaOtpravlennyeFayly_f62c => _resolve(const ['pc.zdesBudutOtobrazhatsyaOtpravlennyeFayly_f62c', 'zdesBudutOtobrazhatsyaOtpravlennyeFayly_f62c'], base.zdesBudutOtobrazhatsyaOtpravlennyeFayly_f62c);

  @override
  String get netGolosovyhSoobscheniy_2427 => _resolve(const ['pc.netGolosovyhSoobscheniy_2427', 'netGolosovyhSoobscheniy_2427', 'noSharedVoice'], base.netGolosovyhSoobscheniy_2427);

  @override
  String get zdesBudutOtobrazhatsyaGolosovyeI_0a73 => _resolve(const ['pc.zdesBudutOtobrazhatsyaGolosovyeI_0a73', 'zdesBudutOtobrazhatsyaGolosovyeI_0a73'], base.zdesBudutOtobrazhatsyaGolosovyeI_0a73);

  @override
  String get netSsylok_b0ec => _resolve(const ['pc.netSsylok_b0ec', 'netSsylok_b0ec', 'noSharedLinks'], base.netSsylok_b0ec);

  @override
  String get zdesBudutOtobrazhatsyaObschieSsylki_6b61 => _resolve(const ['pc.zdesBudutOtobrazhatsyaObschieSsylki_6b61', 'zdesBudutOtobrazhatsyaObschieSsylki_6b61'], base.zdesBudutOtobrazhatsyaObschieSsylki_6b61);

  @override
  String get ssylkaSkopirovanaVBufer_c16e => _resolve(const ['pc.ssylkaSkopirovanaVBufer_c16e', 'ssylkaSkopirovanaVBufer_c16e'], base.ssylkaSkopirovanaVBufer_c16e);

  @override
  String get netMuzyki_1ca3 => _resolve(const ['pc.netMuzyki_1ca3', 'netMuzyki_1ca3'], base.netMuzyki_1ca3);

  @override
  String get zdesBudutOtobrazhatsyaOtpravlennyeTreki_ea23 => _resolve(const ['pc.zdesBudutOtobrazhatsyaOtpravlennyeTreki_ea23', 'zdesBudutOtobrazhatsyaOtpravlennyeTreki_ea23'], base.zdesBudutOtobrazhatsyaOtpravlennyeTreki_ea23);

  @override
  String get udalennyyAkkaunt_ce47 => _resolve(const ['pc.udalennyyAkkaunt_ce47', 'udalennyyAkkaunt_ce47'], base.udalennyyAkkaunt_ce47);

  @override
  String get opisanie_38ca => _resolve(const ['pc.opisanie_38ca', 'opisanie_38ca'], base.opisanie_38ca);

  @override
  String get mobilnyy_5ac7 => _resolve(const ['pc.mobilnyy_5ac7', 'mobilnyy_5ac7'], base.mobilnyy_5ac7);

  @override
  String get bylANedavno_168d => _resolve(const ['messenger.status.lastSeenRecently', 'pc.bylANedavno_168d', 'bylANedavno_168d', 'pc.lastSeenRecently', 'lastSeenRecently'], base.bylANedavno_168d);

  @override
  String get minutu_5373 => _resolve(const ['pc.minutu_5373', 'minutu_5373', 'pc.minuty_5bc9', 'minuty_5bc9'], base.minutu_5373);

  @override
  String get minuty_5bc9 => _resolve(const ['pc.minuty_5bc9', 'minuty_5bc9', 'pc.minutu_5373', 'minutu_5373'], base.minuty_5bc9);

  @override
  String get minut_b877 => _resolve(const ['pc.minut_b877', 'minut_b877'], base.minut_b877);

  @override
  String get nazhmiteChtobyZagruzitNovuyuVersiyu_8b2a => _resolve(const ['pc.nazhmiteChtobyZagruzitNovuyuVersiyu_8b2a', 'nazhmiteChtobyZagruzitNovuyuVersiyu_8b2a'], base.nazhmiteChtobyZagruzitNovuyuVersiyu_8b2a);

  @override
  String get poiskLyudeyBotovGrupp_e84e => _resolve(const ['pc.poiskLyudeyBotovGrupp_e84e', 'poiskLyudeyBotovGrupp_e84e'], base.poiskLyudeyBotovGrupp_e84e);

  @override
  String get vveditePoiskovyyZapros_0b8c => _resolve(const ['pc.vveditePoiskovyyZapros_0b8c', 'vveditePoiskovyyZapros_0b8c'], base.vveditePoiskovyyZapros_0b8c);

  @override
  String get polzovateli_b8c4 => _resolve(const ['pc.polzovateli_b8c4', 'polzovateli_b8c4'], base.polzovateli_b8c4);

  @override
  String get moiLichnyeSoobscheniya_7d3b => _resolve(const ['pc.moiLichnyeSoobscheniya_7d3b', 'moiLichnyeSoobscheniya_7d3b'], base.moiLichnyeSoobscheniya_7d3b);

  @override
  String get sozdatNovyyChat_fd41 => _resolve(const ['messenger.createChat.title', 'messenger.createChatTooltip', 'pc.sozdatNovyyChat_fd41', 'sozdatNovyyChat_fd41'], base.sozdatNovyyChat_fd41);

  @override
  String get lichnyyChat_cbec => _resolve(const ['messenger.createChat.newMessageTitle', 'messenger.createOptions.personalTitle', 'pc.lichnyyChat_cbec', 'lichnyyChat_cbec'], base.lichnyyChat_cbec);

  @override
  String get nachatObschenieSPolzovatelem_0578 => _resolve(const ['messenger.createChat.newMessageDesc', 'messenger.createOptions.personalDesc', 'pc.nachatObschenieSPolzovatelem_0578', 'nachatObschenieSPolzovatelem_0578'], base.nachatObschenieSPolzovatelem_0578);

  @override
  String get sozdatGruppu_459f => _resolve(const ['messenger.createChat.groupTitle', 'messenger.createGroup.title', 'pc.sozdatGruppu_459f', 'sozdatGruppu_459f'], base.sozdatGruppu_459f);

  @override
  String get gruppovoyChatDlyaObscheniyaS_01ba => _resolve(const ['messenger.createChat.groupDesc', 'messenger.createGroup.descriptionPlaceholder', 'pc.gruppovoyChatDlyaObscheniyaS_01ba', 'gruppovoyChatDlyaObscheniyaS_01ba'], base.gruppovoyChatDlyaObscheniyaS_01ba);

  @override
  String get sozdatKanal_9022 => _resolve(const ['messenger.createChat.channelTitle', 'messenger.createChannel.title', 'pc.sozdatKanal_9022', 'sozdatKanal_9022'], base.sozdatKanal_9022);

  @override
  String get kanalDlyaShirokoyAuditorii_9dba => _resolve(const ['messenger.createChat.channelDesc', 'messenger.createChannel.descriptionPlaceholder', 'pc.kanalDlyaShirokoyAuditorii_9dba', 'kanalDlyaShirokoyAuditorii_9dba'], base.kanalDlyaShirokoyAuditorii_9dba);

  @override
  String get redaktirovanie_1167 => _resolve(const ['pc.redaktirovanie_1167', 'redaktirovanie_1167'], base.redaktirovanie_1167);

  @override
  String get vlevo_1af1 => _resolve(const ['pc.vlevo_1af1', 'vlevo_1af1'], base.vlevo_1af1);

  @override
  String get vpravo_c316 => _resolve(const ['pc.vpravo_c316', 'vpravo_c316'], base.vpravo_c316);

  @override
  String get poGor_ff50 => _resolve(const ['pc.poGor_ff50', 'poGor_ff50'], base.poGor_ff50);

  @override
  String get poVert_b4a9 => _resolve(const ['pc.poVert_b4a9', 'poVert_b4a9'], base.poVert_b4a9);

  @override
  String get vvediteNazvanieGruppy_0a69 => _resolve(const ['pc.vvediteNazvanieGruppy_0a69', 'vvediteNazvanieGruppy_0a69'], base.vvediteNazvanieGruppy_0a69);

  @override
  String get dlyaPublichnoyGruppyTrebuetsyaNikneym_15d0 => _resolve(const ['pc.dlyaPublichnoyGruppyTrebuetsyaNikneym_15d0', 'dlyaPublichnoyGruppyTrebuetsyaNikneym_15d0'], base.dlyaPublichnoyGruppyTrebuetsyaNikneym_15d0);

  @override
  String get gruppaSozdana_6b3b => _resolve(const ['pc.gruppaSozdana_6b3b', 'gruppaSozdana_6b3b'], base.gruppaSozdana_6b3b);

  @override
  String get oshibkaPriSozdaniiGruppy_794e => _resolve(const ['pc.oshibkaPriSozdaniiGruppy_794e', 'oshibkaPriSozdaniiGruppy_794e'], base.oshibkaPriSozdaniiGruppy_794e);

  @override
  String get nazhmiteNaIkonkuChtobyVybrat_af03 => _resolve(const ['pc.nazhmiteNaIkonkuChtobyVybrat_af03', 'nazhmiteNaIkonkuChtobyVybrat_af03'], base.nazhmiteNaIkonkuChtobyVybrat_af03);

  @override
  String get nazvanieGruppy_9a39 => _resolve(const ['pc.nazvanieGruppy_9a39', 'nazvanieGruppy_9a39'], base.nazvanieGruppy_9a39);

  @override
  String get opisanieNeobyazatelno_7812 => _resolve(const ['pc.opisanieNeobyazatelno_7812', 'opisanieNeobyazatelno_7812'], base.opisanieNeobyazatelno_7812);

  @override
  String get privatnayaGruppa_d20e => _resolve(const ['pc.privatnayaGruppa_d20e', 'privatnayaGruppa_d20e'], base.privatnayaGruppa_d20e);

  @override
  String get publichnayaGruppa_50f8 => _resolve(const ['pc.publichnayaGruppa_50f8', 'publichnayaGruppa_50f8'], base.publichnayaGruppa_50f8);

  @override
  String get vhodTolkoPoPriglasheniyu_97a1 => _resolve(const ['pc.vhodTolkoPoPriglasheniyu_97a1', 'vhodTolkoPoPriglasheniyu_97a1'], base.vhodTolkoPoPriglasheniyu_97a1);

  @override
  String get lyuboyMozhetNaytiIVstupit_5e26 => _resolve(const ['pc.lyuboyMozhetNaytiIVstupit_5e26', 'lyuboyMozhetNaytiIVstupit_5e26'], base.lyuboyMozhetNaytiIVstupit_5e26);

  @override
  String get publichnayaSsylkanikneymMyGroup_6640 => _resolve(const ['pc.publichnayaSsylkanikneymMyGroup_6640', 'publichnayaSsylkanikneymMyGroup_6640'], base.publichnayaSsylkanikneymMyGroup_6640);

  @override
  String get vvediteNazvanieKanala_5536 => _resolve(const ['pc.vvediteNazvanieKanala_5536', 'vvediteNazvanieKanala_5536'], base.vvediteNazvanieKanala_5536);

  @override
  String get dlyaPublichnogoKanalaTrebuetsyaSsylkanikneym_5f06 => _resolve(const ['pc.dlyaPublichnogoKanalaTrebuetsyaSsylkanikneym_5f06', 'dlyaPublichnogoKanalaTrebuetsyaSsylkanikneym_5f06'], base.dlyaPublichnogoKanalaTrebuetsyaSsylkanikneym_5f06);

  @override
  String get kanalSozdan_1522 => _resolve(const ['pc.kanalSozdan_1522', 'kanalSozdan_1522'], base.kanalSozdan_1522);

  @override
  String get oshibkaPriSozdaniiKanala_7d4b => _resolve(const ['pc.oshibkaPriSozdaniiKanala_7d4b', 'oshibkaPriSozdaniiKanala_7d4b'], base.oshibkaPriSozdaniiKanala_7d4b);

  @override
  String get nazvanieKanala_c548 => _resolve(const ['pc.nazvanieKanala_c548', 'nazvanieKanala_c548'], base.nazvanieKanala_c548);

  @override
  String get privatnyyKanal_3139 => _resolve(const ['pc.privatnyyKanal_3139', 'privatnyyKanal_3139'], base.privatnyyKanal_3139);

  @override
  String get publichnyyKanal_0f7c => _resolve(const ['pc.publichnyyKanal_0f7c', 'publichnyyKanal_0f7c'], base.publichnyyKanal_0f7c);

  @override
  String get podpiskaTolkoPoPriglasheniyu_99c3 => _resolve(const ['pc.podpiskaTolkoPoPriglasheniyu_99c3', 'podpiskaTolkoPoPriglasheniyu_99c3'], base.podpiskaTolkoPoPriglasheniyu_99c3);

  @override
  String get lyuboyMozhetNaytiIPodpisatsya_8579 => _resolve(const ['pc.lyuboyMozhetNaytiIPodpisatsya_8579', 'lyuboyMozhetNaytiIPodpisatsya_8579'], base.lyuboyMozhetNaytiIPodpisatsya_8579);

  @override
  String get ssylkanikneymKanalaMychannel_79f6 => _resolve(const ['pc.ssylkanikneymKanalaMychannel_79f6', 'ssylkanikneymKanalaMychannel_79f6'], base.ssylkanikneymKanalaMychannel_79f6);

  @override
  String get yazykInterfeysa_b78b => _resolve(const ['pc.yazykInterfeysa_b78b', 'yazykInterfeysa_b78b'], base.yazykInterfeysa_b78b);

  @override
  String get dannyeUspeshnoSohraneny_2cc5 => _resolve(const ['pc.dannyeUspeshnoSohraneny_2cc5', 'dannyeUspeshnoSohraneny_2cc5'], base.dannyeUspeshnoSohraneny_2cc5);

  @override
  String get oshibkaPriSohranenii_126f => _resolve(const ['pc.oshibkaPriSohranenii_126f', 'oshibkaPriSohranenii_126f'], base.oshibkaPriSohranenii_126f);

  @override
  String get lichnyeDannye_10a7 => _resolve(const ['pc.lichnyeDannye_10a7', 'lichnyeDannye_10a7', 'pc.polzovateli_e0ec', 'pc.spisokMuzyki_d477', 'pc.nachatZvonok_3d26', 'pc.sozdatOpros_4b9e', 'pc.kommunikatsii_e9b8', 'pc.bezopasnost_fcbc', 'polzovateli_e0ec', 'spisokMuzyki_d477', 'nachatZvonok_3d26', 'sozdatOpros_4b9e', 'kommunikatsii_e9b8', 'bezopasnost_fcbc', 'createPoll'], base.lichnyeDannye_10a7);

  @override
  String get nikneymUsername_8035 => _resolve(const ['pc.nikneymUsername_8035', 'nikneymUsername_8035'], base.nikneymUsername_8035);

  @override
  String get nikneymNelzyaIzmenit_0b99 => _resolve(const ['pc.nikneymNelzyaIzmenit_0b99', 'nikneymNelzyaIzmenit_0b99'], base.nikneymNelzyaIzmenit_0b99);

  @override
  String get oSebeBio_b730 => _resolve(const ['pc.oSebeBio_b730', 'oSebeBio_b730'], base.oSebeBio_b730);

  @override
  String get rasskazhiteNemnogoOSebe_3daa => _resolve(const ['pc.rasskazhiteNemnogoOSebe_3daa', 'rasskazhiteNemnogoOSebe_3daa'], base.rasskazhiteNemnogoOSebe_3daa);

  @override
  String get nastroykiPrivatnostiSohraneny_447c => _resolve(const ['pc.nastroykiPrivatnostiSohraneny_447c', 'nastroykiPrivatnostiSohraneny_447c'], base.nastroykiPrivatnostiSohraneny_447c);

  @override
  String get privatnost_3098 => _resolve(const ['pc.privatnost_3098', 'privatnost_3098', 'pc.oPrilozhenii_77b2', 'oPrilozhenii_77b2'], base.privatnost_3098);

  @override
  String get kommunikatsii_e9b8 => _resolve(const ['pc.kommunikatsii_e9b8', 'kommunikatsii_e9b8', 'pc.polzovateli_e0ec', 'pc.spisokMuzyki_d477', 'pc.nachatZvonok_3d26', 'pc.sozdatOpros_4b9e', 'pc.lichnyeDannye_10a7', 'pc.bezopasnost_fcbc', 'polzovateli_e0ec', 'spisokMuzyki_d477', 'nachatZvonok_3d26', 'sozdatOpros_4b9e', 'lichnyeDannye_10a7', 'bezopasnost_fcbc', 'createPoll'], base.kommunikatsii_e9b8);

  @override
  String get ktoMozhetPisat_3322 => _resolve(const ['pc.ktoMozhetPisat_3322', 'ktoMozhetPisat_3322'], base.ktoMozhetPisat_3322);

  @override
  String get zapisGolosovyh_8073 => _resolve(const ['pc.zapisGolosovyh_8073', 'zapisGolosovyh_8073'], base.zapisGolosovyh_8073);

  @override
  String get otpravkaFaylov_aaca => _resolve(const ['pc.otpravkaFaylov_aaca', 'otpravkaFaylov_aaca'], base.otpravkaFaylov_aaca);

  @override
  String get priglashatVGruppy_3631 => _resolve(const ['pc.priglashatVGruppy_3631', 'priglashatVGruppy_3631'], base.priglashatVGruppy_3631);

  @override
  String get vidimostProfilya_448f => _resolve(const ['pc.vidimostProfilya_448f', 'vidimostProfilya_448f', 'pc.istochnikZagruzki_0e6e', 'istochnikZagruzki_0e6e'], base.vidimostProfilya_448f);

  @override
  String get ktoViditAvatar_b5d8 => _resolve(const ['pc.ktoViditAvatar_b5d8', 'ktoViditAvatar_b5d8'], base.ktoViditAvatar_b5d8);

  @override
  String get vremyaVSeti_be29 => _resolve(const ['pc.vremyaVSeti_be29', 'vremyaVSeti_be29'], base.vremyaVSeti_be29);

  @override
  String get vneshniyVid_5a0f => _resolve(const ['pc.vneshniyVid_5a0f', 'vneshniyVid_5a0f', 'pc.obnovlenie_7e32', 'pc.prilozhenie_38aa', 'obnovlenie_7e32', 'prilozhenie_38aa'], base.vneshniyVid_5a0f);

  @override
  String get rezhimOformleniyaInterfeysa_b91d => _resolve(const ['pc.rezhimOformleniyaInterfeysa_b91d', 'rezhimOformleniyaInterfeysa_b91d'], base.rezhimOformleniyaInterfeysa_b91d);

  @override
  String get pokazyvatVizualnyeEffektyIPerehody_3fd7 => _resolve(const ['pc.pokazyvatVizualnyeEffektyIPerehody_3fd7', 'pokazyvatVizualnyeEffektyIPerehody_3fd7'], base.pokazyvatVizualnyeEffektyIPerehody_3fd7);

  @override
  String get razmerTeksta_3c4f => _resolve(const ['pc.razmerTeksta_3c4f', 'razmerTeksta_3c4f'], base.razmerTeksta_3c4f);

  @override
  String get bezopasnost_fcbc => _resolve(const ['pc.bezopasnost_fcbc', 'bezopasnost_fcbc', 'pc.polzovateli_e0ec', 'pc.spisokMuzyki_d477', 'pc.nachatZvonok_3d26', 'pc.sozdatOpros_4b9e', 'pc.lichnyeDannye_10a7', 'pc.kommunikatsii_e9b8', 'polzovateli_e0ec', 'spisokMuzyki_d477', 'nachatZvonok_3d26', 'sozdatOpros_4b9e', 'lichnyeDannye_10a7', 'kommunikatsii_e9b8', 'createPoll'], base.bezopasnost_fcbc);

  @override
  String get dvuhfaktornayaAutentifikatsiya_acdc => _resolve(const ['pc.dvuhfaktornayaAutentifikatsiya_acdc', 'dvuhfaktornayaAutentifikatsiya_acdc', 'twoFactorAuth', 'pc.dvuhfaktornayanautentifikatsiya_bacc', 'dvuhfaktornayanautentifikatsiya_bacc'], base.dvuhfaktornayaAutentifikatsiya_acdc);

  @override
  String get zaschitaAkkaunta2fa_f1ab => _resolve(const ['pc.zaschitaAkkaunta2fa_f1ab', 'zaschitaAkkaunta2fa_f1ab'], base.zaschitaAkkaunta2fa_f1ab);

  @override
  String get vklyucheno_6b96 => _resolve(const ['pc.vklyucheno_6b96', 'vklyucheno_6b96'], base.vklyucheno_6b96);

  @override
  String get xaneoMobileAktivnoSeychas_3345 => _resolve(const ['pc.xaneoMobileAktivnoSeychas_3345', 'xaneoMobileAktivnoSeychas_3345'], base.xaneoMobileAktivnoSeychas_3345);

  @override
  String get zaschischennyyMessendzher_2f59 => _resolve(const ['pc.zaschischennyyMessendzher_2f59', 'zaschischennyyMessendzher_2f59'], base.zaschischennyyMessendzher_2f59);

  @override
  String get temnayaTema_6018 => _resolve(const ['pc.temnayaTema_6018', 'temnayaTema_6018'], base.temnayaTema_6018);

  @override
  String get vklyuchenaPoUmolchaniyu_7610 => _resolve(const ['pc.vklyuchenaPoUmolchaniyu_7610', 'vklyuchenaPoUmolchaniyu_7610'], base.vklyuchenaPoUmolchaniyu_7610);

  @override
  String get setevoyFiltr_40c2 => _resolve(const ['pc.setevoyFiltr_40c2', 'setevoyFiltr_40c2'], base.setevoyFiltr_40c2);

  @override
  String get vklyuchen_0994 => _resolve(const ['pc.vklyuchen_0994', 'vklyuchen_0994'], base.vklyuchen_0994);

  @override
  String get spisokMuzyki_57d0 => _resolve(const ['pc.musicPlaylist', 'musicPlaylist', 'spisokMuzyki_57d0', 'pc.spisokMuzyki_57d0'], base.spisokMuzyki_57d0);

  @override
  String get trek_5049 => _resolve(const ['pc.trek_5049', 'trek_5049'], base.trek_5049);

  @override
  String get trekov_d3f4 => _resolve(const ['pc.trekov_d3f4', 'trekov_d3f4'], base.trekov_d3f4);

  @override
  String get pozhaluystaZapolniteVoprosIKak_7ad5 => _resolve(const ['pc.pozhaluystaZapolniteVoprosIKak_7ad5', 'pozhaluystaZapolniteVoprosIKak_7ad5'], base.pozhaluystaZapolniteVoprosIKak_7ad5);

  @override
  String get sozdatOpros_8401 => _resolve(const ['pc.sozdatOpros_8401', 'sozdatOpros_8401'], base.sozdatOpros_8401);

  @override
  String get sozdatSpisokZadach_4018 => _resolve(const ['pc.sozdatSpisokZadach_4018', 'sozdatSpisokZadach_4018'], base.sozdatSpisokZadach_4018);

  @override
  String get pozhaluystaZapolniteNazvanieIKak_3783 => _resolve(const ['pc.pozhaluystaZapolniteNazvanieIKak_3783', 'pozhaluystaZapolniteNazvanieIKak_3783'], base.pozhaluystaZapolniteNazvanieIKak_3783);

  @override
  String get sozdatSpisokZadach_0416 => _resolve(const ['pc.sozdatSpisokZadach_0416', 'sozdatSpisokZadach_0416'], base.sozdatSpisokZadach_0416);

  @override
  String get vhodyaschiyVideozvonok_14d4 => _resolve(const ['pc.vhodyaschiyVideozvonok_14d4', 'vhodyaschiyVideozvonok_14d4'], base.vhodyaschiyVideozvonok_14d4);

  @override
  String get prinyat_5dc5 => _resolve(const ['pc.prinyat_5dc5', 'prinyat_5dc5'], base.prinyat_5dc5);

  @override
  String get netObschihFaylov_bf77 => _resolve(const ['pc.netObschihFaylov_bf77', 'netObschihFaylov_bf77'], base.netObschihFaylov_bf77);

  @override
  String get neUdalosRazarhivirovatChatNa_b6f6 => _resolve(const ['pc.neUdalosRazarhivirovatChatNa_b6f6', 'neUdalosRazarhivirovatChatNa_b6f6'], base.neUdalosRazarhivirovatChatNa_b6f6);

  @override
  String get poiskVArhive_c5d8 => _resolve(const ['pc.poiskVArhive_c5d8', 'poiskVArhive_c5d8'], base.poiskVArhive_c5d8);

  @override
  String get poprobuyteIzmenitZapros_52ea => _resolve(const ['pc.poprobuyteIzmenitZapros_52ea', 'poprobuyteIzmenitZapros_52ea'], base.poprobuyteIzmenitZapros_52ea);

  @override
  String get zdesBudutNahoditsyaVashiArhivirovannye_7359 => _resolve(const ['pc.zdesBudutNahoditsyaVashiArhivirovannye_7359', 'zdesBudutNahoditsyaVashiArhivirovannye_7359'], base.zdesBudutNahoditsyaVashiArhivirovannye_7359);

  @override
  String get vernut_54aa => _resolve(const ['pc.vernut_54aa', 'vernut_54aa'], base.vernut_54aa);

  @override
  String get zashifrovannoeSoobschenie_c9ab => _resolve(const ['pc.zashifrovannoeSoobschenie_c9ab', 'zashifrovannoeSoobschenie_c9ab', 'pc.zashifrovannoeSoobschenie_ca35', 'zashifrovannoeSoobschenie_ca35'], base.zashifrovannoeSoobschenie_c9ab);

  @override
  String get soobschenieNahoditsyaVysheVIstorii_dc90 => _resolve(const ['pc.soobschenieNahoditsyaVysheVIstorii_dc90', 'soobschenieNahoditsyaVysheVIstorii_dc90'], base.soobschenieNahoditsyaVysheVIstorii_dc90);

  @override
  String get otpravlyaetFoto_67c1 => _resolve(const ['pc.otpravlyaetFoto_67c1', 'otpravlyaetFoto_67c1'], base.otpravlyaetFoto_67c1);

  @override
  String get otpravlyaetVideo_ce80 => _resolve(const ['pc.otpravlyaetVideo_ce80', 'otpravlyaetVideo_ce80'], base.otpravlyaetVideo_ce80);

  @override
  String get otpravlyaetFayl_5e88 => _resolve(const ['pc.otpravlyaetFayl_5e88', 'otpravlyaetFayl_5e88'], base.otpravlyaetFayl_5e88);

  @override
  String get ktoTo_8405 => _resolve(const ['pc.ktoTo_8405', 'ktoTo_8405'], base.ktoTo_8405);

  @override
  String get trebuetsyaRazreshenieNaKameruI_06fa => _resolve(const ['pc.trebuetsyaRazreshenieNaKameruI_06fa', 'trebuetsyaRazreshenieNaKameruI_06fa'], base.trebuetsyaRazreshenieNaKameruI_06fa);

  @override
  String get kameraNeNaydena_208d => _resolve(const ['pc.kameraNeNaydena_208d', 'kameraNeNaydena_208d'], base.kameraNeNaydena_208d);

  @override
  String get zapisVideoOtmenena_1db7 => _resolve(const ['pc.zapisVideoOtmenena_1db7', 'zapisVideoOtmenena_1db7'], base.zapisVideoOtmenena_1db7);

  @override
  String get slishkomKorotkoeVideosoobschenie_4676 => _resolve(const ['pc.slishkomKorotkoeVideosoobschenie_4676', 'slishkomKorotkoeVideosoobschenie_4676'], base.slishkomKorotkoeVideosoobschenie_4676);

  @override
  String get pozhaluystaPodozhditeOkonchaniyaZagruzkiFaylov_4c35 => _resolve(const ['pc.pozhaluystaPodozhditeOkonchaniyaZagruzkiFaylov_4c35', 'pozhaluystaPodozhditeOkonchaniyaZagruzkiFaylov_4c35'], base.pozhaluystaPodozhditeOkonchaniyaZagruzkiFaylov_4c35);

  @override
  String get audiozvonok_dcf6 => _resolve(const ['pc.audiozvonok_dcf6', 'audiozvonok_dcf6'], base.audiozvonok_dcf6);

  @override
  String get otpravitFotoVideoAudioIli_37e9 => _resolve(const ['pc.otpravitFotoVideoAudioIli_37e9', 'otpravitFotoVideoAudioIli_37e9'], base.otpravitFotoVideoAudioIli_37e9);

  @override
  String get provedenieGolosovaniyaVChate_a629 => _resolve(const ['pc.provedenieGolosovaniyaVChate_a629', 'provedenieGolosovaniyaVChate_a629'], base.provedenieGolosovaniyaVChate_a629);

  @override
  String get sozdatToDoSpisok_cb50 => _resolve(const ['pc.sozdatToDoSpisok_cb50', 'sozdatToDoSpisok_cb50'], base.sozdatToDoSpisok_cb50);

  @override
  String get spisokZadachSOtmetkamiVypolneniya_c778 => _resolve(const ['pc.spisokZadachSOtmetkamiVypolneniya_c778', 'spisokZadachSOtmetkamiVypolneniya_c778'], base.spisokZadachSOtmetkamiVypolneniya_c778);

  @override
  String get trebuetsyaRazreshenieNaZapisAudio_8175 => _resolve(const ['pc.trebuetsyaRazreshenieNaZapisAudio_8175', 'trebuetsyaRazreshenieNaZapisAudio_8175'], base.trebuetsyaRazreshenieNaZapisAudio_8175);

  @override
  String get slishkomKorotkoeSoobschenie_c2ee => _resolve(const ['pc.slishkomKorotkoeSoobschenie_c2ee', 'slishkomKorotkoeSoobschenie_c2ee'], base.slishkomKorotkoeSoobschenie_c2ee);

  @override
  String get uderzhivayteKnopkuDlyaZapisi_a762 => _resolve(const ['pc.uderzhivayteKnopkuDlyaZapisi_a762', 'uderzhivayteKnopkuDlyaZapisi_a762'], base.uderzhivayteKnopkuDlyaZapisi_a762);

  @override
  String get udalennyy_40c6 => _resolve(const ['pc.udalennyy_40c6', 'udalennyy_40c6'], base.udalennyy_40c6);

  @override
  String get udalennyy_c2c8 => _resolve(const ['pc.udalennyy_c2c8', 'udalennyy_c2c8'], base.udalennyy_c2c8);

  @override
  String get neobhodimyRazresheniyaNaMikrofonI_224b => _resolve(const ['pc.neobhodimyRazresheniyaNaMikrofonI_224b', 'neobhodimyRazresheniyaNaMikrofonI_224b'], base.neobhodimyRazresheniyaNaMikrofonI_224b);

  @override
  String get bylATolkoChto_9ac0 => _resolve(const ['pc.bylATolkoChto_9ac0', 'bylATolkoChto_9ac0'], base.bylATolkoChto_9ac0);

  @override
  String get chatNeNayden_ba4f => _resolve(const ['pc.chatNeNayden_ba4f', 'chatNeNayden_ba4f'], base.chatNeNayden_ba4f);

  @override
  String get napishitePervoeSoobschenie_8260 => _resolve(const ['pc.napishitePervoeSoobschenie_8260', 'napishitePervoeSoobschenie_8260'], base.napishitePervoeSoobschenie_8260);

  @override
  String get prisoedinitsyaKKanalu_f863 => _resolve(const ['pc.prisoedinitsyaKKanalu_f863', 'prisoedinitsyaKKanalu_f863'], base.prisoedinitsyaKKanalu_f863);

  @override
  String get vyPodpisany_5fb9 => _resolve(const ['pc.vyPodpisany_5fb9', 'vyPodpisany_5fb9'], base.vyPodpisany_5fb9);

  @override
  String get otpisatsya_ee2d => _resolve(const ['pc.otpisatsya_ee2d', 'otpisatsya_ee2d'], base.otpisatsya_ee2d);

  @override
  String get vyUspeshnoPodpisalisNaKanal_9c99 => _resolve(const ['pc.vyUspeshnoPodpisalisNaKanal_9c99', 'vyUspeshnoPodpisalisNaKanal_9c99'], base.vyUspeshnoPodpisalisNaKanal_9c99);

  @override
  String get vyUspeshnoVstupiliVGruppu_61a1 => _resolve(const ['pc.vyUspeshnoVstupiliVGruppu_61a1', 'vyUspeshnoVstupiliVGruppu_61a1'], base.vyUspeshnoVstupiliVGruppu_61a1);

  @override
  String get neUdalosPrisoedinitsyaPoprobuyteEsche_bce5 => _resolve(const ['pc.neUdalosPrisoedinitsyaPoprobuyteEsche_bce5', 'neUdalosPrisoedinitsyaPoprobuyteEsche_bce5'], base.neUdalosPrisoedinitsyaPoprobuyteEsche_bce5);

  @override
  String get vyrezat_a195 => _resolve(const ['pc.vyrezat_a195', 'vyrezat_a195'], base.vyrezat_a195);

  @override
  String get kopirovat_112b => _resolve(const ['pc.kopirovat_112b', 'kopirovat_112b'], base.kopirovat_112b);

  @override
  String get vstavit_dcc4 => _resolve(const ['pc.vstavit_dcc4', 'vstavit_dcc4'], base.vstavit_dcc4);

  @override
  String get vybratVse_4d09 => _resolve(const ['pc.vybratVse_4d09', 'vybratVse_4d09'], base.vybratVse_4d09);

  @override
  String get zhirnyy_7774 => _resolve(const ['pc.zhirnyy_7774', 'zhirnyy_7774'], base.zhirnyy_7774);

  @override
  String get kursiv_e0b1 => _resolve(const ['pc.kursiv_e0b1', 'kursiv_e0b1'], base.kursiv_e0b1);

  @override
  String get kod_3f34 => _resolve(const ['pc.kod_3f34', 'kod_3f34'], base.kod_3f34);

  @override
  String get zacherknut_02fc => _resolve(const ['pc.zacherknut_02fc', 'zacherknut_02fc'], base.zacherknut_02fc);

  @override
  String get soobschenie_8b9b => _resolve(const ['pc.soobschenie_8b9b', 'soobschenie_8b9b', 'pc.soobschenie_3715', 'soobschenie_3715'], base.soobschenie_8b9b);

  @override
  String get smahniteDlyaOtmeny_e976 => _resolve(const ['pc.smahniteDlyaOtmeny_e976', 'smahniteDlyaOtmeny_e976'], base.smahniteDlyaOtmeny_e976);

  @override
  String get poisk_bfc9 => _resolve(const ['pc.search', 'search', 'poisk_bfc9', 'pc.poisk_bfc9'], base.poisk_bfc9);

  @override
  String get udalitChat_4b2b => _resolve(const ['pc.udalitChat_4b2b', 'udalitChat_4b2b', 'deleteChat'], base.udalitChat_4b2b);

  @override
  String get udalitKanal_482f => _resolve(const ['pc.udalitKanal_482f', 'udalitKanal_482f'], base.udalitKanal_482f);

  @override
  String get pozhalovatsya_a7d9 => _resolve(const ['pc.pozhalovatsya_a7d9', 'pozhalovatsya_a7d9'], base.pozhalovatsya_a7d9);

  @override
  String get redaktirovatGruppu_e40a => _resolve(const ['pc.redaktirovatGruppu_e40a', 'redaktirovatGruppu_e40a'], base.redaktirovatGruppu_e40a);

  @override
  String get udalitGruppu_dff8 => _resolve(const ['pc.udalitGruppu_dff8', 'udalitGruppu_dff8'], base.udalitGruppu_dff8);

  @override
  String get poiskSoobscheniyVremennoNedostupenV_4443 => _resolve(const ['pc.poiskSoobscheniyVremennoNedostupenV_4443', 'poiskSoobscheniyVremennoNedostupenV_4443'], base.poiskSoobscheniyVremennoNedostupenV_4443);

  @override
  String get zhalobaOtpravlenaModeratoram_4547 => _resolve(const ['pc.zhalobaOtpravlenaModeratoram_4547', 'zhalobaOtpravlenaModeratoram_4547'], base.zhalobaOtpravlenaModeratoram_4547);

  @override
  String get redaktirovanieGruppyVremennoNedostupnoV_05d0 => _resolve(const ['pc.redaktirovanieGruppyVremennoNedostupnoV_05d0', 'redaktirovanieGruppyVremennoNedostupnoV_05d0'], base.redaktirovanieGruppyVremennoNedostupnoV_05d0);

  @override
  String get vyUverenyChtoHotiteOchistit_7c3a => _resolve(const ['pc.vyUverenyChtoHotiteOchistit_7c3a', 'vyUverenyChtoHotiteOchistit_7c3a'], base.vyUverenyChtoHotiteOchistit_7c3a);

  @override
  String get ochistit_7074 => _resolve(const ['pc.ochistit_7074', 'ochistit_7074'], base.ochistit_7074);

  @override
  String get udalit_ed2b => _resolve(const ['pc.delete', 'delete', 'udalit_ed2b', 'pc.udalit_ed2b'], base.udalit_ed2b);

  @override
  String get vyyti_0f05 => _resolve(const ['pc.vyyti_0f05', 'vyyti_0f05'], base.vyyti_0f05);

  @override
  String get oshibkaVosproizvedeniya_ac8a => _resolve(const ['pc.oshibkaVosproizvedeniya_ac8a', 'oshibkaVosproizvedeniya_ac8a'], base.oshibkaVosproizvedeniya_ac8a);

  @override
  String get novoeZashifrovannoeSoobschenie_4d30 => _resolve(const ['pc.novoeZashifrovannoeSoobschenie_4d30', 'novoeZashifrovannoeSoobschenie_4d30'], base.novoeZashifrovannoeSoobschenie_4d30);

  @override
  String get poiskChatov_779c => _resolve(const ['pc.poiskChatov_779c', 'poiskChatov_779c'], base.poiskChatov_779c);

  @override
  String get obnovlenie_53e2 => _resolve(const ['pc.obnovlenie_53e2', 'obnovlenie_53e2'], base.obnovlenie_53e2);

  @override
  String get soedinenie_5a58 => _resolve(const ['pc.soedinenie_5a58', 'soedinenie_5a58'], base.soedinenie_5a58);

  @override
  String get lichnye_4cb3 => _resolve(const ['pc.lichnye_4cb3', 'lichnye_4cb3'], base.lichnye_4cb3);

  @override
  String get neUdalosArhivirovatChatNa_36aa => _resolve(const ['pc.neUdalosArhivirovatChatNa_36aa', 'neUdalosArhivirovatChatNa_36aa'], base.neUdalosArhivirovatChatNa_36aa);

  @override
  String get oshibkaZagruzkiChatov_902f => _resolve(const ['pc.oshibkaZagruzkiChatov_902f', 'oshibkaZagruzkiChatov_902f'], base.oshibkaZagruzkiChatov_902f);

  @override
  String get povtorit_b914 => _resolve(const ['pc.povtorit_b914', 'povtorit_b914'], base.povtorit_b914);

  @override
  String get netChatov_85e3 => _resolve(const ['pc.netChatov_85e3', 'netChatov_85e3'], base.netChatov_85e3);

  @override
  String get nachniteNovyyRazgovor_8290 => _resolve(const ['pc.nachniteNovyyRazgovor_8290', 'nachniteNovyyRazgovor_8290'], base.nachniteNovyyRazgovor_8290);

  @override
  String get neUdalosZagruzitAkkaunty_8570 => _resolve(const ['pc.neUdalosZagruzitAkkaunty_8570', 'neUdalosZagruzitAkkaunty_8570'], base.neUdalosZagruzitAkkaunty_8570);

  @override
  String get vyberiteAkkaunt_79e7 => _resolve(const ['pc.vyberiteAkkaunt_79e7', 'vyberiteAkkaunt_79e7'], base.vyberiteAkkaunt_79e7);

  @override
  String get bystryyVhodNaEtomUstroystve_3f30 => _resolve(const ['pc.bystryyVhodNaEtomUstroystve_3f30', 'bystryyVhodNaEtomUstroystve_3f30'], base.bystryyVhodNaEtomUstroystve_3f30);

  @override
  String get voytiSParolem_9277 => _resolve(const ['pc.voytiSParolem_9277', 'voytiSParolem_9277'], base.voytiSParolem_9277);

  @override
  String get sozdatXaneoId_4033 => _resolve(const ['pc.sozdatXaneoId_4033', 'sozdatXaneoId_4033'], base.sozdatXaneoId_4033);

  @override
  String get netSohranennyhAkkauntov_b669 => _resolve(const ['pc.netSohranennyhAkkauntov_b669', 'netSohranennyhAkkauntov_b669'], base.netSohranennyhAkkauntov_b669);

  @override
  String get tolkoChto_4493 => _resolve(const ['pc.tolkoChto_4493', 'tolkoChto_4493'], base.tolkoChto_4493);

  @override
  String get emailNedostupen_fc3e => _resolve(const ['pc.emailNedostupen_fc3e', 'emailNedostupen_fc3e'], base.emailNedostupen_fc3e);

  @override
  String get nevernyyKod_50f9 => _resolve(const ['pc.nevernyyKod_50f9', 'nevernyyKod_50f9'], base.nevernyyKod_50f9);

  @override
  String get oshibkaProverkiKoda_9018 => _resolve(const ['pc.oshibkaProverkiKoda_9018', 'oshibkaProverkiKoda_9018'], base.oshibkaProverkiKoda_9018);

  @override
  String get neobhodimoRazreshenieNaDostupK_5f5c => _resolve(const ['pc.neobhodimoRazreshenieNaDostupK_5f5c', 'neobhodimoRazreshenieNaDostupK_5f5c'], base.neobhodimoRazreshenieNaDostupK_5f5c);

  @override
  String get oVyboreEmail_2609 => _resolve(const ['pc.oVyboreEmail_2609', 'oVyboreEmail_2609'], base.oVyboreEmail_2609);

  @override
  String get podderzhivayutsyaVseDomenyElektronnoyPochty_a4e0 => _resolve(const ['pc.podderzhivayutsyaVseDomenyElektronnoyPochty_a4e0', 'podderzhivayutsyaVseDomenyElektronnoyPochty_a4e0'], base.podderzhivayutsyaVseDomenyElektronnoyPochty_a4e0);

  @override
  String get zapreschennyh_1f49 => _resolve(const ['pc.zapreschennyh_1f49', 'zapreschennyh_1f49'], base.zapreschennyh_1f49);

  @override
  String get sozdatAkkaunt_19ed => _resolve(const ['pc.sozdatAkkaunt_19ed', 'sozdatAkkaunt_19ed'], base.sozdatAkkaunt_19ed);

  @override
  String get naprimerIvan_d7cb => _resolve(const ['pc.naprimerIvan_d7cb', 'naprimerIvan_d7cb'], base.naprimerIvan_d7cb);

  @override
  String get zadayteParol_53d2 => _resolve(const ['pc.zadayteParol_53d2', 'zadayteParol_53d2'], base.zadayteParol_53d2);

  @override
  String get minimum8Simvolov_4ccd => _resolve(const ['pc.minimum8Simvolov_4ccd', 'minimum8Simvolov_4ccd'], base.minimum8Simvolov_4ccd);

  @override
  String get unikalnoeImyaDlyaVashegoProfilya_a0ea => _resolve(const ['pc.unikalnoeImyaDlyaVashegoProfilya_a0ea', 'unikalnoeImyaDlyaVashegoProfilya_a0ea'], base.unikalnoeImyaDlyaVashegoProfilya_a0ea);

  @override
  String get vashEmail_879d => _resolve(const ['pc.vashEmail_8bbd', 'vashEmail_8bbd', 'vashEmail_879d', 'pc.vashEmail_879d'], base.vashEmail_879d);

  @override
  String get dlyaSvyaziIVosstanovleniyaDostupa_c770 => _resolve(const ['pc.dlyaSvyaziIVosstanovleniyaDostupa_c770', 'dlyaSvyaziIVosstanovleniyaDostupa_c770'], base.dlyaSvyaziIVosstanovleniyaDostupa_c770);

  @override
  String get emailAdres_9130 => _resolve(const ['pc.emailAdres_9130', 'emailAdres_9130'], base.emailAdres_9130);

  @override
  String get vvediteParolEscheRaz_7383 => _resolve(const ['pc.vvediteParolEscheRaz_7383', 'vvediteParolEscheRaz_7383'], base.vvediteParolEscheRaz_7383);

  @override
  String get parolEscheRaz_6daf => _resolve(const ['pc.parolEscheRaz_6daf', 'parolEscheRaz_6daf'], base.parolEscheRaz_6daf);

  @override
  String get paroliNeSovpadayut_d82f => _resolve(const ['pc.paroliNeSovpadayut_d82f', 'paroliNeSovpadayut_d82f'], base.paroliNeSovpadayut_d82f);

  @override
  String get ukazhiteVashuRealnuyuDatuRozhdeniya_d9ed => _resolve(const ['pc.ukazhiteVashuRealnuyuDatuRozhdeniya_d9ed', 'ukazhiteVashuRealnuyuDatuRozhdeniya_d9ed'], base.ukazhiteVashuRealnuyuDatuRozhdeniya_d9ed);

  @override
  String get ddmmgggg_3524 => _resolve(const ['pc.ddmmgggg_3524', 'ddmmgggg_3524', 'pc.pleylist_a04c', 'pc.akkaunty_80b5', 'pleylist_a04c', 'akkaunty_80b5', 'accountsTitle'], base.ddmmgggg_3524);

  @override
  String get sdelayteProfilUznavaemym_f2c5 => _resolve(const ['pc.sdelayteProfilUznavaemym_f2c5', 'sdelayteProfilUznavaemym_f2c5'], base.sdelayteProfilUznavaemym_f2c5);

  @override
  String get profilGotov_b57d => _resolve(const ['pc.profilGotov_b57d', 'profilGotov_b57d'], base.profilGotov_b57d);

  @override
  String get ostalosVsegoParaShagov_37e3 => _resolve(const ['pc.ostalosVsegoParaShagov_37e3', 'ostalosVsegoParaShagov_37e3'], base.ostalosVsegoParaShagov_37e3);

  @override
  String get yaPrinimayuPolzovatelskoeSoglashenie_c431 => _resolve(const ['pc.yaPrinimayuPolzovatelskoeSoglashenie_c431', 'yaPrinimayuPolzovatelskoeSoglashenie_c431'], base.yaPrinimayuPolzovatelskoeSoglashenie_c431);

  @override
  String get yaDayuSoglasieNaObrabotku_0d03 => _resolve(const ['pc.yaDayuSoglasieNaObrabotku_0d03', 'yaDayuSoglasieNaObrabotku_0d03'], base.yaDayuSoglasieNaObrabotku_0d03);

  @override
  String get sVozvrascheniem_77ee => _resolve(const ['pc.sVozvrascheniem_77ee', 'sVozvrascheniem_77ee'], base.sVozvrascheniem_77ee);

  @override
  String get zagruzka_43e4 => _resolve(const ['pc.zagruzka_43e4', 'zagruzka_43e4', 'pc.downloadingLabel', 'downloadingLabel'], base.zagruzka_43e4);

  @override
  String get vyberiteAkkauntDlyaVhoda_d3a6 => _resolve(const ['pc.vyberiteAkkauntDlyaVhoda_d3a6', 'vyberiteAkkauntDlyaVhoda_d3a6'], base.vyberiteAkkauntDlyaVhoda_d3a6);

  @override
  String get vvediteVashNikneym_51a6 => _resolve(const ['pc.vvediteVashNikneym_51a6', 'vvediteVashNikneym_51a6'], base.vvediteVashNikneym_51a6);

  @override
  String get voytiVDrugoyAkkaunt_d10f => _resolve(const ['pc.voytiVDrugoyAkkaunt_d10f', 'voytiVDrugoyAkkaunt_d10f'], base.voytiVDrugoyAkkaunt_d10f);

  @override
  String get nedavnieAkkaunty_953d => _resolve(const ['pc.nedavnieAkkaunty_953d', 'nedavnieAkkaunty_953d'], base.nedavnieAkkaunty_953d);

  @override
  String get dobroPozhalovatVXaneo_66d0 => _resolve(const ['pc.dobroPozhalovatVXaneo_66d0', 'dobroPozhalovatVXaneo_66d0'], base.dobroPozhalovatVXaneo_66d0);

  @override
  String get xaneoTeperIVMobilnom_e918 => _resolve(const ['pc.xaneoTeperIVMobilnom_e918', 'xaneoTeperIVMobilnom_e918'], base.xaneoTeperIVMobilnom_e918);

  @override
  String get mneUzheInteresno_5365 => _resolve(const ['pc.mneUzheInteresno_5365', 'mneUzheInteresno_5365'], base.mneUzheInteresno_5365);

  @override
  String get vseVashiDannyePodZaschitoy_b7d9 => _resolve(const ['pc.vseVashiDannyePodZaschitoy_b7d9', 'vseVashiDannyePodZaschitoy_b7d9'], base.vseVashiDannyePodZaschitoy_b7d9);

  @override
  String get vseSoobscheniyaZaschischenySkvoznymShifrovaniem_443e => _resolve(const ['pc.vseSoobscheniyaZaschischenySkvoznymShifrovaniem_443e', 'vseSoobscheniyaZaschischenySkvoznymShifrovaniem_443e'], base.vseSoobscheniyaZaschischenySkvoznymShifrovaniem_443e);

  @override
  String get prodolzhit_e9c3 => _resolve(const ['pc.prodolzhit_e9c3', 'prodolzhit_e9c3', 'continueBtn'], base.prodolzhit_e9c3);

  @override
  String get lokalnyeDataTsentry_f089 => _resolve(const ['pc.lokalnyeDataTsentry_f089', 'lokalnyeDataTsentry_f089'], base.lokalnyeDataTsentry_f089);

  @override
  String get vashiDannyeNikogdaNePokidayut_f871 => _resolve(const ['pc.vashiDannyeNikogdaNePokidayut_f871', 'vashiDannyeNikogdaNePokidayut_f871'], base.vashiDannyeNikogdaNePokidayut_f871);

  @override
  String get kodOtpravlenPovtorno_e109 => _resolve(const ['pc.kodOtpravlenPovtorno_e109', 'kodOtpravlenPovtorno_e109'], base.kodOtpravlenPovtorno_e109);

  @override
  String get dvuhfaktornayanautentifikatsiya_bacc => _resolve(const ['pc.dvuhfaktornayanautentifikatsiya_bacc', 'dvuhfaktornayanautentifikatsiya_bacc', 'pc.dvuhfaktornayaAutentifikatsiya_acdc', 'dvuhfaktornayaAutentifikatsiya_acdc', 'twoFactorAuth'], base.dvuhfaktornayanautentifikatsiya_bacc);

  @override
  String get naVashEmailOtpravlen6_b457 => _resolve(const ['pc.naVashEmailOtpravlen6_b457', 'naVashEmailOtpravlen6_b457'], base.naVashEmailOtpravlen6_b457);

  @override
  String get podtverdit_e260 => _resolve(const ['pc.podtverdit_e260', 'podtverdit_e260'], base.podtverdit_e260);

  @override
  String get nePoluchiliKodOtpravitPovtorno_c1d2 => _resolve(const ['pc.nePoluchiliKodOtpravitPovtorno_c1d2', 'nePoluchiliKodOtpravitPovtorno_c1d2'], base.nePoluchiliKodOtpravitPovtorno_c1d2);

  @override
  String get imyaNikneymOSebe_7a8d => _resolve(const ['pc.imyaNikneymOSebe_7a8d', 'imyaNikneymOSebe_7a8d'], base.imyaNikneymOSebe_7a8d);

  @override
  String get zvonkiSoobscheniyaVidimostProfilya_f905 => _resolve(const ['pc.zvonkiSoobscheniyaVidimostProfilya_f905', 'zvonkiSoobscheniyaVidimostProfilya_f905'], base.zvonkiSoobscheniyaVidimostProfilya_f905);

  @override
  String get parolSessii2fa_de9e => _resolve(const ['pc.parolSessii2fa_de9e', 'parolSessii2fa_de9e'], base.parolSessii2fa_de9e);

  @override
  String get prilozhenie_38aa => _resolve(const ['pc.prilozhenie_38aa', 'prilozhenie_38aa', 'pc.obnovlenie_7e32', 'pc.vneshniyVid_5a0f', 'obnovlenie_7e32', 'vneshniyVid_5a0f'], base.prilozhenie_38aa);

  @override
  String get temaRazmerTekstaAnimatsii_f0a8 => _resolve(const ['pc.temaRazmerTekstaAnimatsii_f0a8', 'temaRazmerTekstaAnimatsii_f0a8'], base.temaRazmerTekstaAnimatsii_f0a8);

  @override
  String get pushUvedomleniyaZvuki_9cc2 => _resolve(const ['pc.pushUvedomleniyaZvuki_9cc2', 'pushUvedomleniyaZvuki_9cc2'], base.pushUvedomleniyaZvuki_9cc2);

  @override
  String get oPrilozhenii_77b2 => _resolve(const ['pc.oPrilozhenii_77b2', 'oPrilozhenii_77b2', 'pc.privatnost_3098', 'privatnost_3098'], base.oPrilozhenii_77b2);

  @override
  String get versiya200Build200_0e7b => _resolve(const ['pc.versiya200Build200_0e7b', 'versiya200Build200_0e7b'], base.versiya200Build200_0e7b);

  @override
  String get redaktirovatProfil_56ad => _resolve(const ['pc.redaktirovatProfil_56ad', 'redaktirovatProfil_56ad'], base.redaktirovatProfil_56ad);

  @override
  String get dobavitKontakt_2903 => _resolve(const ['pc.dobavitKontakt_2903', 'dobavitKontakt_2903', 'pc.globalnyyPoisk_77bf', 'globalnyyPoisk_77bf'], base.dobavitKontakt_2903);

  @override
  String get nikneymPolzovatelyaUsername_a6ff => _resolve(const ['pc.nikneymPolzovatelyaUsername_a6ff', 'nikneymPolzovatelyaUsername_a6ff'], base.nikneymPolzovatelyaUsername_a6ff);

  @override
  String get otobrazhaemoeImyaNeobyazatelno_340a => _resolve(const ['pc.otobrazhaemoeImyaNeobyazatelno_340a', 'otobrazhaemoeImyaNeobyazatelno_340a'], base.otobrazhaemoeImyaNeobyazatelno_340a);

  @override
  String get neUdalosNaytiIliDobavit_649f => _resolve(const ['pc.neUdalosNaytiIliDobavit_649f', 'neUdalosNaytiIliDobavit_649f'], base.neUdalosNaytiIliDobavit_649f);

  @override
  String get ya_feef => _resolve(const ['pc.ya_feef', 'ya_feef', 'pc.a_87a0', 'pc.b_3b67', 'a_87a0', 'b_3b67'], base.ya_feef);

  @override
  String get poiskKontaktov_9a71 => _resolve(const ['pc.poiskKontaktov_9a71', 'poiskKontaktov_9a71'], base.poiskKontaktov_9a71);

  @override
  String get spisokKontaktovPust_58c6 => _resolve(const ['pc.spisokKontaktovPust_58c6', 'spisokKontaktovPust_58c6'], base.spisokKontaktovPust_58c6);

  @override
  String get kontaktyNeNaydeny_1b08 => _resolve(const ['pc.kontaktyNeNaydeny_1b08', 'kontaktyNeNaydeny_1b08'], base.kontaktyNeNaydeny_1b08);

  @override
  String get messages => _resolve(const ['messenger.energy.chatAnimations', 'messenger.chats', 'pc.soobscheniya_7e26', 'soobscheniya_7e26', 'messages', 'pc.messages'], base.messages);

  @override
  String get messageAnimations => _resolve(const ['messenger.energy.messageAnimationsTitle', 'pc.animatsiiSoobscheniy_bc8b', 'animatsiiSoobscheniy_bc8b', 'messageAnimations', 'pc.messageAnimations'], base.messageAnimations);

  @override
  String get messageAnimationsDesc => _resolve(const ['messenger.energy.messageAnimationsDesc', 'pc.pokazyvatAnimatsiiPriOtpravkeI_d663', 'pokazyvatAnimatsiiPriOtpravkeI_d663', 'messageAnimationsDesc', 'pc.messageAnimationsDesc'], base.messageAnimationsDesc);

  @override
  String get archivedChats => _resolve(const ['messenger.context.archiveChat', 'messenger.archivedChats', 'messenger.context.archive', 'pc.arhivirovannyeChaty_d990', 'arhivirovannyeChaty_d990', 'archivedChats', 'pc.archivedChats'], base.archivedChats);

  @override
  String get archiveManagement => _resolve(const ['messenger.archiveManagement', 'pc.upravlenieArhivom_e843', 'upravlenieArhivom_e843', 'archiveManagement', 'pc.archiveManagement'], base.archiveManagement);

  @override
  String get clearHistory => _resolve(const ['messenger.context.clearHistory', 'messenger.delete.clearHistoryTitle', 'pc.ochistitIstoriyu_837a', 'ochistitIstoriyu_837a', 'clearHistory', 'pc.clearHistory'], base.clearHistory);

  @override
  String get clearHistoryDesc => _resolve(const ['messenger.delete.clearHistoryWarning', 'messenger.delete.clearHistoryMessage', 'pc.udalitVseSoobscheniyaLokalno_fbbd', 'udalitVseSoobscheniyaLokalno_fbbd', 'clearHistoryDesc', 'pc.clearHistoryDesc'], base.clearHistoryDesc);

  @override
  String get call => _resolve(const ['pc.pozvonit_ccfa', 'pozvonit_ccfa', 'call', 'pc.call'], base.call);

  @override
  String get sendMessage => _resolve(const ['pc.napisat_0144', 'napisat_0144', 'sendMessage', 'pc.sendMessage'], base.sendMessage);

  @override
  String get deleteContact => _resolve(const ['pc.udalitKontakt_065d', 'udalitKontakt_065d', 'deleteContact', 'pc.deleteContact'], base.deleteContact);

  @override
  String get activeSessions => _resolve(const ['pc.aktivnyeSessii_5c96', 'aktivnyeSessii_5c96', 'activeSessions', 'pc.activeSessions'], base.activeSessions);

  @override
  String get thisDevice => _resolve(const ['pc.etoUstroystvo_26f6', 'etoUstroystvo_26f6', 'thisDevice', 'pc.thisDevice'], base.thisDevice);

  @override
  String get xaneoPcActiveNow => _resolve(const ['pc.xaneoPcAktivnoSeychas_25b4', 'xaneoPcAktivnoSeychas_25b4', 'xaneoPcActiveNow', 'pc.xaneoPcActiveNow'], base.xaneoPcActiveNow);

  @override
  String get activeNow => _resolve(const ['pc.aktivno_87a4', 'aktivno_87a4', 'activeNow', 'pc.activeNow'], base.activeNow);

  @override
  String get twoFactorAuth => _resolve(const ['pc.dvuhfaktornayaAutentifikatsiya_acdc', 'dvuhfaktornayaAutentifikatsiya_acdc', 'twoFactorAuth', 'pc.dvuhfaktornayanautentifikatsiya_bacc', 'dvuhfaktornayanautentifikatsiya_bacc', 'pc.twoFactorAuth'], base.twoFactorAuth);

  @override
  String get twoFactorAuthDesc => _resolve(const ['pc.zaschitaAkkauntaOdnorazovymParolem_e9f1', 'zaschitaAkkauntaOdnorazovymParolem_e9f1', 'twoFactorAuthDesc', 'pc.twoFactorAuthDesc'], base.twoFactorAuthDesc);

  @override
  String get dangerZone => _resolve(const ['pc.opasnayaZona_25bc', 'opasnayaZona_25bc', 'dangerZone', 'pc.dangerZone'], base.dangerZone);

  @override
  String get deleteAccount => _resolve(const ['pc.udalitAkkaunt_05c7', 'udalitAkkaunt_05c7', 'deleteAccount', 'pc.deleteAccount'], base.deleteAccount);

  @override
  String get irreversibleAction => _resolve(const ['pc.neobratimoeDeystvie_7232', 'neobratimoeDeystvie_7232', 'irreversibleAction', 'pc.irreversibleAction'], base.irreversibleAction);

  @override
  String get theme => _resolve(const ['messenger.chatSettings.appearance', 'common.theme', 'pc.tema_9e26', 'tema_9e26', 'theme', 'pc.theme'], base.theme);

  @override
  String get darkThemeDesc => _resolve(const ['messenger.chatSettings.appearance', 'pc.darkThemeDesc', 'darkThemeDesc'], base.darkThemeDesc);

  @override
  String get fontSizeText => _resolve(const ['messenger.chatSettings.textSize', 'pc.razmerShrifta_1155', 'razmerShrifta_1155', 'fontSizeText', 'pc.fontSizeText'], base.fontSizeText);

  @override
  String get showPopups => _resolve(const ['pc.pokazyvatVsplyvayuschieUvedomleniya_754e', 'pokazyvatVsplyvayuschieUvedomleniya_754e', 'showPopups', 'pc.showPopups'], base.showPopups);

  @override
  String get sound => _resolve(const ['pc.zvuk_9329', 'zvuk_9329', 'sound', 'pc.sound'], base.sound);

  @override
  String get soundDesc => _resolve(const ['pc.vosproizvoditZvukPriNovomSoobschenii_47cc', 'vosproizvoditZvukPriNovomSoobschenii_47cc', 'soundDesc', 'pc.soundDesc'], base.soundDesc);

  @override
  String get mainSettings => _resolve(const ['messenger.settings.title', 'header.settings', 'settings.title', 'pc.osnovnyeNastroyki_231c', 'osnovnyeNastroyki_231c', 'mainSettings', 'pc.mainSettings'], base.mainSettings);

  @override
  String get energySavingMode => _resolve(const ['messenger.energy.lowPowerTitle', 'pc.rezhimEkonomiiEnergii_edfc', 'rezhimEkonomiiEnergii_edfc', 'energySavingMode', 'pc.energySavingMode'], base.energySavingMode);

  @override
  String get energySavingModeDesc => _resolve(const ['messenger.energy.lowPowerDesc', 'pc.energySavingModeDesc', 'energySavingModeDesc'], base.energySavingModeDesc);

  @override
  String get autoSleep => _resolve(const ['messenger.energy.autoSleepTitle', 'pc.avtomaticheskiySpyaschiyRezhim_5955', 'avtomaticheskiySpyaschiyRezhim_5955', 'autoSleep', 'pc.autoSleep'], base.autoSleep);

  @override
  String get autoSleepDesc => _resolve(const ['messenger.energy.autoSleepDesc', 'pc.perevoditPrilozhenieVSpyaschiyRezhim_1c07', 'perevoditPrilozhenieVSpyaschiyRezhim_1c07', 'autoSleepDesc', 'pc.autoSleepDesc'], base.autoSleepDesc);

  @override
  String get animations => _resolve(const ['messenger.energy.chatAnimations', 'pc.animatsii_05c7', 'animatsii_05c7', 'animations', 'pc.animations'], base.animations);

  @override
  String get reducedMotion => _resolve(const ['messenger.energy.reducedAnimationsTitle', 'pc.uproschennyeAnimatsii_3a13', 'uproschennyeAnimatsii_3a13', 'reducedMotion', 'pc.reducedMotion'], base.reducedMotion);

  @override
  String get reducedMotionDesc => _resolve(const ['messenger.energy.reducedAnimationsDesc', 'pc.umenshaetKolichestvoAnimatsiyInterfeysa_6bf1', 'umenshaetKolichestvoAnimatsiyInterfeysa_6bf1', 'reducedMotionDesc', 'pc.reducedMotionDesc'], base.reducedMotionDesc);

  @override
  String get comingSoon => _resolve(const ['pc.skoroBudetDostupno_de07', 'skoroBudetDostupno_de07', 'comingSoon', 'pc.comingSoon'], base.comingSoon);

  @override
  String get updateAvailable => _resolve(const ['pc.updateAvailable', 'updateAvailable'], base.updateAvailable);

  @override
  String get clickToViewChanges => _resolve(const ['pc.nazhmiteDlyaProsmotraIzmeneniy_0255', 'nazhmiteDlyaProsmotraIzmeneniy_0255', 'clickToViewChanges', 'pc.clickToViewChanges'], base.clickToViewChanges);

  @override
  String get newVersionAvailable => _resolve(const ['pc.dostupnaNovayaVersiyaPrilozheniya_eeae', 'dostupnaNovayaVersiyaPrilozheniya_eeae', 'newVersionAvailable', 'pc.newVersionAvailable'], base.newVersionAvailable);

  @override
  String get newVersionAvailableTitle => _resolve(const ['header.newVersionAvailable', 'pc.newVersionAvailableTitle', 'newVersionAvailableTitle'], base.newVersionAvailableTitle);

  @override
  String get youHaveLatestVersion => _resolve(const ['header.latestVersion', 'pc.youHaveLatestVersion', 'youHaveLatestVersion'], base.youHaveLatestVersion);

  @override
  String get whatsNew => _resolve(const ['pc.whatsNew', 'whatsNew'], base.whatsNew);

  @override
  String get officialReleaseNotes => _resolve(const ['pc.officialReleaseNotes', 'officialReleaseNotes'], base.officialReleaseNotes);

  @override
  String get preparingDownload => _resolve(const ['pc.podgotovkaKZagruzke_a5c7', 'podgotovkaKZagruzke_a5c7', 'preparingDownload', 'pc.preparingDownload'], base.preparingDownload);

  @override
  String get installationStarted => _resolve(const ['pc.installationStarted', 'installationStarted', 'pc.ustanovkaZapuschena_d378', 'ustanovkaZapuschena_d378'], base.installationStarted);

  @override
  String get whoSeesAvatar => _resolve(const ['messenger.privacy.whoSeesAvatar', 'pc.ktoViditMoyAvatar_e9f6', 'ktoViditMoyAvatar_e9f6', 'whoSeesAvatar', 'pc.whoSeesAvatar'], base.whoSeesAvatar);

  @override
  String get whoSeesBirthday => _resolve(const ['messenger.privacy.whoSeesBirthday', 'pc.ktoViditMoyDenRozhdeniya_ccc7', 'ktoViditMoyDenRozhdeniya_ccc7', 'whoSeesBirthday', 'pc.whoSeesBirthday'], base.whoSeesBirthday);

  @override
  String get whoSeesOnlineTime => _resolve(const ['messenger.privacy.whoSeesOnlineTime', 'pc.ktoViditVremyaMoeyAktivnosti_4349', 'ktoViditVremyaMoeyAktivnosti_4349', 'whoSeesOnlineTime', 'pc.whoSeesOnlineTime'], base.whoSeesOnlineTime);

  @override
  String get downloadVersion => _resolve(const ['pc.downloadVersion', 'downloadVersion'], base.downloadVersion);

  @override
  String get downloadSource => _resolve(const ['pc.downloadSource', 'downloadSource'], base.downloadSource);

  @override
  String get directInAppInstall => _resolve(const ['pc.pryamayaUstanovkaVPrilozhenii_16f5', 'pryamayaUstanovkaVPrilozhenii_16f5', 'directInAppInstall', 'pc.directInAppInstall'], base.directInAppInstall);

  @override
  String get autoDownloadAndRun => _resolve(const ['pc.avtomaticheskoeSkachivanieIZapusk_9a3f', 'avtomaticheskoeSkachivanieIZapusk_9a3f', 'autoDownloadAndRun', 'pc.autoDownloadAndRun'], base.autoDownloadAndRun);

  @override
  String get githubReleasePage => _resolve(const ['pc.stranitsaRelizaNaGithub_1531', 'stranitsaRelizaNaGithub_1531', 'githubReleasePage', 'pc.githubReleasePage'], base.githubReleasePage);

  @override
  String get skip => _resolve(const ['pc.propustit_03ee', 'propustit_03ee', 'skip', 'pc.skip'], base.skip);

  @override
  String get updateAction => _resolve(const ['pc.obnovit_dbe5', 'obnovit_dbe5', 'updateAction', 'pc.updateAction'], base.updateAction);

  @override
  String get installAction => _resolve(const ['pc.ustanovka_516d', 'ustanovka_516d', 'installAction', 'pc.installAction'], base.installAction);

  @override
  String get isTyping => _resolve(const ['messenger.status.typing', 'pc.pechataet_812c', 'pechataet_812c', 'isTyping', 'pc.isTyping'], base.isTyping);

  @override
  String get isRecordingVoice => _resolve(const ['messenger.status.recordingVoice', 'pc.zapisyvaetGolosovoe_2a5c', 'zapisyvaetGolosovoe_2a5c', 'isRecordingVoice', 'pc.isRecordingVoice'], base.isRecordingVoice);

  @override
  String get areTyping => _resolve(const ['pc.areTyping', 'areTyping'], base.areTyping);

  @override
  String get group => _resolve(const ['messenger.chatInfo.groupTitle', 'messenger.createGroup.title', 'messenger.chat.group', 'common.group', 'pc.gruppa_99d9', 'gruppa_99d9', 'group', 'pc.group'], base.group);

  @override
  String get channel => _resolve(const ['messenger.chatInfo.channelTitle', 'messenger.createChannel.title', 'messenger.chat.channel', 'common.channel', 'pc.kanal_2710', 'kanal_2710', 'channel', 'pc.channel'], base.channel);

  @override
  String get profile => _resolve(const ['header.profile', 'profile.title', 'pc.profile', 'profile'], base.profile);

  @override
  String get copied => _resolve(const ['common.copied', 'messenger.copied', 'pc.skopirovano_f70b', 'skopirovano_f70b', 'copied', 'pc.copied'], base.copied);

  @override
  String get userHidInfo => _resolve(const ['pc.polzovatelSkrylInformatsiyuOSebe_f416', 'polzovatelSkrylInformatsiyuOSebe_f416', 'userHidInfo', 'pc.userHidInfo'], base.userHidInfo);

  @override
  String get leaveGroup => _resolve(const ['pc.pokinutGruppu_e6ce', 'pokinutGruppu_e6ce', 'leaveGroup', 'pc.leaveGroup'], base.leaveGroup);

  @override
  String get joinGroup => _resolve(const ['messenger.chat.joinGroup', 'pc.prisoedinitsyaKGruppe_eb45', 'prisoedinitsyaKGruppe_eb45', 'joinGroup', 'pc.joinGroup'], base.joinGroup);

  @override
  String get unsubscribeChannel => _resolve(const ['messenger.chat.unsubscribeChannel', 'pc.otpisatsyaOtKanala_fdbc', 'otpisatsyaOtKanala_fdbc', 'unsubscribeChannel', 'pc.unsubscribeChannel'], base.unsubscribeChannel);

  @override
  String get subscribeChannel => _resolve(const ['messenger.chat.subscribeChannel', 'pc.podpisatsyaNaKanal_2dad', 'podpisatsyaNaKanal_2dad', 'subscribeChannel', 'pc.subscribeChannel'], base.subscribeChannel);

  @override
  String get deleteChat => _resolve(const ['messenger.context.deleteChat', 'messenger.delete.deleteChatTitle', 'messenger.chat.delete', 'messenger.delete', 'pc.udalitChat_4b2b', 'udalitChat_4b2b', 'deleteChat', 'pc.deleteChat'], base.deleteChat);

  @override
  String get pinChat => _resolve(const ['messenger.chat.pin', 'messenger.pin', 'messenger.pinned.title', 'pc.pin', 'pin', 'pinChat', 'pc.pinChat'], base.pinChat);

  @override
  String get unpinChat => _resolve(const ['messenger.chat.unpin', 'messenger.unpin', 'messenger.pinned.unpin', 'pc.unpin', 'unpin', 'unpinChat', 'pc.unpinChat'], base.unpinChat);

  @override
  String get muteNotifications => _resolve(const ['messenger.chat.mute', 'messenger.mute', 'pc.muteNotifications', 'muteNotifications'], base.muteNotifications);

  @override
  String get unmuteNotifications => _resolve(const ['messenger.chat.unmute', 'messenger.unmute', 'pc.vklyuchitUvedomleniya_d311', 'vklyuchitUvedomleniya_d311', 'unmuteNotifications', 'pc.unmuteNotifications'], base.unmuteNotifications);

  @override
  String get backToChats => _resolve(const ['pc.nazadKChatam_7edb', 'nazadKChatam_7edb', 'backToChats', 'pc.backToChats'], base.backToChats);

  @override
  String get globalSearch => _resolve(const ['pc.globalnyyPoisk_7ff2', 'globalnyyPoisk_7ff2', 'globalSearch', 'pc.globalSearch'], base.globalSearch);

  @override
  String get chatSettings => _resolve(const ['pc.nastroykiChata_1e0d', 'nastroykiChata_1e0d', 'chatSettings', 'pc.chatSettings'], base.chatSettings);

  @override
  String get emoji => _resolve(const ['pc.emodzi_f822', 'emodzi_f822', 'emoji', 'pc.emoji'], base.emoji);

  @override
  String get attachFile => _resolve(const ['pc.attachFile', 'attachFile'], base.attachFile);

  @override
  String get startCall => _resolve(const ['messenger.callType.title', 'messenger.calls.start', 'messenger.calls.audio', 'messenger.calls.startCall', 'pc.startCall', 'startCall'], base.startCall);

  @override
  String get audioCall => _resolve(const ['messenger.callType.audio', 'messenger.calls.audio', 'messenger.calls.audioCall', 'pc.golosovoyZvonok_b615', 'golosovoyZvonok_b615', 'audioCall', 'pc.golosovoyZvonok_5410', 'golosovoyZvonok_5410', 'pc.audioCall'], base.audioCall);

  @override
  String get audioCallDesc => _resolve(const ['messenger.callType.audioDesc', 'messenger.createGroup.callsDescription', 'pc.pozvonitPoGolosovoySvyazi_4069', 'pozvonitPoGolosovoySvyazi_4069', 'audioCallDesc', 'pc.audioCallDesc'], base.audioCallDesc);

  @override
  String get videoCall => _resolve(const ['messenger.callType.video', 'messenger.calls.video', 'messenger.calls.videoCall', 'pc.videozvonok_8142', 'videozvonok_8142', 'videoCall', 'pc.videozvonok_dd18', 'videozvonok_dd18', 'pc.videoCall'], base.videoCall);

  @override
  String get videoCallDesc => _resolve(const ['messenger.callType.videoDesc', 'pc.pozvonitSVklyuchennoyKameroy_fb05', 'pozvonitSVklyuchennoyKameroy_fb05', 'videoCallDesc', 'pc.videoCallDesc'], base.videoCallDesc);

  @override
  String get voiceRecordTitle => _resolve(const ['pc.zapisGolosovogoGs_db4e', 'zapisGolosovogoGs_db4e', 'voiceRecordTitle', 'pc.voiceRecordTitle'], base.voiceRecordTitle);

  @override
  String get videoRecordTitle => _resolve(const ['pc.videoRecordTitle', 'videoRecordTitle'], base.videoRecordTitle);

  @override
  String get holdToRecordHint => _resolve(const ['pc.holdToRecordHint', 'holdToRecordHint'], base.holdToRecordHint);

  @override
  String get addAttachment => _resolve(const ['messenger.attach.file', 'messenger.attach.uploadFile', 'pc.dobavitVlozhenie_769b', 'dobavitVlozhenie_769b', 'addAttachment', 'pc.addAttachment'], base.addAttachment);

  @override
  String get emojiPanelInDev => _resolve(const ['pc.panelEmodziVRazrabotke_b6ce', 'panelEmodziVRazrabotke_b6ce', 'emojiPanelInDev', 'pc.emojiPanelInDev'], base.emojiPanelInDev);

  @override
  String get recordingVoice => _resolve(const ['pc.zapisGolosovogo_9c91', 'zapisGolosovogo_9c91', 'recordingVoice', 'pc.recordingVoice'], base.recordingVoice);

  @override
  String get recordingVideo => _resolve(const ['pc.zapisVideo_dd2a', 'zapisVideo_dd2a', 'recordingVideo', 'pc.recordingVideo'], base.recordingVideo);

  @override
  String get releaseToSend => _resolve(const ['pc.otpustiteDlyaOtpravki_ea7b', 'otpustiteDlyaOtpravki_ea7b', 'releaseToSend', 'pc.releaseToSend'], base.releaseToSend);

  @override
  String get typeMessage => _resolve(const ['messenger.input.message', 'messenger.typeMessage', 'messenger.messageInputPlaceholder', 'pc.napisatSoobschenie_62d4', 'napisatSoobschenie_62d4', 'typeMessage', 'pc.typeMessage'], base.typeMessage);

  @override
  String get file => _resolve(const ['messenger.attach.uploadFile', 'messenger.attach.file', 'common.file', 'pc.fayl_2d46', 'fayl_2d46', 'file', 'pc.file'], base.file);

  @override
  String get todoList => _resolve(const ['messenger.attach.todoList', 'messenger.attach.todoListTitle', 'messenger.todoModal.title', 'pc.spisokZadach_1852', 'spisokZadach_1852', 'todoList', 'pc.todoList'], base.todoList);

  @override
  String get poll => _resolve(const ['messenger.attach.pollShort', 'messenger.attach.poll', 'messenger.pollModal.title', 'pc.opros_9f36', 'opros_9f36', 'poll', 'pc.poll'], base.poll);

  @override
  String get today => _resolve(const ['common.today', 'messenger.today', 'pc.segodnya_9626', 'segodnya_9626', 'today', 'pc.today'], base.today);

  @override
  String get yesterday => _resolve(const ['common.yesterday', 'messenger.yesterday', 'pc.vchera_61d4', 'vchera_61d4', 'yesterday', 'pc.yesterday'], base.yesterday);

  @override
  String get monthJan => _resolve(const ['pc.yanvarya_d861', 'yanvarya_d861', 'monthJan', 'pc.monthJan'], base.monthJan);

  @override
  String get monthFeb => _resolve(const ['pc.fevralya_fcf9', 'fevralya_fcf9', 'monthFeb', 'pc.monthFeb'], base.monthFeb);

  @override
  String get monthMar => _resolve(const ['pc.marta_bb77', 'marta_bb77', 'monthMar', 'pc.monthMar'], base.monthMar);

  @override
  String get monthApr => _resolve(const ['pc.aprelya_2b5a', 'aprelya_2b5a', 'monthApr', 'pc.aprel_03e9', 'aprel_03e9', 'pc.monthApr'], base.monthApr);

  @override
  String get monthMay => _resolve(const ['pc.maya_4dbb', 'maya_4dbb', 'monthMay', 'pc.monthMay'], base.monthMay);

  @override
  String get monthJun => _resolve(const ['pc.iyunya_adcb', 'iyunya_adcb', 'monthJun', 'pc.iyun_cfcb', 'iyun_cfcb', 'pc.monthJun'], base.monthJun);

  @override
  String get monthJul => _resolve(const ['pc.iyulya_3236', 'iyulya_3236', 'monthJul', 'pc.iyul_89fb', 'iyul_89fb', 'pc.monthJul'], base.monthJul);

  @override
  String get monthAug => _resolve(const ['pc.avgusta_e3aa', 'avgusta_e3aa', 'monthAug', 'pc.monthAug'], base.monthAug);

  @override
  String get monthSep => _resolve(const ['pc.sentyabrya_a146', 'sentyabrya_a146', 'monthSep', 'pc.monthSep'], base.monthSep);

  @override
  String get monthOct => _resolve(const ['pc.oktyabrya_7abd', 'oktyabrya_7abd', 'monthOct', 'pc.monthOct'], base.monthOct);

  @override
  String get monthNov => _resolve(const ['pc.noyabrya_6e78', 'noyabrya_6e78', 'monthNov', 'pc.monthNov'], base.monthNov);

  @override
  String get monthDec => _resolve(const ['pc.dekabrya_29cc', 'dekabrya_29cc', 'monthDec', 'pc.dekabr_39b3', 'dekabr_39b3', 'pc.monthDec'], base.monthDec);

  @override
  String get createTodo => _resolve(const ['messenger.todoModal.title', 'pc.sozdatToDo_8c92', 'sozdatToDo_8c92', 'createTodo', 'pc.createTodo'], base.createTodo);

  @override
  String get listName => _resolve(const ['messenger.todoModal.listNameLabel', 'pc.nazvanieSpiska_c3cc', 'nazvanieSpiska_c3cc', 'listName', 'pc.listName'], base.listName);

  @override
  String get todoItems => _resolve(const ['messenger.todoModal.itemsLabel', 'pc.todoItems', 'todoItems', 'pc.punkty_0481', 'punkty_0481'], base.todoItems);

  @override
  String get addTodoItem => _resolve(const ['messenger.todoModal.addItem', 'pc.addTodoItem', 'addTodoItem', 'pc.dobavitPunkt_930c', 'dobavitPunkt_930c'], base.addTodoItem);

  @override
  String get itemHintPrefix => _resolve(const ['pc.itemHintPrefix', 'itemHintPrefix'], base.itemHintPrefix);

  @override
  String get createPoll => _resolve(const ['messenger.pollModal.title', 'pc.sozdatOpros_4b9e', 'sozdatOpros_4b9e', 'createPoll', 'pc.polzovateli_e0ec', 'pc.spisokMuzyki_d477', 'pc.nachatZvonok_3d26', 'pc.lichnyeDannye_10a7', 'pc.kommunikatsii_e9b8', 'pc.bezopasnost_fcbc', 'polzovateli_e0ec', 'spisokMuzyki_d477', 'nachatZvonok_3d26', 'lichnyeDannye_10a7', 'kommunikatsii_e9b8', 'bezopasnost_fcbc', 'pc.createPoll'], base.createPoll);

  @override
  String get pollQuestion => _resolve(const ['messenger.pollModal.questionLabel', 'pc.vopros_0911', 'vopros_0911', 'pollQuestion', 'pc.pollQuestion'], base.pollQuestion);

  @override
  String get pollOptions => _resolve(const ['messenger.pollModal.optionsLabel', 'pc.pollOptions', 'pollOptions', 'pc.variantyOtveta_ef4e', 'variantyOtveta_ef4e'], base.pollOptions);

  @override
  String get addPollOption => _resolve(const ['messenger.pollModal.addOption', 'pc.addPollOption', 'addPollOption', 'pc.dobavitVariant_76be', 'dobavitVariant_76be'], base.addPollOption);

  @override
  String get optionHintPrefix => _resolve(const ['pc.optionHintPrefix', 'optionHintPrefix'], base.optionHintPrefix);

  @override
  String get allowMultipleAnswers => _resolve(const ['pc.allowMultipleAnswers', 'allowMultipleAnswers'], base.allowMultipleAnswers);

  @override
  String get singleChoice => _resolve(const ['pc.odinochnyyVybor_d920', 'odinochnyyVybor_d920', 'singleChoice', 'pc.singleChoice'], base.singleChoice);

  @override
  String get accountsTitle => _resolve(const ['pc.akkaunty_80b5', 'akkaunty_80b5', 'accountsTitle', 'pc.pleylist_a04c', 'pc.ddmmgggg_3524', 'pleylist_a04c', 'ddmmgggg_3524', 'pc.accountsTitle'], base.accountsTitle);

  @override
  String get addAccount => _resolve(const ['pc.dobavitAkkaunt_5253', 'dobavitAkkaunt_5253', 'addAccount', 'pc.addAccount'], base.addAccount);

  @override
  String get accountLimitNotice => _resolve(const ['pc.accountLimitNotice', 'accountLimitNotice', 'pc.limit5Akkauntov_fdb7', 'limit5Akkauntov_fdb7'], base.accountLimitNotice);

  @override
  String get media => _resolve(const ['messenger.chatInfo.media', 'common.media', 'pc.media_c247', 'media_c247', 'media', 'pc.media'], base.media);

  @override
  String get files => _resolve(const ['messenger.chatInfo.files', 'common.files', 'pc.fayly_200c', 'fayly_200c', 'files', 'pc.files'], base.files);

  @override
  String get voice => _resolve(const ['profile.access.voice', 'common.voice', 'pc.voice', 'voice'], base.voice);

  @override
  String get links => _resolve(const ['messenger.chatInfo.links', 'common.links', 'pc.ssylki_9f58', 'ssylki_9f58', 'links', 'pc.links'], base.links);

  @override
  String get bio => _resolve(const ['profile.profile.displayName', 'pc.aboutMe', 'aboutMe', 'oSebe_0b3b', 'bio', 'pc.bio'], base.bio);

  @override
  String get username => _resolve(const ['profile.profile.username', 'pc.imyaPolzovatelya_6fd4', 'imyaPolzovatelya_6fd4', 'username', 'pc.username'], base.username);

  @override
  String get birthday => _resolve(const ['profile.profile.birthdate', 'pc.denRozhdeniya_e41d', 'denRozhdeniya_e41d', 'birthday', 'pc.birthday'], base.birthday);

  @override
  String get noSharedMedia => _resolve(const ['pc.netMediafaylov_08d2', 'netMediafaylov_08d2', 'noSharedMedia', 'pc.noSharedMedia'], base.noSharedMedia);

  @override
  String get noSharedFiles => _resolve(const ['pc.netFaylov_e95e', 'netFaylov_e95e', 'noSharedFiles', 'pc.noSharedFiles'], base.noSharedFiles);

  @override
  String get noSharedVoice => _resolve(const ['pc.netGolosovyhSoobscheniy_2427', 'netGolosovyhSoobscheniy_2427', 'noSharedVoice', 'pc.noSharedVoice'], base.noSharedVoice);

  @override
  String get noSharedLinks => _resolve(const ['pc.netSsylok_b0ec', 'netSsylok_b0ec', 'noSharedLinks', 'pc.noSharedLinks'], base.noSharedLinks);

  @override
  String get savedMessagesDesc => _resolve(const ['messenger.favorites.emptyDesc', 'messenger.savedMessages.desc', 'messenger.favorites.desc', 'pc.savedMessagesDesc', 'savedMessagesDesc'], base.savedMessagesDesc);

  @override
  String get music => _resolve(const ['pc.muzyka_0660', 'muzyka_0660', 'music', 'pc.music'], base.music);

  @override
  String get noSharedMusic => _resolve(const ['pc.noSharedMusic', 'noSharedMusic'], base.noSharedMusic);

  @override
  String get secureDesktopCommunicator => _resolve(const ['pc.secureDesktopCommunicator', 'secureDesktopCommunicator'], base.secureDesktopCommunicator);

  @override
  String get noMessagesTitle => _resolve(const ['messenger.empty.noMessages', 'pc.netSoobscheniy_29d4', 'netSoobscheniy_29d4', 'noMessagesTitle', 'pc.noMessagesTitle'], base.noMessagesTitle);

  @override
  String get noMessagesSubtitle => _resolve(const ['messenger.empty.startNow', 'pc.noMessagesSubtitle', 'noMessagesSubtitle'], base.noMessagesSubtitle);

  @override
  String get groupWelcome => _resolve(const ['messenger.empty.groupWelcome'], base.groupWelcome);

  @override
  String get channelWelcome => _resolve(const ['messenger.empty.channelWelcome'], base.channelWelcome);

  @override
  String get closeActionMinimizeToTraySubtitle => _resolve(const ['settings.closeActionMinimizeToTraySubtitle', 'pc.closeActionMinimizeToTraySubtitle', 'closeActionMinimizeToTraySubtitle'], base.closeActionMinimizeToTraySubtitle);

  @override
  String get closeActionMinimizeToTaskbarSubtitle => _resolve(const ['settings.closeActionMinimizeToTaskbarSubtitle', 'pc.closeActionMinimizeToTaskbarSubtitle', 'closeActionMinimizeToTaskbarSubtitle'], base.closeActionMinimizeToTaskbarSubtitle);

  @override
  String get closeActionExitAppSubtitle => _resolve(const ['settings.closeActionExitAppSubtitle', 'pc.closeActionExitAppSubtitle', 'closeActionExitAppSubtitle'], base.closeActionExitAppSubtitle);

  @override
  String get downloadingLabel => _resolve(const ['pc.downloadingLabel', 'downloadingLabel', 'pc.zagruzka_43e4', 'zagruzka_43e4'], base.downloadingLabel);

  @override
  String get downloadErrorLabel => _resolve(const ['pc.downloadErrorLabel', 'downloadErrorLabel'], base.downloadErrorLabel);

  @override
  String get closeActionTitle => _resolve(const ['settings.closeActionTitle', 'messenger.generalSettings.closeAction', 'closeActionTitle', 'pc.closeActionTitle'], base.closeActionTitle);

  @override
  String get closeActionDescription => _resolve(const ['settings.closeActionDescription', 'closeActionDescription', 'pc.closeActionDescription'], base.closeActionDescription);

  @override
  String get closeActionMinimizeToTray => _resolve(const ['messenger.call.minimize', 'settings.closeActionMinimizeToTray', 'closeActionMinimizeToTray', 'pc.closeActionMinimizeToTray'], base.closeActionMinimizeToTray);

  @override
  String get closeActionExitApp => _resolve(const ['messenger.delete.buttons.leave', 'settings.closeActionExitApp', 'closeActionExitApp', 'pc.closeActionExitApp'], base.closeActionExitApp);

  @override
  String get closeActionMinimizeToTaskbar => _resolve(const ['settings.closeActionMinimizeToTaskbar', 'closeActionMinimizeToTaskbar', 'pc.closeActionMinimizeToTaskbar'], base.closeActionMinimizeToTaskbar);

  @override
  String get showWindow => _resolve(const ['showWindow', 'pc.showWindow'], base.showWindow);

  @override
  String get exitApp => _resolve(const ['exitApp', 'pc.exitApp'], base.exitApp);

  @override
  String get minuteShort => _resolve(const ['pc.minuteShort', 'minuteShort'], base.minuteShort);

  @override
  String get secondShort => _resolve(const ['pc.secondShort', 'secondShort'], base.secondShort);

  @override
  String get openChat => _resolve(const ['pc.openChat', 'openChat'], base.openChat);

  @override
  String get markAsRead => _resolve(const ['pc.markAsRead', 'markAsRead'], base.markAsRead);

  @override
  String get qrLoginTitle => _resolve(const ['qrLoginTitle', 'pc.qrLoginTitle'], base.qrLoginTitle);

  @override
  String get qrLoginSubtitle => _resolve(const ['qrLoginSubtitle', 'pc.qrLoginSubtitle'], base.qrLoginSubtitle);

  @override
  String get qrApprovalTitle => _resolve(const ['qrApprovalTitle', 'pc.qrApprovalTitle'], base.qrApprovalTitle);

  @override
  String get qrApprovalDesc => _resolve(const ['qrApprovalDesc', 'pc.qrApprovalDesc'], base.qrApprovalDesc);

  @override
  String get qrVerificationCodeLabel => _resolve(const ['qrVerificationCodeLabel', 'pc.qrVerificationCodeLabel'], base.qrVerificationCodeLabel);

  @override
  String get qrVerificationCodeHint => _resolve(const ['qrVerificationCodeHint', 'pc.qrVerificationCodeHint'], base.qrVerificationCodeHint);

  @override
  String get qrScanInstructionTitle => _resolve(const ['pc.istochnikZagruzki_0e6e', 'pc.vidimostProfilya_448f', 'istochnikZagruzki_0e6e', 'vidimostProfilya_448f', 'qrScanInstructionTitle', 'pc.qrScanInstructionTitle'], base.qrScanInstructionTitle);

  @override
  String get qrStep1 => _resolve(const ['qrStep1', 'pc.qrStep1'], base.qrStep1);

  @override
  String get qrStep2 => _resolve(const ['qrStep2', 'pc.qrStep2'], base.qrStep2);

  @override
  String get qrStep3 => _resolve(const ['qrStep3', 'pc.qrStep3'], base.qrStep3);

  @override
  String get qrCodeLoginBtn => _resolve(const ['qrCodeLoginBtn', 'pc.qrCodeLoginBtn'], base.qrCodeLoginBtn);

  @override
  String get codeLoginTitle => _resolve(const ['codeLoginTitle', 'pc.codeLoginTitle'], base.codeLoginTitle);

  @override
  String get codeLoginSubtitle => _resolve(const ['codeLoginSubtitle', 'pc.codeLoginSubtitle'], base.codeLoginSubtitle);

  @override
  String get sixDigitCodeLabel => _resolve(const ['sixDigitCodeLabel', 'pc.sixDigitCodeLabel'], base.sixDigitCodeLabel);

  @override
  String get codeInstructionTitle => _resolve(const ['pc.privatnost_3098', 'pc.oPrilozhenii_77b2', 'privatnost_3098', 'oPrilozhenii_77b2', 'codeInstructionTitle', 'pc.codeInstructionTitle'], base.codeInstructionTitle);

  @override
  String get codeInstructionText => _resolve(const ['codeInstructionText', 'pc.codeInstructionText'], base.codeInstructionText);

  @override
  String get getCodeBtn => _resolve(const ['getCodeBtn', 'pc.getCodeBtn'], base.getCodeBtn);

  @override
  String get backToQrBtn => _resolve(const ['backToQrBtn', 'pc.backToQrBtn'], base.backToQrBtn);

  @override
  String get qrTimerLabel => _resolve(const ['qrTimerLabel', 'pc.qrTimerLabel'], base.qrTimerLabel);

  @override
  String get refreshQrBtn => _resolve(const ['refreshQrBtn', 'pc.refreshQrBtn'], base.refreshQrBtn);

  @override
  String get registrationDisabled => _resolve(const ['registrationDisabled', 'pc.registrationDisabled'], base.registrationDisabled);

  @override
  String get loginWithPasswordLink => _resolve(const ['pc.loginWithPasswordLink', 'loginWithPasswordLink'], base.loginWithPasswordLink);

  @override
  String get cantLoginSendToEmail => _resolve(const ['cantLoginSendToEmail', 'pc.cantLoginSendToEmail'], base.cantLoginSendToEmail);

  @override
  String get resendCodeToEmail => _resolve(const ['resendCodeToEmail', 'pc.resendCodeToEmail'], base.resendCodeToEmail);

  @override
  String get codeSentToBot => _resolve(const ['codeSentToBot', 'pc.codeSentToBot'], base.codeSentToBot);

  @override
  String get emailCodeFailed => _resolve(const ['emailCodeFailed', 'pc.emailCodeFailed'], base.emailCodeFailed);

  @override
  String get enterUsernameErr => _resolve(const ['pc.enterUsernameErr', 'enterUsernameErr'], base.enterUsernameErr);

  @override
  String get sendCodeFailedErr => _resolve(const ['pc.sendCodeFailedErr', 'sendCodeFailedErr'], base.sendCodeFailedErr);

  @override
  String get enterAllDigitsErr => _resolve(const ['pc.enterAllDigitsErr', 'enterAllDigitsErr'], base.enterAllDigitsErr);

  @override
  String get invalidCodeErr => _resolve(const ['pc.invalidCodeErr', 'invalidCodeErr'], base.invalidCodeErr);

  @override
  String get enterPasswordErr => _resolve(const ['pc.enterPasswordErr', 'enterPasswordErr'], base.enterPasswordErr);

  @override
  String get invalidPasswordErr => _resolve(const ['pc.invalidPasswordErr', 'invalidPasswordErr'], base.invalidPasswordErr);

  @override
  String get passwordTooSoonErr => _resolve(const ['pc.passwordTooSoonErr', 'passwordTooSoonErr'], base.passwordTooSoonErr);

  @override
  String get submitCodeBtn => _resolve(const ['pc.voyti_63a7', 'voyti_63a7', 'submitCodeBtn', 'pc.submitCodeBtn'], base.submitCodeBtn);

  @override
  String get loginApproved => _resolve(const ['pc.loginApproved', 'loginApproved'], base.loginApproved);

  @override
  String get requestExpiredErr => _resolve(const ['pc.requestExpiredErr', 'requestExpiredErr'], base.requestExpiredErr);

  @override
  String get rateLimitedErr => _resolve(const ['pc.rateLimitedErr', 'rateLimitedErr'], base.rateLimitedErr);

  @override
  String get confirmOnDeviceStatus => _resolve(const ['pc.confirmOnDeviceStatus', 'confirmOnDeviceStatus'], base.confirmOnDeviceStatus);

  @override
  String get sixDigitCodeSentSub => _resolve(const ['sixDigitCodeSentSub', 'pc.sixDigitCodeSentSub'], base.sixDigitCodeSentSub);

  @override
  String get confirmOnDeviceSub => _resolve(const ['confirmOnDeviceSub', 'pc.confirmOnDeviceSub'], base.confirmOnDeviceSub);

  @override
  String get awaitingDeviceApproval => _resolve(const ['awaitingDeviceApproval', 'pc.awaitingDeviceApproval'], base.awaitingDeviceApproval);

  @override
  String get mustBeSixDigits => _resolve(const ['pc.mustBeSixDigits', 'mustBeSixDigits'], base.mustBeSixDigits);

  @override
  String get continueBtn => _resolve(const ['pc.prodolzhit_e9c3', 'prodolzhit_e9c3', 'continueBtn', 'pc.continueBtn'], base.continueBtn);

  @override
  String get backBtn => _resolve(const ['pc.nazad_2b0b', 'nazad_2b0b', 'backBtn', 'pc.backBtn'], base.backBtn);

  @override
  String get confirmDeviceRequestText => _resolve(const ['confirmDeviceRequestText', 'pc.confirmDeviceRequestText'], base.confirmDeviceRequestText);

  @override
  String get sendingEmailCode => _resolve(const ['pc.sendingEmailCode', 'sendingEmailCode'], base.sendingEmailCode);

  @override
  String welcomeUser(String username) {
    if (!_rt.hasActiveCustomPack) return base.welcomeUser(username);
    final res = _rt.get('welcomeUser', params: {'username': username});
    if (res != 'welcomeUser') return res;
    return base.welcomeUser(username);
  }

  @override
  String fontSize(int size) {
    if (!_rt.hasActiveCustomPack) return base.fontSize(size);
    final res = _rt.get('fontSize', params: {'size': size});
    if (res != 'fontSize') return res;
    return base.fontSize(size);
  }

  @override
  String codeSentToEmail(String email) {
    if (!_rt.hasActiveCustomPack) return base.codeSentToEmail(email);
    final res = _rt.get('codeSentToEmail', params: {'email': email});
    if (res != 'codeSentToEmail') return res;
    return base.codeSentToEmail(email);
  }

  @override
  String resendIn(int count) {
    if (!_rt.hasActiveCustomPack) return base.resendIn(count);
    final res = _rt.get('resendIn', params: {'count': count});
    if (res != 'resendIn') return res;
    return base.resendIn(count);
  }

  @override
  String membersCount(int count) {
    if (!_rt.hasActiveCustomPack) return base.membersCount(count);
    final res = _rt.get('membersCount', params: {'count': count});
    if (res != 'membersCount') return res;
    return base.membersCount(count);
  }

  @override
  String subscribersCount(int count) {
    if (!_rt.hasActiveCustomPack) return base.subscribersCount(count);
    final res = _rt.get('subscribersCount', params: {'count': count});
    if (res != 'subscribersCount') return res;
    return base.subscribersCount(count);
  }

  @override
  String requestCodeViaEmailIn(int seconds) {
    if (!_rt.hasActiveCustomPack) return base.requestCodeViaEmailIn(seconds);
    final res = _rt.get('requestCodeViaEmailIn', params: {'seconds': seconds});
    if (res != 'requestCodeViaEmailIn') return res;
    return base.requestCodeViaEmailIn(seconds);
  }

  @override
  String requestCodeViaPasswordIn(int seconds) {
    if (!_rt.hasActiveCustomPack) return base.requestCodeViaPasswordIn(seconds);
    final res = _rt.get('requestCodeViaPasswordIn', params: {'seconds': seconds});
    if (res != 'requestCodeViaPasswordIn') return res;
    return base.requestCodeViaPasswordIn(seconds);
  }

  @override
  String emailCodeSent(String email) {
    if (!_rt.hasActiveCustomPack) return base.emailCodeSent(email);
    final res = _rt.get('emailCodeSent', params: {'email': email});
    if (res != 'emailCodeSent') return res;
    return base.emailCodeSent(email);
  }

}
