import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recentEmojiKey = 'xaneo_recent_message_emojis';
const _accentColor = Color(0xFF6366F1);
bool _emojiPickerVisible = false;

class _EmojiItem {
  const _EmojiItem({
    required this.emoji,
    required this.name,
    required this.keywords,
    required this.category,
  });

  final String emoji;
  final String name;
  final List<String> keywords;
  final String category;

  factory _EmojiItem.fromJson(Map<String, dynamic> json) => _EmojiItem(
        emoji: json['emoji']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        keywords: (json['keywords'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false),
        category: json['category']?.toString() ?? 'Symbols',
      );

  bool matches(String query) {
    final normalized = query.toLowerCase();
    return emoji.contains(query) ||
        name.toLowerCase().contains(normalized) ||
        keywords.any((keyword) => keyword.toLowerCase().contains(normalized));
  }
}

class _EmojiCategory {
  const _EmojiCategory(this.id, this.icon, this.label);

  final String id;
  final String icon;
  final String label;
}

const _categories = <_EmojiCategory>[
  _EmojiCategory('recent', '🕐', 'Недавние'),
  _EmojiCategory('Smileys & Emotion', '😀', 'Смайлы'),
  _EmojiCategory('People & Body', '👋', 'Люди'),
  _EmojiCategory('Animals & Nature', '🐱', 'Животные'),
  _EmojiCategory('Food & Drink', '🍕', 'Еда'),
  _EmojiCategory('Activities', '⚽', 'Активности'),
  _EmojiCategory('Travel & Places', '🚗', 'Путешествия'),
  _EmojiCategory('Objects', '💡', 'Объекты'),
  _EmojiCategory('Symbols', '❤️', 'Символы'),
  _EmojiCategory('Flags', '🏳️', 'Флаги'),
];

Future<void> showEmojiPickerPanel({
  required BuildContext context,
  required GlobalKey anchorKey,
  required TextEditingController controller,
  required FocusNode focusNode,
  required bool isDark,
}) async {
  if (_emojiPickerVisible) return;
  _emojiPickerVisible = true;
  final anchorBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  final anchorRect = anchorBox == null
      ? Rect.zero
      : anchorBox.localToGlobal(Offset.zero) & anchorBox.size;
  var insertionSelection = controller.selection;

  void insertEmoji(String emoji) {
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : insertionSelection.isValid
            ? insertionSelection
            : TextSelection.collapsed(offset: value.text.length);
    final start = math.max(0, selection.start);
    final end = math.max(start, selection.end);
    final newText = value.text.replaceRange(start, end, emoji);
    insertionSelection = TextSelection.collapsed(offset: start + emoji.length);
    controller.value = value.copyWith(
      text: newText,
      selection: insertionSelection,
      composing: TextRange.empty,
    );
  }

  try {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Закрыть панель эмодзи',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final compact = media.size.width < 700;
        final panelWidth = math.min(380.0, media.size.width - 24);
        final panelHeight = math.min(
          430.0,
          media.size.height - media.viewInsets.bottom - 24,
        );
        final left = anchorRect == Rect.zero
            ? (media.size.width - panelWidth) / 2
            : (anchorRect.center.dx - panelWidth / 2)
                .clamp(12.0, media.size.width - panelWidth - 12.0);
        final top = anchorRect == Rect.zero
            ? math.max(12.0, media.size.height - panelHeight - 80)
            : (anchorRect.top - panelHeight - 8)
                .clamp(12.0, media.size.height - panelHeight - 12.0);

        return Stack(
          children: [
            Positioned(
              left: compact ? (media.size.width - panelWidth) / 2 : left,
              top: compact ? null : top,
              bottom: compact ? media.viewInsets.bottom + 12 : null,
              width: panelWidth,
              height: panelHeight,
              child: _EmojiPickerPanel(
                isDark: isDark,
                onEmojiSelected: insertEmoji,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        );
      },
    );
  } finally {
    _emojiPickerVisible = false;
    if (context.mounted) {
      focusNode.requestFocus();
      controller.selection = insertionSelection.isValid
          ? insertionSelection
          : TextSelection.collapsed(offset: controller.text.length);
    }
  }
}

class _EmojiPickerPanel extends StatefulWidget {
  const _EmojiPickerPanel({
    required this.isDark,
    required this.onEmojiSelected,
    required this.onClose,
  });

  final bool isDark;
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onClose;

  @override
  State<_EmojiPickerPanel> createState() => _EmojiPickerPanelState();
}

class _EmojiPickerPanelState extends State<_EmojiPickerPanel> {
  static Future<List<_EmojiItem>>? _cachedItems;

  final _searchController = TextEditingController();
  List<_EmojiItem> _items = const [];
  List<String> _recent = const [];
  String _category = 'recent';
  String _query = '';
  _EmojiItem? _preview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _cachedItems ??= _loadItems();
    final prefs = await SharedPreferences.getInstance();
    final results = await Future.wait<dynamic>([
      _cachedItems!,
      Future<List<String>>.value(
        prefs.getStringList(_recentEmojiKey) ?? const <String>[],
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _items = results[0] as List<_EmojiItem>;
      _recent = results[1] as List<String>;
      _loading = false;
    });
  }

  static Future<List<_EmojiItem>> _loadItems() async {
    final source = await rootBundle.loadString('assets/emoji/emoji_data.json');
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_EmojiItem.fromJson)
        .where((item) => item.emoji.isNotEmpty)
        .toList(growable: false);
  }

  List<_EmojiItem> get _visibleItems {
    if (_query.isNotEmpty) {
      return _items
          .where((item) => item.matches(_query))
          .toList(growable: false);
    }
    if (_category == 'recent') {
      final byEmoji = {for (final item in _items) item.emoji: item};
      return _recent
          .map((emoji) => byEmoji[emoji])
          .whereType<_EmojiItem>()
          .toList(growable: false);
    }
    return _items
        .where((item) => item.category == _category)
        .toList(growable: false);
  }

  Future<void> _select(_EmojiItem item) async {
    widget.onEmojiSelected(item.emoji);
    final recent = <String>[
      item.emoji,
      ..._recent.where((emoji) => emoji != item.emoji),
    ].take(36).toList(growable: false);
    setState(() {
      _recent = recent;
      _preview = item;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentEmojiKey, recent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background =
        widget.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFDFDFD);
    final foreground = widget.isDark ? Colors.white : const Color(0xFF111827);
    final muted = widget.isDark ? Colors.white54 : Colors.black54;
    final border = widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);
    final surface = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.045);
    final visibleItems = _visibleItems;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Эмодзи',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Закрыть',
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close_rounded, color: muted, size: 19),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                style: TextStyle(color: foreground, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Поиск эмодзи...',
                  hintStyle: TextStyle(color: muted),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: muted, size: 19),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon:
                              Icon(Icons.close_rounded, color: muted, size: 17),
                        ),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accentColor),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 43,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = _query.isEmpty && _category == category.id;
                  return Tooltip(
                    message: category.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _category = category.id;
                        });
                      },
                      child: Container(
                        width: 35,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? _accentColor.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(category.icon,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: border),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : visibleItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _category == 'recent' && _query.isEmpty
                                  ? 'Недавние эмодзи появятся здесь'
                                  : 'Ничего не найдено',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth < 350 ? 7 : 8;
                            return GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 3,
                                crossAxisSpacing: 3,
                              ),
                              itemCount: visibleItems.length,
                              itemBuilder: (context, index) {
                                final item = visibleItems[index];
                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _preview = item),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _select(item),
                                    child: Center(
                                      child: Text(
                                        item.emoji,
                                        style: const TextStyle(fontSize: 23),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
            Divider(height: 1, color: border),
            SizedBox(
              height: 42,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text(
                      _preview?.emoji ??
                          _categories
                              .firstWhere((item) => item.id == _category)
                              .icon,
                      style: const TextStyle(fontSize: 23),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _preview?.name ??
                            _categories
                                .firstWhere((item) => item.id == _category)
                                .label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
