#!/usr/bin/env python3
import json
import re

DYNAMIC_DART_PATH = '/home/xaneodev/xaneo_pc/lib/l10n/dynamic_app_localizations.dart'
with open(DYNAMIC_DART_PATH, 'r', encoding='utf-8') as f:
    dynamic_content = f.read()

getter_map = {}
for m in re.finditer(r'String get ([a-zA-Z0-9_]+) => _resolve\(const \[(.*?)\]', dynamic_content):
    g_name = m.group(1)
    keys = [k.strip("'\" ") for k in m.group(2).split(',') if k.strip("'\" ")]
    getter_map[g_name] = keys

with open('/home/xaneodev/tsukishiro_agent_lang.json', 'r', encoding='utf-8') as f:
    tsukishiro = json.load(f)['strings']

test_suites = {
    "1. Главное меню настроек (Screen 0)": [
        ('mainSettings', 'Конфигурация ядра'),
        ('appearance', 'Параметры симуляции'),
        ('appearanceDesc', 'Язык, интерфейс, протоколы'),
        ('closeActionTitle', 'Действие при закрытии окна'),
        ('closeActionDescription', 'Описание действия закрытия'),
        ('language', 'Язык'),
        ('languageDescription', 'Описание языка'),
        ('notifications', 'Уведомления'),
        ('notificationsDescription', 'Описание уведомлений'),
        ('energySaving', 'Энергосбережение'),
        ('energySavingDesc', 'Описание энергосбережения'),
        ('about', 'О приложении'),
        ('aboutDescription', 'Описание о приложении'),
    ],
    "2. Профиль оперативника (Screen 1)": [
        ('basicInfo', 'Основная информация'),
        ('yourName', 'Ваше имя'),
        ('nickname', 'Никнейм'),
        ('aboutMe', 'О себе'),
        ('aboutMeHint', 'Расскажите о себе...'),
        ('save', 'Сохранить'),
    ],
    "3. Приватность и каналы связи (Screen 2)": [
        ('communications', 'Коммуникации'),
        ('whoCanMessage', 'Кто может писать сообщения'),
        ('whoCanCall', 'Кто может вызывать на голосовой мост'),
        ('whoCanRecordVoice', 'Кто может записывать голосовые'),
        ('whoCanSendFiles', 'Кто может отправлять файлы'),
        ('whoCanInvite', 'Кто может приглашать в группы'),
        ('profileVisibility', 'Видимость профиля'),
        ('whoSeesNickname', 'Кто видит мой никнейм'),
        ('whoSeesAvatar', 'Кто видит аватар агента'),
        ('whoSeesBirthday', 'Кто знает дату активации'),
        ('whoSeesOnlineTime', 'Кто видит время активности в матрице'),
        ('everyone', 'Все'),
        ('contactsOnly', 'Только контакты'),
        ('nobody', 'Никто'),
    ],
    "4. Протоколы связи (Screen 3)": [
        ('messages', 'Сообщения'),
        ('messageAnimations', 'Анимации сообщений'),
        ('messageAnimationsDesc', 'Показывать анимации...'),
        ('archivedChats', 'Архивированные чаты'),
        ('clearHistory', 'Сжечь историю логов'),
    ],
    "5. Список агентов (Screen 4)": [
        ('contacts', 'Список агентов'),
        ('addContact', '+ Добавить'),
        ('noContactsYet', 'У вас пока нет контактов'),
    ],
    "6. Параметры симуляции / Тема (Screen 5)": [
        ('theme', 'Тема'),
        ('darkTheme', 'Тёмная тема'),
        ('fontSizeText', 'Размер шрифта'),
    ],
    "7. Энергосбережение чипа (Screen 7)": [
        ('energySavingMode', 'Режим экономии энергии'),
        ('energySavingModeDesc', 'Описание экономии'),
        ('autoSleep', 'Автоматический спящий режим'),
        ('autoSleepDesc', 'Описание спящего режима'),
        ('reducedMotion', 'Упрощённые анимации'),
        ('reducedMotionDesc', 'Описание упрощённых анимаций'),
    ],
    "8. О приложении (Screen 8)": [
        ('appInfo', 'Информация о приложении'),
        ('checkUpdates', 'Проверить обновления'),
    ],
}

print("=" * 80)
print("🎯 РЕЗУЛЬТАТ ПРОВЕРКИ 9 ЭКРАНОВ НАСТРОЕК (TSUKISHIRO PACK)")
print("=" * 80)

total = 0
resolved = 0
for title, items in test_suites.items():
    print(f"\n📁 {title}:")
    for getter, label in items:
        total += 1
        keys = getter_map.get(getter, [])
        match_val = None
        match_key = None
        for k in keys:
            if k in tsukishiro:
                match_val = tsukishiro[k]
                match_key = k
                break
        if match_val:
            resolved += 1
            print(f"   ✅ [{label:<30}] -> \"{match_val}\" ({match_key})")
        else:
            print(f"   ⚠️ [{label:<30}] -> Не найдено в манифесте")

print("\n" + "=" * 80)
print(f"📊 ИТОГ: Разрешено {resolved}/{total} ({resolved/total*100:.1f}%)")
print("=" * 80)
