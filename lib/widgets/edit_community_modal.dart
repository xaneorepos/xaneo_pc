import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/community_settings_localizations.dart';
import '../services/api_service.dart';
import 'avatar_cropper.dart';
import 'base_custom_modal.dart';
import 'create_channel_modal.dart';
import 'create_group_modal.dart';

class EditChannelModal extends CreateChannelModal {
  final String chatId;
  final Map<String, dynamic> data;
  final List<dynamic> availableGroups;

  const EditChannelModal({
    super.key,
    required this.chatId,
    required this.data,
    this.availableGroups = const [],
  }) : super(isEditing: true, initialData: data);

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String chatId,
    required List<dynamic> availableGroups,
  }) async {
    final response = await ApiService().getCommunityDetails(
      chatId: chatId,
      isGroup: false,
    );
    if (!context.mounted || !response.success || response.data == null)
      return null;
    return BaseCustomModal.show<Map<String, dynamic>>(
      context: context,
      modal: EditChannelModal(
        chatId: chatId,
        data: response.data!,
        availableGroups: availableGroups,
      ),
    );
  }

  @override
  State<EditChannelModal> createState() => _EditChannelModalState();
}

class _EditChannelModalState extends BaseCustomModalState<EditChannelModal> {
  @override
  double get modalWidth => 520;
  @override
  double get modalHeightFactor => .8;

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController controller,
    bool isDark,
    double scale,
  ) => _CommunitySettingsForm(
    chatId: widget.chatId,
    data: widget.data,
    availableGroups: widget.availableGroups,
    isGroup: false,
    scrollController: controller,
    isDark: isDark,
    scale: scale,
  );
}

class EditGroupModal extends CreateGroupModal {
  final String chatId;
  final Map<String, dynamic> data;

  const EditGroupModal({super.key, required this.chatId, required this.data})
    : super(isEditing: true, initialData: data);

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String chatId,
  }) async {
    final response = await ApiService().getCommunityDetails(
      chatId: chatId,
      isGroup: true,
    );
    if (!context.mounted || !response.success || response.data == null)
      return null;
    return BaseCustomModal.show<Map<String, dynamic>>(
      context: context,
      modal: EditGroupModal(chatId: chatId, data: response.data!),
    );
  }

  @override
  State<EditGroupModal> createState() => _EditGroupModalState();
}

class _EditGroupModalState extends BaseCustomModalState<EditGroupModal> {
  @override
  double get modalWidth => 520;
  @override
  double get modalHeightFactor => .8;

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController controller,
    bool isDark,
    double scale,
  ) => _CommunitySettingsForm(
    chatId: widget.chatId,
    data: widget.data,
    isGroup: true,
    scrollController: controller,
    isDark: isDark,
    scale: scale,
  );
}

class _CommunitySettingsForm extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> data;
  final List<dynamic> availableGroups;
  final bool isGroup;
  final ScrollController scrollController;
  final bool isDark;
  final double scale;

  const _CommunitySettingsForm({
    required this.chatId,
    required this.data,
    required this.isGroup,
    required this.scrollController,
    required this.isDark,
    required this.scale,
    this.availableGroups = const [],
  });

  @override
  State<_CommunitySettingsForm> createState() => _CommunitySettingsFormState();
}

