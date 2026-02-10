import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Продвинутая 3D карточка с эффектом стекла (glassmorphism)
class GlassCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final bool enableGlow;
  final Color? glowColor;
  final double glowIntensity;
  final bool enableHover;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width = 400,
    this.height = 500,
    this.borderRadius = 24,
    this.enableGlow = true,
    this.glowColor,
    this.glowIntensity = 0.5,
    this.enableHover = true,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  double _glowX = 0;
  double _glowY = 0;
  bool _isHovered = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateRotation(Offset localPosition) {
    if (!widget.enableHover) return;

    final centerX = widget.width / 2;
    final centerY = widget.height / 2;

    // Вычисляем угол вращения на основе позиции курсора
    _rotateY = ((localPosition.dx - centerX) / centerX) * 12;
    _rotateX = -((localPosition.dy - centerY) / centerY) * 12;

    // Позиция свечения следует за курсором
    _glowX = (localPosition.dx / widget.width - 0.5) * 100;
    _glowY = (localPosition.dy / widget.height - 0.5) * 100;

    setState(() {});
  }

  void _resetRotation() {
    if (!widget.enableHover) return;

    _rotateX = 0;
    _rotateY = 0;
    _isHovered = false;
    _animationController.reverse();
    setState(() {});
  }

  void _onEnter() {
    if (!widget.enableHover) return;
    _isHovered = true;
    _animationController.forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = widget.glowColor ??
        (isDark ? Colors.white : Colors.black);

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onHover: (event) => _updateRotation(event.localPosition),
      onExit: (_) => _resetRotation(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_rotateX * math.pi / 180)
                ..rotateY(_rotateY * math.pi / 180)
                ..scale(_scaleAnimation.value),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: Stack(
                  children: [
                    // Внешнее свечение
                    if (widget.enableGlow)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(widget.borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withOpacity(
                                    _isHovered
                                        ? (widget.glowIntensity * _glowAnimation.value).clamp(0.0, 1.0)
                                        : 0.15),
                                blurRadius: _isHovered ? 40 : 20,
                                spreadRadius: _isHovered ? 2 : 0,
                                offset: Offset(_glowX * 0.2, _glowY * 0.2),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Основной контейнер с glassmorphism эффектом
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      Colors.white.withOpacity(0.12),
                                      Colors.white.withOpacity(0.05),
                                    ]
                                  : [
                                      Colors.white.withOpacity(0.8),
                                      Colors.white.withOpacity(0.6),
                                    ],
                            ),
                            borderRadius:
                                BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Блик (shine effect)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        child: CustomPaint(
                          painter: ShinePainter(
                            glowX: _glowX,
                            glowY: _glowY,
                            isHovered: _isHovered,
                          ),
                        ),
                      ),
                    ),

                    // Контент
                    ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Painter для создания эффекта блика
class ShinePainter extends CustomPainter {
  final double glowX;
  final double glowY;
  final bool isHovered;

  ShinePainter({
    required this.glowX,
    required this.glowY,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isHovered) return;

    final center = Offset(
      size.width / 2 + glowX * 2,
      size.height / 2 + glowY * 2,
    );

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(Rect.fromCenter(
        center: center,
        width: size.width * 0.8,
        height: size.height * 0.8,
      ));

    canvas.drawCircle(center, size.width * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant ShinePainter oldDelegate) {
    return glowX != oldDelegate.glowX ||
        glowY != oldDelegate.glowY ||
        isHovered != oldDelegate.isHovered;
  }
}
