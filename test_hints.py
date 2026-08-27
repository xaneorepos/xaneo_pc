#!/usr/bin/env python3
import json

SETTINGS_HINTS = {
    # Personal
    'basicInfo': ['messenger.personal.sectionTitle', 'messenger.settings.personalTitle'],
    'osnovnayaInformatsiya_6fec': ['messenger.personal.sectionTitle', 'messenger.settings.personalTitle'],
    'yourName': ['messenger.personal.name', 'profile.profile.displayName'],
    'imya_d38d': ['messenger.personal.name', 'profile.profile.displayName'],
    'registerStep0Subtitle': ['messenger.personal.namePlaceholder'],
    'vvediteVasheImya_751e': ['messenger.personal.namePlaceholder'],
    'nickname': ['messenger.personal.nickname', 'profile.profile.username'],
    'nikneym_3fea': ['messenger.personal.nickname', 'profile.profile.username'],
    'nicknameCannotBeChanged': ['messenger.personal.nicknameCannotBeChanged'],
    'aboutMe': ['messenger.personal.bio', 'profile.profile.bio'],
    'oSebe_0b3b': ['messenger.personal.bio', 'profile.profile.bio'],
    'aboutMeHint': ['messenger.personal.bioPlaceholder'],
    'rasskazhiteOSebe_1c37': ['messenger.personal.bioPlaceholder'],
    'save': ['messenger.createGroup.createButton', 'common.save', 'profile.profile.save'],
    'sohranit_74ea': ['messenger.createGroup.createButton', 'common.save', 'profile.profile.save'],
    'saving': ['common.saving'],
    'sohranenie_c15f': ['common.saving'],

    # Privacy
    'communications': ['messenger.privacy.communications'],
    'kommunikatsii_1242': ['messenger.privacy.communications'],
    'whoCanMessage': ['messenger.privacy.whoCanMessage'],
    'ktoMozhetPisatSoobscheniya_4645': ['messenger.privacy.whoCanMessage'],
    'whoCanCall': ['messenger.privacy.whoCanCall'],
    'ktoMozhetZvonit_c427': ['messenger.privacy.whoCanCall'],
    'whoCanRecordVoice': ['messenger.privacy.whoCanRecordVoice'],
    'ktoMozhetZapisyvatGolosovye_c69a': ['messenger.privacy.whoCanRecordVoice'],
    'whoCanSendFiles': ['messenger.privacy.whoCanSendFiles'],
    'ktoMozhetOtpravlyatFayly_2e40': ['messenger.privacy.whoCanSendFiles'],
    'whoCanInvite': ['messenger.privacy.whoCanInvite'],
    'ktoMozhetPriglashatVGruppy_cdc0': ['messenger.privacy.whoCanInvite'],
    'profileVisibility': ['messenger.privacy.profileVisibility'],
    'vidimostProfilya_34bf': ['messenger.privacy.profileVisibility'],
    'whoSeesNickname': ['messenger.privacy.whoSeesNickname'],
    'ktoViditMoyNikneym_54b8': ['messenger.privacy.whoSeesNickname'],
    'whoSeesAvatar': ['messenger.privacy.whoSeesAvatar'],
    'whoSeesBirthday': ['messenger.privacy.whoSeesBirthday'],
    'whoSeesOnlineTime': ['messenger.privacy.whoSeesOnlineTime'],
    'everyone': ['messenger.privacy.all', 'common.all'],
    'vse_984b': ['messenger.privacy.all', 'common.all'],
    'contactsOnly': ['messenger.privacy.contactsOnly'],
    'tolkoKontakty_a559': ['messenger.privacy.contactsOnly'],
    'nobody': ['messenger.privacy.nobody'],
    'nikto_ba19': ['messenger.privacy.nobody'],

    # Chats
    'messages': ['messenger.energy.chatAnimations', 'messenger.chats'],
    'messageAnimations': ['messenger.energy.messageAnimationsTitle'],
    'messageAnimationsDesc': ['messenger.energy.messageAnimationsDesc'],
    'archivedChats': ['messenger.archivedChats', 'messenger.context.archive'],
    'archiveManagement': ['messenger.archiveManagement'],
    'clearHistory': ['messenger.context.clearHistory', 'messenger.delete.clearHistoryTitle'],
    'clearHistoryDesc': ['messenger.delete.clearHistoryWarning', 'messenger.delete.clearHistoryMessage'],

    # Contacts
    'addContact': ['messenger.contacts.createTitle', 'common.add'],
    'dobavitKontakt_4278': ['messenger.contacts.createTitle', 'common.add'],
    'dobavit_5eba': ['messenger.contacts.createTitle', 'common.add'],
    'noContactsYet': ['messenger.contacts.empty'],

    # Appearance
    'theme': ['messenger.chatSettings.appearance', 'common.theme'],
    'darkTheme': ['messenger.chatSettings.appearance', 'common.darkTheme'],
    'darkThemeDesc': ['messenger.chatSettings.appearance'],
    'fontSizeText': ['messenger.chatSettings.textSize'],

    # Window close
    'closeActionTitle': ['settings.closeActionTitle', 'messenger.generalSettings.closeAction'],
    'closeActionDescription': ['settings.closeActionDescription'],
    'closeActionMinimizeToTray': ['settings.closeActionMinimizeToTray'],
    'closeActionMinimizeToTraySubtitle': ['settings.closeActionMinimizeToTraySubtitle'],
    'closeActionMinimizeToTaskbar': ['settings.closeActionMinimizeToTaskbar'],
    'closeActionMinimizeToTaskbarSubtitle': ['settings.closeActionMinimizeToTaskbarSubtitle'],
    'closeActionExitApp': ['settings.closeActionExitApp'],
    'closeActionExitAppSubtitle': ['settings.closeActionExitAppSubtitle'],

    # Energy
    'energySavingMode': ['messenger.energy.lowPowerTitle'],
    'energySavingModeDesc': ['messenger.energy.lowPowerDesc'],
    'autoSleep': ['messenger.energy.autoSleepTitle'],
    'autoSleepDesc': ['messenger.energy.autoSleepDesc'],
    'animations': ['messenger.energy.chatAnimations'],
    'reducedMotion': ['messenger.energy.reducedAnimationsTitle'],
    'reducedMotionDesc': ['messenger.energy.reducedAnimationsDesc'],

    # About
    'appInfo': ['messenger.settings.aboutTitle', 'messenger.settings.about'],
    'checkUpdates': ['header.checkForUpdates', 'common.checkUpdates'],
    'checkingUpdates': ['header.checkingForUpdates'],
    'youHaveLatestVersion': ['header.latestVersion'],
    'newVersionAvailableTitle': ['header.newVersionAvailable'],
}

print(f"Total new hints: {len(SETTINGS_HINTS)}")