class _CommunitySettingsFormState extends State<_CommunitySettingsForm> {
  static const permissionLabelKeys = {
    'change-info': 'messenger.admin.changeInfo',
    'manage-admins': 'messenger.admin.manageAdmins',
    'manage-permissions': 'messenger.admin.managePermissions',
    'delete-messages': 'messenger.admin.deleteMessages',
    'ban-members': 'messenger.admin.banMembers',
    'post-messages': 'messenger.admin.postMessages',
  };
  static const reactionChoices = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🔥',
    '👏',
    '🎉',
    '🤔',
    '👎',
    '🤯',
    '🥰',
  ];

  late final TextEditingController name;
  late final TextEditingController username;
  late final TextEditingController description;
  late bool isPrivate;
  late bool callsEnabled;
  late Map<String, bool> permissions;
  late bool reactionsEnabled;
  late Set<String> reactions;
  late bool slowEnabled;
  late int slowSeconds;
  late bool adminsException;
  late bool verifiedException;
  String? discussionId;
  File? avatarFile;
  bool saving = false;
  String? error;

  CommunitySettingsLocalizations get l10n =>
      CommunitySettingsLocalizations.of(context);

  bool get isCreator =>
      widget.data['is_creator'] == true || widget.data['is_owner'] == true;
  bool get canManage => isCreator || permissions['manage-permissions'] == true;

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    name = TextEditingController(text: data['name']?.toString() ?? '');
    username = TextEditingController(text: data['username']?.toString() ?? '');
    description = TextEditingController(
      text: data['description']?.toString() ?? '',
    );
    isPrivate = data['privacy'] == 'private';
    callsEnabled = data['group_calls_enabled'] == true;
    final rawPerms = data['admin_permissions'] is Map
        ? Map<String, dynamic>.from(data['admin_permissions'] as Map)
        : <String, dynamic>{};
    permissions = {
      for (final key in permissionLabelKeys.keys) key: rawPerms[key] != false,
    };
    final advanced = data['advanced_settings'] is Map
        ? Map<String, dynamic>.from(data['advanced_settings'] as Map)
        : <String, dynamic>{};
    reactionsEnabled = advanced['reactions_enabled'] != false;
    reactions = Set<String>.from(
      (advanced['allowed_reactions'] is List
              ? advanced['allowed_reactions'] as List
              : const ['👍', '❤️', '😂', '😮'])
          .map((e) => e.toString()),
    );
    final slow = advanced['slow_mode'] is Map
        ? Map<String, dynamic>.from(advanced['slow_mode'] as Map)
        : <String, dynamic>{};
    slowEnabled = slow['enabled'] == true;
    slowSeconds =
        int.tryParse(slow['duration_seconds']?.toString() ?? '') ?? 60;
    final exceptions = slow['exceptions'] is Map
        ? Map<String, dynamic>.from(slow['exceptions'] as Map)
        : <String, dynamic>{};
    adminsException = exceptions['admins'] != false;
    verifiedException = exceptions['verified'] == true;
    discussionId = data['discussion_group_id']?.toString();
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null || !mounted) return;
    final cropped = await AvatarCropper.show(
      context,
      File(result.files.single.path!),
    );
    if (cropped != null && mounted) setState(() => avatarFile = cropped);
  }

  Future<void> save() async {
    final cleanName = name.text.trim();
    final cleanUsername = username.text.trim().replaceAll('@', '');
    if (cleanName.isEmpty || (!isPrivate && cleanUsername.isEmpty)) {
      setState(
        () => error = cleanName.isEmpty
            ? l10n.text('messenger.editChat.nameRequired')
            : l10n.text('messenger.editChat.publicNicknameRequired'),
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final advanced = widget.isGroup
        ? {
            'admin_permissions': permissions,
            'slow_mode': {
              'enabled': slowEnabled,
              'duration_seconds': slowSeconds,
              'exceptions': {
                'admins': adminsException,
                'verified': verifiedException,
                'custom_list': const <dynamic>[],
              },
            },
          }
        : {
            'reactions_enabled': reactionsEnabled,
            'allowed_reactions': reactions.toList(),
          };
    final payload = <String, dynamic>{
      'name': cleanName,
      'description': description.text.trim(),
      'privacy': isPrivate ? 'private' : 'public',
      if (!isPrivate) 'username': cleanUsername,
      if (isCreator) 'admin_permissions': jsonEncode(permissions),
      if (canManage) 'advanced_settings': jsonEncode(advanced),
      if (widget.isGroup) 'group_calls_enabled': callsEnabled,
      if (!widget.isGroup) 'discussion_group_id': discussionId ?? '',
    };
    final response = await ApiService().updateCommunity(
      chatId: widget.chatId,
      isGroup: widget.isGroup,
      data: payload,
      avatarFile: avatarFile,
    );
    if (!mounted) return;
    if (!response.success || response.data == null) {
      setState(() {
        saving = false;
        error = response.error ?? l10n.text('messenger.editChat.saveFailed');
      });
      return;
    }
    Navigator.of(context).pop(response.data);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final primary = widget.isDark ? Colors.white : Colors.black;
    return ListView(
      controller: widget.scrollController,
      children: [
        Text(
          l10n.text(
            widget.isGroup
                ? 'messenger.editChat.settingsGroup'
                : 'messenger.editChat.settingsChannel',
          ),
          style: TextStyle(
            fontSize: 18 * s,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        SizedBox(height: 18 * s),
        if (error != null)
          Container(
            padding: EdgeInsets.all(12 * s),
            margin: EdgeInsets.only(bottom: 14 * s),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(9 * s),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        _identity(),
        _field(
          l10n.text('messenger.editChat.description'),
          description,
          maxLength: 500,
          maxLines: 3,
        ),
        _title(l10n.text('messenger.editChat.type')),
        _privacyChooser(),
        if (!isPrivate)
          _field(
            l10n.text('messenger.editChat.nickname'),
            username,
            maxLength: 50,
            prefix: '@',
          ),
        if (isPrivate &&
            (widget.data['invite_link']?.toString().isNotEmpty ?? false))
          _readonly(
            l10n.text('messenger.editChat.inviteLink'),
            'xaneo.ru/${widget.data['invite_link']}',
          ),
        if (widget.isGroup) ...[
          _title(l10n.text('messenger.editChat.groupCalls')),
          _switch(
            title: l10n.text(
              callsEnabled
                  ? 'messenger.common.enabledPlural'
                  : 'messenger.common.disabledPlural',
            ),
            subtitle: l10n.text('messenger.editChat.groupCallsDesc'),
            icon: Icons.phone_rounded,
            value: callsEnabled,
            onChanged: (v) => setState(() => callsEnabled = v),
          ),
        ] else ...[
          _title(l10n.text('messenger.editChat.discussionGroup')),
          DropdownButtonFormField<String>(
            initialValue:
                widget.availableGroups.any((g) => _groupId(g) == discussionId)
                ? discussionId
                : null,
            decoration: _decoration(l10n.text('messenger.editChat.notLinked')),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(l10n.text('messenger.editChat.notLinked')),
              ),
              ...widget.availableGroups.map(
                (g) => DropdownMenuItem<String>(
                  value: _groupId(g),
                  child: Text(_groupName(g)),
                ),
              ),
            ],
            onChanged: (v) => setState(() => discussionId = v),
          ),
        ],
        if (canManage || isCreator) _adminPermissions(),
        if (!widget.isGroup && canManage) _reactionSettings(),
        if (widget.isGroup && canManage) _slowSettings(),
        SizedBox(height: 24 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: Text(l10n.text('common.cancel')),
            ),
            SizedBox(width: 8 * s),
            FilledButton(
              onPressed: saving ? null : save,
              child: saving
                  ? SizedBox(
                      width: 16 * s,
                      height: 16 * s,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.text('common.save')),
            ),
          ],
        ),
        SizedBox(height: 8 * s),
      ],
    );
  }

  String _groupId(dynamic group) =>
      (group is Map ? group['chat_id'] ?? group['id'] : '')
          .toString()
          .replaceFirst('group_', '');
  String _groupName(dynamic group) =>
      (group is Map
              ? group['group_name'] ?? group['name'] ?? group['chat_name']
              : '')
          .toString();

  Widget _identity() {
    final avatar = widget.data['avatar_url']?.toString();
    return Row(
      children: [
        GestureDetector(
          onTap: pickAvatar,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 34 * widget.scale,
                  backgroundColor: widget.isDark
                      ? const Color(0xFF242428)
                      : const Color(0xFFE4E4E7),
                  backgroundImage: avatarFile != null
                      ? FileImage(avatarFile!)
                      : (avatar != null && avatar.isNotEmpty
                                ? NetworkImage(avatar)
                                : null)
                            as ImageProvider?,
                  child:
                      avatarFile == null && (avatar == null || avatar.isEmpty)
                      ? FaIcon(
                          widget.isGroup
                              ? FontAwesomeIcons.users
                              : FontAwesomeIcons.bullhorn,
                          color: widget.isDark
                              ? Colors.white54
                              : Colors.black54,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 10 * widget.scale,
                    backgroundColor: widget.isDark
                        ? Colors.white
                        : Colors.black,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 11 * widget.scale,
                      color: widget.isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 14 * widget.scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.text(
                  widget.isGroup
                      ? 'messenger.editChat.groupName'
                      : 'messenger.editChat.channelName',
                ),
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 6 * widget.scale),
              TextField(
                controller: name,
                maxLength: 100,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 14 * widget.scale,
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontFamily: 'Inter',
                ),
                decoration:
                    _decoration(
                      l10n.text('messenger.editChat.namePlaceholder'),
                    ).copyWith(
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14 * widget.scale,
                        vertical: 12 * widget.scale,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    hintText: label,
    hintStyle: TextStyle(
      fontSize: 13 * widget.scale,
      color: widget.isDark ? Colors.white30 : Colors.black38,
    ),
    filled: true,
    fillColor: widget.isDark ? const Color(0xFF18181B) : Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8 * widget.scale),
      borderSide: BorderSide(
        color: widget.isDark
            ? const Color(0xFF242428)
            : const Color(0xFFE4E4E7),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8 * widget.scale),
      borderSide: BorderSide(
        color: widget.isDark ? Colors.white54 : Colors.black54,
      ),
    ),
  );
  Widget _field(
    String label,
    TextEditingController controller, {
    int? maxLength,
    int maxLines = 1,
    String? prefix,
  }) => Padding(
    padding: EdgeInsets.only(top: 16 * widget.scale),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12 * widget.scale,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white54 : Colors.black54,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 6 * widget.scale),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            fontSize: 14 * widget.scale,
            color: widget.isDark ? Colors.white : Colors.black,
            fontFamily: 'Inter',
          ),
          decoration: _decoration(label).copyWith(
            prefixText: prefix,
            counterText: maxLength == null
                ? null
                : '${controller.text.length}/$maxLength',
            contentPadding: EdgeInsets.all(14 * widget.scale),
          ),
        ),
      ],
    ),
  );

  Widget _privacyChooser() => Row(
    children: [
      Expanded(
        child: _privacyOption(
          selected: !isPrivate,
          title: l10n.text('messenger.editChat.public'),
          subtitle: widget.isGroup
              ? l10n.text('messenger.editChat.publicJoin')
              : l10n.text('messenger.editChat.publicSubscribe'),
          icon: Icons.public_rounded,
          onTap: () => setState(() => isPrivate = false),
        ),
      ),
      SizedBox(width: 10 * widget.scale),
      Expanded(
        child: _privacyOption(
          selected: isPrivate,
          title: l10n.text('messenger.editChat.private'),
          subtitle: l10n.text('messenger.editChat.inviteOnly'),
          icon: Icons.lock_outline_rounded,
          onTap: () => setState(() => isPrivate = true),
        ),
      ),
    ],
  );

  Widget _privacyOption({
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(12 * widget.scale),
        decoration: BoxDecoration(
          color: selected
              ? (widget.isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE4E4E7))
              : (widget.isDark
                    ? const Color(0xFF141416)
                    : const Color(0xFFF4F4F5)),
          borderRadius: BorderRadius.circular(8 * widget.scale),
          border: Border.all(
            color: selected
                ? (widget.isDark ? Colors.white : Colors.black)
                : (widget.isDark
                      ? const Color(0xFF242428)
                      : const Color(0xFFE4E4E7)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18 * widget.scale,
              color: selected
                  ? (widget.isDark ? Colors.white : Colors.black)
                  : (widget.isDark ? Colors.white38 : Colors.black38),
            ),
            SizedBox(width: 10 * widget.scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13 * widget.scale,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5 * widget.scale,
                      color: widget.isDark ? Colors.white54 : Colors.black54,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _title(String value) => Padding(
    padding: EdgeInsets.only(top: 22 * widget.scale, bottom: 7 * widget.scale),
    child: Text(
      value,
      style: TextStyle(
        fontSize: 13 * widget.scale,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: 12 * widget.scale,
      vertical: 8 * widget.scale,
    ),
    decoration: BoxDecoration(
      color: widget.isDark ? const Color(0xFF141416) : const Color(0xFFF4F4F5),
      borderRadius: BorderRadius.circular(8 * widget.scale),
      border: Border.all(
        color: widget.isDark
            ? const Color(0xFF242428)
            : const Color(0xFFE4E4E7),
      ),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18 * widget.scale,
          color: widget.isDark ? Colors.white54 : Colors.black54,
        ),
        SizedBox(width: 10 * widget.scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13 * widget.scale,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11 * widget.scale,
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
  Widget _readonly(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: SelectableText(value),
  );

  Widget _adminPermissions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(l10n.text('messenger.admin.permissions')),
      ...permissionLabelKeys.entries
          .where((e) => !widget.isGroup || e.key != 'post-messages')
          .map(
            (e) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l10n.text(e.value)),
              value: permissions[e.key],
              onChanged: isCreator
                  ? (v) => setState(() => permissions[e.key] = v ?? false)
                  : null,
            ),
          ),
    ],
  );

  Widget _reactionSettings() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(l10n.text('messenger.reactions.title')),
      _switch(
        title: l10n.text(
          reactionsEnabled
              ? 'messenger.common.enabledPlural'
              : 'messenger.common.disabledPlural',
        ),
        subtitle: l10n.text('messenger.reactions.choose'),
        icon: Icons.add_reaction_outlined,
        value: reactionsEnabled,
        onChanged: (v) => setState(() => reactionsEnabled = v),
      ),
      if (reactionsEnabled)
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: reactionChoices
              .map(
                (emoji) => FilterChip(
                  label: Text(
                    emoji,
                    style: TextStyle(fontSize: 19 * widget.scale),
                  ),
                  selected: reactions.contains(emoji),
                  onSelected: (v) => setState(
                    () => v ? reactions.add(emoji) : reactions.remove(emoji),
                  ),
                ),
              )
              .toList(),
        ),
    ],
  );

  Widget _slowSettings() {
    const presets = [5, 10, 30, 60, 300, 900, 3600];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(l10n.text('messenger.slowMode.title')),
        _switch(
          title: l10n.text(
            slowEnabled
                ? 'messenger.common.enabled'
                : 'messenger.common.disabled',
          ),
          subtitle: l10n.text('messenger.slowMode.interval'),
          icon: Icons.schedule_rounded,
          value: slowEnabled,
          onChanged: (v) => setState(() => slowEnabled = v),
        ),
        if (slowEnabled) ...[
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: presets
                .map(
                  (e) => ChoiceChip(
                    label: Text(l10n.duration(e)),
                    selected: slowSeconds == e,
                    onSelected: (_) => setState(() => slowSeconds = e),
                  ),
                )
                .toList(),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.text('messenger.slowMode.admins')),
            value: adminsException,
            onChanged: (v) => setState(() => adminsException = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.text('messenger.slowMode.verified')),
            value: verifiedException,
            onChanged: (v) => setState(() => verifiedException = v ?? false),
          ),
        ],
      ],
    );
  }
}
