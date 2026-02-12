import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/geometry_3d.dart';
import '../widgets/advanced_background.dart';
import '../widgets/custom_title_bar.dart';
import '../widgets/about_app_modal.dart';

/// Экран входа в систему с продвинутыми 3D эффектами
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
  with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLoginFocused = false;
  bool _isPasswordFocused = false;
  
  // Переменные настроек
  bool _notificationsEnabled = true;
  double _fontSize = 16.0;
  int _selectedLanguageIndex = 1; // Индекс русского языка в списке
  bool _showSettings = false; // Показывать модальное окно настроек
  bool _showAboutApp = false; // Показывать модальное окно "О приложении"
  
  // Список доступных языков
  final List<Map<String, String>> _availableLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ru', 'name': 'Русский'},
  ];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _settingsAnimationController;
  late AnimationController _aboutAppAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FocusNode _loginFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _aboutAppAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    _loginFocus.addListener(() {
      setState(() => _isLoginFocused = _loginFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _settingsAnimationController.dispose();
    _aboutAppAnimationController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Имитация запроса к серверу
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.welcomeUser(_loginController.text)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
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
          // Продвинутый фон (не масштабируется)
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
          
          // Кнопка настроек (не масштабируется)
          Positioned(
            top: 50,
            right: 20,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() => _showSettings = true);
                  _settingsAnimationController.forward();
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark 
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.03),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.white.withOpacity((0.05 + _pulseController.value * 0.03).clamp(0.0, 1.0))
                                : Colors.black.withOpacity((0.05 + _pulseController.value * 0.03).clamp(0.0, 1.0)),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: isDark ? Colors.white : Colors.black,
                        size: 22,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Основной контент (масштабируется)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _ScaledContent(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildLoginForm(l10n!, isDark),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Модальное окно настроек (ниже title bar)
          if (_showSettings) _buildSettingsModal(context, isDark),
          
          // Модальное окно "О приложении" (ниже title bar)
          if (_showAboutApp) _buildAboutAppModal(context, isDark),
          
          // Title bar (выше всех по z-index)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: CustomTitleBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShapes(bool isDark) {
    return Stack(
      children: [
        // Левая сторона - сфера
        Positioned(
          top: 100,
          left: 20,
          child: FloatingGeometry(
            floatRange: 15,
            floatDuration: const Duration(seconds: 6),
            child: Sphere3D(
              size: 70,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 12),
            ),
          ),
        ),
        
        // Правая сторона - куб
        Positioned(
          top: 150,
          right: 30,
          child: FloatingGeometry(
            floatRange: 20,
            floatDuration: const Duration(seconds: 5),
            child: Cube3D(
              size: 55,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 15),
            ),
          ),
        ),
        
        // Нижняя левая - тор
        Positioned(
          bottom: 120,
          left: 50,
          child: FloatingGeometry(
            floatRange: 12,
            floatDuration: const Duration(seconds: 7),
            child: Torus3D(
              size: 60,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 10),
            ),
          ),
        ),
        
        // Нижняя правая - куб
        Positioned(
          bottom: 80,
          right: 60,
          child: FloatingGeometry(
            floatRange: 18,
            floatDuration: const Duration(seconds: 5),
            child: Cube3D(
              size: 45,
              color: isDark ? Colors.white : Colors.black,
              rotationDuration: const Duration(seconds: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AppLocalizations l10n, bool isDark) {
    return GlassCard(
      width: 380,
      height: 480,
      borderRadius: 28,
      enableGlow: true,
      glowColor: isDark ? Colors.white : Colors.black,
      glowIntensity: 0.35,
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Логотип
              _buildHeader(isDark),
              
              const SizedBox(height: 36),
              
              // Поле логина
              _buildLoginField(l10n, isDark),
              
              const SizedBox(height: 18),
              
              // Поле пароля
              _buildPasswordField(l10n, isDark),
              
              const SizedBox(height: 28),
              
              // Кнопка входа
              _buildLoginButton(l10n, isDark),
              
              const SizedBox(height: 18),
              
              // Ссылка на регистрацию
              _buildRegisterLink(l10n, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Малый логотип
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(_rotateController.value * 2 * math.pi * 0.2),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.white, Colors.grey.shade400]
                        : [Colors.black, Colors.grey.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity((0.2 + _pulseController.value * 0.1).clamp(0.0, 1.0))
                          : Colors.black.withOpacity((0.2 + _pulseController.value * 0.1).clamp(0.0, 1.0)),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'X',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Заголовок
            Text(
              'xaneo_pc',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginField(AppLocalizations? l10n, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isLoginFocused
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity((0.1 + _pulseController.value * 0.05).clamp(0.0, 1.0))
                          : Colors.black.withOpacity((0.1 + _pulseController.value * 0.05).clamp(0.0, 1.0)),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _loginController,
            focusNode: _loginFocus,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: l10n!.loginFieldHint,
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: _isLoginFocused
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : Colors.black,
                  width: 1.5,
                ),
              ),
              labelStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fillAllFields;
              }
              return null;
            },
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(AppLocalizations? l10n, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isPasswordFocused
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity((0.1 + _pulseController.value * 0.05).clamp(0.0, 1.0))
                          : Colors.black.withOpacity((0.1 + _pulseController.value * 0.05).clamp(0.0, 1.0)),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: l10n!.passwordFieldHint,
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: _isPasswordFocused
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : Colors.black,
                  width: 1.5,
                ),
              ),
              labelStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fillAllFields;
              }
              return null;
            },
          ),
        );
      },
    );
  }

  Widget _buildLoginButton(AppLocalizations? l10n, bool isDark) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _handleLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(12),
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
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n!.loginButton,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.black : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.login_rounded,
                      size: 18,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterLink(AppLocalizations? l10n, bool isDark) {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            // TODO: Переход к экрану регистрации
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Text(
                l10n!.noAccount,
                style: TextStyle(
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: isDark
                      ? Colors.white.withOpacity((0.3 + _pulseController.value * 0.2).clamp(0.0, 1.0))
                      : Colors.black.withOpacity((0.3 + _pulseController.value * 0.2).clamp(0.0, 1.0)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Закрывает модальное окно с анимацией
  void _closeSettings() async {
    await _settingsAnimationController.reverse();
    setState(() => _showSettings = false);
  }

  /// Строит модальное окно настроек как часть Stack
  Widget _buildSettingsModal(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return AnimatedBuilder(
          animation: _settingsAnimationController,
          builder: (context, child) {
            return Stack(
              children: [
                // Затемнение только для области под title bar (ниже 40 пикселей)
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _closeSettings,
                    child: Container(
                      color: isDark 
                          ? Colors.black.withOpacity(0.5 * _settingsAnimationController.value)
                          : Colors.black.withOpacity(0.3 * _settingsAnimationController.value),
                    ),
                  ),
                ),
                
                // Контент модального окна с анимацией
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _settingsAnimationController,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                    ),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.95,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _settingsAnimationController,
                        curve: Curves.easeOut,
                      )),
                      child: Center(
                        child: Container(
                          width: screenSize.width * 0.85,
                          constraints: BoxConstraints(
                            maxWidth: 480,
                            maxHeight: screenSize.height * 0.85,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      Colors.grey.shade900.withOpacity(0.85),
                                      Colors.black.withOpacity(0.9),
                                    ]
                                  : [
                                      Colors.white.withOpacity(0.9),
                                      Colors.grey.shade50.withOpacity(0.85),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.08),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.6)
                                    : Colors.grey.withOpacity(0.4),
                                blurRadius: 50,
                                spreadRadius: 10,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                                blurRadius: 1,
                                spreadRadius: 0,
                                offset: const Offset(0, -1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Заголовок с кнопкой закрытия
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.08)
                                              : Colors.black.withOpacity(0.05),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Анимированная иконка
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 800),
                                          tween: Tween<double>(begin: 0.0, end: 1.0),
                                          curve: Curves.elasticOut,
                                          builder: (context, iconAnim, child) {
                                            return Transform.rotate(
                                              angle: iconAnim * 2 * math.pi * 0.3,
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: isDark
                                                        ? [
                                                            Colors.white.withOpacity(0.2),
                                                            Colors.white.withOpacity(0.05),
                                                          ]
                                                        : [
                                                            Colors.black.withOpacity(0.1),
                                                            Colors.black.withOpacity(0.02),
                                                          ],
                                                  ),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? Colors.white.withOpacity(0.25)
                                                        : Colors.black.withOpacity(0.1),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isDark
                                                          ? Colors.white.withOpacity(0.1)
                                                          : Colors.black.withOpacity(0.05),
                                                      blurRadius: 15,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.settings_rounded,
                                                  color: isDark ? Colors.white : Colors.black,
                                                  size: 24,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    l10n!.settings,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // Кнопка закрытия
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _closeSettings,
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
                          ),
                          
                          // Содержимое настроек
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // === СЕКЦИЯ: ВНЕШНИЙ ВИД ===
                                  _buildSectionHeader(l10n.darkTheme, isDark, Icons.palette_outlined),
                                  const SizedBox(height: 10),
                                  
                                  // Тёмная тема
                                  _buildAnimatedSettingsTile(
                                    icon: Icons.dark_mode_rounded,
                                    title: l10n.darkTheme,
                                    subtitle: l10n.darkThemeDescription,
                                    isDark: isDark,
                                    trailing: _buildAnimatedSwitch(
                                      value: themeProvider.isDarkMode,
                                      isDark: isDark,
                                      onChanged: (value) {
                                        themeProvider.setDarkMode(value);
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // === СЕКЦИЯ: ЯЗЫК ===
                                  _buildSectionHeader(l10n.language, isDark, Icons.translate_rounded),
                                  const SizedBox(height: 10),
                                  
                                  // Выбор языка
                                  _buildLanguageSelector(localeProvider, isDark, l10n),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // === СЕКЦИЯ: УВЕДОМЛЕНИЯ ===
                                  _buildSectionHeader(l10n.notifications, isDark, Icons.notifications_outlined),
                                  const SizedBox(height: 10),
                                  
                                  // Уведомления
                                  _buildAnimatedSettingsTile(
                                    icon: Icons.notifications_active_rounded,
                                    title: l10n.notifications,
                                    subtitle: l10n.notificationsDescription,
                                    isDark: isDark,
                                    trailing: _buildAnimatedSwitch(
                                      value: _notificationsEnabled,
                                      isDark: isDark,
                                      onChanged: (value) {
                                        setState(() {
                                          _notificationsEnabled = value;
                                        });
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // === СЕКЦИЯ: ШРИФТ ===
                                  _buildSectionHeader(l10n.fontSize(_fontSize.round()), isDark, Icons.text_fields_rounded),
                                  const SizedBox(height: 10),
                                  
                                  // Размер шрифта
                                  _buildFontSizeSliderInline(isDark),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // === СЕКЦИЯ: О ПРИЛОЖЕНИИ ===
                                  _buildSectionHeader(l10n.appVersion, isDark, Icons.info_outline_rounded),
                                  const SizedBox(height: 10),
                                  
                                  // Версия приложения
                                  _buildVersionCard(isDark, l10n),
                                  
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ))],
        );
      },
      );
    },
  );
}

  /// Создаёт слайдер размера шрифта (inline версия без StateSetter)
  Widget _buildFontSizeSliderInline(bool isDark) {
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
          // Превью текста
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
            ),
            child: const Text('Aa Бб Вв'),
          ),
          const SizedBox(height: 20),
          // Слайдер
          Material(
            color: Colors.transparent,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                activeTrackColor: isDark ? Colors.white : Colors.black,
                inactiveTrackColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
                thumbColor: isDark ? Colors.white : Colors.black,
                overlayColor: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
              ),
              child: Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),
            ),
          ),
          // Метки
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              Text(
                '24',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Создаёт заголовок секции с иконкой
  Widget _buildSectionHeader(String title, bool isDark, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Создаёт анимированную плитку настройки
  Widget _buildAnimatedSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget trailing,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Иконка
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Переключатель
            trailing,
          ],
        ),
      ),
    );
  }

  /// Создаёт анимированный переключатель
  Widget _buildAnimatedSwitch({
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: value
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.white, Colors.grey.shade300]
                      : [Colors.black, Colors.grey.shade800],
                )
              : null,
          color: value
              ? null
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade500),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Создаёт красивый селектор языка
  Widget _buildLanguageSelector(LocaleProvider localeProvider, bool isDark, AppLocalizations l10n) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showLanguagePicker(context, localeProvider),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              // Иконка
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.language,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.languageDescription,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Выбранный язык
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    Text(
                      _getLanguageNameFromLocale(localeProvider.locale),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Создаёт красивую карточку версии
  Widget _buildVersionCard(bool isDark, AppLocalizations l10n) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showAboutAppModal,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
          child: Row(
            children: [
              // Логотип
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.white, Colors.grey.shade400]
                        : [Colors.black, Colors.grey.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'X',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'xaneo_pc',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Статус и стрелка
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'stable',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Возвращает название языка по локали
  String _getLanguageNameFromLocale(Locale? locale) {
    final code = locale?.languageCode ?? 'ru';
    for (final lang in _availableLanguages) {
      if (lang['code'] == code) {
        return lang['name']!;
      }
    }
    return 'Русский';
  }

  /// Показывает диалог выбора языка
  void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
    final l10n = AppLocalizations.of(context);
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Language',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: animation.value * 10,
            sigmaY: animation.value * 10,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDark = themeProvider.isDarkMode;
            final screenSize = MediaQuery.of(context).size;
            
            return Center(
              child: Container(
                width: screenSize.width * 0.75,
                constraints: BoxConstraints(
                  maxWidth: 380,
                  maxHeight: screenSize.height * 0.5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.grey.shade900.withOpacity(0.9),
                            Colors.black.withOpacity(0.95),
                          ]
                        : [
                            Colors.white.withOpacity(0.95),
                            Colors.grey.shade50.withOpacity(0.9),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.6)
                          : Colors.grey.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Заголовок
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Кнопка отмены
                              _buildPickerButton(
                                icon: Icons.close_rounded,
                                isDark: isDark,
                                isPrimary: false,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              
                              // Заголовок
                              Text(
                                l10n!.selectLanguage,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              
                              // Кнопка подтверждения
                              _buildPickerButton(
                                icon: Icons.check_rounded,
                                isDark: isDark,
                                isPrimary: true,
                                onTap: () {
                                  final selectedLanguage = _availableLanguages[_selectedLanguageIndex];
                                  final selectedLocale = Locale(selectedLanguage['code']!);
                                  localeProvider.setLocale(selectedLocale);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),

                        // CupertinoPicker
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.all(16),
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
                                        Colors.black.withOpacity(0.03),
                                        Colors.black.withOpacity(0.01),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: CupertinoPicker(
                              backgroundColor: Colors.transparent,
                              itemExtent: 50,
                              diameterRatio: 1.3,
                              squeeze: 1.1,
                              scrollController: FixedExtentScrollController(
                                initialItem: _selectedLanguageIndex,
                              ),
                              onSelectedItemChanged: (int index) {
                                _selectedLanguageIndex = index;
                              },
                              children: _availableLanguages.map((language) {
                                return Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Флаг
                                      Container(
                                        width: 32,
                                        height: 32,
                                        margin: const EdgeInsets.only(right: 14),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isDark
                                                ? [
                                                    Colors.white.withOpacity(0.18),
                                                    Colors.white.withOpacity(0.05),
                                                  ]
                                                : [
                                                    Colors.black.withOpacity(0.08),
                                                    Colors.black.withOpacity(0.02),
                                                  ],
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.25)
                                                : Colors.black.withOpacity(0.1),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDark
                                                  ? Colors.white.withOpacity(0.08)
                                                  : Colors.black.withOpacity(0.03),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            language['code'] == 'ru' ? '🇷🇺' : '🇬🇧',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        language['name']!,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Создаёт кнопку для пикера
  Widget _buildPickerButton({
    required IconData icon,
    required bool isDark,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.white, Colors.grey.shade300]
                        : [Colors.black, Colors.grey.shade800],
                  )
                : null,
            color: isPrimary
                ? null
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            border: isPrimary
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity(0.25)
                          : Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isPrimary
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white : Colors.black),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Показывает модальное окно "О приложении"
  void _showAboutAppModal() {
    setState(() => _showAboutApp = true);
    _aboutAppAnimationController.forward();
  }
  
  /// Закрывает модальное окно "О приложении"
  void _closeAboutApp() async {
    await _aboutAppAnimationController.reverse();
    setState(() => _showAboutApp = false);
  }
  
  /// Строит модальное окно "О приложении" как часть Stack
  Widget _buildAboutAppModal(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _aboutAppAnimationController,
      builder: (context, child) {
        final animValue = _aboutAppAnimationController.value;
        return Stack(
          children: [
            // Затемнение только для области под title bar
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _closeAboutApp,
                child: Container(
                  color: isDark 
                      ? Colors.black.withOpacity(0.5 * animValue)
                      : Colors.black.withOpacity(0.3 * animValue),
                ),
              ),
            ),
            
            // Контент модального окна
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              bottom: 20,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _aboutAppAnimationController,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.95,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _aboutAppAnimationController,
                    curve: Curves.easeOut,
                  )),
                  child: AboutAppModal(
                    onClose: _closeAboutApp,
                  ),
                ),
              ),
            ),
          ],
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
