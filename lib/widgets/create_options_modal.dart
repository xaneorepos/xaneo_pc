import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'base_custom_modal.dart';
import 'create_channel_modal.dart';
import 'create_group_modal.dart';

/// Desktop-модалка выбора варианта создания (Личный чат, Группа, Канал)
class CreateOptionsModal extends BaseCustomModal {
  final VoidCallback onSelectPersonalChat;

  const CreateOptionsModal({
    super.key,
    required this.onSelectPersonalChat,
    super.modalTag = 'СОЗДАНИЕ',
    super.title = 'СОЗДАТЬ НОВУЮ БЕСЕДУ',
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onSelectPersonalChat,
  }) {
    return BaseCustomModal.show(
      context: context,
      modal: CreateOptionsModal(
        onSelectPersonalChat: onSelectPersonalChat,
      ),
    );
  }

  @override
  State<CreateOptionsModal> createState() => _CreateOptionsModalState();
}

class _CreateOptionsModalState extends BaseCustomModalState<CreateOptionsModal> {
  @override
  double get modalWidth => 460.0;

  @override
  String getModalTitle(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    return _OptionsL10n.get('header', lang).toUpperCase();
  }

  @override
  Widget buildContent(BuildContext context, ScrollController scrollController, bool isDark, double scale) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _OptionsL10n.get('title', lang),
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 16 * scale),

          // Option 1: Personal Chat
          _buildOptionTile(
            context: context,
            isDark: isDark,
            scale: scale,
            icon: FontAwesomeIcons.solidComment,
            iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            title: _OptionsL10n.get('personal_chat_title', lang),
            subtitle: _OptionsL10n.get('personal_chat_sub', lang),
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelectPersonalChat();
            },
          ),

          SizedBox(height: 10 * scale),

          // Option 2: Group Chat
          _buildOptionTile(
            context: context,
            isDark: isDark,
            scale: scale,
            icon: FontAwesomeIcons.users,
            iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
            title: _OptionsL10n.get('group_title', lang),
            subtitle: _OptionsL10n.get('group_sub', lang),
            onTap: () {
              Navigator.of(context).pop();
              CreateGroupModal.show(context: context);
            },
          ),

          SizedBox(height: 10 * scale),

          // Option 3: Channel
          _buildOptionTile(
            context: context,
            isDark: isDark,
            scale: scale,
            icon: FontAwesomeIcons.bullhorn,
            iconColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
            title: _OptionsL10n.get('channel_title', lang),
            subtitle: _OptionsL10n.get('channel_sub', lang),
            onTap: () {
              Navigator.of(context).pop();
              CreateChannelModal.show(context: context);
            },
          ),

          SizedBox(height: 8 * scale),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required bool isDark,
    required double scale,
    required dynamic icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final tileBg = isDark ? const Color(0xFF141416) : const Color(0xFFF4F4F5);
    final hoverBg = isDark ? const Color(0xFF1F1F23) : const Color(0xFFE4E4E7);
    final borderColor = isDark ? const Color(0xFF242428) : const Color(0xFFE4E4E7);

    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setTileState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setTileState(() => isHovered = true),
          onExit: (_) => setTileState(() => isHovered = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.all(14 * scale),
              decoration: BoxDecoration(
                color: isHovered ? hoverBg : tileBg,
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42 * scale,
                    height: 42 * scale,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    child: Center(
                      child: icon is IconData
                          ? Icon(
                              icon,
                              size: 18 * scale,
                              color: iconColor,
                            )
                          : FaIcon(
                              icon as FaIconData,
                              size: 18 * scale,
                              color: iconColor,
                            ),
                    ),
                  ),
                  SizedBox(width: 14 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20 * scale,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OptionsL10n {
  static const Map<String, Map<String, String>> _map = {
    'ru': {
      'header': 'СОЗДАНИЕ',
      'title': 'Начать новую беседу',
      'personal_chat_title': 'Личный чат',
      'personal_chat_sub': 'Начать общение с пользователем',
      'group_title': 'Создать группу',
      'group_sub': 'Групповой чат для общения нескольких участников',
      'channel_title': 'Создать канал',
      'channel_sub': 'Канал для публикаций широкой аудитории',
    },
    'en': {
      'header': 'CREATE',
      'title': 'Start new conversation',
      'personal_chat_title': 'Personal Chat',
      'personal_chat_sub': 'Start messaging with another user',
      'group_title': 'Create Group',
      'group_sub': 'Group chat for multi-user discussions',
      'channel_title': 'Create Channel',
      'channel_sub': 'Broadcasting channel for a wide audience',
    },
    'es': {
      'header': 'CREAR',
      'title': 'Iniciar nueva conversación',
      'personal_chat_title': 'Chat personal',
      'personal_chat_sub': 'Enviar mensajes a otro usuario',
      'group_title': 'Crear grupo',
      'group_sub': 'Chat grupal para múltiples participantes',
      'channel_title': 'Crear canal',
      'channel_sub': 'Canal de difusión para gran audiencia',
    },
    'fr': {
      'header': 'CRÉER',
      'title': 'Démarrer une nouvelle discussion',
      'personal_chat_title': 'Discussion privée',
      'personal_chat_sub': 'Envoyer un message à un utilisateur',
      'group_title': 'Créer un groupe',
      'group_sub': 'Discussion de groupe pour plusieurs personnes',
      'channel_title': 'Créer une chaîne',
      'channel_sub': 'Chaîne de diffusion pour une large audience',
    },
    'ar': {
      'header': 'إنشاء',
      'title': 'بدء محادثة جديدة',
      'personal_chat_title': 'محادثة خاصة',
      'personal_chat_sub': 'بدء المحادثة مع مستخدم آخر',
      'group_title': 'إنشاء مجموعة',
      'group_sub': 'محادثة جماعية للمناقشات متعددة الأعضاء',
      'channel_title': 'إنشاء قناة',
      'channel_sub': 'قناة بث للجمهور العريض',
    },
    'ja': {
      'header': '作成',
      'title': '新しい会話を開始',
      'personal_chat_title': 'ダイレクトチャット',
      'personal_chat_sub': 'ユーザーと個別にメッセージを送受信',
      'group_title': 'グループを作成',
      'group_sub': '複数メンバーでのグループチャット',
      'channel_title': 'チャンネルを作成',
      'channel_sub': '大規模な受講者に向けた配信チャンネル',
    },
    'ko': {
      'header': '만들기',
      'title': '새 대화 시작',
      'personal_chat_title': '개인 대화',
      'personal_chat_sub': '다른 사용자와 1:1 대화 시작',
      'group_title': '그룹 만들기',
      'group_sub': '여러 참가자와의 그룹 대화방',
      'channel_title': '채널 만들기',
      'channel_sub': '광범위한 청중을 위한 방송 채널',
    },
    'zh': {
      'header': '创建',
      'title': '发起新对话',
      'personal_chat_title': '私聊',
      'personal_chat_sub': '与指定用户发起一对一聊天',
      'group_title': '创建群组',
      'group_sub': '多人讨论交流的群聊',
      'channel_title': '创建频道',
      'channel_sub': '面向广大受众的广播频道',
    },
  };

  static String get(String key, String lang) {
    final l = _map.containsKey(lang) ? lang : 'en';
    return _map[l]?[key] ?? _map['en']?[key] ?? key;
  }
}
