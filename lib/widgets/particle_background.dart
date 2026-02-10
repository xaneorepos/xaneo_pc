import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Виджет для создания анимированного фона с частицами
class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double minSize;
  final double maxSize;
  final double minSpeed;
  final double maxSpeed;

  const ParticleBackground({
    super.key,
    this.particleCount = 50,
    this.particleColor = Colors.white,
    this.minSize = 1.0,
    this.maxSize = 3.0,
    this.minSpeed = 0.5,
    this.maxSpeed = 2.0,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _initializeParticles();
  }

  void _initializeParticles() {
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: widget.minSize + _random.nextDouble() * (widget.maxSize - widget.minSize),
        speed: widget.minSpeed + _random.nextDouble() * (widget.maxSpeed - widget.minSpeed),
        opacity: 0.1 + _random.nextDouble() * 0.4,
      ));
    }
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
        _updateParticles();
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            color: widget.particleColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.y -= particle.speed * 0.001;
      
      // Если частица вышла за пределы экрана, возвращаем её вниз
      if (particle.y < 0) {
        particle.y = 1.0;
        particle.x = _random.nextDouble();
      }
    }
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = particle.y * size.height;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return true;
  }
}
