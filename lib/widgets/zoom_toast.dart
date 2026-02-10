import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';

/// Toast-виджет для отображения текущего масштаба
class ZoomToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(BuildContext context, double scale) {
    // Удаляем предыдущий toast если есть
    hide();

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final scalePercent = (scale * 100).round();

    _overlayEntry = OverlayEntry(
      builder: (context) => _ZoomToastWidget(
        scale: scale,
        scalePercent: scalePercent,
        isDark: isDark,
      ),
    );

    // Используем WidgetsBinding для задержки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      
      final overlay = Navigator.of(context).overlay;
      if (overlay != null) {
        overlay.insert(_overlayEntry!);

        // Автоматически скрываем через 2 секунды
        _timer = Timer(const Duration(seconds: 2), () {
          hide();
        });
      }
    });
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _ZoomToastWidget extends StatefulWidget {
  final double scale;
  final int scalePercent;
  final bool isDark;

  const _ZoomToastWidget({
    required this.scale,
    required this.scalePercent,
    required this.isDark,
  });

  @override
  State<_ZoomToastWidget> createState() => _ZoomToastWidgetState();
}

class _ZoomToastWidgetState extends State<_ZoomToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка уменьшения
                Icon(
                  Icons.remove,
                  size: 16,
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                ),
                const SizedBox(width: 12),
                // Индикатор масштаба
                Container(
                  width: 80,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ((widget.scale - 0.7) / 1.3).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDark
                              ? [Colors.white, Colors.grey.shade400]
                              : [Colors.black, Colors.grey.shade700],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Процент масштаба
                Text(
                  '${widget.scalePercent}%',
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                // Иконка увеличения
                Icon(
                  Icons.add,
                  size: 16,
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет-обёртка для обработки горячих клавиш масштабирования
class ZoomScope extends StatefulWidget {
  final Widget child;

  const ZoomScope({
    super.key,
    required this.child,
  });

  @override
  State<ZoomScope> createState() => _ZoomScopeState();
}

class _ZoomScopeState extends State<ZoomScope> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () {
          final scaleProvider = context.read<ScaleProvider?>();
          if (scaleProvider != null) {
            scaleProvider.zoomIn();
            ZoomToast.show(context, scaleProvider.scale);
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): () {
          final scaleProvider = context.read<ScaleProvider?>();
          if (scaleProvider != null) {
            scaleProvider.zoomIn();
            ZoomToast.show(context, scaleProvider.scale);
          }
        },
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () {
          final scaleProvider = context.read<ScaleProvider?>();
          if (scaleProvider != null) {
            scaleProvider.zoomOut();
            ZoomToast.show(context, scaleProvider.scale);
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): () {
          final scaleProvider = context.read<ScaleProvider?>();
          if (scaleProvider != null) {
            scaleProvider.zoomOut();
            ZoomToast.show(context, scaleProvider.scale);
          }
        },
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () {
          final scaleProvider = context.read<ScaleProvider?>();
          if (scaleProvider != null) {
            scaleProvider.resetZoom();
            ZoomToast.show(context, scaleProvider.scale);
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true): () {
          final scaleProvider = context.read<ScaleProvider?>();
          if (scaleProvider != null) {
            scaleProvider.resetZoom();
            ZoomToast.show(context, scaleProvider.scale);
          }
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: widget.child,
      ),
    );
  }
}

/// Виджет для применения масштаба к дочерним элементам
class ScaledContent extends StatelessWidget {
  final Widget child;

  const ScaledContent({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scaleProvider = context.watch<ScaleProvider?>();
    final scale = scaleProvider?.scale ?? 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: child,
    );
  }
}
