#!/usr/bin/env python3
"""
Find all AppLocalizations getters used in xaneo_settings_modal.dart
"""
import re

with open('/home/xaneodev/xaneo_pc/lib/widgets/xaneo_settings_modal.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Look for l10n?.<getter> or AppLocalizations.of(context)?.<getter>
matches = set(re.findall(r'(?:l10n\?|AppLocalizations\.of\(context\)\?)\.([a-zA-Z0-9_]+)', content))
print(f"Found {len(matches)} getters in xaneo_settings_modal.dart:")
for g in sorted(matches):
    print(f"  {g}")
