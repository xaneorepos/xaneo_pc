import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scale_provider.dart';

enum ToastType { info, success, error, warning }

/// Премиальный Toast-виджет в стиле веб-клиента xaneomain (стиль "Black Raven")
class CustomToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static final GlobalKey<_ToastWidgetState> _toastKey = GlobalKey<_ToastWidgetState>();

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_overlayEntry != null) {
      _timer?.cancel();
      _timer = null;

      final state = _toastKey.currentState;
      if (state != null) {
        state.dismiss(() {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _showNewToast(context, message, type, duration);
        });
        return;
      } else {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    }

    _showNewToast(context, message, type, duration);
  }

  static void _showNewToast(
    BuildContext context,
    String message,
    ToastType type,
    Duration duration,
  ) {
    final scaleProvider = Provider.of<ScaleProvider>(context, listen: false);
    final scale = scaleProvider.scale;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        key: _toastKey,
        message: message,
        type: type,
        scale: scale,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      
      final overlay = Navigator.of(context).overlay;
      if (overlay != null) {
        overlay.insert(_overlayEntry!);

        _timer = Timer(duration, () {
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

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final double scale;

  const _ToastWidget({
    super.key,
    required this.message,
    required this.type,
    required this.scale,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
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
      curve: const Cubic(0.4, 0.0, 0.2, 1.0),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.4, 0.0, 0.2, 1.0),
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
    Color typeColor = Colors.white;
    IconData? iconData;
    bool hasLeftBorder = false;

    switch (widget.type) {
      case ToastType.success:
        typeColor = const Color(0xFF44FF44);
        iconData = Icons.check_circle_outline_rounded;
        hasLeftBorder = true;
        break;
      case ToastType.error:
        typeColor = const Color(0xFFFF4444);
        iconData = Icons.error_outline_rounded;
        hasLeftBorder = true;
        break;
      case ToastType.warning:
        typeColor = const Color(0xFFFFB300);
        iconData = Icons.warning_amber_rounded;
        hasLeftBorder = true;
        break;
      case ToastType.info:
        typeColor = Colors.white54;
        iconData = Icons.info_outline_rounded;
        hasLeftBorder = false;
        break;
    }

    final double scale = widget.scale;

    return Positioned(
      bottom: 24 * scale,
      left: 20 * scale,
      right: 20 * scale,
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
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  if (hasLeftBorder)
                    BoxShadow(
                      color: typeColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25 * scale),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xE6000000), // rgba(0, 0, 0, 0.9)
                      borderRadius: BorderRadius.circular(25 * scale),
                      border: Border.all(
                        color: const Color(0x1AFFFFFF), // rgba(255, 255, 255, 0.1)
                        width: 1,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hasLeftBorder)
                            Container(
                              width: 4 * scale,
                              color: typeColor,
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20 * scale,
                              vertical: 12 * scale,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  iconData,
                                  color: typeColor,
                                  size: 16 * scale,
                                ),
                                SizedBox(width: 10 * scale),
                                Flexible(
                                  child: Text(
                                    widget.message,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
