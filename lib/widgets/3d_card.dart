import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D карточка с эффектом параллакса и вращения
class Card3D extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double perspective;
  final bool enableHover;
  final VoidCallback? onTap;

  const Card3D({
    super.key,
    required this.child,
    this.width = 300,
    this.height = 400,
    this.perspective = 0.002,
    this.enableHover = true,
    this.onTap,
  });

  @override
  State<Card3D> createState() => _Card3DState();
}

class _Card3DState extends State<Card3D> with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  final double _scale = 1.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
    _rotateY = ((localPosition.dx - centerX) / centerX) * 15; // Максимальный угол 15 градусов
    _rotateX = -((localPosition.dy - centerY) / centerY) * 15;
    
    setState(() {});
  }

  void _resetRotation() {
    if (!widget.enableHover) return;
    
    _rotateX = 0;
    _rotateY = 0;
    setState(() {});
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        _updateRotation(event.localPosition);
      },
      onExit: (_) {
        _resetRotation();
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, widget.perspective)
                ..rotateX(_rotateX * math.pi / 180)
                ..rotateY(_rotateY * math.pi / 180)
                ..scale(_scaleAnimation.value),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(
                        _rotateY * 0.5,
                        -_rotateX * 0.5,
                      ),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
