#!/usr/bin/env python3
"""
Анализ и адаптация JSON языковых пакетов под xaneo_pc.
Проверяет:
 1. Валидность структуры пакета
 2. Соответствие ключей manifest.v1.json
 3. Наличие ключей, которые использует xaneo_pc
 4. Процент строк, которые переопределяются в xaneo_pc
"""

import json
import os
import glob

MANIFEST_PATH = '/home/xaneodev/xaneo_pc/assets/manifest.v1.json'
with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
    manifest = json.load(f)

manifest_keys = manifest.get('keys', {})

candidate_files = [
    '/home/xaneodev/tsukishiro_agent_lang.json',
    '/home/xaneodev/dorevolyucionnyj_lang.json',
    '/home/xaneodev/Загрузки/flirty_ru_lang.json',
    '/home/xaneodev/Загрузки/flirty_ru_lang_extra_dirty.json',
]

for filepath in candidate_files:
    if not os.path.exists(filepath):
        print(f"⚠️ Файл не найден: {filepath}")
        continue
    
    print("=" * 80)
    print(f"📄 АНАЛИЗ ПАКЕТА: {os.path.basename(filepath)}")
    print(f"   Путь: {filepath}")
    print("=" * 80)

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            pack = json.load(f)
    except Exception as e:
        print(f"❌ Ошибка парсинга JSON: {e}")
        continue

    # Метаданные
    print(f"  • schema_version: {pack.get('schema_version')}")
    print(f"  • locale:         {pack.get('locale')}")
    print(f"  • name:           {pack.get('name')} ({pack.get('native_name')})")
    print(f"  • fallback:       {pack.get('fallback_locale')}")
    print(f"  • direction:      {pack.get('direction')}")

    strings = pack.get('strings', {})
    print(f"  • Всего строк в пакете: {len(strings)}")

    # Проверка ключей против манифеста
    valid_keys = 0
    unknown_keys = []
    for k in strings.keys():
        if k in manifest_keys:
            valid_keys += 1
        else:
            unknown_keys.append(k)

    print(f"  • Ключей, совпадающих с манифестом: {valid_keys} / {len(strings)} ({valid_keys/max(1, len(strings))*100:.1f}%)")
    if unknown_keys:
        print(f"  ⚠️ Неизвестных ключей (не в манифесте): {len(unknown_keys)}")
        for uk in unknown_keys[:10]:
            print(f"     - {uk}")
        if len(unknown_keys) > 10:
            print(f"     ... и ещё {len(unknown_keys) - 10}")

    # Проверим примеры ключевых фраз xaneo_pc
    sample_pc_keys = [
        'messenger.chats', 'chats', 'messenger.search', 'search',
        'messenger.settings.title', 'settings', 'profile',
        'messenger.attach.file', 'file', 'offline', 'online',
        'login', 'register', 'messenger.calls.start', 'startCall'
    ]
    matched_samples = [k for k in sample_pc_keys if k in strings]
    print(f"  • Совпадений с ключевыми терминами PC: {len(matched_samples)} / {len(sample_pc_keys)}")
    print("\n")
