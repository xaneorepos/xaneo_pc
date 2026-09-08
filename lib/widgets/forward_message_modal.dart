import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../services/runtime_translations.dart';
import 'base_custom_modal.dart';

typedef ForwardTargetLoader = Future<List<Map<String, dynamic>>> Function();
typedef ForwardTargetHandler =
    Future<void> Function(Map<String, dynamic> target, bool showAttribution);

class ForwardMessageModal extends BaseCustomModal {
  final ForwardTargetLoader loadTargets;
  final ForwardTargetHandler onForward;

  const ForwardMessageModal({
    super.key,
    required this.loadTargets,
    required this.onForward,
  });

  static Future<void> show({
    required BuildContext context,
    required ForwardTargetLoader loadTargets,
    required ForwardTargetHandler onForward,
  }) {
    return BaseCustomModal.show<void>(
      context: context,
      barrierLabel: ForwardModalStrings.of(context).title,
      modal: ForwardMessageModal(
        loadTargets: loadTargets,
        onForward: onForward,
      ),
    );
  }

  @override
  State<ForwardMessageModal> createState() => _ForwardMessageModalState();
}

class _ForwardMessageModalState
    extends BaseCustomModalState<ForwardMessageModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _targets = const [];
  bool _showAttribution = true;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  double get modalWidth => 480;

  @override
  double get modalHeightFactor => 0.76;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final targets = await widget.loadTargets();
      if (!mounted) return;
      setState(() {
        _targets = targets;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ForwardModalStrings.of(context).loadError;
      });
    }
  }

  Future<void> _select(Map<String, dynamic> target) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await widget.onForward(target, _showAttribution);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = ForwardModalStrings.of(context).sendError;
      });
    }
  }

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final strings = ForwardModalStrings.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? _targets
        : _targets.where((target) {
            final name = (target['chat_display_name'] ?? '').toString();
            return name.toLowerCase().contains(query);
          }).toList();
    final primary = isDark ? Colors.white : const Color(0xFF171717);
    final secondary = isDark ? Colors.white60 : Colors.black54;
    final fill = isDark ? const Color(0xFF181818) : const Color(0xFFF4F4F5);
    final outline = isDark ? const Color(0xFF303030) : const Color(0xFFE1E1E3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.title,
          style: TextStyle(
            color: primary,
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16 * scale),
        TextField(
          controller: _searchController,
          enabled: !_sending,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: primary, fontSize: 14 * scale),
          decoration: InputDecoration(
            hintText: strings.search,
            hintStyle: TextStyle(color: secondary),
            prefixIcon: Icon(Icons.search_rounded, color: secondary),
            filled: true,
            fillColor: fill,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: primary, width: 1.2),
            ),
          ),
        ),
        SizedBox(height: 12 * scale),
        Semantics(
          label: strings.showAuthor,
          toggled: _showAttribution,
          child: InkWell(
            onTap: _sending
                ? null
                : () => setState(() => _showAttribution = !_showAttribution),
            borderRadius: BorderRadius.circular(10 * scale),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8 * scale),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.showAuthor,
                      style: TextStyle(color: primary, fontSize: 14 * scale),
                    ),
                  ),
                  Switch.adaptive(
                    value: _showAttribution,
                    activeThumbColor: primary,
                    activeTrackColor: primary.withValues(alpha: 0.28),
                    onChanged: _sending
                        ? null
                        : (value) => setState(() => _showAttribution = value),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(color: outline, height: 1),
        SizedBox(height: 8 * scale),
        if (_error != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8 * scale),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: const Color(0xFFDC2626),
                      fontSize: 13 * scale,
                    ),
                  ),
                ),
                if (!_sending)
                  TextButton(onPressed: _load, child: Text(strings.retry)),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : visible.isEmpty
              ? Center(
                  child: Text(
                    strings.empty,
                    style: TextStyle(color: secondary),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => SizedBox(height: 2 * scale),
                  itemBuilder: (context, index) {
                    final target = visible[index];
                    final name = (target['chat_display_name'] ?? '').toString();
                    final type = (target['chat_type'] ?? '').toString();
                    return ListTile(
                      enabled: !_sending,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4 * scale,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                      ),
                      leading: _ForwardAvatar(target: target, size: 42 * scale),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primary,
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        strings.chatType(type),
                        style: TextStyle(
                          color: secondary,
                          fontSize: 12 * scale,
                        ),
                      ),
                      trailing: _sending
                          ? SizedBox(
                              width: 16 * scale,
                              height: 16 * scale,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                      onTap: () => _select(target),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ForwardAvatar extends StatelessWidget {
  final Map<String, dynamic> target;
  final double size;

  const _ForwardAvatar({required this.target, required this.size});

  @override
  Widget build(BuildContext context) {
    final name = (target['chat_display_name'] ?? '').toString();
    final type = (target['chat_type'] ?? '').toString();
    final rawUrl = target['avatar_url']?.toString();
    final url = _absoluteUrl(rawUrl);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.09),
      ),
      child: Center(
        child: type == 'favorites'
            ? Icon(Icons.bookmark_rounded, size: size * 0.46)
            : Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );

    if (url == null) return SizedBox.square(dimension: size, child: fallback);
    final isSvg =
        Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') == true;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: isSvg
            ? SvgPicture.network(
                url,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => fallback,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }

  String? _absoluteUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    final base = Uri.parse(ApiService.baseUrl);
    return base
        .replace(path: value.startsWith('/') ? value : '/$value', query: null)
        .toString();
  }
}

class ForwardModalStrings {
  final BuildContext context;
  const ForwardModalStrings._(this.context);

  static ForwardModalStrings of(BuildContext context) =>
      ForwardModalStrings._(context);

  static const _values = <String, Map<String, String>>{
    'ru': {
      'title': 'Переслать сообщение',
      'search': 'Поиск чатов',
      'showAuthor': 'Показывать автора',
      'personal': 'Личный чат',
      'group': 'Группа',
      'channel': 'Канал',
      'favorites': 'Избранное',
      'empty': 'Нет доступных чатов',
      'loadError': 'Не удалось загрузить чаты',
      'sendError': 'Не удалось переслать сообщение',
      'retry': 'Повторить',
      'forwardedFrom': 'переслано от',
    },
    'en': {
      'title': 'Forward message',
      'search': 'Search chats',
      'showAuthor': 'Show author',
      'personal': 'Personal chat',
      'group': 'Group',
      'channel': 'Channel',
      'favorites': 'Saved messages',
      'empty': 'No available chats',
      'loadError': 'Could not load chats',
      'sendError': 'Could not forward message',
      'retry': 'Retry',
      'forwardedFrom': 'forwarded from',
    },
    'fr': {
      'title': 'Transférer le message',
      'search': 'Rechercher des discussions',
      'showAuthor': 'Afficher l’auteur',
      'personal': 'Discussion privée',
      'group': 'Groupe',
      'channel': 'Canal',
      'favorites': 'Messages enregistrés',
      'empty': 'Aucune discussion disponible',
      'loadError': 'Impossible de charger les discussions',
      'sendError': 'Impossible de transférer le message',
      'retry': 'Réessayer',
      'forwardedFrom': 'transféré de',
    },
    'es': {
      'title': 'Reenviar mensaje',
      'search': 'Buscar chats',
      'showAuthor': 'Mostrar autor',
      'personal': 'Chat personal',
      'group': 'Grupo',
      'channel': 'Canal',
      'favorites': 'Mensajes guardados',
      'empty': 'No hay chats disponibles',
      'loadError': 'No se pudieron cargar los chats',
      'sendError': 'No se pudo reenviar el mensaje',
      'retry': 'Reintentar',
      'forwardedFrom': 'reenviado de',
    },
    'zh': {
      'title': '转发消息',
      'search': '搜索聊天',
      'showAuthor': '显示作者',
      'personal': '私聊',
      'group': '群组',
      'channel': '频道',
      'favorites': '收藏',
      'empty': '没有可用聊天',
      'loadError': '无法加载聊天',
      'sendError': '无法转发消息',
      'retry': '重试',
      'forwardedFrom': '转发自',
    },
    'ja': {
      'title': 'メッセージを転送',
      'search': 'チャットを検索',
      'showAuthor': '送信者を表示',
      'personal': '個人チャット',
      'group': 'グループ',
      'channel': 'チャンネル',
      'favorites': '保存済みメッセージ',
      'empty': '利用可能なチャットはありません',
      'loadError': 'チャットを読み込めませんでした',
      'sendError': 'メッセージを転送できませんでした',
      'retry': '再試行',
      'forwardedFrom': '転送元',
    },
    'ko': {
      'title': '메시지 전달',
      'search': '채팅 검색',
      'showAuthor': '작성자 표시',
      'personal': '개인 채팅',
      'group': '그룹',
      'channel': '채널',
      'favorites': '저장한 메시지',
      'empty': '사용 가능한 채팅이 없습니다',
      'loadError': '채팅을 불러오지 못했습니다',
      'sendError': '메시지를 전달하지 못했습니다',
      'retry': '다시 시도',
      'forwardedFrom': '전달됨',
    },
    'ar': {
      'title': 'إعادة توجيه الرسالة',
      'search': 'البحث في المحادثات',
      'showAuthor': 'إظهار الكاتب',
      'personal': 'محادثة شخصية',
      'group': 'مجموعة',
      'channel': 'قناة',
      'favorites': 'الرسائل المحفوظة',
      'empty': 'لا توجد محادثات متاحة',
      'loadError': 'تعذر تحميل المحادثات',
      'sendError': 'تعذر إعادة توجيه الرسالة',
      'retry': 'إعادة المحاولة',
      'forwardedFrom': 'مُعاد توجيهه من',
    },
  };

  String _get(String name, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    final fallback = (_values[locale] ?? _values['en']!)[name]!;
    return RuntimeTranslations.instance.resolve(key, fallback);
  }

  String get title => _get('title', 'messenger.forward.title');
  String get search => _get('search', 'messenger.forward.searchPlaceholder');
  String get showAuthor => _get('showAuthor', 'messenger.forward.showAuthor');
  String get empty => _get('empty', 'messenger.forward.empty');
  String get loadError => _get('loadError', 'messenger.forward.loadError');
  String get sendError => _get('sendError', 'messenger.forward.sendError');
  String get retry => _get('retry', 'messenger.common.retry');
  String get forwardedFrom =>
      _get('forwardedFrom', 'messenger.message.forwardedFrom');

  String chatType(String type) {
    final normalized =
        const {
          'personal': 'personal',
          'group': 'group',
          'channel': 'channel',
          'favorites': 'favorites',
        }[type] ??
        'personal';
    final key = const {
      'personal': 'messenger.forward.typePersonal',
      'favorites': 'messenger.forward.typePersonal',
      'group': 'messenger.forward.typeGroup',
      'channel': 'messenger.forward.typeChannel',
    }[normalized]!;
    return _get(normalized, key);
  }
}
