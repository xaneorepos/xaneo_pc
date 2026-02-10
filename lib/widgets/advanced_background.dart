import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Продвинутый анимированный фон с 3D эффектами
class AdvancedBackground extends StatefulWidget {
  final bool isDark;
  final bool enableGrid;
  final bool enableParticles;
  final bool enableGeometricShapes;

  const AdvancedBackground({
    super.key,
    required this.isDark,
    this.enableGrid = true,
    this.enableParticles = true,
    this.enableGeometricShapes = true,
  });

  @override
  State<AdvancedBackground> createState() => _AdvancedBackgroundState();
}

class _AdvancedBackgroundState extends State<AdvancedBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _shapeController;
  late AnimationController _pulseController;
  final List<Particle3D> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _shapeController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _initializeParticles();
  }

  void _initializeParticles() {
    for (int i = 0; i < 40; i++) {
      _particles.add(Particle3D(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        z: _random.nextDouble(),
        size: 1 + _random.nextDouble() * 3,
        speedX: (_random.nextDouble() - 0.5) * 0.001,
        speedY: (_random.nextDouble() - 0.5) * 0.001,
        speedZ: (_random.nextDouble() - 0.5) * 0.002,
        opacity: 0.1 + _random.nextDouble() * 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _shapeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Градиентный фон
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: widget.isDark
                  ? [
                      Colors.grey.shade900.withOpacity(0.3),
                      Colors.black,
                    ]
                  : [
                      Colors.grey.shade200.withOpacity(0.5),
                      Colors.white,
                    ],
            ),
          ),
        ),

        // Сетка
        if (widget.enableGrid)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: Grid3DPainter(
                    color: widget.isDark ? Colors.white : Colors.black,
                    opacity: 0.03 + _pulseController.value * 0.02,
                    perspective: _pulseController.value * 0.1,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

        // 3D частицы
        if (widget.enableParticles)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                _updateParticles();
                return CustomPaint(
                  painter: Particle3DPainter(
                    particles: _particles,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

        // Геометрические фигуры
        if (widget.enableGeometricShapes)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shapeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GeometricShapesPainter(
                    color: widget.isDark ? Colors.white : Colors.black,
                    animation: _shapeController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

        // Виньетка
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  widget.isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.x += particle.speedX;
      particle.y += particle.speedY;
      particle.z += particle.speedZ;

      // Зацикливание
      if (particle.x < 0) particle.x = 1;
      if (particle.x > 1) particle.x = 0;
      if (particle.y < 0) particle.y = 1;
      if (particle.y > 1) particle.y = 0;
      if (particle.z < 0) particle.z = 1;
      if (particle.z > 1) particle.z = 0;
    }
  }
}

class Particle3D {
  double x;
  double y;
  double z;
  final double size;
  final double speedX;
  final double speedY;
  final double speedZ;
  final double opacity;

  Particle3D({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.speedZ,
    required this.opacity,
  });
}

class Particle3DPainter extends CustomPainter {
  final List<Particle3D> particles;
  final Color color;

  Particle3DPainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Проекция 3D на 2D с учётом глубины
      final scale = 0.5 + particle.z * 0.5;
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      final projectedSize = particle.size * scale;
      final opacity = (particle.opacity * scale).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), projectedSize, paint);

      // Свечение для близких частиц
      if (particle.z > 0.7) {
        final glowPaint = Paint()
          ..color = color.withOpacity((opacity * 0.3).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(Offset(x, y), projectedSize * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant Particle3DPainter oldDelegate) => true;
}

class Grid3DPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double perspective;

  Grid3DPainter({
    required this.color,
    required this.opacity,
    required this.perspective,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final spacing = 60.0;
    final centerY = size.height * 0.6;

    // Горизонтальные линии с перспективой
    for (var y = centerY; y < size.height + spacing; y += spacing) {
      final perspectiveOffset = (y - centerY) * perspective * 0.1;
      canvas.drawLine(
        Offset(-perspectiveOffset, y),
        Offset(size.width + perspectiveOffset, y),
        paint,
      );
    }

    // Вертикальные линии с перспективой
    final verticalSpacing = spacing * 1.5;
    for (var x = 0.0; x < size.width + verticalSpacing; x += verticalSpacing) {
      final bottomX = x + (x - size.width / 2) * perspective * 0.2;
      canvas.drawLine(
        Offset(x, centerY),
        Offset(bottomX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant Grid3DPainter oldDelegate) {
    return opacity != oldDelegate.opacity || perspective != oldDelegate.perspective;
  }
}

class GeometricShapesPainter extends CustomPainter {
  final Color color;
  final double animation;

  GeometricShapesPainter({
    required this.color,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Большой круг в углу
    _drawCircle(
      canvas,
      size,
      Offset(-50, size.height * 0.3),
      150,
      animation,
    );

    // Малый круг
    _drawCircle(
      canvas,
      size,
      Offset(size.width + 30, size.height * 0.7),
      80,
      animation * 1.5,
    );

    // Линии
    _drawLines(canvas, size, animation);
  }

  void _drawCircle(Canvas canvas, Size size, Offset center, double radius, double anim) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Основной круг
    canvas.drawCircle(center, radius, paint);

    // Вращающиеся дуги
    final arcPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 0.5;
    final startAngle = anim * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.7),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.2),
      startAngle + math.pi,
      sweepAngle * 0.6,
      false,
      arcPaint,
    );
  }

  void _drawLines(Canvas canvas, Size size, double anim) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Диагональные линии
    final offset = anim * 100;

    for (var i = -5; i < 10; i++) {
      final x1 = i * 100 + offset % 100;
      final y1 = 0.0;
      final x2 = x1 + size.height * 0.3;
      final y2 = size.height;

      if (x1 < size.width + 200 && x2 > -200) {
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GeometricShapesPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
