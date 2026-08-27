#!/usr/bin/env python3
"""
Скрипт для поиска строк в модалках настроек и связанных модалках.
"""

import re
import os

target_files = [
    '/home/xaneodev/xaneo_pc/lib/widgets/xaneo_settings_modal.dart',
    '/home/xaneodev/xaneo_pc/lib/widgets/about_app_modal.dart',
    '/home/xaneodev/xaneo_pc/lib/widgets/email_verification_modal.dart',
    '/home/xaneodev/xaneo_pc/lib/widgets/tfa_verification_dialog.dart',
    '/home/xaneodev/xaneo_pc/lib/widgets/update_modal.dart',
    '/home/xaneodev/xaneo_pc/lib/widgets/create_options_modal.dart',
]

cyrillic_pattern = re.compile(r'[\u0400-\u04FF]')

for filepath in target_files:
    if not os.path.exists(filepath):
        continue
    print("=" * 80)
    print(f"📄 ФАЙЛ: {os.path.basename(filepath)}")
    print("=" * 80)
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    hardcodes = []
    for idx, line in enumerate(lines, 1):
        # Ищем строки с кириллицей в кавычках
        quotes = re.findall(r"'(.*?)'|\"(.*?)\"", line)
        for q in quotes:
            text = q[0] if q[0] else q[1]
            if cyrillic_pattern.search(text):
                # Проверяем окружение: защищено ли resolveByText или ?? '...'
                is_protected = ('resolveByText' in line) or ('??' in line) or ('get(' in line)
                if not is_protected:
                    hardcodes.append((idx, text, line.strip()))

    print(f"  Найдено незащищенных строк (без fallback / resolveByText): {len(hardcodes)}")
    for line_num, text, full_line in hardcodes[:15]:
        print(f"   L{line_num:4d}: \"{text}\" -> {full_line[:90]}")
    if len(hardcodes) > 15:
        print(f"   ... и ещё {len(hardcodes) - 15} строк")
    print()
