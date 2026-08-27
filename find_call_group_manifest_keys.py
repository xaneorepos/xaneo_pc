#!/usr/bin/env python3
import json

with open('/home/xaneodev/xaneo_pc/assets/manifest.v1.json', 'r', encoding='utf-8') as f:
    manifest = json.load(f)['keys']

print("Ключи в манифесте со словом call:")
for k, v in manifest.items():
    if 'call' in k.lower():
        print(f"  {k}: {v.get('description', '')}")

print("\nКлючи в манифесте со словом group:")
for k, v in manifest.items():
    if 'creategroup' in k.lower() or 'editgroup' in k.lower():
        print(f"  {k}: {v.get('description', '')}")

print("\nКлючи в манифесте со словом channel:")
for k, v in manifest.items():
    if 'createchannel' in k.lower() or 'editchannel' in k.lower():
        print(f"  {k}: {v.get('description', '')}")
