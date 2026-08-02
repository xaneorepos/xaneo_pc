import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import 'base_custom_modal.dart';

/// Модальное окно глобального поиска для Xaneo PC.
/// Построено на кастомной базовой модалке BaseCustomModal.
class GlobalSearchModal extends BaseCustomModal {
  final ApiService apiService;
  final Function(Map<String, dynamic> item, String type) onResultSelected;

  const GlobalSearchModal({
    super.key,
    super.modalTag = '',
    super.title = '',
    required this.apiService,
    required this.onResultSelected,
  });

  /// Вызов модалки через системный метод BaseCustomModal.show
  static void show({
    required BuildContext context,
    required ApiService apiService,
    required Function(Map<String, dynamic> item, String type) onResultSelected,
  }) {
    BaseCustomModal.show(
      context: context,
      barrierLabel: 'GlobalSearchModal',
      modal: GlobalSearchModal(
        apiService: apiService,
        onResultSelected: onResultSelected,
      ),
    );
  }

  @override
  State<GlobalSearchModal> createState() => _GlobalSearchModalState();
}

class _GlobalSearchModalState extends BaseCustomModalState<GlobalSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  String _query = '';
  bool _isLoading = false;
  String _selectedCategory = 'all'; // 'all', 'users', 'groups', 'channels', 'bots', 'favorites'

  List<dynamic> _users = [];
  List<dynamic> _groups = [];
  List<dynamic> _channels = [];
  List<dynamic> _bots = [];
  List<dynamic> _favorites = [];

  @override
  String getModalTitle(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    return _SearchL10n.get('header', lang).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _query = text.trim();
    if (_query.startsWith('@')) {
      _query = _query.substring(1).trim();
    }
    _debounceTimer?.cancel();

    if (_query.isEmpty) {
      setState(() {
        _users = [];
        _groups = [];
        _channels = [];
        _bots = [];
        _favorites = [];
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (_query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await widget.apiService.searchUsers(_query);
      debugPrint('🔍 GlobalSearch API response success: ${res.success}, data: ${res.data}');

      if (mounted) {
        setState(() {
          if (res.success && res.data != null) {
            final data = res.data!;
            
            final favData = data['favorites'];
            _favorites = favData != null ? [favData] : [];

            _bots = data['bots'] as List? ?? [];
            _users = data['users'] as List? ?? [];
            _groups = data['groups'] as List? ?? [];
            _channels = data['channels'] as List? ?? [];
          } else {
            _favorites = [];
            _bots = [];
            _users = [];
            _groups = [];
            _channels = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Exception in GlobalSearch _performSearch: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget buildContent(BuildContext context, ScrollController scrollController, bool isDark, double scale) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Поле ввода поиска
        Container(
          height: 42 * scale,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14 * scale,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: _SearchL10n.get('hint', lang),
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13 * scale,
                fontFamily: 'Inter',
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white54 : Colors.black54,
                size: 18 * scale,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: isDark ? Colors.white54 : Colors.black54,
                        size: 16 * scale,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8 * scale),
            ),
          ),
        ),
        SizedBox(height: 12 * scale),

        // Категории
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', _SearchL10n.get('all', lang), isDark, scale),
              _buildFilterChip('users', _SearchL10n.get('users', lang), isDark, scale),
              _buildFilterChip('groups', _SearchL10n.get('groups', lang), isDark, scale),
              _buildFilterChip('channels', _SearchL10n.get('channels', lang), isDark, scale),
              _buildFilterChip('bots', _SearchL10n.get('bots', lang), isDark, scale),
              _buildFilterChip('favorites', _SearchL10n.get('favorites', lang), isDark, scale),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),

        // Основной контент результатов
        Expanded(
          child: _isLoading
              ? Center(
                  child: SizedBox(
                    width: 24 * scale,
                    height: 24 * scale,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                )
              : _buildResultsList(context, scrollController, isDark, scale, lang),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String categoryKey, String label, bool isDark, double scale) {
    final isSelected = _selectedCategory == categoryKey;

    final activeBg = isDark ? Colors.white : Colors.black;
    final activeFg = isDark ? Colors.black : Colors.white;
    final inactiveBg = isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
    final inactiveFg = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);

    return Container(
      margin: EdgeInsets.only(right: 6 * scale),
      child: Material(
        color: isSelected ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(6 * scale),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = categoryKey;
            });
          },
          borderRadius: BorderRadius.circular(6 * scale),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6 * scale),
              border: Border.all(
                color: isSelected ? Colors.transparent : borderColor,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? activeFg : inactiveFg,
                fontSize: 12 * scale,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, ScrollController scrollController, bool isDark, double scale, String lang) {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 44 * scale,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            SizedBox(height: 10 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scale),
              child: Text(
                _SearchL10n.get('empty_query', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13 * scale,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasFavorites = _favorites.isNotEmpty && (_selectedCategory == 'all' || _selectedCategory == 'favorites');
    final hasBots = _bots.isNotEmpty && (_selectedCategory == 'all' || _selectedCategory == 'bots');
    final hasGroups = _groups.isNotEmpty && (_selectedCategory == 'all' || _selectedCategory == 'groups');
    final hasChannels = _channels.isNotEmpty && (_selectedCategory == 'all' || _selectedCategory == 'channels');
    final hasUsers = _users.isNotEmpty && (_selectedCategory == 'all' || _selectedCategory == 'users');

    if (!hasFavorites && !hasBots && !hasGroups && !hasChannels && !hasUsers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40 * scale,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            SizedBox(height: 10 * scale),
            Text(
              _SearchL10n.get('nothing_found', lang),
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13 * scale,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      children: [
        if (hasFavorites) ...[
          _buildSectionHeader(_SearchL10n.get('sec_favorites', lang), isDark, scale),
          ..._favorites.map((item) => _buildResultItem(item, 'favorites', isDark, scale, lang)),
        ],
        if (hasBots) ...[
          _buildSectionHeader(_SearchL10n.get('sec_bots', lang), isDark, scale),
          ..._bots.map((item) => _buildResultItem(item, 'bot', isDark, scale, lang)),
        ],
        if (hasChannels) ...[
          _buildSectionHeader(_SearchL10n.get('sec_channels', lang), isDark, scale),
          ..._channels.map((item) => _buildResultItem(item, 'channel', isDark, scale, lang)),
        ],
        if (hasGroups) ...[
          _buildSectionHeader(_SearchL10n.get('sec_groups', lang), isDark, scale),
          ..._groups.map((item) => _buildResultItem(item, 'group', isDark, scale, lang)),
        ],
        if (hasUsers) ...[
          _buildSectionHeader(_SearchL10n.get('sec_users', lang), isDark, scale),
          ..._users.map((item) => _buildResultItem(item, 'user', isDark, scale, lang)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(top: 10 * scale, bottom: 6 * scale, left: 4 * scale),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2 * scale,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item, String type, bool isDark, double scale, String lang) {
    String name = '';
    String subtitle = '';
    IconData iconData = Icons.person_rounded;
    Color iconColor = const Color(0xFF2563EB);

    if (type == 'favorites') {
      name = _SearchL10n.get('favorites', lang);
      subtitle = _SearchL10n.get('saved_sub', lang);
      iconData = Icons.bookmark_rounded;
      iconColor = const Color(0xFF8B5CF6);
    } else if (type == 'user') {
      final username = item['username']?.toString() ?? '';
      final firstName = item['first_name']?.toString() ?? '';
      final lastName = item['last_name']?.toString() ?? '';
      name = '$firstName $lastName'.trim();
      if (name.isEmpty) name = username;
      subtitle = '@$username';
      iconData = Icons.person_rounded;
      iconColor = const Color(0xFF2563EB);
    } else if (type == 'bot') {
      name = item['first_name']?.toString() ?? item['username']?.toString() ?? _SearchL10n.get('bot_label', lang);
      subtitle = '@${item['username'] ?? _SearchL10n.get('bot_label', lang).toLowerCase()}';
      iconData = Icons.smart_toy_rounded;
      iconColor = const Color(0xFF10B981);
    } else if (type == 'group') {
      name = item['name']?.toString() ?? _SearchL10n.get('group_label', lang);
      final count = item['members_count'] is int ? item['members_count'] as int : int.tryParse(item['members_count']?.toString() ?? '0') ?? 0;
      subtitle = _SearchL10n.formatMembers(count, lang);
      iconData = Icons.groups_rounded;
      iconColor = const Color(0xFFA855F7);
    } else if (type == 'channel') {
      name = item['name']?.toString() ?? _SearchL10n.get('channel_label', lang);
      final count = item['subscribers_count'] is int ? item['subscribers_count'] as int : int.tryParse(item['subscribers_count']?.toString() ?? '0') ?? 0;
      subtitle = _SearchL10n.formatSubscribers(count, lang);
      iconData = Icons.campaign_rounded;
      iconColor = const Color(0xFFF59E0B);
    }

    final avatarUrl = item['avatar']?.toString() ?? item['avatar_url']?.toString();
    final avatarGradient = item['avatar_gradient']?.toString();

    return Container(
      margin: EdgeInsets.only(bottom: 6 * scale),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            widget.onResultSelected(item, type);
          },
          borderRadius: BorderRadius.circular(8 * scale),
          hoverColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
            child: Row(
              children: [
                // Аватар (SVG / PNG / Инициалы)
                _buildAvatarWidget(avatarUrl, name, iconData, iconColor, scale, isDark, avatarGradient: avatarGradient),
                SizedBox(width: 12 * scale),

                // Текст
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 11 * scale,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14 * scale,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(
    String? avatarUrl,
    String displayName,
    IconData fallbackIcon,
    Color iconColor,
    double scale,
    bool isDark, {
    String? avatarGradient,
  }) {
    final size = 36.0 * scale;
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image/svg+xml')) {
        try {
          String svgString = '';
          if (avatarUrl.startsWith('data:image/svg+xml;base64,')) {
            final base64String = avatarUrl.substring('data:image/svg+xml;base64,'.length);
            svgString = utf8.decode(base64.decode(base64String));
          } else {
            final commaIndex = avatarUrl.indexOf(',');
            if (commaIndex != -1) {
              svgString = Uri.decodeComponent(avatarUrl.substring(commaIndex + 1));
            }
          }
          if (svgString.isNotEmpty) {
            return ClipOval(
              child: SvgPicture.string(
                svgString,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            );
          }
        } catch (_) {}
      } else {
        return ClipOval(
          child: Image.network(
            avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackAvatar(initials, iconColor, size, scale, avatarGradient: avatarGradient),
          ),
        );
      }
    }

    return _buildFallbackAvatar(initials, iconColor, size, scale, avatarGradient: avatarGradient);
  }

  Widget _buildFallbackAvatar(String initials, Color iconColor, double size, double scale, {String? avatarGradient}) {
    List<Color> gradientColors = [
      iconColor.withValues(alpha: 0.8),
      iconColor.withValues(alpha: 0.4),
    ];

    if (avatarGradient != null && avatarGradient.isNotEmpty) {
      try {
        final hexes = avatarGradient.split(',').map((s) => s.trim()).toList();
        if (hexes.length >= 2) {
          gradientColors = hexes.map((h) {
            final clean = h.replaceAll('#', '');
            return Color(int.parse('FF$clean', radix: 16));
          }).toList();
        }
      } catch (_) {}
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14 * scale,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _SearchL10n {
  static const Map<String, Map<String, String>> _map = {
    'ru': {
      'header': 'ГЛОБАЛЬНЫЙ ПОИСК',
      'hint': 'Поиск контактов, чатов, каналов, ботов...',
      'all': 'Все',
      'users': 'Люди',
      'groups': 'Группы',
      'channels': 'Каналы',
      'bots': 'Боты',
      'favorites': 'Избранное',
      'empty_query': 'Введите запрос для поиска по контактам, сообщениям и глобальной базе',
      'nothing_found': 'Ничего не найдено',
      'sec_favorites': 'Избранное',
      'sec_bots': 'Боты',
      'sec_channels': 'Каналы',
      'sec_groups': 'Группы',
      'sec_users': 'Пользователи',
      'saved_sub': 'Сохраненные сообщения',
      'bot_label': 'Бот',
      'group_label': 'Группа',
      'channel_label': 'Канал',
    },
    'en': {
      'header': 'GLOBAL SEARCH',
      'hint': 'Search contacts, chats, channels, bots...',
      'all': 'All',
      'users': 'People',
      'groups': 'Groups',
      'channels': 'Channels',
      'bots': 'Bots',
      'favorites': 'Saved',
      'empty_query': 'Type to search contacts, chats, channels and global directory',
      'nothing_found': 'Nothing found',
      'sec_favorites': 'Saved Messages',
      'sec_bots': 'Bots',
      'sec_channels': 'Channels',
      'sec_groups': 'Groups',
      'sec_users': 'Users',
      'saved_sub': 'Saved messages',
      'bot_label': 'Bot',
      'group_label': 'Group',
      'channel_label': 'Channel',
    },
    'zh': {
      'header': '全局搜索',
      'hint': '搜索联系人、聊天、频道、机器人...',
      'all': '全部',
      'users': '用户',
      'groups': '群组',
      'channels': '频道',
      'bots': '机器人',
      'favorites': '收藏',
      'empty_query': '输入内容以搜索联系人、聊天记录和全局目录',
      'nothing_found': '未找到匹配结果',
      'sec_favorites': '收藏夹',
      'sec_bots': '机器人',
      'sec_channels': '频道',
      'sec_groups': '群组',
      'sec_users': '用户',
      'saved_sub': '已保存的消息',
      'bot_label': '机器人',
      'group_label': '群组',
      'channel_label': '频道',
    },
    'es': {
      'header': 'BÚSQUEDA GLOBAL',
      'hint': 'Buscar contactos, chats, canales, bots...',
      'all': 'Todo',
      'users': 'Personas',
      'groups': 'Grupos',
      'channels': 'Canales',
      'bots': 'Bots',
      'favorites': 'Guardados',
      'empty_query': 'Escribe para buscar contactos, chats y directorio global',
      'nothing_found': 'No se encontraron resultados',
      'sec_favorites': 'Mensajes guardados',
      'sec_bots': 'Bots',
      'sec_channels': 'Canales',
      'sec_groups': 'Grupos',
      'sec_users': 'Usuarios',
      'saved_sub': 'Mensajes guardados',
      'bot_label': 'Bot',
      'group_label': 'Grupo',
      'channel_label': 'Canal',
    },
    'fr': {
      'header': 'RECHERCHE GLOBALE',
      'hint': 'Rechercher contacts, discussions, chaînes, bots...',
      'all': 'Tout',
      'users': 'Personnes',
      'groups': 'Groupes',
      'channels': 'Chaînes',
      'bots': 'Bots',
      'favorites': 'Favoris',
      'empty_query': 'Saisissez votre recherche dans les contacts et le répertoire global',
      'nothing_found': 'Aucun résultat trouvé',
      'sec_favorites': 'Messages enregistrés',
      'sec_bots': 'Bots',
      'sec_channels': 'Chaînes',
      'sec_groups': 'Groupes',
      'sec_users': 'Utilisateurs',
      'saved_sub': 'Messages enregistrés',
      'bot_label': 'Bot',
      'group_label': 'Groupe',
      'channel_label': 'Chaîne',
    },
    'ar': {
      'header': 'البحث العالمي',
      'hint': 'البحث في جهات الاتصال والمحادثات والقنوات...',
      'all': 'الكل',
      'users': 'أشخاص',
      'groups': 'مجموعات',
      'channels': 'قنوات',
      'bots': 'روبوتات',
      'favorites': 'المحفوظات',
      'empty_query': 'اكتب للبحث في جهات الاتصال والمحادثات والدليل العام',
      'nothing_found': 'لم يتم العثور على نتائج',
      'sec_favorites': 'الرسائل المحفوظة',
      'sec_bots': 'البوتات',
      'sec_channels': 'القنوات',
      'sec_groups': 'المجموعات',
      'sec_users': 'المستخدمون',
      'saved_sub': 'الرسائل المحفوظة',
      'bot_label': 'بوت',
      'group_label': 'مجموعة',
      'channel_label': 'قناة',
    },
    'ja': {
      'header': 'グローバル検索',
      'hint': '連絡先、チャット、チャンネル、ボットを検索...',
      'all': 'すべて',
      'users': 'ユーザー',
      'groups': 'グループ',
      'channels': 'チャンネル',
      'bots': 'ボット',
      'favorites': '保存済み',
      'empty_query': 'キーワードを入力して検索します',
      'nothing_found': '結果が見つかりませんでした',
      'sec_favorites': '保存済みメッセージ',
      'sec_bots': 'ボット',
      'sec_channels': 'チャンネル',
      'sec_groups': 'グループ',
      'sec_users': 'ユーザー',
      'saved_sub': '保存済みメッセージ',
      'bot_label': 'ボット',
      'group_label': 'グループ',
      'channel_label': 'チャンネル',
    },
    'ko': {
      'header': '글로벌 검색',
      'hint': '연락처, 대화, 채널, 봇 검색...',
      'all': '전체',
      'users': '사용자',
      'groups': '그룹',
      'channels': '채널',
      'bots': '봇',
      'favorites': '보관함',
      'empty_query': '검색어를 입력하여 전체 디렉토리를 검색하세요',
      'nothing_found': '검색 결과가 없습니다',
      'sec_favorites': '저장된 메시지',
      'sec_bots': '봇',
      'sec_channels': '채널',
      'sec_groups': '그룹',
      'sec_users': '사용자',
      'saved_sub': '저장된 메시지',
      'bot_label': '봇',
      'group_label': '그룹',
      'channel_label': '채널',
    },
  };

  static String get(String key, String lang) {
    final l = _map.containsKey(lang) ? lang : 'en';
    return _map[l]?[key] ?? _map['en']?[key] ?? key;
  }

  static String formatMembers(int count, String lang) {
    switch (lang) {
      case 'ru': return '$count участников';
      case 'zh': return '$count 位成员';
      case 'es': return '$count miembros';
      case 'fr': return '$count membres';
      case 'ar': return '$count عضو';
      case 'ja': return '$count メンバー';
      case 'ko': return '$count 명의 멤버';
      default: return '$count members';
    }
  }

  static String formatSubscribers(int count, String lang) {
    switch (lang) {
      case 'ru': return '$count подписчиков';
      case 'zh': return '$count 位订阅者';
      case 'es': return '$count suscriptores';
      case 'fr': return '$count abonnés';
      case 'ar': return '$count مشترك';
      case 'ja': return '$count 登録者';
      case 'ko': return '$count 명의 구독자';
      default: return '$count subscribers';
    }
  }
}
