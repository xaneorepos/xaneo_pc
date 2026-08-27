#!/usr/bin/env python3
"""
Умный статический анализатор локализации для xaneo_pc.
Анализирует контекст выражений и различает:
  🔴 РЕАЛЬНЫЕ НЕАДАПТИРОВАННЫЕ ХАРДКОДЫ (прямой текст в UI без вызова l10n / DynamicAppLocalizations / resolveByText)
  🟢 ЗАЩИЩЁННЫЕ FALLBACK-СТРОКИ (вызовы l10n?.getter ?? 'Текст' или resolveByText('Текст'))
  ⚪ СЛОВАРИ И ВНУТРЕННИЕ ОШИБКИ API (словари локализации, исключения сервисов)
"""

import os
import re

EXCLUDE_DIRS = {'l10n', 'generated', '.dart_tool', 'build', '.git'}
EXCLUDE_FILES = {'dynamic_app_localizations.dart', 'app_localizations.dart', 'app_localizations_ru.dart', 'app_localizations_en.dart'}

CYRILLIC_STRING_REGEX = re.compile(
    r"""(?<![\w])(?:'([^'\\]*(?:\\.[^'\\]*)*)'|"([^"\\]*(?:\\.[^"\\]*)*)")"""
)

def has_cyrillic(text: str) -> bool:
    return bool(re.search(r'[\u0400-\u04FF]', text))

IGNORE_EXACT = {
    '[Ошибка дешифрования]',
    'ru',
}

def get_statement_context(lines, current_idx, lookback=4):
    """Объединяет текущую строку с несколькими предыдущими строками для анализа контекста выражения."""
    start = max(0, current_idx - lookback)
    return " ".join(lines[i].strip() for i in range(start, current_idx + 1))

def classify_match(context: str, current_line: str, match_text: str) -> str:
    # 1. Защищено через RuntimeTranslations / resolveByText / DynamicAppLocalizations
    if 'resolveByText(' in context or 'RuntimeTranslations' in context:
        return 'protected_fallback'
    
    if ('l10n?.' in context or 'AppLocalizations.of(' in context or 'lookupAppLocalizations(' in context) and ('??' in context or '||' in context or 'getModalTitle' in context or 'getModalTag' in context):
        return 'protected_fallback'

    # 2. Словарные карты (напр. 'ru': { 'key': 'Значение' } или 'bold': 'Жирный')
    if re.search(r"'(?:ru|en|es|fr|zh|ar|ja|ko)'\s*:\s*\{", context) or re.search(r"'(?:title|header|hint|label|cancel|save|edit|bold|italic|code|strikethrough)'\s*:\s*'", context):
        return 'dict_entry'
    
    # 3. Сервисные/внутренние ошибки в api_service
    if 'ApiResponse(' in context or 'error:' in context or 'throw ' in context or 'Exception(' in context:
        return 'api_internal'

    # 4. Отладочные логи
    if 'debugPrint(' in context or 'print(' in context or 'logger.' in context:
        return 'debug_log'

    # Если это прямой текст в UI (Text('...'), label: '...', tooltip: '...')
    return 'real_hardcode'

def scan_file(filepath: str):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    records = []
    for line_idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
            continue

        for match in CYRILLIC_STRING_REGEX.finditer(line):
            raw_val = match.group(1) if match.group(1) is not None else match.group(2)
            if not raw_val or not has_cyrillic(raw_val) or raw_val in IGNORE_EXACT:
                continue

            context = get_statement_context(lines, line_idx, lookback=4)
            category = classify_match(context, stripped, raw_val)

            records.append({
                'line_num': line_idx + 1,
                'text': raw_val,
                'line_content': stripped,
                'category': category,
            })
    return records

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    lib_dir = os.path.join(base_dir, 'lib')
    if not os.path.exists(lib_dir):
        lib_dir = '/home/xaneodev/xaneo_pc/lib'

    print(f"🔍 Запуск интеллектуального сканера локализации: {lib_dir}\n")

    results = {}
    real_hardcodes_count = 0
    protected_count = 0
    dict_count = 0
    api_count = 0

    for root, dirs, files in os.walk(lib_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        for file in sorted(files):
            if not file.endswith('.dart') or file in EXCLUDE_FILES:
                continue

            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, base_dir)
            file_records = scan_file(full_path)
            if file_records:
                results[rel_path] = file_records
                for r in file_records:
                    if r['category'] == 'real_hardcode':
                        real_hardcodes_count += 1
                    elif r['category'] == 'protected_fallback':
                        protected_count += 1
                    elif r['category'] == 'dict_entry':
                        dict_count += 1
                    elif r['category'] == 'api_internal':
                        api_count += 1

    print("=" * 80)
    print(" 📊 СВОДКА ПО КАТЕГОРИЯМ СТРОК:")
    print("=" * 80)
    print(f"  🔴 Реальные неадаптированные хардкоды в UI:   {real_hardcodes_count}")
    print(f"  🟢 Защищённые динамические фоллбеки (l10n):   {protected_count}")
    print(f"  ⚪ Словарные таблицы и карты переводов:       {dict_count}")
    print(f"  ⚙️ Внутренние ошибки сервисов и API:          {api_count}")
    print("=" * 80)
    print("\n")

    # Вывод только РЕАЛЬНЫХ хардкодов, требующих адаптации
    print("=" * 80)
    print(" 🔴 СПИСОК РЕАЛЬНЫХ НЕАДАПТИРОВАННЫХ ХАРДКОДОВ В UI (ТРЕБУЮТ ИСПРАВЛЕНИЯ):")
    print("=" * 80)

    unfixed_found = False
    for rel_path, items in sorted(results.items()):
        real_items = [r for r in items if r['category'] == 'real_hardcode']
        if not real_items:
            continue

        unfixed_found = True
        print(f"\n📁 [{rel_path}] — {len(real_items)} прямых хардкодов:")
        for item in real_items:
            print(f"  • Стр. {item['line_num']:<5} : \"{item['text']}\"")
            print(f"    Код: {item['line_content']}")

    if not unfixed_found:
        print("\n✅ Отлично! В UI нет ни одного незащищённого хардкода!")

    print("\n" + "=" * 80)
    print("🏁 Анализ завершён.")
    print("=" * 80)

if __name__ == '__main__':
    main()
