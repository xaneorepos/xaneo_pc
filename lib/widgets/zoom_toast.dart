import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';

/// Toast-виджет для отображения текущего масштаба
class ZoomToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static final GlobalKey<_ZoomToastWidgetState> _toastKey = GlobalKey<_ZoomToastWidgetState>();

  static double _currentScale = 1.0;
  static int _currentScalePercent = 100;
  static bool _currentIsDark = true;

  static void show(BuildContext context, double scale) {
    _currentScale = scale;
    _currentScalePercent = (scale * 100).round();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _currentIsDark = themeProvider.isDarkMode;

    _timer?.cancel();

    if (_overlayEntry != null) {
      // Rebuild the existing overlay with new values
      _overlayEntry!.markNeedsBuild();
      
      // If the entry animation was reversing or stopped, play it forward again
      _toastKey.currentState?._controller.forward();

      // Reset the timer
      _timer = Timer(const Duration(seconds: 2), () {
        hide();
      });
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _ZoomToastWidget(
        key: _toastKey,
        scale: _currentScale,
        scalePercent: _currentScalePercent,
        isDark: _currentIsDark,
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

    final state = _toastKey.currentState;
    if (state != null) {
      state.dismiss(() {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
}

class _ZoomToastWidget extends StatefulWidget {
  final double scale;
  final int scalePercent;
  final bool isDark;

  const _ZoomToastWidget({
    super.key,
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

  void dismiss(VoidCallback onAnimationComplete) {
    if (!mounted) {
      onAnimationComplete();
      return;
    }
    _controller.reverse().then((_) {
      if (mounted) {
        onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
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
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xE6000000), // rgba(0, 0, 0, 0.9)
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0x1AFFFFFF), // rgba(255, 255, 255, 0.1)
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Иконка уменьшения
                          const Icon(
                            Icons.remove_rounded,
                            size: 16,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 12),
                          // Индикатор масштаба
                          Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: ((widget.scale - 0.7) / 1.3).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Процент масштаба
                          Text(
                            '${widget.scalePercent}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Иконка увеличения
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.white60,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
