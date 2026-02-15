import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/geometry_3d.dart';
import '../widgets/advanced_background.dart';

/// Экран онбординга с продвинутыми 3D эффектами
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  
  // Анимационные контроллеры
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  
  // Анимации
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    
    // Инициализация контроллеров анимации
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Настройка анимаций
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Запуск начальных анимаций
    _fadeController.forward();
    _scaleController.forward();
    _logoController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      
      // Анимация перехода
      _fadeController.reset();
      _scaleController.reset();
      
      _fadeController.forward();
      _scaleController.forward();
    } else {
      // Завершение онбординга
      _markOnboardingComplete();
    }
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Продвинутый фон с 3D эффектами (не масштабируется)
          Positioned.fill(
            child: AdvancedBackground(
              isDark: isDark,
              enableGrid: true,
              enableParticles: true,
              enableGeometricShapes: true,
            ),
          ),
          
          // Плавающие 3D фигуры (не масштабируются)
          _buildFloatingShapes(isDark),
          
          // Основной контент (масштабируется)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _ScaledContent(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Логотип с 3D эффектом
                        _buildAnimatedLogo(isDark),
                        
                        const SizedBox(height: 40),
                        
                        // Карточка с контентом
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _fadeAnimation,
                            _scaleAnimation,
                          ]),
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: _buildOnboardingCard(l10n, isDark),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Индикаторы шагов
                        _buildStepIndicators(isDark),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопка навигации
                        _buildNavigationButton(l10n, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShapes(bool isDark) {
    return Stack(
      children: [
        // Левый верхний угол - куб
        Positioned(
          top: 80,
          left: 30,
          child: FloatingGeometry(
            floatRange: 15,
            floatDuration: const Duration(seconds: 5),
            child: Cube3D(
              size: 60,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 15),
            ),
          ),
        ),
        
        // Правый верхний угол - сфера
        Positioned(
          top: 120,
          right: 50,
          child: FloatingGeometry(
            floatRange: 20,
            floatDuration: const Duration(seconds: 6),
            child: Sphere3D(
              size: 80,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 10),
            ),
          ),
        ),
        
        // Левый нижний угол - тор
        Positioned(
          bottom: 100,
          left: 60,
          child: FloatingGeometry(
            floatRange: 12,
            floatDuration: const Duration(seconds: 7),
            child: Torus3D(
              size: 70,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 12),
            ),
          ),
        ),
        
        // Правый нижний угол - куб
        Positioned(
          bottom: 150,
          right: 40,
          child: FloatingGeometry(
            floatRange: 18,
            floatDuration: const Duration(seconds: 5),
            child: Cube3D(
              size: 50,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + _logoAnimation.value * 0.5,
          child: Transform.rotate(
            angle: (1 - _logoAnimation.value) * 0.2,
            child: Opacity(
              opacity: _logoAnimation.value.clamp(0.0, 1.0),
              child: _buildLogo(isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.9),
                      Colors.grey.shade400,
                    ]
                  : [
                      Colors.black.withOpacity(0.9),
                      Colors.grey.shade700,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.white.withOpacity((0.3 + _pulseController.value * 0.2).clamp(0.0, 1.0))
                    : Colors.black.withOpacity((0.3 + _pulseController.value * 0.2).clamp(0.0, 1.0)),
                blurRadius: 25 + _pulseController.value * 10,
                spreadRadius: 2 + _pulseController.value * 3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'X',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.black : Colors.white,
                shadows: [
                  Shadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnboardingCard(AppLocalizations l10n, bool isDark) {
    final steps = [
      {
        'title': l10n.welcomeTitle,
        'description': l10n.welcomeDescription,
        'icon': Icons.rocket_launch_rounded,
        'button': l10n.getStartedButton,
      },
      {
        'title': l10n.privacyTitle,
        'description': l10n.privacyDescription,
        'icon': Icons.shield_rounded,
        'button': l10n.continueButton,
      },
      {
        'title': l10n.dataStorageTitle,
        'description': l10n.dataStorageDescription,
        'icon': Icons.storage_rounded,
        'button': l10n.finishButton,
      },
    ];

    final step = steps[_currentStep];

    return GlassCard(
      width: 380,
      height: 380,
      borderRadius: 28,
      enableGlow: true,
      glowColor: isDark ? Colors.white : Colors.black,
      glowIntensity: 0.4,
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D иконка
            _build3DIcon(step['icon'] as IconData, isDark),
            
            const SizedBox(height: 28),
            
            // Заголовок
            Text(
              step['title'] as String,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 14),
            
            // Описание
            Text(
              step['description'] as String,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DIcon(IconData icon, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(math.sin(_pulseController.value * math.pi) * 0.1)
            ..rotateY(_rotateController.value * 2 * math.pi * 0.3),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey.shade800,
                        Colors.grey.shade600,
                      ]
                    : [
                        Colors.grey.shade300,
                        Colors.grey.shade500,
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withOpacity((0.15 + _pulseController.value * 0.1).clamp(0.0, 1.0))
                      : Colors.black.withOpacity((0.15 + _pulseController.value * 0.1).clamp(0.0, 1.0)),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 36,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicators(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isPast = index < _currentStep;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 36 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive || isPast
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: isActive
              ? Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                )
              : null,
        );
      }),
    );
  }

  Widget _buildNavigationButton(AppLocalizations l10n, bool isDark) {
    final buttonText = _currentStep == 0
        ? l10n.getStartedButton
        : _currentStep == 1
            ? l10n.continueButton
            : l10n.finishButton;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _nextStep,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity((0.2 + _pulseController.value * 0.15).clamp(0.0, 1.0))
                        : Colors.black.withOpacity((0.2 + _pulseController.value * 0.15).clamp(0.0, 1.0)),
                    blurRadius: 20 + _pulseController.value * 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.black : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Виджет для применения масштаба к контенту
class _ScaledContent extends StatelessWidget {
  final Widget child;

  const _ScaledContent({required this.child});

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
