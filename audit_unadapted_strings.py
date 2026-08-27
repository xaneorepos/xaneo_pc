#!/usr/bin/env python3
"""
Скрипт для поиска строк в xaneo_pc, которые имеют стандартную локализацию,
но НЕ адаптированы / НЕ сопоставлены с пользовательскими языковыми пакетами (manifest.v1.json).
"""

import json
import re
import os

# 1. Загружаем манифест
manifest_path = '/home/xaneodev/xaneomain/localization/schema/manifest.v1.json'
with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest_data = json.load(f)

manifest_keys = manifest_data.get('keys', {})

def normalize_text(t):
    if not t:
        return ""
    t = re.sub(r'[^\w\s]', '', t, flags=re.UNICODE)
    t = re.sub(r'\s+', '', t)
    return t.lower()

# Собираем все русские тексты из манифеста
manifest_ru_exact = set()
manifest_ru_norm = {}
for k, v in manifest_keys.items():
    ru = v.get('fallback_ru') or v.get('ru') or ''
    if ru:
        manifest_ru_exact.add(ru)
        norm = normalize_text(ru)
        if norm:
            manifest_ru_norm[norm] = k

# 2. Загружаем все геттеры из app_localizations.dart и их русские значения из app_localizations_ru.dart
ru_dart_path = '/home/xaneodev/xaneo_pc/lib/l10n/app_localizations_ru.dart'
with open(ru_dart_path, 'r', encoding='utf-8') as f:
    ru_dart_content = f.read()

# Парсим геттеры
getter_to_val = {}
for m in re.finditer(r'String get ([a-zA-Z0-9_]+) => (.*?);', ru_dart_content):
    g_name = m.group(1)
    val = m.group(2).strip("'\"")
    getter_to_val[g_name] = val

# 3. Загружаем DynamicAppLocalizations чтобы проверить, какие ключи сопоставлены явно
dynamic_l10n_path = '/home/xaneodev/xaneo_pc/lib/l10n/dynamic_app_localizations.dart'
explicit_mappings = {}
if os.path.exists(dynamic_l10n_path):
    with open(dynamic_l10n_path, 'r', encoding='utf-8') as f:
        dyn_content = f.read()
    for m in re.finditer(r'String get ([a-zA-Z0-9_]+) => _resolve\(const \[(.*?)\]', dyn_content):
        g_name = m.group(1)
        raw_keys = [k.strip("'\" ") for k in m.group(2).split(',') if k.strip("'\" ")]
        explicit_mappings[g_name] = raw_keys

# 4. Анализируем каждый геттер: может ли он быть переведён пользовательским языком?
unadapted_getters = []
adapted_getters = []

for g_name, ru_val in getter_to_val.items():
    # Проверка 1: Есть ли прямой ключ в манифесте?
    if g_name in manifest_keys:
        adapted_getters.append((g_name, ru_val, 'exact_key_match', g_name))
        continue

    # Проверка 2: Есть ли явные алиасы в dynamic_app_localizations?
    mapped_keys = explicit_mappings.get(g_name, [])
    found_manifest_key = None
    for k in mapped_keys:
        if k in manifest_keys:
            found_manifest_key = k
            break
    if found_manifest_key:
        adapted_getters.append((g_name, ru_val, 'mapped_alias', found_manifest_key))
        continue

    # Проверка 3: Находится ли русский текст в манифесте через resolveByText?
    if ru_val in manifest_ru_exact:
        adapted_getters.append((g_name, ru_val, 'exact_ru_text_match', ''))
        continue

    norm = normalize_text(ru_val)
    if norm in manifest_ru_norm:
        adapted_getters.append((g_name, ru_val, 'normalized_ru_text_match', manifest_ru_norm[norm]))
        continue

    # Если ни один метод не связал геттер с манифестом — он НЕ АДАПТИРОВАН!
    unadapted_getters.append((g_name, ru_val))

print("=" * 80)
print(f"📊 АНАЛИЗ ПОКРЫТИЯ ПОЛЬЗОВАТЕЛЬСКИМИ ЯЗЫКАМИ (MANIFEST V1):")
print("=" * 80)
print(f"Всего геттеров в AppLocalizations: {len(getter_to_val)}")
print(f"✅ Адаптировано под кастомные языки: {len(adapted_getters)} ({len(adapted_getters)/len(getter_to_val)*100:.1f}%)")
print(f"❌ НЕ АДАПТИРОВАНО под кастомные языки: {len(unadapted_getters)} ({len(unadapted_getters)/len(getter_to_val)*100:.1f}%)")
print("=" * 80)

if unadapted_getters:
    print("\n🔍 НЕАДАПТИРОВАННЫЕ СТРОКИ (есть в интерфейсе, но отсутствуют в manifest.v1.json):")
    print("-" * 80)
    for g_name, ru_val in unadapted_getters[:50]:  # Первые 50 для наглядности
        print(f"  • {g_name:<35} -> \"{ru_val}\"")
    if len(unadapted_getters) > 50:
        print(f"  ... и ещё {len(unadapted_getters) - 50} строк.")
