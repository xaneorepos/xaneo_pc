import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/geometry_3d.dart';
import '../widgets/advanced_background.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
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

    _rotateController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

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
    _rotateController.dispose();
    _pulseController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // API сервис
  final _apiService = ApiService();

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Получаем JWT токен
        final tokenResponse = await _apiService.obtainToken(
          _loginController.text.trim(),
          _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (tokenResponse.success) {
          // Токен получен успешно
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
          
          // TODO: Навигация на главный экран
          // Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Ошибка авторизации
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tokenResponse.error ?? 'Ошибка авторизации'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка подключения к серверу'),
              backgroundColor: Colors.red,
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
            // Переход к экрану регистрации
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterScreen(),
              ),
            );
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
