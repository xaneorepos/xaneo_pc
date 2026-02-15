import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D вращающийся куб
class Cube3D extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration rotationDuration;
  final bool enableShadow;

  const Cube3D({
    super.key,
    this.size = 100,
    this.color,
    this.rotationDuration = const Duration(seconds: 10),
    this.enableShadow = true,
  });

  @override
  State<Cube3D> createState() => _Cube3DState();
}

class _Cube3DState extends State<Cube3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? (isDark ? Colors.white : Colors.black);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(_controller.value * 2 * math.pi)
            ..rotateY(_controller.value * 2 * math.pi * 0.7),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 2,
              ),
              boxShadow: widget.enableShadow
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Горизонтальные линии
                Positioned.fill(
                  child: CustomPaint(
                    painter: CubeLinesPainter(color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Painter для линий куба
class CubeLinesPainter extends CustomPainter {
  final Color color;

  CubeLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Центральная линия по горизонтали
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Центральная линия по вертикали
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Диагонали
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CubeLinesPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

/// 3D вращающийся тор (кольцо)
class Torus3D extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration rotationDuration;

  const Torus3D({
    super.key,
    this.size = 100,
    this.color,
    this.rotationDuration = const Duration(seconds: 8),
  });

  @override
  State<Torus3D> createState() => _Torus3DState();
}

class _Torus3DState extends State<Torus3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? (isDark ? Colors.white : Colors.black);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_controller.value * 2 * math.pi * 0.5)
            ..rotateZ(_controller.value * 2 * math.pi),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: TorusPainter(color: color),
          ),
        );
      },
    );
  }
}

/// Painter для тора
class TorusPainter extends CustomPainter {
  final Color color;

  TorusPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Основной круг
    canvas.drawCircle(center, radius, paint);

    // Внутренние эллипсы для 3D эффекта
    final innerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 1.8 - i * 10,
        height: radius * 0.6 - i * 3,
      );
      canvas.drawOval(rect, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TorusPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

/// 3D сфера с линиями
class Sphere3D extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration rotationDuration;

  const Sphere3D({
    super.key,
    this.size = 100,
    this.color,
    this.rotationDuration = const Duration(seconds: 12),
  });

  @override
  State<Sphere3D> createState() => _Sphere3DState();
}

class _Sphere3DState extends State<Sphere3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? (isDark ? Colors.white : Colors.black);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_controller.value * 2 * math.pi),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: SpherePainter(color: color, rotation: _controller.value),
          ),
        );
      },
    );
  }
}

/// Painter для сферы
class SpherePainter extends CustomPainter {
  final Color color;
  final double rotation;

  SpherePainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Основной круг с градиентом
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          color.withOpacity(0.4),
          color.withOpacity(0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, gradientPaint);

    // Контур
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, outlinePaint);

    // Меридианы
    final meridianPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 1; i < 4; i++) {
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 2 * (i / 4),
        height: radius * 2,
      );
      canvas.drawOval(rect, meridianPaint);
    }

    // Параллели
    for (var i = 1; i < 4; i++) {
      final y = center.dy - radius + (radius * 2 * i / 4);
      final width = radius * 2 * math.sin(math.acos((i - 2) / 2));
      canvas.drawLine(
        Offset(center.dx - width / 2, y),
        Offset(center.dx + width / 2, y),
        meridianPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpherePainter oldDelegate) {
    return color != oldDelegate.color || rotation != oldDelegate.rotation;
  }
}

/// Плавающая геометрическая фигура
class FloatingGeometry extends StatefulWidget {
  final Widget child;
  final Offset startPosition;
  final Duration floatDuration;
  final double floatRange;

  const FloatingGeometry({
    super.key,
    required this.child,
    this.startPosition = Offset.zero,
    this.floatDuration = const Duration(seconds: 4),
    this.floatRange = 20,
  });

  @override
  State<FloatingGeometry> createState() => _FloatingGeometryState();
}

class _FloatingGeometryState extends State<FloatingGeometry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.floatDuration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            widget.startPosition.dx +
                math.sin(_controller.value * math.pi * 2) * widget.floatRange,
            widget.startPosition.dy +
                math.cos(_controller.value * math.pi * 2) * widget.floatRange * 0.5,
          ),
          child: Opacity(
            opacity: (0.3 + _controller.value * 0.2).clamp(0.0, 1.0),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Сетка линий для фона
class GridLines extends StatelessWidget {
  final Color? color;
  final double spacing;
  final double lineWidth;

  const GridLines({
    super.key,
    this.color,
    this.spacing = 50,
    this.lineWidth = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = color ?? (isDark ? Colors.white : Colors.black);

    return CustomPaint(
      painter: GridPainter(
        color: lineColor.withOpacity(0.1),
        spacing: spacing,
        lineWidth: lineWidth,
      ),
      size: Size.infinite,
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double lineWidth;

  GridPainter({
    required this.color,
    required this.spacing,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // Вертикальные линии
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Горизонтальные линии
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return color != oldDelegate.color ||
        spacing != oldDelegate.spacing ||
        lineWidth != oldDelegate.lineWidth;
  }
}
