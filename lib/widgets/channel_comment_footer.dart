import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class ChannelCommentFooter extends StatelessWidget {
  const ChannelCommentFooter({super.key, required this.onOpen, this.summary});
  final Future<void> Function() onOpen;
  final Map<String, dynamic>? summary;

  String _label(int count) {
    if (count == 0) return 'Прокомментировать';
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 19) return '$count комментариев';
    if (mod10 == 1) return '$count комментарий';
    if (mod10 >= 2 && mod10 <= 4) return '$count комментария';
    return '$count комментариев';
  }

  Widget _avatar(
    Map<String, dynamic> commenter,
    Color foreground,
    Color surface,
  ) {
    final name = commenter['name']?.toString() ?? '';
    final url = commenter['avatar']?.toString() ?? '';
    final fallback = ColoredBox(
      color: foreground.withValues(alpha: 0.16),
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    Widget child = fallback;
    if (url.startsWith('data:image/svg+xml')) {
      final bytes = Uri.tryParse(url)?.data?.contentAsBytes();
      if (bytes != null) child = SvgPicture.memory(bytes, fit: BoxFit.cover);
    } else if (url.startsWith('http')) {
      child = url.toLowerCase().contains('.svg')
          ? SvgPicture.network(url, fit: BoxFit.cover)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: surface, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final count = int.tryParse(summary?['count']?.toString() ?? '') ?? 0;
    final commenters = (summary?['recent_commenters'] as List? ?? [])
        .whereType<Map>()
        .take(3)
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
    final label = _label(count);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(top: 9),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: foreground.withValues(alpha: 0.14)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (count > 0 && commenters.isNotEmpty)
                    SizedBox(
                      width: 22.0 + (commenters.length - 1) * 16,
                      height: 22,
                      child: Stack(
                        children: [
                          for (var i = 0; i < commenters.length; i++)
                            Positioned(
                              left: i * 16.0,
                              child: _avatar(
                                commenters[i],
                                foreground,
                                surface,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.mode_comment_outlined,
                      size: 18,
                      color: foreground.withValues(alpha: 0.78),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: foreground.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
