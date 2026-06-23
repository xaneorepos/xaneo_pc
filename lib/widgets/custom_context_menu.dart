import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scale_provider.dart';

class CustomContextMenuItem {
  final Widget? icon;
  final String label;
  final VoidCallback onTap;

  CustomContextMenuItem({
    this.icon,
    required this.label,
    required this.onTap,
  });
}

class CustomContextMenu {
  static void show({
    required BuildContext context,
    required Offset position,
    required List<CustomContextMenuItem> items,
  }) {
    if (items.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleProvider = Provider.of<ScaleProvider>(context, listen: false);
    final scale = scaleProvider.scale;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CustomContextMenu",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        final screenSize = MediaQuery.of(context).size;
        final menuWidth = 200.0 * scale;
        // Estimate height based on item height (approx 44) plus padding
        final estimatedHeight = (items.length * 44.0 + 8.0) * scale;

        double left = position.dx;
        double top = position.dy;

        // Keep inside screen boundaries
        if (left + menuWidth > screenSize.width) {
          left = screenSize.width - menuWidth - 16;
        }
        if (top + estimatedHeight > screenSize.height) {
          top = screenSize.height - estimatedHeight - 16;
        }
        if (left < 16) left = 16;
        if (top < 16) top = 16;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: _CustomContextMenuWidget(
                  items: items,
                  isDark: isDark,
                  scale: scale,
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }
}

class _CustomContextMenuWidget extends StatelessWidget {
  final List<CustomContextMenuItem> items;
  final bool isDark;
  final double scale;

  const _CustomContextMenuWidget({
    required this.items,
    required this.isDark,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xE6282828) : const Color(0xE6FFFFFF);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 32 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12 * scale),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (index) {
              return _CustomContextMenuItemWidget(
                item: items[index],
                isDark: isDark,
                scale: scale,
                isFirst: index == 0,
                isLast: index == items.length - 1,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CustomContextMenuItemWidget extends StatefulWidget {
  final CustomContextMenuItem item;
  final bool isDark;
  final double scale;
  final bool isFirst;
  final bool isLast;

  const _CustomContextMenuItemWidget({
    required this.item,
    required this.isDark,
    required this.scale,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_CustomContextMenuItemWidget> createState() => _CustomContextMenuItemWidgetState();
}

class _CustomContextMenuItemWidgetState extends State<_CustomContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isDark = widget.isDark;

    final basePadding = 16.0 * scale;
    final hoverPadding = 20.0 * scale;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          widget.item.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: 200 * scale,
          padding: EdgeInsets.symmetric(vertical: 12 * scale),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))
                : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: widget.isFirst ? Radius.circular(12 * scale) : Radius.zero,
              topRight: widget.isFirst ? Radius.circular(12 * scale) : Radius.zero,
              bottomLeft: widget.isLast ? Radius.circular(12 * scale) : Radius.zero,
              bottomRight: widget.isLast ? Radius.circular(12 * scale) : Radius.zero,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                width: _isHovered ? hoverPadding : basePadding,
              ),
              if (widget.item.icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: _isHovered 
                        ? (isDark ? Colors.white : Colors.black) 
                        : (isDark ? Colors.white70 : Colors.black54),
                    size: 16 * scale,
                  ),
                  child: widget.item.icon!,
                ),
                SizedBox(width: 12 * scale),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: _isHovered
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 16 * scale),
            ],
          ),
        ),
      ),
    );
  }
}
