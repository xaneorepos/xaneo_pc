#!/usr/bin/env python3
import json

manifest_keys_map = {
    'create_channel_tag': ['messenger.createChannel.title', 'messenger.chatInfo.channelTitle', 'common.channel'],
    'create_group_tag': ['messenger.createGroup.title', 'messenger.chatInfo.groupTitle', 'common.group'],
    'edit_channel_tag': ['messenger.editChat.editChannelTitle', 'messenger.context.editChannel'],
    'edit_group_tag': ['messenger.editChat.editGroupTitle', 'messenger.context.editGroup'],
    'title_create_channel': ['messenger.createChannel.title'],
    'title_create_group': ['messenger.createGroup.title'],
    'title_edit_channel': ['messenger.editChat.editChannelTitle', 'messenger.context.editChannel'],
    'title_edit_group': ['messenger.editChat.editGroupTitle', 'messenger.context.editGroup'],
    'label_channel_name': ['messenger.createChannel.name'],
    'label_group_name': ['messenger.createGroup.name'],
    'hint_channel_name': ['messenger.createChannel.namePlaceholder'],
    'hint_group_name': ['messenger.createGroup.namePlaceholder'],
    'label_privacy': ['messenger.createChannel.type', 'messenger.createGroup.type'],
    'privacy_public_title': ['messenger.createChannel.public', 'messenger.createGroup.public'],
    'privacy_public_sub': ['messenger.createChannel.typeDescription', 'messenger.createGroup.typeDescription'],
    'privacy_private_title': ['messenger.createChannel.private', 'messenger.createGroup.private'],
    'label_link': ['messenger.createChannel.nickname', 'messenger.createGroup.nickname'],
    'hint_username': ['messenger.createChannel.nicknamePlaceholder', 'messenger.createGroup.nicknamePlaceholder'],
    'label_description': ['messenger.createChannel.description', 'messenger.createGroup.description'],
    'hint_description': ['messenger.createChannel.descriptionPlaceholder', 'messenger.createGroup.descriptionPlaceholder'],
    'cancel': ['messenger.delete.buttons.cancel', 'common.cancel'],
    'create': ['messenger.createChannel.title', 'messenger.createGroup.title', 'common.create'],
    'save': ['messenger.editChat.editGroupTitle', 'common.save'],
}

ru_map = {
    'create_channel_tag': 'КАНАЛ',
    'create_group_tag': 'ГРУППА',
    'edit_channel_tag': 'РЕДАКТИРОВАНИЕ КАНАЛА',
    'edit_group_tag': 'РЕДАКТИРОВАНИЕ ГРУППЫ',
    'title_create_channel': 'Создание канала',
    'title_create_group': 'Создание группы',
    'title_edit_channel': 'Редактировать канал',
    'title_edit_group': 'Редактировать группу',
    'label_channel_name': 'Название канала',
    'label_group_name': 'Название группы',
    'hint_channel_name': 'Например, Новости Xaneo',
    'hint_group_name': 'Например, Команда разработчиков',
    'label_privacy': 'Тип',
    'privacy_public_title': 'Публичный',
    'privacy_public_sub': 'Доступен по ссылке',
    'privacy_private_title': 'Частный',
    'label_link': 'Публичная ссылка (@tag)',
    'hint_username': 'укажите_ссылку',
    'label_description': 'Описание (необязательно)',
    'hint_description': 'Расскажите о вашей группе или канале...',
    'cancel': 'Отмена',
    'create': 'Создать',
    'save': 'Сохранить',
}

packs = [
    '/home/xaneodev/tsukishiro_agent_lang.json',
    '/home/xaneodev/Загрузки/flirty_ru_lang.json',
]

for p in packs:
    print("=" * 80)
    print(f"ТЕСТ МОДАЛКИ КАНАЛОВ/ГРУПП ДЛЯ: {p.split('/')[-1]}")
    print("=" * 80)
    with open(p, 'r', encoding='utf-8') as f:
        strings = json.load(f)['strings']

    def resolve(k):
        for mk in manifest_keys_map.get(k, []):
            if mk in strings:
                return strings[mk], mk
        # fallback resolve by text
        ru_val = ru_map.get(k, '')
        return ru_val, 'default'

    for k in ru_map.keys():
        res, src = resolve(k)
        print(f"  [{k:<22}] -> \"{res}\" (от: {src})")
    print("\n")
