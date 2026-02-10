import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../styles/app_styles.dart';
import '../widgets/3d_card.dart';
import '../widgets/particle_background.dart';

/// Экран онбординга с тремя этапами
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  
  // Анимационные контроллеры
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _logoController;
  
  // Анимации
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    
    // Инициализация контроллеров анимации
    _slideController = AnimationController(
      duration: AppStyles.animationDurationMedium,
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: AppStyles.animationDurationFast,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: AppStyles.animationDurationFast,
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Настройка анимаций
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppStyles.animationCurveEaseOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: AppStyles.animationCurveEaseOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppStyles.animationCurveEaseOut,
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    // Запуск начальных анимаций
    _fadeController.forward();
    _scaleController.forward();
    _logoController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      
      // Анимация перехода
      _slideController.reset();
      _fadeController.reset();
      _scaleController.reset();
      
      _slideController.forward();
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
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Фон с частицами
          Positioned.fill(
            child: ParticleBackground(
              particleColor: isDark ? Colors.white : Colors.black,
              particleCount: 30,
            ),
          ),
          
          // Основной контент
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип с анимацией
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.5 + _logoAnimation.value * 0.5,
                        child: Opacity(
                          opacity: _logoAnimation.value,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // 3D карточка с контентом
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _slideAnimation,
                      _fadeAnimation,
                      _scaleAnimation,
                    ]),
                    builder: (context, child) {
                      return SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: _buildOnboardingCard(l10n, isDark),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Индикаторы шагов
                  _buildStepIndicators(isDark),
                  
                  const SizedBox(height: 40),
                  
                  // Кнопка навигации
                  _buildNavigationButton(l10n, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'X',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(AppLocalizations? l10n, bool isDark) {
    final steps = [
      {
        'title': l10n!.welcomeTitle,
        'description': l10n!.welcomeDescription,
        'icon': Icons.rocket_launch,
        'button': l10n!.getStartedButton,
      },
      {
        'title': l10n!.privacyTitle,
        'description': l10n!.privacyDescription,
        'icon': Icons.lock,
        'button': l10n!.continueButton,
      },
      {
        'title': l10n!.dataStorageTitle,
        'description': l10n!.dataStorageDescription,
        'icon': Icons.storage,
        'button': l10n!.finishButton,
      },
    ];

    final step = steps[_currentStep];

    return Card3D(
      width: 400,
      height: 500,
      perspective: 0.001,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.grey.shade900.withOpacity(0.9),
                    Colors.grey.shade800.withOpacity(0.9),
                  ]
                : [
                    Colors.grey.shade100.withOpacity(0.9),
                    Colors.grey.shade200.withOpacity(0.9),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка с 3D эффектом
            _build3DIcon(step['icon'] as IconData, isDark),
            
            const SizedBox(height: 32),
            
            // Заголовок
            Text(
              step['title'] as String,
              style: AppStyles.titleLarge(context),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Описание
            Text(
              step['description'] as String,
              style: AppStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DIcon(IconData icon, bool isDark) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final rotation = _logoController.value * 2 * math.pi;
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotation),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.grey.shade700, Colors.grey.shade500]
                    : [Colors.grey.shade400, Colors.grey.shade600],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 50,
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButton(AppLocalizations? l10n, bool isDark) {
    final buttonText = _currentStep == 0
        ? l10n!.getStartedButton
        : _currentStep == 1
            ? l10n!.continueButton
            : l10n!.finishButton;

    return ElevatedButton(
      onPressed: _nextStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        shadowColor: isDark
            ? Colors.white.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
