import 'dart:ui';
import 'dart:math' as math;
import 'dart:io' show Platform, Process;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

/// Глобальная кнопка настроек с модальным окном
class SettingsButton extends StatefulWidget {
  const SettingsButton({super.key});

  @override
  State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton>
    with TickerProviderStateMixin {
  bool _showSettings = false;
  late AnimationController _settingsAnimationController;
  late AnimationController _pulseController;
  late AnimationController _aboutAnimationController;

  // Переменные настроек
  bool _notificationsEnabled = true;
  double _fontSize = 16.0;
  int _selectedLanguageIndex = 1;

  // Список доступных языков
  final List<Map<String, String>> _availableLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ru', 'name': 'Русский'},
  ];

  @override
  void initState() {
    super.initState();

    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _aboutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _settingsAnimationController.dispose();
    _aboutAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openSettings() {
    setState(() => _showSettings = true);
    _settingsAnimationController.forward();
  }

  void _closeSettings() async {
    await _settingsAnimationController.reverse();
    setState(() => _showSettings = false);
  }

  Future<String> _getProcessorArchitecture() async {
    try {
      final result = await Process.run('uname', ['-m']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showAboutDialog(BuildContext context, bool isDark) async {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Получаем информацию о платформе
    final platform = Platform.isLinux ? 'Linux' : Platform.operatingSystem;
    final processorArch = await _getProcessorArchitecture();
    final version = '1.0.0'; // Можно сделать динамическим из pubspec.yaml

    // Запускаем анимацию
    _aboutAnimationController.forward();

    // Создаем OverlayEntry для модалки о приложении
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _aboutAnimationController,
        builder: (context, child) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Затемнение
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    _aboutAnimationController.reverse().then((_) {
                      overlayEntry.remove();
                    });
                  },
                  child: Container(
                    color: isDark
                        ? Colors.black.withOpacity(0.6 * _aboutAnimationController.value)
                        : Colors.black.withOpacity(0.4 * _aboutAnimationController.value),
                  ),
                ),
              ),

              // Контент модалки
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.95,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _aboutAnimationController,
                    curve: Curves.easeOut,
                  )),
                  child: Container(
                  width: screenSize.width * 0.85,
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    maxHeight: screenSize.height * 0.85,
                  ),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.grey.shade900.withOpacity(0.95),
                              Colors.black.withOpacity(0.95),
                            ]
                          : [
                              Colors.white.withOpacity(0.95),
                              Colors.grey.shade50.withOpacity(0.9),
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
                            : Colors.grey.withOpacity(0.6),
                        blurRadius: 60,
                        spreadRadius: 15,
                        offset: const Offset(0, 25),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Заголовок
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.06),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
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
                                                    Colors.white.withOpacity(0.25),
                                                    Colors.white.withOpacity(0.1),
                                                  ]
                                                : [
                                                    Colors.black.withOpacity(0.15),
                                                    Colors.black.withOpacity(0.05),
                                                  ],
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.3)
                                                : Colors.black.withOpacity(0.15),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.star_rounded,
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
                                    l10n?.about ?? 'О приложении',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      _aboutAnimationController.reverse().then((_) {
                                        overlayEntry.remove();
                                      });
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.06),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.1),
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

                          // Содержимое
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Огромный логотип с названием
                                  Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDark
                                                  ? [
                                                      Colors.white.withOpacity(0.2),
                                                      Colors.grey.shade800.withOpacity(0.6),
                                                    ]
                                                  : [
                                                      Colors.black.withOpacity(0.1),
                                                      Colors.grey.shade200.withOpacity(0.6),
                                                    ],
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withOpacity(0.25)
                                                  : Colors.black.withOpacity(0.12),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'X',
                                              style: TextStyle(
                                                color: isDark ? Colors.white : Colors.black,
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Xaneo PC',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${l10n?.version ?? 'Версия'}: $version',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Техническая информация
                                  _buildSectionHeader('🔧 ${l10n?.technicalInfo ?? 'Техническая информация'}', isDark, Icons.build),
                                  const SizedBox(height: 12),
                                  _buildFeatureItem(l10n?.platform ?? 'Платформа', platform, isDark),
                                  _buildFeatureItem(l10n?.architecture ?? 'Архитектура процессора', processorArch, isDark),
                                  const SizedBox(height: 24),

                                  // Ссылка на GitHub
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () async {
                                        const url = 'https://github.com/saneome/xaneo_pc';
                                        if (await canLaunchUrl(Uri.parse(url))) {
                                          await launchUrl(Uri.parse(url));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isDark
                                                ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]
                                                : [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.01)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.08)
                                                : Colors.black.withOpacity(0.04),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.link,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n?.viewOnGitHub ?? 'Посмотреть на GitHub',
                                              style: TextStyle(
                                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                                fontSize: 13,
                                                fontFamily: 'Inter',
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Кнопка закрытия
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      _aboutAnimationController.reverse().then((_) {
                                        overlayEntry.remove();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isDark
                                              ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.06)]
                                              : [Colors.black.withOpacity(0.06), Colors.black.withOpacity(0.03)],
                                        ),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.1),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        l10n?.close ?? 'Закрыть',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));

    // Добавляем OverlayEntry в Overlay
    Overlay.of(context).insert(overlayEntry);
  }

  Widget _buildFeatureItem(String title, String description, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.01)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)]
                    : [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Stack(
      children: [
        // Кнопка настроек
        Positioned(
          top: 50,
          right: 20,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _openSettings,
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

        // Модальное окно настроек
        if (_showSettings) _buildSettingsModal(context, isDark),
      ],
    );
  }

  Widget _buildSettingsModal(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return AnimatedBuilder(
      animation: _settingsAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Затемнение
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

            // Контент модального окна
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
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Заголовок
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
                                        l10n?.settings ?? 'Настройки',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
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

                              // Содержимое
                              Flexible(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(l10n?.darkTheme ?? 'Тёмная тема', isDark, Icons.palette_outlined),
                                      const SizedBox(height: 10),
                                      _buildAnimatedSettingsTile(
                                        icon: Icons.dark_mode_rounded,
                                        title: l10n?.darkTheme ?? 'Тёмная тема',
                                        subtitle: l10n?.darkThemeDescription ?? 'Включить тёмную тему',
                                        isDark: isDark,
                                        trailing: _buildAnimatedSwitch(
                                          value: themeProvider.isDarkMode,
                                          isDark: isDark,
                                          onChanged: (value) => themeProvider.setDarkMode(value),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _buildSectionHeader(l10n?.language ?? 'Язык', isDark, Icons.translate_rounded),
                                      const SizedBox(height: 10),
                                      _buildLanguageSelector(localeProvider, isDark, l10n),
                                      const SizedBox(height: 24),
                                      _buildSectionHeader(l10n?.notifications ?? 'Уведомления', isDark, Icons.notifications_outlined),
                                      const SizedBox(height: 10),
                                      _buildAnimatedSettingsTile(
                                        icon: Icons.notifications_active_rounded,
                                        title: l10n?.notifications ?? 'Уведомления',
                                        subtitle: l10n?.notificationsDescription ?? 'Включить уведомления',
                                        isDark: isDark,
                                        trailing: _buildAnimatedSwitch(
                                          value: _notificationsEnabled,
                                          isDark: isDark,
                                          onChanged: (value) {
                                            setState(() => _notificationsEnabled = value);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _buildSectionHeader(l10n?.fontSize(_fontSize.round()) ?? 'Размер шрифта: ${_fontSize.round()}', isDark, Icons.text_fields_rounded),
                                      const SizedBox(height: 10),
                                      _buildFontSizeSlider(isDark),
                                      const SizedBox(height: 24),
                                      _buildSectionHeader(l10n?.about ?? 'О приложении', isDark, Icons.info_outlined),
                                      const SizedBox(height: 10),
                                      _buildAnimatedSettingsTile(
                                        icon: Icons.info_rounded,
                                        title: l10n?.about ?? 'О приложении',
                                        subtitle: l10n?.aboutDescription ?? 'Информация о приложении',
                                        isDark: isDark,
                                        trailing: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () => _showAboutDialog(context, isDark),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isDark
                                                    ? Colors.white.withOpacity(0.1)
                                                    : Colors.black.withOpacity(0.05),
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: isDark ? Colors.white : Colors.black,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

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
                ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                : [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.01)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
              child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
            ),
            const SizedBox(width: 14),
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
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

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
          color: value ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
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

  Widget _buildFontSizeSlider(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.01)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            child: const Text('Aa Бб Вв'),
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                activeTrackColor: isDark ? Colors.white : Colors.black,
                inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                thumbColor: isDark ? Colors.white : Colors.black,
                overlayColor: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
              ),
              child: Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (value) => setState(() => _fontSize = value),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 11)),
              Text('24', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(LocaleProvider localeProvider, bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.01)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: _availableLanguages.map((lang) {
          final isSelected = localeProvider.locale?.languageCode == lang['code'];
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                localeProvider.setLocale(Locale(lang['code']!));
                setState(() {
                  _selectedLanguageIndex = _availableLanguages.indexWhere((l) => l['code'] == lang['code']);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      lang['name']!,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
