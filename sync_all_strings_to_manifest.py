#!/usr/bin/env python3
"""
Скрипт для полной синхронизации и добавления недостающих ключей xaneo_pc в manifest.v1.json,
обновления тестовых языковых пакетов и регенерации DynamicAppLocalizations.
"""

import json
import re
import os

MANIFEST_PATH = '/home/xaneodev/xaneomain/localization/schema/manifest.v1.json'
RU_DART_PATH = '/home/xaneodev/xaneo_pc/lib/l10n/app_localizations_ru.dart'
DYNAMIC_DART_PATH = '/home/xaneodev/xaneo_pc/lib/l10n/dynamic_app_localizations.dart'
TSUKISHIRO_PATH = '/home/xaneodev/xaneo_pc/assets/languages/tsukishiro_agent_lang.json'
DOREVOLYUCIONNYJ_PATH = '/home/xaneodev/xaneo_pc/assets/languages/dorevolyucionnyj_lang.json'

def main():
    # 1. Загрузка манифеста
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    manifest_keys = manifest.setdefault('keys', {})

    # 2. Чтение всех геттеров и значений из app_localizations_ru.dart
    with open(RU_DART_PATH, 'r', encoding='utf-8') as f:
        ru_dart = f.read()

    getters = {}
    for m in re.finditer(r'String get ([a-zA-Z0-9_]+) => (.*?);', ru_dart):
        g_name = m.group(1)
        raw_val = m.group(2).strip()
        if (raw_val.startswith("'") and raw_val.endswith("'")) or (raw_val.startswith('"') and raw_val.endswith('"')):
            val = raw_val[1:-1].encode().decode('unicode-escape')
        else:
            val = raw_val.strip("'\"")
        getters[g_name] = val

    print(f"Найдено {len(getters)} геттеров в app_localizations_ru.dart.")

    # 3. Сопоставляем и добавляем отсутствующие ключи
    added_to_manifest = 0
    mapping_for_dynamic = {}

    for g_name, ru_val in getters.items():
        # Определяем canonical_key
        # Если геттер уже в манифесте
        if g_name in manifest_keys:
            mapping_for_dynamic[g_name] = [g_name]
            continue

        # Проверим по существующему fallback_ru
        found_key = None
        for k, v in manifest_keys.items():
            if v.get('fallback_ru') == ru_val or v.get('ru') == ru_val:
                found_key = k
                break
        
        if found_key:
            mapping_for_dynamic[g_name] = [g_name, found_key]
        else:
            # Создаем новый ключ в манифесте
            key_id = f"pc.{g_name}" if not g_name.startswith('pc.') else g_name
            manifest_keys[key_id] = {
                "fallback_ru": ru_val,
                "description": f"Desktop PC string: {g_name}",
                "category": "pc"
            }
            mapping_for_dynamic[g_name] = [g_name, key_id]
            added_to_manifest += 1

    print(f"Добавлено новых ключей в manifest.v1.json: {added_to_manifest}")

    # Сохраняем обновленный манифест
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("manifest.v1.json сохранён.")

    # 4. Обновляем языковой пакет Tsukishiro (добавляем все ключи с префиксом стиля Tsukishiro)
    if os.path.exists(TSUKISHIRO_PATH):
        with open(TSUKISHIRO_PATH, 'r', encoding='utf-8') as f:
            tsuki_pack = json.load(f)
        tsuki_strings = tsuki_pack.setdefault('strings', {})
        
        for k, v in manifest_keys.items():
            if k not in tsuki_strings:
                ru_text = v.get('fallback_ru', '')
                # Сохраняем или адаптируем
                tsuki_strings[k] = ru_text
        
        with open(TSUKISHIRO_PATH, 'w', encoding='utf-8') as f:
            json.dump(tsuki_pack, f, ensure_ascii=False, indent=2)
        print(f"tsukishiro_agent_lang.json обновлён (всего {len(tsuki_strings)} строк).")

    # 5. Обновляем языковой пакет Dorevolyucionnyj
    if os.path.exists(DOREVOLYUCIONNYJ_PATH):
        with open(DOREVOLYUCIONNYJ_PATH, 'r', encoding='utf-8') as f:
            dorev_pack = json.load(f)
        dorev_strings = dorev_pack.setdefault('strings', {})
        
        for k, v in manifest_keys.items():
            if k not in dorev_strings:
                ru_text = v.get('fallback_ru', '')
                dorev_strings[k] = ru_text
        
        with open(DOREVOLYUCIONNYJ_PATH, 'w', encoding='utf-8') as f:
            json.dump(dorev_pack, f, ensure_ascii=False, indent=2)
        print(f"dorevolyucionnyj_lang.json обновлён (всего {len(dorev_strings)} строк).")

    # 6. Регенерируем dynamic_app_localizations.dart
    code_lines = [
        "// GENERATED FILE - DO NOT EDIT MANUALLY",
        "// DynamicAppLocalizations with 100% manifest and custom language pack support",
        "import 'package:flutter/widgets.dart'; ",
        "import '../services/runtime_translations.dart';",
        "import 'app_localizations.dart';",
        "",
        "class DynamicAppLocalizations extends AppLocalizations {",
        "  final AppLocalizations base;",
        "  final RuntimeTranslations _rt = RuntimeTranslations.instance;",
        "",
        "  DynamicAppLocalizations(this.base) : super(base.localeName);",
        "",
        "  String _resolve(List<String> keys, String fallback) {",
        "    return _rt.get(keys, fallback: fallback);",
        "  }",
        "",
    ]

    for g_name, ru_val in sorted(getters.items()):
        keys_list = mapping_for_dynamic.get(g_name, [g_name])
        keys_repr = ", ".join(f"'{k}'" for k in keys_list)
        code_lines.append(f"  @override")
        code_lines.append(f"  String get {g_name} => _resolve(const [{keys_repr}], base.{g_name});")
        code_lines.append("")

    code_lines.append("}")
    code_lines.append("")

    with open(DYNAMIC_DART_PATH, 'w', encoding='utf-8') as f:
        f.write("\n".join(code_lines))
    print(f"DynamicAppLocalizations регенерирован ({len(getters)} переопределённых геттеров).")

if __name__ == '__main__':
    main()
