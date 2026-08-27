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

candidate_files = [
    '/home/xaneodev/tsukishiro_agent_lang.json',
    '/home/xaneodev/Загрузки/flirty_ru_lang.json',
    '/home/xaneodev/dorevolyucionnyj_lang.json',
]

settings_getters = [
    ('mainSettings', 'НАСТРОЙКИ'),
    ('personalData', 'Личные данные'),
    ('personalDataDesc', 'Описание личных данных'),
    ('privacyTitle', 'Приватность'),
    ('privacyDesc', 'Описание приватности'),
    ('chatsSettings', 'Настройки чатов'),
    ('chatsSettingsDesc', 'Описание настроек чатов'),
    ('contacts', 'Контакты'),
    ('contactsDesc', 'Описание контактов'),
    ('energySaving', 'Энергосбережение'),
    ('energySavingDesc', 'Описание энергосбережения'),
    ('appearance', 'Внешний вид'),
    ('appearanceDesc', 'Описание внешнего вида'),
    ('account', 'Аккаунт'),
    ('interface', 'Интерфейс'),
    ('logout', 'Выйти из аккаунта'),
]

for filepath in candidate_files:
    print("=" * 80)
    print(f"⚙️ ТЕСТ НАСТРОЕК В PC ДЛЯ: {filepath.split('/')[-1]}")
    print("=" * 80)

    with open(filepath, 'r', encoding='utf-8') as f:
        pack = json.load(f)

    pack_strings = pack.get('strings', {})

    def resolve_getter(g_name):
        keys = getter_map.get(g_name, [g_name])
        for k in keys:
            if k in pack_strings:
                return pack_strings[k], k
        return '---', None

    for g_name, label in settings_getters:
        val, matched_key = resolve_getter(g_name)
        print(f"  [{label:<28}] ({g_name}) -> \"{val}\" (по ключу: {matched_key})")
    print("\n")
