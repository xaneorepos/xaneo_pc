import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/geometry_3d.dart';
import '../widgets/advanced_background.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/account_service.dart';
import '../services/logger_service.dart';
import '../widgets/settings_modal.dart';
import '../widgets/custom_toast.dart';
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
    final username = _loginController.text.trim();
    Logger.info('LoginScreen', 'Login attempt started for user: $username');
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final password = _passwordController.text;
        
        // Получаем JWT токен
        Logger.info('LoginScreen', 'Requesting JWT token for user: $username');
        final tokenResponse = await _apiService.obtainToken(username, password);

        if (tokenResponse.success) {
          Logger.info('LoginScreen', 'Token obtained successfully. Fetching E2EE keys from server.');
          // Токен получен успешно, теперь настраиваем крипто-ключи (E2EE)
          final keysResponse = await _apiService.getMyKeys();
          bool cryptoSetupSuccess = false;

          if (keysResponse.success && keysResponse.data != null && keysResponse.data!['xsec2'] != null) {
            // Ключи есть на сервере, расшифровываем их
            Logger.info('LoginScreen', 'Keys found on server. Attempting to unlock/decrypt key bundle.');
            final xsec2 = keysResponse.data!['xsec2'] as Map<String, dynamic>;
            final encryptedBlob = xsec2['encrypted_blob'] as Map<String, dynamic>;
            
            cryptoSetupSuccess = await CryptoService().unlockFromBlob(encryptedBlob, password);
            Logger.info('LoginScreen', 'Key bundle decryption result: $cryptoSetupSuccess');

            if (!cryptoSetupSuccess) {
              // В случае неудачи (например, старый Argon2id blob с веб-клиента),
              // генерируем новые ключи в поддерживаемом формате pbkdf2-aes-gcm и загружаем их.
              Logger.warning('LoginScreen', 'Failed to decrypt server keys. Regenerating new keys under pbkdf2-aes-gcm...');
              try {
                final newBlob = await CryptoService().generateAndStoreKeys(password);
                final uploadResponse = await _apiService.uploadKeys(
                  x25519PublicKey: newBlob['pub']['x25519'] as String,
                  ed25519PublicKey: newBlob['pub']['ed25519'] as String,
                  encryptedBlob: newBlob,
                );
                cryptoSetupSuccess = uploadResponse.success;
                Logger.info('LoginScreen', 'Fallback key regeneration and upload success status: $cryptoSetupSuccess');
                if (!cryptoSetupSuccess) {
                  Logger.error('LoginScreen', 'Failed to upload regenerated keys: ${uploadResponse.error}');
                  if (mounted) {
                    CustomToast.show(
                      context,
                      uploadResponse.error ?? 'Ошибка восстановления ключей (не удалось перезаписать)',
                      type: ToastType.error,
                    );
                  }
                }
              } catch (e) {
                Logger.error('LoginScreen', 'Error during fallback key generation', e);
                if (mounted) {
                  CustomToast.show(
                    context,
                    'Критическая ошибка при пересоздании ключей шифрования',
                    type: ToastType.error,
                  );
                }
              }
            }
          } else if (keysResponse.statusCode == 404 || (keysResponse.data != null && keysResponse.data!['code'] == 'KEYS_NOT_FOUND')) {
            // Ключей нет на сервере, генерируем новые
            Logger.info('LoginScreen', 'Keys not found on server (404/KEYS_NOT_FOUND). Generating new keys.');
            try {
              final newBlob = await CryptoService().generateAndStoreKeys(password);
              final uploadResponse = await _apiService.uploadKeys(
                x25519PublicKey: newBlob['pub']['x25519'] as String,
                ed25519PublicKey: newBlob['pub']['ed25519'] as String,
                encryptedBlob: newBlob,
              );
              
              cryptoSetupSuccess = uploadResponse.success;
              Logger.info('LoginScreen', 'New key generation and upload success status: $cryptoSetupSuccess');
              if (!cryptoSetupSuccess) {
                Logger.error('LoginScreen', 'Failed to upload new keys: ${uploadResponse.error}');
                if (mounted) {
                  CustomToast.show(
                    context,
                    uploadResponse.error ?? 'Ошибка загрузки ключей на сервер',
                    type: ToastType.error,
                  );
                }
              }
            } catch (e) {
              Logger.error('LoginScreen', 'Error generating and uploading new keys', e);
            }
          } else {
            // Другая ошибка при получении ключей
            Logger.error('LoginScreen', 'Failed to fetch keys from server: ${keysResponse.error} (status ${keysResponse.statusCode})');
            if (mounted) {
              CustomToast.show(
                context,
                keysResponse.error ?? 'Ошибка при получении ключей шифрования',
                type: ToastType.error,
              );
            }
          }

          setState(() {
            _isLoading = false;
          });

          if (cryptoSetupSuccess) {
            Logger.info('LoginScreen', 'Crypto keys successfully configured. Fetching user profile...');
            final profileRes = await _apiService.getProfile();
            bool savedSuccess = false;
            if (profileRes.success && profileRes.data != null) {
              Logger.info('LoginScreen', 'Profile fetched successfully. Saving current account: ${profileRes.data!['username']}');
              savedSuccess = await AccountService().saveCurrentAccount(profileRes.data!);
            } else {
              Logger.error('LoginScreen', 'Failed to fetch user profile: ${profileRes.error}');
            }
            
            if (!savedSuccess) {
              Logger.error('LoginScreen', 'Failed to save account locally. Exceeded account limit or save error.');
              await _apiService.logout();
              await CryptoService().clearKeys();
              if (mounted) {
                CustomToast.show(
                  context,
                  'Превышен лимит в 5 аккаунтов на этом клиенте или ошибка подключения.',
                  type: ToastType.error,
                );
              }
              setState(() {
                _isLoading = false;
              });
              return;
            }

            if (mounted) {
              Logger.info('LoginScreen', 'Login flow completed successfully. Navigating to messenger.');
              final l10n = AppLocalizations.of(context);
              if (l10n != null) {
                CustomToast.show(
                  context,
                  l10n.welcomeUser(_loginController.text),
                  type: ToastType.success,
                );
              }
              // Навигация в мессенджер
              Navigator.of(context).pushReplacementNamed('/messenger');
            }
          }
        } else {
          Logger.warning('LoginScreen', 'Token obtain failed: ${tokenResponse.error} (status ${tokenResponse.statusCode})');
          setState(() {
            _isLoading = false;
          });
          // Ошибка авторизации
          if (mounted) {
            CustomToast.show(
              context,
              tokenResponse.error ?? 'Ошибка авторизации',
              type: ToastType.error,
            );
          }
        }
      } catch (e, stack) {
        Logger.error('LoginScreen', 'Unexpected error during login process', e, stack);
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          CustomToast.show(
            context,
            'Ошибка подключения к серверу',
            type: ToastType.error,
          );
        }
      }
    } else {
      Logger.warning('LoginScreen', 'Form validation failed.');
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
          
          // Кнопка настроек
          const Positioned.fill(
            child: SettingsButton(),
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
            spellCheckConfiguration: null,
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
            spellCheckConfiguration: null,
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
