#!/usr/bin/env python3
"""
Тест реального перевода экранов Xaneo PC для каждого из 4 пользовательских языковых пакетов.
"""

import json
import re

# Загружаем DynamicAppLocalizations карту геттеров
DYNAMIC_DART_PATH = '/home/xaneodev/xaneo_pc/lib/l10n/dynamic_app_localizations.dart'
with open(DYNAMIC_DART_PATH, 'r', encoding='utf-8') as f:
    dynamic_content = f.read()

# Парсим геттер -> список ключей
getter_map = {}
for m in re.finditer(r'String get ([a-zA-Z0-9_]+) => _resolve\(const \[(.*?)\]', dynamic_content):
    g_name = m.group(1)
    keys = [k.strip("'\" ") for k in m.group(2).split(',') if k.strip("'\" ")]
    getter_map[g_name] = keys

# Загружаем русские дефолты
RU_DART_PATH = '/home/xaneodev/xaneo_pc/lib/l10n/app_localizations_ru.dart'
with open(RU_DART_PATH, 'r', encoding='utf-8') as f:
    ru_content = f.read()

getter_to_ru = {}
for m in re.finditer(r'String get ([a-zA-Z0-9_]+) => (.*?);', ru_content):
    getter_name = m.group(1)
    raw_val = m.group(2).strip()
    if (raw_val.startswith("'") and raw_val.endswith("'")) or (raw_val.startswith('"') and raw_val.endswith('"')):
        val = raw_val[1:-1].encode().decode('unicode-escape')
    else:
        val = raw_val.strip("'\"")
    getter_to_ru[getter_name] = val

candidate_files = [
    '/home/xaneodev/tsukishiro_agent_lang.json',
    '/home/xaneodev/dorevolyucionnyj_lang.json',
    '/home/xaneodev/Загрузки/flirty_ru_lang.json',
    '/home/xaneodev/Загрузки/flirty_ru_lang_extra_dirty.json',
]

for filepath in candidate_files:
    print("=" * 80)
    print(f"🎮 ТЕСТИРОВАНИЕ РЕЗОЛВА СТРОК ДЛЯ: {filepath.split('/')[-1]}")
    print("=" * 80)

    with open(filepath, 'r', encoding='utf-8') as f:
        pack = json.load(f)

    pack_strings = pack.get('strings', {})

    # Симулируем DynamicAppLocalizations._resolve
    def resolve_getter(g_name):
        keys = getter_map.get(g_name, [g_name])
        fallback = getter_to_ru.get(g_name, g_name)
        for k in keys:
            if k in pack_strings:
                return pack_strings[k], k
        return fallback, None

    # Проверим ключевые элементы интерфейса
    test_ui_elements = [
        ('chats', 'Чаты в меню'),
        ('search', 'Поиск'),
        ('settings', 'Настройки'),
        ('lichnyeDannye_be85', 'Личные данные'),
        ('toArchive', 'В архив'),
        ('savedMessages', 'Избранное'),
        ('group', 'Группа'),
        ('channel', 'Канал'),
        ('delete', 'Удалить'),
        ('edit', 'Редактировать'),
        ('copy', 'Скопировать'),
        ('reply', 'Ответить'),
        ('pin', 'Закрепить'),
        ('online', 'В сети'),
        ('offline', 'Не в сети'),
        ('isRecordingVoice', 'Записывает голосовое...'),
        ('isTyping', 'Печатает...'),
        ('startCall', 'Начать звонок'),
        ('audioCall', 'Голосовой звонок'),
        ('videoCall', 'Видеозвонок'),
        ('addAttachment', 'Добавить вложение'),
        ('file', 'Файл'),
        ('todoList', 'Список задач'),
        ('poll', 'Опрос'),
        ('createTodo', 'СОЗДАТЬ TO-DO'),
        ('createPoll', 'СОЗДАТЬ ОПРОС'),
    ]

    translated_count = 0
    for g_name, label in test_ui_elements:
        val, matched_key = resolve_getter(g_name)
        default_val = getter_to_ru.get(g_name, '')
        is_changed = (val != default_val)
        if is_changed:
            translated_count += 1
            print(f"  ✅ [{label:<22}] ({g_name}) -> \"{val}\" (по ключу: {matched_key})")
        else:
            print(f"  ▫️ [{label:<22}] ({g_name}) -> \"{val}\" (дефолт)")

    print("-" * 80)
    print(f"  Итого переведено в тесте: {translated_count} / {len(test_ui_elements)} ({translated_count/len(test_ui_elements)*100:.1f}%)")
    print("\n")
