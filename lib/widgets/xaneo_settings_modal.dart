import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import '../models/app_version_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'base_custom_modal.dart';

// ─── Описание раздела настроек ──────────────────────────────────────────────


class _SettingsSection {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  const _SettingsSection({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.gradient = const [Color(0xFF2563EB), Color(0xFF7C3AED)],
  });
}

// Разделы только для авторизованных пользователей
final _accountSections = [
  _SettingsSection(
    id: 'personal',
    title: 'Личные данные',
    description: 'Имя, никнейм, фото профиля, о себе',
    icon: Icons.person_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'privacy',
    title: 'Приватность',
    description: 'Кто может писать, звонить, видеть профиль',
    icon: Icons.lock_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'chats',
    title: 'Настройки чатов',
    description: 'Уведомления, темы пузырьков, история',
    icon: Icons.chat_bubble_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'contacts',
    title: 'Контакты',
    description: 'Ваши сохранённые контакты',
    icon: Icons.people_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'security',
    title: 'Безопасность',
    description: 'Сессии, пароль, двойная аутентификация',
    icon: Icons.shield_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
];

// Разделы интерфейса (доступны всегда)
final _interfaceSections = [
  _SettingsSection(
    id: 'appearance',
    title: 'Внешний вид',
    description: 'Тема, шрифт, масштаб интерфейса',
    icon: Icons.palette_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'language',
    title: 'Язык',
    description: 'Язык интерфейса клиента',
    icon: Icons.language_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'notifications',
    title: 'Уведомления',
    description: 'Звуки, баннеры, показ уведомлений',
    icon: Icons.notifications_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'energy',
    title: 'Энергосбережение',
    description: 'Анимации, фоновая активность, производительность',
    icon: Icons.bolt_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _SettingsSection(
    id: 'about',
    title: 'О приложении',
    description: 'Версия, проверка обновлений, ссылки',
    icon: Icons.info_outline_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
];


// ─── Главный виджет ──────────────────────────────────────────────────────────

class XaneoSettingsModal extends BaseCustomModal {
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onLogout;
  final Function(dynamic contact)? onSelectChat;
  final Function(dynamic contact)? onStartCall;

  const XaneoSettingsModal({
    super.key,
    this.currentUser,
    this.onLogout,
    this.onSelectChat,
    this.onStartCall,
  }) : super(modalTag: 'НАСТРОЙКИ', title: 'Настройки');

  /// Открыть модалку настроек через BaseCustomModal.show
  static Future<void> open(
    BuildContext context, {
    Map<String, dynamic>? currentUser,
    VoidCallback? onLogout,
    Function(dynamic contact)? onSelectChat,
    Function(dynamic contact)? onStartCall,
  }) {
    return BaseCustomModal.show(
      context: context,
      modal: XaneoSettingsModal(
        currentUser: currentUser,
        onLogout: onLogout,
        onSelectChat: onSelectChat,
        onStartCall: onStartCall,
      ),
      barrierLabel: 'SettingsModal',
    );
  }

  @override
  State<XaneoSettingsModal> createState() => _XaneoSettingsModalState();
}

// ─── State ───────────────────────────────────────────────────────────────────

class _XaneoSettingsModalState
    extends BaseCustomModalState<XaneoSettingsModal> {
  @override
  double get modalWidth => 580.0;

  @override
  double get modalHeightFactor => 0.90;

  // ── Update ─────────────────────────────────────────────────────────────────
  bool _isCheckingUpdate = false;
  String? _updateStatusMessage;
  AppVersionInfo? _foundUpdateInfo;

  Future<void> _handleManualUpdateCheck() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = 'Проверка обновлений...';
      _foundUpdateInfo = null;
    });

    final update = await UpdateService().checkForUpdates(force: true);
    final currentVersion = await UpdateService().getCurrentVersion();

    if (!mounted) return;

    setState(() {
      _isCheckingUpdate = false;
      if (update != null) {
        _foundUpdateInfo = update;
        _updateStatusMessage = 'Доступна новая версия v${update.version}!';
      } else {
        _updateStatusMessage = 'У вас установлена актуальная версия v$currentVersion';
      }
    });
  }

  // ── Appearance ────────────────────────────────────────────────────────────

  double _fontSize = 15.0;

  // ── Notifications ─────────────────────────────────────────────────────────
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  // ── Energy ────────────────────────────────────────────────────────────────
  bool _reducedMotion = false;
  bool _lowPowerMode = false;
  bool _messageAnimations = true;
  bool _autoSleep = true;

  // ── Privacy ──────────────────────────────────────────────────────────────
  String _whoCanMessage = 'all';
  String _whoCanCall = 'all';
  String _whoCanRecordVoice = 'all';
  String _whoCanSendFiles = 'all';
  String _whoCanInvite = 'all';
  String _whoSeesNickname = 'all';
  String _whoSeesAvatar = 'all';
  String _whoSeesBirthday = 'all';
  String _whoSeesOnlineTime = 'all';
  bool _privacyLoading = false;
  bool _privacyLoaded = false;  // флаг: загружали ли уже
  bool _privacySaving = false;
  String? _privacyError;

  // ── Contacts ─────────────────────────────────────────────────────────────
  List<dynamic> _pcContacts = [];
  bool _pcContactsLoading = false;
  bool _pcContactsLoaded = false;
  String? _pcContactsError;

  // ── Personal ─────────────────────────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _personalSaving = false;
  String? _personalError;
  String? _personalSuccess;

  bool get _isLoggedIn => widget.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    if (_isLoggedIn) {
      final u = widget.currentUser!;
      _firstNameCtrl.text = u['first_name']?.toString() ?? '';
      _usernameCtrl.text = u['username']?.toString() ?? '';
      _bioCtrl.text = u['bio']?.toString() ?? '';
      _fetchFreshProfile();
    }
  }

  Future<void> _fetchFreshProfile() async {
    try {
      final res = await ApiService().dio.get('/user/profile/');
      final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : null;
      if (data != null && mounted) {
        setState(() {
          if (widget.currentUser != null) {
            widget.currentUser!.addAll(data);
          }
          _firstNameCtrl.text = data['first_name']?.toString() ?? '';
          _usernameCtrl.text = data['username']?.toString() ?? '';
          _bioCtrl.text = data['bio']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('settings_notifications') ?? true;
        _soundEnabled = prefs.getBool('settings_sound') ?? true;
        _fontSize = prefs.getDouble('settings_font_size') ?? 15.0;
        _reducedMotion = prefs.getBool('settings_reduced_motion') ?? false;
        _lowPowerMode = prefs.getBool('settings_low_power') ?? false;
        _messageAnimations = prefs.getBool('settings_msg_animations') ?? true;
        _autoSleep = prefs.getBool('settings_auto_sleep') ?? true;
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notifications', _notificationsEnabled);
    await prefs.setBool('settings_sound', _soundEnabled);
    await prefs.setDouble('settings_font_size', _fontSize);
    await prefs.setBool('settings_reduced_motion', _reducedMotion);
    await prefs.setBool('settings_low_power', _lowPowerMode);
    await prefs.setBool('settings_msg_animations', _messageAnimations);
    await prefs.setBool('settings_auto_sleep', _autoSleep);
  }

  Future<void> _loadPrivacySettings() async {
    if (_privacyLoading) return;
    setState(() {
      _privacyLoading = true;
      _privacyError = null;
    });
    try {
      final res = await ApiService().dio.get('/user/privacy-settings/');
      final d = res.data?['privacy_settings'] ?? res.data ?? {};
      if (mounted) {
        setState(() {
          _whoCanMessage = d['who_can_message'] ?? 'all';
          _whoCanCall = d['who_can_call'] ?? 'all';
          _whoCanRecordVoice = d['who_can_record_voice'] ?? 'all';
          _whoCanSendFiles = d['who_can_send_files'] ?? 'all';
          _whoCanInvite = d['who_can_invite'] ?? 'all';
          _whoSeesNickname = d['who_sees_nickname'] ?? 'all';
          _whoSeesAvatar = d['who_sees_avatar'] ?? 'all';
          _whoSeesBirthday = d['who_sees_birthday'] ?? 'all';
          _whoSeesOnlineTime = d['who_sees_online_time'] ?? 'all';
          _privacyLoading = false;
          _privacyLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _privacyLoading = false;
          _privacyLoaded = true;
          _privacyError = 'Не удалось загрузить настройки';
        });
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() {
      _privacySaving = true;
      _privacyError = null;
    });
    try {
      await ApiService().dio.patch('/user/privacy-settings/', data: {
        'who_can_message': _whoCanMessage,
        'who_can_call': _whoCanCall,
        'who_can_record_voice': _whoCanRecordVoice,
        'who_can_send_files': _whoCanSendFiles,
        'who_can_invite': _whoCanInvite,
        'who_sees_nickname': _whoSeesNickname,
        'who_sees_avatar': _whoSeesAvatar,
        'who_sees_birthday': _whoSeesBirthday,
        'who_sees_online_time': _whoSeesOnlineTime,
      });
      if (mounted) setState(() => _privacySaving = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _privacySaving = false;
          _privacyError = 'Ошибка сохранения';
        });
      }
    }
  }

  Future<void> _savePersonalData() async {
    setState(() {
      _personalSaving = true;
      _personalError = null;
      _personalSuccess = null;
    });
    try {
      final newFirstName = _firstNameCtrl.text.trim();
      final newBio = _bioCtrl.text.trim();

      final res = await ApiService().dio.patch('/user/profile/', data: {
        'first_name': newFirstName,
        'bio': newBio,
      });

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          if (widget.currentUser != null) {
            widget.currentUser!['first_name'] = newFirstName;
            widget.currentUser!['bio'] = newBio;
          }
          setState(() {
            _personalSaving = false;
            _personalSuccess = 'Данные сохранены';
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _personalSuccess = null);
          });
        } else {
          setState(() {
            _personalSaving = false;
            _personalError = 'Ошибка сохранения';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _personalSaving = false;
          _personalError = 'Ошибка сохранения: $e';
        });
      }
    }
  }

  // ── buildContent ────────────────────────────────────────────────────────────

  @override
  Widget buildContent(
      BuildContext context, ScrollController sc, bool isDark, double scale) {
    final currentKey = ValueKey(_activeSection ?? 'menu');
    final isMenu = _activeSection == null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final childKey = child.key as ValueKey<String>?;
        final isChildMenu = childKey?.value == 'menu';
        
        final slideOffset = isChildMenu
            ? const Offset(-0.03, 0)
            : const Offset(0.03, 0);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: slideOffset,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: currentKey,
        child: isMenu
            ? _buildMenu(context, isDark, scale, sc)
            : _buildSectionView(context, isDark, scale),
      ),
    );
  }

  // ── Главное меню ────────────────────────────────────────────────────────────

  Widget _buildMenu(
      BuildContext context, bool isDark, double scale, ScrollController sc) {
    final divider = Divider(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
      thickness: 1,
      height: 1,
    );

    final user = widget.currentUser;
    final firstName = user?['first_name']?.toString() ??
        user?['username']?.toString() ??
        'Гость';
    final username = user?['username']?.toString() ?? '';
    final avatar = user?['avatar']?.toString();
    final gradient = user?['avatar_gradient']?.toString() ?? '';

    return ListView(
      controller: sc,
      shrinkWrap: true,
      children: [
        // Блок пользователя
        _isLoggedIn
            ? _buildUserCard(firstName, username, avatar, gradient, isDark, scale)
            : _buildGuestCard(isDark, scale),

        divider,
        SizedBox(height: 14 * scale),

        // Раздел аккаунта
        if (_isLoggedIn) ...[
          _groupLabel('АККАУНТ', isDark, scale),
          SizedBox(height: 6 * scale),
          ..._accountSections.map((s) => _menuRow(s, isDark, scale)),
          SizedBox(height: 16 * scale),
          divider,
          SizedBox(height: 14 * scale),
        ],

        // Раздел интерфейса
        _groupLabel('ИНТЕРФЕЙС', isDark, scale),
        SizedBox(height: 6 * scale),
        ..._interfaceSections.map((s) => _menuRow(s, isDark, scale)),

        // Выйти
        if (_isLoggedIn && widget.onLogout != null) ...[
          SizedBox(height: 16 * scale),
          divider,
          SizedBox(height: 8 * scale),
          _dangerRow(
            icon: Icons.logout_rounded,
            label: 'Выйти из аккаунта',
            isDark: isDark,
            scale: scale,
            onTap: () {
              Navigator.of(context).pop();
              widget.onLogout?.call();
            },
          ),
        ],

        SizedBox(height: 16 * scale),
        Center(
          child: Text(
            'Xaneo PC v1.0.0',
            style: TextStyle(
              fontSize: 11 * scale,
              color: isDark ? Colors.white24 : Colors.black26,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: 4 * scale),
      ],
    );
  }

  // ── Подраздел ────────────────────────────────────────────────────────────────

  Widget _buildSectionView(BuildContext context, bool isDark, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовок с кнопкой «Назад»
        Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _activeSection = null),
                child: Container(
                  padding: EdgeInsets.all(6 * scale),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14 * scale,
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
            SizedBox(width: 10 * scale),
            Text(
              _sectionTitle(_activeSection!),
              style: TextStyle(
                fontSize: 17 * scale,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 18 * scale),
        Flexible(
          child: SingleChildScrollView(
            child: _buildSectionBody(context, _activeSection!, isDark, scale),
          ),
        ),
      ],
    );
  }

  String _sectionTitle(String id) {
    const m = {
      'appearance': 'Внешний вид',
      'language': 'Язык',
      'notifications': 'Уведомления',
      'energy': 'Энергосбережение',
      'personal': 'Личные данные',
      'chats': 'Настройки чатов',
      'privacy': 'Приватность',
      'contacts': 'Контакты',
      'security': 'Безопасность',
    };
    return m[id] ?? id;
  }

  Widget _buildSectionBody(
      BuildContext context, String id, bool isDark, double scale) {
    switch (id) {
      case 'appearance':
        return _buildAppearance(context, isDark, scale);
      case 'language':
        return _buildLanguage(context, isDark, scale);
      case 'notifications':
        return _buildNotifications(isDark, scale);
      case 'energy':
        return _buildEnergy(isDark, scale);
      case 'personal':
        return _buildPersonal(isDark, scale);
      case 'privacy':
        return _buildPrivacy(isDark, scale);
      case 'contacts':
        return _buildContacts(isDark, scale);
      case 'chats':
        return _buildChats(isDark, scale);
      case 'security':
        return _buildSecurity(isDark, scale);
      case 'about':
        return _buildAboutSection(isDark, scale);
      default:
        return _comingSoon(isDark, scale);
    }
  }

  Widget _buildAboutSection(bool isDark, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'О приложении',
          subtitle: 'Информация о клиенте Xaneo PC и проверка обновлений',
          icon: Icons.info_outline_rounded,
          gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          isDark: isDark,
          scale: scale,
        ),
        SizedBox(height: 16 * scale),
        Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.desktop_windows_rounded, size: 24 * scale, color: isDark ? Colors.white : Colors.black87),
                  SizedBox(width: 12 * scale),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xaneo PC Desktop Client',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Версия: 1.0.0+1 (Linux / Windows / macOS)',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16 * scale),
              if (_updateStatusMessage != null) ...[
                Text(
                  _updateStatusMessage!,
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w500,
                    color: _foundUpdateInfo != null
                        ? Colors.greenAccent
                        : (isDark ? Colors.white70 : Colors.black70),
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 12 * scale),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isCheckingUpdate ? null : _handleManualUpdateCheck,
                    icon: _isCheckingUpdate
                        ? SizedBox(
                            width: 14 * scale,
                            height: 14 * scale,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh_rounded, size: 16 * scale),
                    label: Text(
                      _isCheckingUpdate ? 'Проверка...' : 'Проверить обновления',
                      style: TextStyle(fontSize: 13 * scale, fontFamily: 'Inter'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black87,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                    ),
                  ),
                  if (_foundUpdateInfo != null) ...[
                    SizedBox(width: 10 * scale),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(_foundUpdateInfo!.downloadUrl ?? _foundUpdateInfo!.htmlUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: Icon(Icons.download_rounded, size: 16 * scale),
                      label: Text('Скачать v${_foundUpdateInfo!.version}', style: TextStyle(fontSize: 13 * scale, fontFamily: 'Inter')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.greenAccent),
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ── Personal ─────────────────────────────────────────────────────────────────

  Widget _buildPersonal(bool isDark, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Основная информация', isDark, scale),
        SizedBox(height: 10 * scale),
        _inputField(
          label: 'Имя',
          controller: _firstNameCtrl,
          isDark: isDark,
          scale: scale,
          hint: 'Введите ваше имя',
        ),
        SizedBox(height: 12 * scale),
        _inputField(
          label: 'Никнейм',
          controller: _usernameCtrl,
          isDark: isDark,
          scale: scale,
          hint: '@username',
          readOnly: true,
          note: 'Никнейм нельзя изменить в приложении',
        ),
        SizedBox(height: 12 * scale),
        _textAreaField(
          label: 'О себе',
          controller: _bioCtrl,
          isDark: isDark,
          scale: scale,
          hint: 'Расскажите о себе...',
        ),
        SizedBox(height: 18 * scale),
        if (_personalError != null)
          _errorBanner(_personalError!, isDark, scale),
        if (_personalSuccess != null)
          _successBanner(_personalSuccess!, isDark, scale),
        _primaryButton(
          label: _personalSaving ? 'Сохранение...' : 'Сохранить',
          isDark: isDark,
          scale: scale,
          onTap: _personalSaving ? null : _savePersonalData,
        ),
      ],
    );
  }

  // ── Privacy ──────────────────────────────────────────────────────────────────

  Widget _buildPrivacy(bool isDark, double scale) {
    // Загружаем один раз при первом открытии секции
    if (!_privacyLoaded && !_privacyLoading) {
      _privacyLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPrivacySettings();
      });
    }

    if (_privacyLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32 * scale),
          child: CircularProgressIndicator(
            color: const Color(0xFF2563EB),
            strokeWidth: 2,
          ),
        ),
      );
    }

    const options = [
      ('all', 'Все'),
      ('contacts', 'Только контакты'),
      ('nobody', 'Никто'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Коммуникации', isDark, scale),
        SizedBox(height: 8 * scale),
        _dropdownRow(
          label: 'Кто может писать сообщения',
          value: _whoCanMessage,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanMessage = v),
        ),
        _dropdownRow(
          label: 'Кто может звонить',
          value: _whoCanCall,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanCall = v),
        ),
        _dropdownRow(
          label: 'Кто может записывать голосовые',
          value: _whoCanRecordVoice,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanRecordVoice = v),
        ),
        _dropdownRow(
          label: 'Кто может отправлять файлы',
          value: _whoCanSendFiles,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanSendFiles = v),
        ),
        _dropdownRow(
          label: 'Кто может приглашать в группы',
          value: _whoCanInvite,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanInvite = v),
        ),
        SizedBox(height: 16 * scale),
        _sectionHeader('Видимость профиля', isDark, scale),
        SizedBox(height: 8 * scale),
        _dropdownRow(
          label: 'Кто видит мой никнейм',
          value: _whoSeesNickname,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesNickname = v),
        ),
        _dropdownRow(
          label: 'Кто видит мой аватар',
          value: _whoSeesAvatar,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesAvatar = v),
        ),
        _dropdownRow(
          label: 'Кто видит мой день рождения',
          value: _whoSeesBirthday,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesBirthday = v),
        ),
        _dropdownRow(
          label: 'Кто видит время моей активности',
          value: _whoSeesOnlineTime,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesOnlineTime = v),
        ),
        SizedBox(height: 18 * scale),
        if (_privacyError != null) _errorBanner(_privacyError!, isDark, scale),
        _primaryButton(
          label: _privacySaving ? 'Сохранение...' : 'Сохранить',
          isDark: isDark,
          scale: scale,
          onTap: _privacySaving ? null : _savePrivacySettings,
        ),
      ],
    );
  }

  // ── Contacts ─────────────────────────────────────────────────────────────────

  Future<void> _loadPcContacts() async {
    setState(() {
      _pcContactsLoading = true;
      _pcContactsError = null;
    });
    try {
      final res = await ApiService().dio.get('/contacts/list/');
      final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {};
      final list = data['contacts'] is List ? data['contacts'] as List : [];
      if (mounted) {
        setState(() {
          _pcContacts = list;
          _pcContactsLoading = false;
          _pcContactsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pcContactsLoading = false;
          _pcContactsLoaded = true;
          _pcContactsError = 'Не удалось загрузить контакты';
        });
      }
    }
  }

  Future<void> _deletePcContact(int contactUserId) async {
    try {
      await ApiService().dio.post('/contacts/delete/', data: {'user_id': contactUserId});
      _loadPcContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления контакта: $e')),
        );
      }
    }
  }

  void _showAddContactDialog(bool isDark, double scale) {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * scale)),
        title: Text(
          'Добавить контакт',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14 * scale),
              decoration: InputDecoration(
                hintText: 'Никнейм пользователя',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13 * scale),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 10 * scale),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14 * scale),
              decoration: InputDecoration(
                hintText: 'Отображаемое имя (опционально)',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13 * scale),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Отмена', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black87,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final un = usernameCtrl.text.trim().replaceAll('@', '');
              final cn = nameCtrl.text.trim();
              if (un.isNotEmpty) {
                Navigator.of(ctx).pop();
                try {
                  await ApiService().dio.post('/contacts/create/', data: {
                    'username': un,
                    if (cn.isNotEmpty) 'custom_name': cn,
                  });
                  _loadPcContacts();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Не удалось добавить контакт: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Widget _buildContacts(bool isDark, double scale) {
    if (!_pcContactsLoaded && !_pcContactsLoading) {
      _loadPcContacts();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('Контакты (${_pcContacts.length})', isDark, scale),
            TextButton.icon(
              onPressed: () => _showAddContactDialog(isDark, scale),
              icon: Icon(Icons.person_add_rounded, size: 16 * scale, color: isDark ? Colors.white70 : Colors.black87),
              label: Text(
                'Добавить',
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * scale),
        if (_pcContactsLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30 * scale),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          )
        else if (_pcContactsError != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20 * scale),
            child: Text(
              _pcContactsError!,
              style: TextStyle(fontSize: 13 * scale, color: Colors.redAccent),
            ),
          )
        else if (_pcContacts.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30 * scale),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline_rounded, size: 40 * scale, color: isDark ? Colors.white30 : Colors.black26),
                  SizedBox(height: 8 * scale),
                  Text(
                    'У вас пока нет сохранённых контактов',
                    style: TextStyle(fontSize: 13 * scale, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pcContacts.length,
            separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
            itemBuilder: (context, index) {
              final item = _pcContacts[index];
              final userId = item['contact_user_id'] ?? 0;
              final username = item['contact_user_username']?.toString() ?? '';
              final firstName = item['contact_user_first_name']?.toString() ?? '';
              final customName = item['custom_name']?.toString();
              final avatar = item['custom_avatar'] ?? item['contact_user_avatar'];
              final gradient = item['contact_user_avatar_gradient']?.toString() ?? '';

              final displayName = (customName != null && customName.isNotEmpty)
                  ? customName
                  : (firstName.isNotEmpty ? firstName : username);

              return Container(
                padding: EdgeInsets.all(10 * scale),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    // Аватар
                    _buildUserCardAvatar(avatar?.toString(), gradient, displayName, 40 * scale),
                    SizedBox(width: 12 * scale),
                    // Имя и юзернейм
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (username.isNotEmpty)
                            Text(
                              '@$username',
                              style: TextStyle(
                                fontSize: 11 * scale,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Действия (Позвонить, Написать, Вертикальное троеточие)
                    IconButton(
                      icon: Icon(Icons.phone_rounded, size: 18 * scale),
                      color: isDark ? Colors.white70 : Colors.black87,
                      tooltip: 'Позвонить',
                      onPressed: () {
                        if (widget.onStartCall != null) {
                          widget.onStartCall!(item);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.chat_bubble_rounded, size: 18 * scale),
                      color: isDark ? Colors.white70 : Colors.black87,
                      tooltip: 'Написать',
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.onSelectChat != null) {
                          widget.onSelectChat!(item);
                        }
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18 * scale,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val == 'delete') {
                          _deletePcContact(userId);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              const Text('Удалить контакт', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ── Chats Settings ───────────────────────────────────────────────────────────

  Widget _buildChats(bool isDark, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Сообщения', isDark, scale),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: 'Анимации сообщений',
          description: 'Показывать анимации при отправке и получении',
          value: _messageAnimations,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _messageAnimations = v);
            _savePrefs();
          },
        ),
        SizedBox(height: 12 * scale),
        _infoTile(
          icon: Icons.archive_rounded,
          label: 'Архивированные чаты',
          subtitle: 'Управление архивом',
          isDark: isDark,
          scale: scale,
        ),
        SizedBox(height: 12 * scale),
        _infoTile(
          icon: Icons.delete_sweep_rounded,
          label: 'Очистить историю',
          subtitle: 'Удалить все сообщения локально',
          isDark: isDark,
          scale: scale,
          color: Colors.red,
        ),
      ],
    );
  }

  // ── Security ─────────────────────────────────────────────────────────────────

  Widget _buildSecurity(bool isDark, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Активные сессии', isDark, scale),
        SizedBox(height: 8 * scale),
        _infoTile(
          icon: Icons.computer_rounded,
          label: 'Это устройство',
          subtitle: 'Xaneo PC • Активно сейчас',
          isDark: isDark,
          scale: scale,
          trailing: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 8 * scale, vertical: 3 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Активно',
              style: TextStyle(
                fontSize: 10 * scale,
                color: const Color(0xFF059669),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 16 * scale),
        _sectionHeader('Двойная аутентификация', isDark, scale),
        SizedBox(height: 8 * scale),
        _infoTile(
          icon: Icons.verified_user_rounded,
          label: '2FA',
          subtitle: 'Защита аккаунта одноразовым паролем',
          isDark: isDark,
          scale: scale,
        ),
        SizedBox(height: 16 * scale),
        _sectionHeader('Опасная зона', isDark, scale),
        SizedBox(height: 8 * scale),
        _infoTile(
          icon: Icons.delete_forever_rounded,
          label: 'Удалить аккаунт',
          subtitle: 'Необратимое действие',
          isDark: isDark,
          scale: scale,
          color: Colors.red,
        ),
      ],
    );
  }

  // ── Appearance ───────────────────────────────────────────────────────────────

  Widget _buildAppearance(BuildContext context, bool isDark, double scale) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Тема', isDark, scale),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: 'Тёмная тема',
          description: 'Переключить между тёмным и светлым режимом',
          value: themeProvider.isDarkMode,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => themeProvider.setDarkMode(v),
        ),
        SizedBox(height: 20 * scale),
        _sectionHeader('Размер шрифта', isDark, scale),
        SizedBox(height: 8 * scale),
        Row(
          children: [
            Text('А',
                style: TextStyle(
                    fontSize: 12 * scale,
                    color: isDark ? Colors.white38 : Colors.black38)),
            Expanded(
              child: Slider(
                value: _fontSize,
                min: 12,
                max: 20,
                divisions: 8,
                activeColor: const Color(0xFF2563EB),
                inactiveColor: isDark ? Colors.white12 : Colors.black12,
                onChanged: (v) {
                  setState(() => _fontSize = v);
                  _savePrefs();
                },
              ),
            ),
            Text('А',
                style: TextStyle(
                    fontSize: 20 * scale,
                    color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
        Center(
          child: Text('${_fontSize.round()} px',
              style: TextStyle(
                  fontSize: 11 * scale,
                  color: isDark ? Colors.white38 : Colors.black38)),
        ),
      ],
    );
  }

  // ── Language ─────────────────────────────────────────────────────────────────

  Widget _buildLanguage(BuildContext context, bool isDark, double scale) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentCode = localeProvider.locale?.languageCode ?? 'ru';
    return Column(
      children: [
        _radioRow('Русский', 'ru', currentCode, isDark, scale, (v) {
          localeProvider.setLocale(const Locale('ru'));
          _savePrefs();
        }),
        _radioRow('English', 'en', currentCode, isDark, scale, (v) {
          localeProvider.setLocale(const Locale('en'));
          _savePrefs();
        }),
      ],
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────────

  Widget _buildNotifications(bool isDark, double scale) {
    return Column(
      children: [
        _switchRow(
          label: 'Уведомления',
          description: 'Показывать всплывающие уведомления',
          value: _notificationsEnabled,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _notificationsEnabled = v);
            _savePrefs();
          },
        ),
        SizedBox(height: 12 * scale),
        _switchRow(
          label: 'Звук',
          description: 'Воспроизводить звук при новом сообщении',
          value: _soundEnabled,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _soundEnabled = v);
            _savePrefs();
          },
        ),
      ],
    );
  }

  // ── Energy ────────────────────────────────────────────────────────────────────

  Widget _buildEnergy(bool isDark, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Основные настройки', isDark, scale),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: 'Режим экономии энергии',
          description: 'Оптимизирует работу приложения для экономии ресурсов',
          value: _lowPowerMode,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _lowPowerMode = v);
            _savePrefs();
          },
        ),
        SizedBox(height: 12 * scale),
        _switchRow(
          label: 'Автоматический спящий режим',
          description: 'Переводит приложение в спящий режим при неактивности',
          value: _autoSleep,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _autoSleep = v);
            _savePrefs();
          },
        ),
        SizedBox(height: 20 * scale),
        _sectionHeader('Анимации', isDark, scale),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: 'Анимации сообщений',
          description: 'Показывать анимации при отправке и получении',
          value: _messageAnimations,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _messageAnimations = v);
            _savePrefs();
          },
        ),
        SizedBox(height: 12 * scale),
        _switchRow(
          label: 'Упрощённые анимации',
          description: 'Уменьшает количество анимаций интерфейса',
          value: _reducedMotion,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _reducedMotion = v);
            _savePrefs();
          },
        ),
      ],
    );
  }

  // ── Coming Soon ───────────────────────────────────────────────────────────────

  Widget _comingSoon(bool isDark, double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32 * scale),
        child: Column(
          children: [
            Icon(Icons.construction_rounded,
                size: 32 * scale,
                color: isDark ? Colors.white24 : Colors.black26),
            SizedBox(height: 12 * scale),
            Text('Скоро будет доступно',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: isDark ? Colors.white38 : Colors.black38,
                )),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ── UI Primitive Blocks ───────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildUserCardAvatar(String? avatar, String gradient, String firstName, double size) {
    List<Color> gradColors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED)
    ];
    final hexes = RegExp(r'#([0-9a-fA-F]{6})')
        .allMatches(gradient)
        .map((m) => Color(int.parse('FF${m.group(1)}', radix: 16)))
        .toList();
    if (hexes.length >= 2) gradColors = hexes;

    final hasAvatar = avatar != null &&
        avatar.isNotEmpty &&
        (avatar.startsWith('http') || avatar.startsWith('/'));

    return ClipOval(
      child: hasAvatar
          ? Image.network(
              avatar.startsWith('http') ? avatar : 'https://xaneo.ru$avatar',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _gradientCircle(gradColors, firstName, size),
            )
          : _gradientCircle(gradColors, firstName, size),
    );
  }

  Widget _buildUserCard(String firstName, String username, String? avatar,
      String gradient, bool isDark, double scale) {
    List<Color> gradColors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED)
    ];
    final hexes = RegExp(r'#([0-9a-fA-F]{6})')
        .allMatches(gradient)
        .map((m) => Color(int.parse('FF${m.group(1)}', radix: 16)))
        .toList();
    if (hexes.length >= 2) gradColors = hexes;

    final hasAvatar = avatar != null &&
        avatar.isNotEmpty &&
        (avatar.startsWith('http') || avatar.startsWith('/'));

    Widget avatarWidget = ClipOval(
      child: hasAvatar
          ? Image.network(
              avatar.startsWith('http') ? avatar : 'https://xaneo.ru$avatar',
              width: 52 * scale,
              height: 52 * scale,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _gradientCircle(gradColors, firstName, 52 * scale),
            )
          : _gradientCircle(gradColors, firstName, 52 * scale),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: Row(
        children: [
          avatarWidget,
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(firstName,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    )),
                if (username.isNotEmpty)
                  Text('@$username',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: isDark ? Colors.white38 : Colors.black38,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: Row(
        children: [
          Container(
            width: 48 * scale,
            height: 48 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
            ),
            child: Center(
              child: Icon(Icons.person_off_rounded,
                  size: 22 * scale,
                  color: isDark ? Colors.white38 : Colors.black38),
            ),
          ),
          SizedBox(width: 12 * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Гостевой режим',
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  )),
              SizedBox(height: 2 * scale),
              Text('Войдите для доступа к аккаунту',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: isDark ? Colors.white38 : Colors.black38,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientCircle(List<Color> colors, String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _groupLabel(String label, bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(left: 4 * scale, bottom: 4 * scale),
      child: Text(label,
          style: TextStyle(
            fontSize: 10 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4 * scale,
            color: isDark ? Colors.white24 : Colors.black26,
          )),
    );
  }

  Widget _sectionHeader(String label, bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2 * scale),
      child: Text(label,
          style: TextStyle(
            fontSize: 10 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2 * scale,
            color: isDark ? Colors.white30 : Colors.black38,
          )),
    );
  }

  Widget _menuRow(_SettingsSection section, bool isDark, double scale) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _activeSection = section.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(vertical: 2 * scale),
          padding: EdgeInsets.symmetric(
              horizontal: 10 * scale, vertical: 10 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10 * scale),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 38 * scale,
                height: 38 * scale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10 * scale),
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Center(
                  child: Icon(
                    section.icon,
                    size: 17 * scale,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 13 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title,
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        )),
                    SizedBox(height: 2 * scale),
                    Text(section.description,
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: isDark ? Colors.white38 : Colors.black45,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18 * scale,
                  color: isDark ? Colors.white24 : Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dangerRow({
    required IconData icon,
    required String label,
    required bool isDark,
    required double scale,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 2 * scale),
          padding: EdgeInsets.symmetric(
              horizontal: 10 * scale, vertical: 10 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10 * scale),
            color: Colors.red.withOpacity(0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 38 * scale,
                height: 38 * scale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10 * scale),
                  color: Colors.red.withOpacity(0.12),
                ),
                child: Center(
                  child: Icon(icon, size: 17 * scale, color: Colors.red),
                ),
              ),
              SizedBox(width: 13 * scale),
              Text(label,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required String description,
    required bool value,
    required bool isDark,
    required double scale,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  )),
              SizedBox(height: 2 * scale),
              Text(description,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: isDark ? Colors.white38 : Colors.black45,
                  )),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _radioRow(String label, String value, String groupValue, bool isDark,
      double scale, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(label,
          style: TextStyle(
              fontSize: 14 * scale,
              color: isDark ? Colors.white : Colors.black87)),
      value: value,
      groupValue: groupValue,
      activeColor: const Color(0xFF2563EB),
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _dropdownRow({
    required String label,
    required String value,
    required List<(String, String)> options,
    required bool isDark,
    required double scale,
    required void Function(String) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5 * scale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13 * scale,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          XaneoCustomDropdown(
            value: value,
            options: options,
            onChanged: onChanged,
            isDark: isDark,
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required double scale,
    String hint = '',
    bool readOnly = false,
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black45,
            )),
        SizedBox(height: 5 * scale),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14 * scale,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 13 * scale,
            ),
            filled: true,
            fillColor: readOnly
                ? (isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03))
                : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.04)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * scale),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * scale),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * scale),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 12 * scale, vertical: 10 * scale),
            isDense: true,
          ),
        ),
        if (note != null) ...[
          SizedBox(height: 4 * scale),
          Text(note,
              style: TextStyle(
                fontSize: 10 * scale,
                color: isDark ? Colors.white24 : Colors.black26,
              )),
        ],
      ],
    );
  }

  Widget _textAreaField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required double scale,
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black45,
            )),
        SizedBox(height: 5 * scale),
        TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(
            fontSize: 14 * scale,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 13 * scale,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * scale),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * scale),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * scale),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 12 * scale, vertical: 10 * scale),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required bool isDark,
    required double scale,
    VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12 * scale),
          decoration: BoxDecoration(
            color: onTap != null
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white12 : Colors.black12),
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
                color: onTap != null
                    ? (isDark ? Colors.black : Colors.white)
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isDark,
    required double scale,
    Color? color,
    Widget? trailing,
  }) {
    final c = color ?? (isDark ? Colors.white70 : Colors.black87);
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18 * scale, color: c),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                        color: c)),
                SizedBox(height: 2 * scale),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11 * scale,
                        color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _errorBanner(String msg, bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Text(msg,
            style: TextStyle(
                fontSize: 12 * scale, color: Colors.red.shade300)),
      ),
    );
  }

  Widget _successBanner(String msg, bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8 * scale),
          border:
              Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
        ),
        child: Text(msg,
            style: TextStyle(
                fontSize: 12 * scale,
                color: const Color(0xFF059669))),
      ),
    );
  }
}

