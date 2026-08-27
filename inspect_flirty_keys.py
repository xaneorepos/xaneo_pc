#!/usr/bin/env python3
import json

with open('/home/xaneodev/Загрузки/flirty_ru_lang.json', 'r', encoding='utf-8') as f:
    flirty = json.load(f)['strings']

print("Ключи со словом call:")
for k, v in flirty.items():
    if 'call' in k.lower():
        print(f"  {k}: {v}")

print("\nКлючи со словом chat / group / channel / archive / delete / save / attach:")
for k, v in flirty.items():
    if any(w in k.lower() for w in ['group', 'channel', 'archive', 'delete', 'saved', 'attach']):
        print(f"  {k}: {v}")
