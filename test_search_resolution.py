#!/usr/bin/env python3
import json

manifest_keys_map = {
    'header': ['messenger.search', 'common.search', 'header.search'],
    'hint': ['messenger.searchPlaceholder', 'messenger.search', 'common.search'],
    'all': ['common.all', 'messenger.search.all'],
    'users': ['messenger.search.users', 'messenger.chatInfo.user', 'common.users'],
    'groups': ['messenger.chatInfo.groupTitle', 'messenger.createGroup.title', 'common.group'],
    'channels': ['messenger.chatInfo.channelTitle', 'messenger.createChannel.title', 'common.channel'],
    'bots': ['messenger.status.bot', 'common.bots'],
    'favorites': ['messenger.favorites.title', 'messenger.savedMessages', 'header.savedMessages'],
    'empty_query': ['messenger.search.emptyQuery', 'messenger.searchPlaceholder'],
    'nothing_found': ['messenger.search.nothingFound', 'common.nothingFound'],
    'sec_favorites': ['messenger.favorites.title', 'messenger.savedMessages'],
    'sec_bots': ['messenger.status.bot', 'common.bots'],
    'sec_channels': ['messenger.chatInfo.channelTitle', 'messenger.createChannel.title'],
    'sec_groups': ['messenger.chatInfo.groupTitle', 'messenger.createGroup.title'],
    'sec_users': ['messenger.search.users', 'messenger.chatInfo.user'],
    'saved_sub': ['messenger.favorites.emptyDesc', 'messenger.savedMessages.desc'],
    'bot_label': ['messenger.status.bot', 'common.bot'],
    'group_label': ['messenger.chatInfo.groupTitle', 'common.group'],
    'channel_label': ['messenger.chatInfo.channelTitle', 'common.channel'],
}

candidate_files = [
    '/home/xaneodev/tsukishiro_agent_lang.json',
    '/home/xaneodev/Загрузки/flirty_ru_lang.json',
    '/home/xaneodev/dorevolyucionnyj_lang.json',
]

for filepath in candidate_files:
    print("=" * 80)
    print(f"🔍 ТЕСТ ПОИСКА В PC ДЛЯ: {filepath.split('/')[-1]}")
    print("=" * 80)
    with open(filepath, 'r', encoding='utf-8') as f:
        pack = json.load(f)['strings']

    for k, candidates in manifest_keys_map.items():
        val = None
        m_k = None
        for c in candidates:
            if c in pack:
                val = pack[c]
                m_k = c
                break
        print(f"  [{k:<18}] -> \"{val}\" (по ключу: {m_k})")
    print("\n")