// ─── Кастомный выпадающий список (Dropdown) Xaneo ───────────────────────────

class XaneoCustomDropdown extends StatefulWidget {
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final double scale;

  const XaneoCustomDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDark,
    required this.scale,
  });

  @override
  State<XaneoCustomDropdown> createState() => _XaneoCustomDropdownState();
}

class _XaneoCustomDropdownState extends State<XaneoCustomDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isHovered = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = _createOverlayEntry(size);
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry(Size buttonSize) {
    final isDark = widget.isDark;
    final scale = widget.scale;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
              onSecondaryTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: Offset(0, 4 * scale),
            child: Material(
              color: Colors.transparent,
              child: _XaneoDropdownMenuOverlay(
                options: widget.options,
                selectedValue: widget.value,
                isDark: isDark,
                scale: scale,
                minWidth: math.max(150 * scale, buttonSize.width),
                onSelect: (val) {
                  _closeDropdown();
                  widget.onChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isDark = widget.isDark;
    final selectedOption = widget.options.firstWhere(
      (o) => o.$1 == widget.value,
      orElse: () => widget.options.isNotEmpty ? widget.options.first : ('', ''),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: 11 * scale,
              vertical: 6 * scale,
            ),
            decoration: BoxDecoration(
              color: _isOpen
                  ? (isDark ? const Color(0xFF2563EB).withOpacity(0.18) : const Color(0xFF2563EB).withOpacity(0.1))
                  : _isHovered
                      ? (isDark ? Colors.white.withOpacity(0.09) : Colors.black.withOpacity(0.06))
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(
                color: _isOpen
                    ? const Color(0xFF2563EB)
                    : (_isHovered
                        ? (isDark ? Colors.white30 : Colors.black38)
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08))),
                width: _isOpen ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedOption.$2,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    color: _isOpen
                        ? const Color(0xFF2563EB)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                SizedBox(width: 6 * scale),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16 * scale,
                    color: _isOpen
                        ? const Color(0xFF2563EB)
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XaneoDropdownMenuOverlay extends StatefulWidget {
  final List<(String, String)> options;
  final String selectedValue;
  final bool isDark;
  final double scale;
  final double minWidth;
  final ValueChanged<String> onSelect;

  const _XaneoDropdownMenuOverlay({
    required this.options,
    required this.selectedValue,
    required this.isDark,
    required this.scale,
    required this.minWidth,
    required this.onSelect,
  });

  @override
  State<_XaneoDropdownMenuOverlay> createState() => __XaneoDropdownMenuOverlayState();
}

class __XaneoDropdownMenuOverlayState extends State<_XaneoDropdownMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final scale = widget.scale;

    final bgColor = isDark ? const Color(0xFF141417) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: Alignment.topRight,
        child: Container(
          constraints: BoxConstraints(minWidth: widget.minWidth),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10 * scale),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
                blurRadius: 18 * scale,
                offset: Offset(0, 6 * scale),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.options.map((opt) {
                final isSelected = opt.$1 == widget.selectedValue;
                return _XaneoDropdownItemRow(
                  label: opt.$2,
                  isSelected: isSelected,
                  isDark: isDark,
                  scale: scale,
                  onTap: () => widget.onSelect(opt.$1),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _XaneoDropdownItemRow extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final double scale;
  final VoidCallback onTap;

  const _XaneoDropdownItemRow({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_XaneoDropdownItemRow> createState() => __XaneoDropdownItemRowState();
}

class __XaneoDropdownItemRowState extends State<_XaneoDropdownItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final scale = widget.scale;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 9 * scale,
          ),
          color: _isHovered
              ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05))
              : Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5 * scale,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected
                      ? const Color(0xFF2563EB)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              if (widget.isSelected) ...[
                SizedBox(width: 12 * scale),
                Icon(
                  Icons.check_rounded,
                  size: 14 * scale,
                  color: const Color(0xFF2563EB),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
