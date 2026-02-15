import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../styles/app_styles.dart';

/// Модальное окно "О приложении"
class AboutAppModal extends StatefulWidget {
  final VoidCallback onClose;
  
  const AboutAppModal({super.key, required this.onClose});

  @override
  State<AboutAppModal> createState() => _AboutAppModalState();
}

class _AboutAppModalState extends State<AboutAppModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  
  // Для пасхалки
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;
  bool _showEasterEgg = false;
  
  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }
  
  Future<void> _openGitHub() async {
    const url = 'https://github.com/saneome/xaneo_pc';
    try {
      if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('start', [url]);
      }
    } catch (e) {
      debugPrint('Could not open URL: $e');
    }
  }
  
  void _handleLogoTap() {
    final now = DateTime.now();
    
    if (_lastLogoTap != null && now.difference(_lastLogoTap!).inMilliseconds < 500) {
      _logoTapCount++;
      if (_logoTapCount >= 3) {
        setState(() {
          _showEasterEgg = true;
        });
        _logoTapCount = 0;
      }
    } else {
      _logoTapCount = 1;
    }
    
    _lastLogoTap = now;
    
    // Анимация нажатия
    _logoController.forward().then((_) {
      _logoController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final screenSize = MediaQuery.of(context).size;
        
        return Center(
          child: Container(
            width: screenSize.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: screenSize.height * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey.shade900.withOpacity(0.95),
                        Colors.black.withOpacity(0.98),
                      ]
                    : [
                        Colors.white.withOpacity(0.98),
                        Colors.grey.shade50.withOpacity(0.95),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.8)
                      : Colors.grey.withOpacity(0.5),
                  blurRadius: 60,
                  spreadRadius: 15,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок с кнопкой закрытия
                      _buildHeader(isDark),
                      
                      // Основной контент
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Логотип
                              _buildLogo(isDark),
                              
                              const SizedBox(height: 24),
                              
                              // Название и версия
                              _buildAppInfo(isDark),
                              
                              const SizedBox(height: 32),
                              
                              // Описание
                              _buildDescription(isDark),
                              
                              const SizedBox(height: 32),
                              
                              // Ссылка на GitHub
                              _buildGitHubButton(isDark),
                              
                              const SizedBox(height: 24),
                              
                              // Технологии
                              _buildTechStack(isDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Пасхалка
                  if (_showEasterEgg) _buildEasterEgg(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.02),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'О приложении',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                fontFamily: AppStyles.fontFamily,
                decoration: TextDecoration.none,
              ),
              selectionColor: Colors.transparent,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogo(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleLogoTap,
        child: ScaleTransition(
          scale: _logoAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.white, Colors.grey.shade300]
                    : [Colors.black, Colors.grey.shade700],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'X',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                  fontFamily: AppStyles.fontFamily,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppInfo(bool isDark) {
    return Column(
      children: [
        Text(
          'xaneo_pc',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 2,
            fontFamily: AppStyles.fontFamily,
            decoration: TextDecoration.none,
          ),
          selectionColor: Colors.transparent,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ]
                  : [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade400,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade400.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 1,
                  fontFamily: AppStyles.fontFamily,
                  decoration: TextDecoration.none,
                ),
                selectionColor: Colors.transparent,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'stable',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade400,
                    fontFamily: AppStyles.fontFamily,
                    decoration: TextDecoration.none,
                  ),
                  selectionColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDescription(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ]
              : [
                  Colors.black.withOpacity(0.02),
                  Colors.black.withOpacity(0.01),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Современное десктопное приложение\nс красивым интерфейсом и 3D эффектами',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              fontFamily: AppStyles.fontFamily,
              decoration: TextDecoration.none,
            ),
            selectionColor: Colors.transparent,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureChip('Flutter', isDark),
              const SizedBox(width: 8),
              _buildFeatureChip('Linux', isDark),
              const SizedBox(width: 8),
              _buildFeatureChip('Open Source', isDark),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          fontFamily: AppStyles.fontFamily,
          decoration: TextDecoration.none,
        ),
        selectionColor: Colors.transparent,
      ),
    );
  }
  
  Widget _buildGitHubButton(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openGitHub,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                    ]
                  : [
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.04),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.code_rounded,
                size: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 12),
              Text(
                'github.com/saneome/xaneo_pc',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: AppStyles.fontFamily,
                  decoration: TextDecoration.none,
                ),
                selectionColor: Colors.transparent,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTechStack(bool isDark) {
    return Column(
      children: [
        Text(
          'Технологии',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            letterSpacing: 1,
            fontFamily: AppStyles.fontFamily,
            decoration: TextDecoration.none,
          ),
          selectionColor: Colors.transparent,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTechIcon(Icons.flutter_dash_rounded, 'Flutter', isDark),
            const SizedBox(width: 16),
            _buildTechIcon(Icons.palette_rounded, 'Material', isDark),
            const SizedBox(width: 16),
            _buildTechIcon(Icons.animation_rounded, 'Animations', isDark),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTechIcon(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white : Colors.black,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontFamily: AppStyles.fontFamily,
            decoration: TextDecoration.none,
          ),
          selectionColor: Colors.transparent,
        ),
      ],
    );
  }
  
  // Пасхалка - конфетти эффект
  Widget _buildEasterEgg(bool isDark) {
    return Positioned.fill(
      child: _ConfettiOverlay(
        isDark: isDark,
        onClose: () {
          setState(() {
            _showEasterEgg = false;
          });
        },
      ),
    );
  }
}

/// Виджет с конфетти эффектом
class _ConfettiOverlay extends StatefulWidget {
  final bool isDark;
  final VoidCallback onClose;
  
  const _ConfettiOverlay({required this.isDark, required this.onClose});
  
  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward().then((_) {
        widget.onClose();
      });
    
    // Создаём частицы
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle.random());
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
        return GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Stack(
              children: [
                // Центральное сообщение
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.pink.shade400,
                              Colors.orange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🎉 Вы нашли пасхалку! 🎉',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: AppStyles.fontFamily,
                            decoration: TextDecoration.none,
                          ),
                          selectionColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Спасибо за использование xaneo_pc!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: AppStyles.fontFamily,
                          decoration: TextDecoration.none,
                        ),
                        selectionColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
                
                // Частицы конфетти
                ...List.generate(_particles.length, (index) {
                  final particle = _particles[index];
                  final progress = _controller.value;
                  
                  final x = particle.startX + particle.speedX * progress * 200;
                  final y = particle.startY + particle.speedY * progress * 300 + 
                            0.5 * 9.8 * progress * progress * 100;
                  
                  return Positioned(
                    left: x,
                    top: y,
                    child: Transform.rotate(
                      angle: particle.rotation + progress * particle.rotationSpeed,
                      child: Container(
                        width: particle.size,
                        height: particle.size,
                        decoration: BoxDecoration(
                          color: particle.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double speedX;
  final double speedY;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  
  _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
  
  factory _ConfettiParticle.random() {
    final random = math.Random();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    
    return _ConfettiParticle(
      startX: random.nextDouble() * 400,
      startY: random.nextDouble() * 100,
      speedX: (random.nextDouble() - 0.5) * 2,
      speedY: random.nextDouble() * 0.5,
      size: 4 + random.nextDouble() * 8,
      color: colors[random.nextInt(colors.length)],
      rotation: random.nextDouble() * math.pi * 2,
      rotationSpeed: (random.nextDouble() - 0.5) * 10,
    );
  }
}
