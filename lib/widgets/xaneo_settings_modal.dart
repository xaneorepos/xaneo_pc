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
import 'package:package_info_plus/package_info_plus.dart';
import 'base_custom_modal.dart';
import '../l10n/app_localizations.dart';

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
List<_SettingsSection> _getAccountSections(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    _SettingsSection(
      id: 'personal',
      title:
          l10n?.personalData ??
          (AppLocalizations.of(context)?.lichnyeDannye_be85 ?? 'Fallback'),
      description:
          l10n?.personalDataDesc ??
          (AppLocalizations.of(context)?.imyaNikneymFotoProfilya_28ac ??
              'Fallback'),
      icon: Icons.person_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'privacy',
      title:
          l10n?.privacyTitle ??
          (AppLocalizations.of(context)?.privatnost_0899 ?? 'Fallback'),
      description:
          l10n?.privacyDesc ??
          (AppLocalizations.of(context)?.ktoMozhetPisatZvonitVidet_1789 ??
              'Fallback'),
      icon: Icons.lock_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'chats',
      title:
          l10n?.chatsSettings ??
          (AppLocalizations.of(context)?.nastroykiChatov_7ca8 ?? 'Fallback'),
      description:
          l10n?.chatsSettingsDesc ??
          (AppLocalizations.of(context)?.uvedomleniyaTemyIstoriya_51da ??
              'Fallback'),
      icon: Icons.chat_bubble_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'contacts',
      title:
          l10n?.contacts ??
          (AppLocalizations.of(context)?.kontakty_7576 ?? 'Fallback'),
      description:
          l10n?.contactsDesc ??
          (AppLocalizations.of(context)?.vashiSohranennyeKontakty_a641 ??
              'Fallback'),
      icon: Icons.people_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'security',
      title:
          l10n?.security ??
          (AppLocalizations.of(context)?.bezopasnost_3677 ?? 'Fallback'),
      description:
          l10n?.securityDesc ??
          (AppLocalizations.of(context)?.sessiiParolAutentifikatsiya_73f5 ??
              'Fallback'),
      icon: Icons.shield_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
  ];
}

// Разделы интерфейса (доступны всегда)
List<_SettingsSection> _getInterfaceSections(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    _SettingsSection(
      id: 'appearance',
      title:
          l10n?.appearance ??
          (AppLocalizations.of(context)?.vneshniyVid_6873 ?? 'Fallback'),
      description:
          l10n?.appearanceDesc ??
          (AppLocalizations.of(context)?.temaShriftMasshtab_d8c9 ?? 'Fallback'),
      icon: Icons.palette_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'window',
      title:
          l10n?.closeActionTitle ??
          (AppLocalizations.of(context)?.closeActionTitle ??
              'Действие при закрытии окна'),
      description:
          l10n?.closeActionDescription ??
          (AppLocalizations.of(context)?.closeActionDescription ??
              'Работа в фоне и системный трей'),
      icon: Icons.desktop_windows_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'language',
      title:
          l10n?.language ??
          (AppLocalizations.of(context)?.yazyk_0577 ?? 'Fallback'),
      description:
          l10n?.languageDescription ??
          (AppLocalizations.of(context)?.yazykInterfeysaKlienta_2ad3 ??
              'Fallback'),
      icon: Icons.language_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'notifications',
      title:
          l10n?.notifications ??
          (AppLocalizations.of(context)?.uvedomleniya_d2ed ?? 'Fallback'),
      description:
          l10n?.notificationsDescription ??
          (AppLocalizations.of(context)?.zvukiBannery_1b60 ?? 'Fallback'),
      icon: Icons.notifications_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'energy',
      title:
          l10n?.energySaving ??
          (AppLocalizations.of(context)?.energosberezhenie_0b19 ?? 'Fallback'),
      description:
          l10n?.energySavingDesc ??
          (AppLocalizations.of(context)?.animatsiiIProizvoditelnost_fba8 ??
              'Fallback'),
      icon: Icons.bolt_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SettingsSection(
      id: 'about',
      title:
          l10n?.about ??
          (AppLocalizations.of(context)?.oPrilozhenii_322e ?? 'Fallback'),
      description:
          l10n?.aboutDescription ??
          (AppLocalizations.of(context)?.versiyaProverkaObnovleniySsylki_6efc ??
              'Fallback'),
      icon: Icons.info_outline_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
  ];
}

// ─── Главный виджет ──────────────────────────────────────────────────────────

class XaneoSettingsModal extends BaseCustomModal {
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onLogout;
  final Function(dynamic contact)? onSelectChat;
  final Function(dynamic contact)? onStartCall;
  final Function(AppVersionInfo update)? onUpdateFound;

  XaneoSettingsModal({
    super.key,
    this.currentUser,
    this.onLogout,
    this.onSelectChat,
    this.onStartCall,
    this.onUpdateFound,
  }) : super(modalTag: '', title: '');

  /// Открыть модалку настроек через BaseCustomModal.show
  static Future<void> open(
    BuildContext context, {
    Map<String, dynamic>? currentUser,
    VoidCallback? onLogout,
    Function(dynamic contact)? onSelectChat,
    Function(dynamic contact)? onStartCall,
    Function(AppVersionInfo update)? onUpdateFound,
  }) {
    return BaseCustomModal.show(
      context: context,
      modal: XaneoSettingsModal(
        currentUser: currentUser,
        onLogout: onLogout,
        onSelectChat: onSelectChat,
        onStartCall: onStartCall,
        onUpdateFound: onUpdateFound,
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

  @override
  String getModalTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return (l10n?.mainSettings ?? 'НАСТРОЙКИ').toUpperCase();
  }

  String? _activeSection;

  // ── Update ─────────────────────────────────────────────────────────────────
  bool _isCheckingUpdate = false;
  String? _updateStatusMessage;
  AppVersionInfo? _foundUpdateInfo;

  Future<void> _handleManualUpdateCheck() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = l10n?.checkingUpdates ?? 'Проверка обновлений...';
      _foundUpdateInfo = null;
    });

    final update = await UpdateService().checkForUpdates(force: true);
    final currentVersion = await UpdateService().getCurrentVersion();

    if (!mounted) return;

    setState(() {
      _isCheckingUpdate = false;
      if (update != null) {
        _foundUpdateInfo = update;
        _updateStatusMessage =
            '${l10n?.newVersionAvailableTitle ?? "Доступна новая версия"} v${update.version}!';
        if (widget.onUpdateFound != null) {
          widget.onUpdateFound!(update);
        }
      } else {
        _updateStatusMessage =
            '${l10n?.youHaveLatestVersion ?? "У вас установлена актуальная версия"} v$currentVersion';
      }
    });
  }

  // ── Appearance ────────────────────────────────────────────────────────────

  double _fontSize = 15.0;
  String _windowCloseAction = 'minimizeToTray';

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
  bool _privacyLoaded = false; // флаг: загружали ли уже
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

  // ── Security ─────────────────────────────────────────────────────────────
  final _securityCodeCtrl = TextEditingController();
  bool _securityLoading = false;
  bool _securityLoaded = false;
  bool _securityBusy = false;
  bool _tfaEnabled = false;
  String? _pendingTfaAction;
  String? _securityError;
  String? _securitySuccess;
  List<Map<String, dynamic>> _securitySessions = const [];

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
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : null;
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
    _securityCodeCtrl.dispose();
    super.dispose();
  }

  static const Map<String, Map<String, String>> _securityTranslations = {
    'loadError': {
      'ru': 'Не удалось загрузить настройки безопасности',
      'en': 'Failed to load security settings',
      'fr': 'Impossible de charger les paramètres de sécurité',
      'es': 'No se pudieron cargar los ajustes de seguridad',
      'zh': '无法加载安全设置',
      'ja': 'セキュリティ設定を読み込めませんでした',
      'ko': '보안 설정을 불러오지 못했습니다',
      'ar': 'تعذر تحميل إعدادات الأمان',
    },
    'codeSent': {
      'ru': 'Код отправлен на email',
      'en': 'Code sent to email',
      'fr': 'Code envoyé par e-mail',
      'es': 'Código enviado por correo electrónico',
      'zh': '验证码已发送至邮箱',
      'ja': 'コードをメールで送信しました',
      'ko': '이메일로 코드를 전송했습니다',
      'ar': 'تم إرسال الرمز إلى البريد الإلكتروني',
    },
    'sendCodeError': {
      'ru': 'Ошибка отправки кода',
      'en': 'Failed to send code',
      'fr': 'Échec de l’envoi du code',
      'es': 'No se pudo enviar el código',
      'zh': '无法发送验证码',
      'ja': 'コードを送信できませんでした',
      'ko': '코드를 전송하지 못했습니다',
      'ar': 'تعذر إرسال الرمز',
    },
    'validCode': {
      'ru': 'Введите корректный 6-значный код',
      'en': 'Enter a valid 6-digit code',
      'fr': 'Saisissez un code valide à 6 chiffres',
      'es': 'Introduce un código válido de 6 dígitos',
      'zh': '请输入有效的 6 位验证码',
      'ja': '有効な6桁のコードを入力してください',
      'ko': '유효한 6자리 코드를 입력하세요',
      'ar': 'أدخل رمزًا صالحًا مكونًا من 6 أرقام',
    },
    'updated': {
      'ru': 'Настройки 2FA обновлены',
      'en': '2FA settings updated',
      'fr': 'Paramètres 2FA mis à jour',
      'es': 'Ajustes de 2FA actualizados',
      'zh': '双重验证设置已更新',
      'ja': '2FA設定を更新しました',
      'ko': '2FA 설정이 업데이트되었습니다',
      'ar': 'تم تحديث إعدادات المصادقة الثنائية',
    },
    'invalidCode': {
      'ru': 'Неверный код',
      'en': 'Invalid code',
      'fr': 'Code incorrect',
      'es': 'Código incorrecto',
      'zh': '验证码无效',
      'ja': 'コードが正しくありません',
      'ko': '잘못된 코드입니다',
      'ar': 'الرمز غير صحيح',
    },
    'terminateError': {
      'ru': 'Не удалось завершить сессию',
      'en': 'Failed to terminate session',
      'fr': 'Impossible de terminer la session',
      'es': 'No se pudo finalizar la sesión',
      'zh': '无法终止会话',
      'ja': 'セッションを終了できませんでした',
      'ko': '세션을 종료하지 못했습니다',
      'ar': 'تعذر إنهاء الجلسة',
    },
    'twoFactorTitle': {
      'ru': 'Двухфакторная аутентификация',
      'en': 'Two-factor authentication',
      'fr': 'Authentification à deux facteurs',
      'es': 'Autenticación de dos factores',
      'zh': '双重验证',
      'ja': '二要素認証',
      'ko': '이중 인증',
      'ar': 'المصادقة الثنائية',
    },
    'tfaEnabled': {
      'ru': '2FA включена',
      'en': '2FA enabled',
      'fr': '2FA activée',
      'es': '2FA activada',
      'zh': '双重验证已启用',
      'ja': '2FAは有効です',
      'ko': '2FA가 활성화되었습니다',
      'ar': 'المصادقة الثنائية مفعّلة',
    },
    'tfaDisabled': {
      'ru': '2FA отключена',
      'en': '2FA disabled',
      'fr': '2FA désactivée',
      'es': '2FA desactivada',
      'zh': '双重验证已停用',
      'ja': '2FAは無効です',
      'ko': '2FA가 비활성화되었습니다',
      'ar': 'المصادقة الثنائية معطّلة',
    },
    'twoFactorDesc': {
      'ru': 'Защита аккаунта одноразовым паролем',
      'en': 'Protect your account with a one-time password',
      'fr': 'Protégez votre compte avec un mot de passe à usage unique',
      'es': 'Protege tu cuenta con una contraseña de un solo uso',
      'zh': '使用一次性密码保护您的账户',
      'ja': 'ワンタイムパスワードでアカウントを保護します',
      'ko': '일회용 비밀번호로 계정을 보호하세요',
      'ar': 'احمِ حسابك بكلمة مرور تُستخدم لمرة واحدة',
    },
    'disable': {
      'ru': 'Отключить',
      'en': 'Disable',
      'fr': 'Désactiver',
      'es': 'Desactivar',
      'zh': '停用',
      'ja': '無効にする',
      'ko': '비활성화',
      'ar': 'تعطيل',
    },
    'enable': {
      'ru': 'Включить',
      'en': 'Enable',
      'fr': 'Activer',
      'es': 'Activar',
      'zh': '启用',
      'ja': '有効にする',
      'ko': '활성화',
      'ar': 'تفعيل',
    },
    'confirm': {
      'ru': 'Подтвердить',
      'en': 'Confirm',
      'fr': 'Confirmer',
      'es': 'Confirmar',
      'zh': '确认',
      'ja': '確認',
      'ko': '확인',
      'ar': 'تأكيد',
    },
    'activeSessions': {
      'ru': 'Активные сессии',
      'en': 'Active sessions',
      'fr': 'Sessions actives',
      'es': 'Sesiones activas',
      'zh': '活动会话',
      'ja': 'アクティブなセッション',
      'ko': '활성 세션',
      'ar': 'الجلسات النشطة',
    },
    'refresh': {
      'ru': 'Обновить',
      'en': 'Refresh',
      'fr': 'Actualiser',
      'es': 'Actualizar',
      'zh': '刷新',
      'ja': '更新',
      'ko': '새로고침',
      'ar': 'تحديث',
    },
    'noSessions': {
      'ru': 'Нет активных сессий',
      'en': 'No active sessions',
      'fr': 'Aucune session active',
      'es': 'No hay sesiones activas',
      'zh': '没有活动会话',
      'ja': 'アクティブなセッションはありません',
      'ko': '활성 세션이 없습니다',
      'ar': 'لا توجد جلسات نشطة',
    },
    'unknownDevice': {
      'ru': 'Неизвестное устройство',
      'en': 'Unknown device',
      'fr': 'Appareil inconnu',
      'es': 'Dispositivo desconocido',
      'zh': '未知设备',
      'ja': '不明なデバイス',
      'ko': '알 수 없는 기기',
      'ar': 'جهاز غير معروف',
    },
    'thisDevice': {
      'ru': 'Это устройство',
      'en': 'This device',
      'fr': 'Cet appareil',
      'es': 'Este dispositivo',
      'zh': '此设备',
      'ja': 'このデバイス',
      'ko': '이 기기',
      'ar': 'هذا الجهاز',
    },
    'active': {
      'ru': 'Активно',
      'en': 'Active',
      'fr': 'Actif',
      'es': 'Activa',
      'zh': '活动',
      'ja': 'アクティブ',
      'ko': '활성',
      'ar': 'نشطة',
    },
    'terminate': {
      'ru': 'Завершить',
      'en': 'Terminate',
      'fr': 'Terminer',
      'es': 'Finalizar',
      'zh': '终止',
      'ja': '終了',
      'ko': '종료',
      'ar': 'إنهاء',
    },
  };

  String _securityText(String key) {
    final translations = _securityTranslations[key]!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return translations[languageCode] ?? translations['en']!;
  }

  Future<void> _loadSecurity({bool force = false}) async {
    if (_securityLoading || (_securityLoaded && !force)) return;
    setState(() {
      _securityLoading = true;
      _securityError = null;
    });
    final result = await ApiService().getSecurityOverview();
    if (!mounted) return;
    final data = result.data ?? const <String, dynamic>{};
    setState(() {
      _securityLoading = false;
      _securityLoaded = result.success;
      if (result.success) {
        _tfaEnabled = data['tfa_enabled'] == true;
        _securitySessions = (data['sessions'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _securityError = _securityText('loadError');
      }
    });
  }

  Future<void> _requestSecurityTfaCode() async {
    final action = _tfaEnabled ? 'disable' : 'enable';
    setState(() {
      _securityBusy = true;
      _securityError = null;
      _securitySuccess = null;
    });
    final result = await ApiService().requestTfaSettingsCode(action);
    if (!mounted) return;
    setState(() {
      _securityBusy = false;
      if (result.success) {
        _pendingTfaAction = action;
        _securitySuccess =
            AppLocalizations.of(context)?.codeSent ?? _securityText('codeSent');
      } else {
        _securityError =
            AppLocalizations.of(context)?.sendCodeError ??
            _securityText('sendCodeError');
      }
    });
  }

  Future<void> _confirmSecurityTfa() async {
    final action = _pendingTfaAction;
    final code = _securityCodeCtrl.text.trim();
    if (action == null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _securityError = _securityText('validCode'));
      return;
    }
    setState(() {
      _securityBusy = true;
      _securityError = null;
    });
    final result = await ApiService().confirmTfaSettings(action, code);
    if (!mounted) return;
    setState(() {
      _securityBusy = false;
      if (result.success) {
        _tfaEnabled = action == 'enable';
        _pendingTfaAction = null;
        _securityCodeCtrl.clear();
        _securitySuccess = _securityText('updated');
        if (widget.currentUser != null) {
          widget.currentUser!['tfa_enabled'] = _tfaEnabled;
        }
      } else {
        _securityError = _securityText('invalidCode');
      }
    });
  }

  Future<void> _terminateSecuritySession(int sessionId) async {
    setState(() {
      _securityBusy = true;
      _securityError = null;
    });
    final result = await ApiService().terminateSession(sessionId);
    if (!mounted) return;
    setState(() {
      _securityBusy = false;
      if (result.success) {
        _securitySessions.removeWhere((item) => item['id'] == sessionId);
      } else {
        _securityError = _securityText('terminateError');
      }
    });
  }

  String _dynamicVersion = '1.0.14';
  String _dynamicBuildNumber = '14';

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String v = '1.0.14';
    String b = '14';
    const overrideVer = String.fromEnvironment('OVERRIDE_VERSION');
    if (overrideVer.isNotEmpty) {
      v = overrideVer;
    } else {
      try {
        final pkg = await PackageInfo.fromPlatform();
        v = pkg.version;
        b = pkg.buildNumber;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _dynamicVersion = v;
        _dynamicBuildNumber = b;
        _notificationsEnabled = prefs.getBool('settings_notifications') ?? true;
        _soundEnabled = prefs.getBool('settings_sound') ?? true;
        _fontSize = prefs.getDouble('settings_font_size') ?? 15.0;
        _reducedMotion = prefs.getBool('settings_reduced_motion') ?? false;
        _lowPowerMode = prefs.getBool('settings_low_power') ?? false;
        _messageAnimations = prefs.getBool('settings_msg_animations') ?? true;
        _autoSleep = prefs.getBool('settings_auto_sleep') ?? true;
        _windowCloseAction =
            prefs.getString('window_close_action') ?? 'minimizeToTray';
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
    await prefs.setString('window_close_action', _windowCloseAction);
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
          _privacyError =
              (AppLocalizations.of(context)?.neUdalosZagruzitNastroyki_f753 ??
              'Fallback');
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
      await ApiService().dio.patch(
        '/user/privacy-settings/',
        data: {
          'who_can_message': _whoCanMessage,
          'who_can_call': _whoCanCall,
          'who_can_record_voice': _whoCanRecordVoice,
          'who_can_send_files': _whoCanSendFiles,
          'who_can_invite': _whoCanInvite,
          'who_sees_nickname': _whoSeesNickname,
          'who_sees_avatar': _whoSeesAvatar,
          'who_sees_birthday': _whoSeesBirthday,
          'who_sees_online_time': _whoSeesOnlineTime,
        },
      );
      if (mounted) setState(() => _privacySaving = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _privacySaving = false;
          _privacyError =
              (AppLocalizations.of(context)?.oshibkaSohraneniya_0387 ??
              'Fallback');
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

      final res = await ApiService().dio.patch(
        '/user/profile/',
        data: {'first_name': newFirstName, 'bio': newBio},
      );

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          if (widget.currentUser != null) {
            widget.currentUser!['first_name'] = newFirstName;
            widget.currentUser!['bio'] = newBio;
          }
          setState(() {
            _personalSaving = false;
            _personalSuccess =
                (AppLocalizations.of(context)?.dannyeSohraneny_fd62 ??
                'Fallback');
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _personalSuccess = null);
          });
        } else {
          setState(() {
            _personalSaving = false;
            _personalError =
                (AppLocalizations.of(context)?.oshibkaSohraneniya_0387 ??
                'Fallback');
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
    BuildContext context,
    ScrollController sc,
    bool isDark,
    double scale,
  ) {
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
    BuildContext context,
    bool isDark,
    double scale,
    ScrollController sc,
  ) {
    final divider = Divider(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
      thickness: 1,
      height: 1,
    );

    final user = widget.currentUser;
    final firstName =
        user?['first_name']?.toString() ??
        user?['username']?.toString() ??
        (AppLocalizations.of(context)?.gost_9618 ?? 'Fallback');
    final username = user?['username']?.toString() ?? '';
    final avatar = user?['avatar']?.toString();
    final gradient = user?['avatar_gradient']?.toString() ?? '';

    return ListView(
      controller: sc,
      shrinkWrap: true,
      children: [
        // Блок пользователя
        _isLoggedIn
            ? _buildUserCard(
                firstName,
                username,
                avatar,
                gradient,
                isDark,
                scale,
              )
            : _buildGuestCard(isDark, scale),

        divider,
        SizedBox(height: 14 * scale),

        // Раздел аккаунта
        if (_isLoggedIn) ...[
          _groupLabel(
            AppLocalizations.of(context)?.account ??
                (AppLocalizations.of(context)?.akkaunt_38ac ?? 'Fallback'),
            isDark,
            scale,
          ),
          SizedBox(height: 6 * scale),
          ..._getAccountSections(
            context,
          ).map((s) => _menuRow(s, isDark, scale)),
          SizedBox(height: 16 * scale),
          divider,
          SizedBox(height: 14 * scale),
        ],

        // Раздел интерфейса
        _groupLabel(
          AppLocalizations.of(context)?.interface ??
              (AppLocalizations.of(context)?.interfeys_49be ?? 'Fallback'),
          isDark,
          scale,
        ),
        SizedBox(height: 6 * scale),
        ..._getInterfaceSections(
          context,
        ).map((s) => _menuRow(s, isDark, scale)),

        // Выйти
        if (_isLoggedIn && widget.onLogout != null) ...[
          SizedBox(height: 16 * scale),
          divider,
          SizedBox(height: 8 * scale),
          _dangerRow(
            icon: Icons.logout_rounded,
            label:
                AppLocalizations.of(context)?.logout ??
                (AppLocalizations.of(context)?.vyytiIzAkkaunta_6d41 ??
                    'Fallback'),
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
            'Xaneo PC v$_dynamicVersion',
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
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14 * scale,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
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
    final l10n = AppLocalizations.of(context);
    var m = {
      'appearance': l10n?.appearance ?? 'Внешний вид',
      'window': l10n?.closeActionTitle ?? 'Действие при закрытии окна',
      'language': l10n?.language ?? 'Язык',
      'notifications': l10n?.notifications ?? 'Уведомления',
      'energy': l10n?.energySaving ?? 'Энергосбережение',
      'personal': l10n?.personalData ?? 'Личные данные',
      'chats': l10n?.chatsSettings ?? 'Настройки чатов',
      'privacy': l10n?.privacyDesc ?? 'Приватность',
      'contacts': l10n?.contacts ?? 'Контакты',
      'security': l10n?.security ?? 'Безопасность',
      'about': l10n?.about ?? 'О приложении',
    };
    return m[id] ?? id;
  }

  Widget _buildSectionBody(
    BuildContext context,
    String id,
    bool isDark,
    double scale,
  ) {
    switch (id) {
      case 'appearance':
        return _buildAppearance(context, isDark, scale);
      case 'window':
        return _buildWindowSection(context, isDark, scale);
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

  Widget _buildWindowSection(BuildContext context, bool isDark, double scale) {
    final l10n = AppLocalizations.of(context);

    final options = [
      {
        'value': 'minimizeToTray',
        'title':
            l10n?.closeActionMinimizeToTray ??
            'Сворачивать в трей (работать в фоне)',
        'subtitle':
            l10n?.closeActionMinimizeToTraySubtitle ??
            'При нажатии на крестик окно сворачивается в системный трей и продолжает работать в фоне',
        'icon': Icons.system_update_alt_rounded,
      },
      {
        'value': 'minimizeToTaskbar',
        'title':
            l10n?.closeActionMinimizeToTaskbar ?? 'Сворачивать на панель задач',
        'subtitle':
            l10n?.closeActionMinimizeToTaskbarSubtitle ??
            'При нажатии на крестик окно сворачивается на панель задач',
        'icon': Icons.minimize_rounded,
      },
      {
        'value': 'exitApp',
        'title': l10n?.closeActionExitApp ?? 'Завершать работу приложения',
        'subtitle':
            l10n?.closeActionExitAppSubtitle ??
            'При нажатии на крестик приложение полностью завершает работу',
        'icon': Icons.power_settings_new_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          l10n?.closeActionTitle ?? 'Действие при закрытии окна',
          isDark,
          scale,
        ),
        SizedBox(height: 16 * scale),
        ...options.map((opt) {
          final isSelected = _windowCloseAction == opt['value'];
          return Container(
            margin: EdgeInsets.only(bottom: 12 * scale),
            child: InkWell(
              onTap: () async {
                setState(() {
                  _windowCloseAction = opt['value'] as String;
                });
                await _savePrefs();
              },
              borderRadius: BorderRadius.circular(16 * scale),
              child: Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05))
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.2))
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05)),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20 * scale,
                      height: 20 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.white38 : Colors.black38),
                          width: 2 * scale,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10 * scale,
                                height: 10 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 14 * scale),
                    Icon(
                      opt['icon'] as IconData,
                      size: 20 * scale,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14 * scale,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 3 * scale),
                          Text(
                            opt['subtitle'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12 * scale,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAboutSection(bool isDark, double scale) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          l10n?.appInfo ?? 'Информация о приложении',
          isDark,
          scale,
        ),
        SizedBox(height: 16 * scale),
        Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.desktop_windows_rounded,
                    size: 24 * scale,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
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
                        '${l10n?.version ?? "Версия"}: $_dynamicVersion+$_dynamicBuildNumber (Linux / Windows / macOS)',
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
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 12 * scale),
              ],

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isCheckingUpdate
                        ? null
                        : _handleManualUpdateCheck,
                    icon: _isCheckingUpdate
                        ? SizedBox(
                            width: 14 * scale,
                            height: 14 * scale,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.refresh_rounded, size: 16 * scale),
                    label: Text(
                      _isCheckingUpdate
                          ? (l10n?.checkingUpdates ?? 'Проверка обновлений...')
                          : (l10n?.checkUpdates ?? 'Проверить обновления'),
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontFamily: 'Inter',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black87,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 10 * scale,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10 * scale),
                      ),
                    ),
                  ),
                  if (_foundUpdateInfo != null) ...[
                    SizedBox(width: 10 * scale),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          _foundUpdateInfo!.downloadUrl ??
                              _foundUpdateInfo!.htmlUrl,
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: Icon(Icons.download_rounded, size: 16 * scale),
                      label: Text(
                        '${l10n?.downloadVersion ?? "Скачать"} v${_foundUpdateInfo!.version}',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontFamily: 'Inter',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.greenAccent),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scale,
                          vertical: 10 * scale,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          l10n?.basicInfo ??
              (AppLocalizations.of(context)?.osnovnayaInformatsiya_6fec ??
                  'Fallback'),
          isDark,
          scale,
        ),
        SizedBox(height: 10 * scale),
        _inputField(
          label:
              l10n?.yourName ??
              (AppLocalizations.of(context)?.imya_d38d ?? 'Fallback'),
          controller: _firstNameCtrl,
          isDark: isDark,
          scale: scale,
          hint:
              l10n?.registerStep0Subtitle ??
              (AppLocalizations.of(context)?.vvediteVasheImya_751e ??
                  'Fallback'),
        ),
        SizedBox(height: 12 * scale),
        _inputField(
          label:
              l10n?.nickname ??
              (AppLocalizations.of(context)?.nikneym_3fea ?? 'Fallback'),
          controller: _usernameCtrl,
          isDark: isDark,
          scale: scale,
          hint: '@username',
          readOnly: true,
          note:
              l10n?.nicknameCannotBeChanged ??
              (AppLocalizations.of(
                    context,
                  )?.nikneymNelzyaIzmenitVPrilozhenii_75d0 ??
                  'Fallback'),
        ),
        SizedBox(height: 12 * scale),
        _textAreaField(
          label:
              l10n?.aboutMe ??
              (AppLocalizations.of(context)?.oSebe_0b3b ?? 'Fallback'),
          controller: _bioCtrl,
          isDark: isDark,
          scale: scale,
          hint:
              l10n?.aboutMeHint ??
              (AppLocalizations.of(context)?.rasskazhiteOSebe_1c37 ??
                  'Fallback'),
        ),
        SizedBox(height: 18 * scale),
        if (_personalError != null)
          _errorBanner(_personalError!, isDark, scale),
        if (_personalSuccess != null)
          _successBanner(_personalSuccess!, isDark, scale),
        _primaryButton(
          label: _personalSaving
              ? (l10n?.saving ??
                    (AppLocalizations.of(context)?.sohranenie_c15f ??
                        'Fallback'))
              : (l10n?.save ??
                    (AppLocalizations.of(context)?.sohranit_74ea ??
                        'Fallback')),
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

    final l10n = AppLocalizations.of(context);
    final options = [
      (
        'all',
        l10n?.everyone ??
            (AppLocalizations.of(context)?.vse_984b ?? 'Fallback'),
      ),
      (
        'contacts',
        l10n?.contactsOnly ??
            (AppLocalizations.of(context)?.tolkoKontakty_a559 ?? 'Fallback'),
      ),
      (
        'nobody',
        l10n?.nobody ??
            (AppLocalizations.of(context)?.nikto_ba19 ?? 'Fallback'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          l10n?.communications ??
              (AppLocalizations.of(context)?.kommunikatsii_1242 ?? 'Fallback'),
          isDark,
          scale,
        ),
        SizedBox(height: 8 * scale),
        _dropdownRow(
          label:
              l10n?.whoCanMessage ??
              (AppLocalizations.of(context)?.ktoMozhetPisatSoobscheniya_4645 ??
                  'Fallback'),
          value: _whoCanMessage,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanMessage = v),
        ),
        _dropdownRow(
          label:
              l10n?.whoCanCall ??
              (AppLocalizations.of(context)?.ktoMozhetZvonit_c427 ??
                  'Fallback'),
          value: _whoCanCall,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanCall = v),
        ),
        _dropdownRow(
          label:
              l10n?.whoCanRecordVoice ??
              (AppLocalizations.of(context)?.ktoMozhetZapisyvatGolosovye_c69a ??
                  'Fallback'),
          value: _whoCanRecordVoice,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanRecordVoice = v),
        ),
        _dropdownRow(
          label:
              l10n?.whoCanSendFiles ??
              (AppLocalizations.of(context)?.ktoMozhetOtpravlyatFayly_2e40 ??
                  'Fallback'),
          value: _whoCanSendFiles,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanSendFiles = v),
        ),
        _dropdownRow(
          label:
              l10n?.whoCanInvite ??
              (AppLocalizations.of(context)?.ktoMozhetPriglashatVGruppy_cdc0 ??
                  'Fallback'),
          value: _whoCanInvite,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoCanInvite = v),
        ),
        SizedBox(height: 16 * scale),
        _sectionHeader(
          l10n?.profileVisibility ??
              (AppLocalizations.of(context)?.vidimostProfilya_34bf ??
                  'Fallback'),
          isDark,
          scale,
        ),
        SizedBox(height: 8 * scale),
        _dropdownRow(
          label:
              l10n?.whoSeesNickname ??
              (AppLocalizations.of(context)?.ktoViditMoyNikneym_54b8 ??
                  'Fallback'),
          value: _whoSeesNickname,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesNickname = v),
        ),
        _dropdownRow(
          label: l10n?.whoSeesAvatar ?? 'Кто видит мой аватар',
          value: _whoSeesAvatar,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesAvatar = v),
        ),
        _dropdownRow(
          label: l10n?.whoSeesBirthday ?? 'Кто видит мой день рождения',
          value: _whoSeesBirthday,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesBirthday = v),
        ),
        _dropdownRow(
          label: l10n?.whoSeesOnlineTime ?? 'Кто видит время моей активности',
          value: _whoSeesOnlineTime,
          options: options,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => setState(() => _whoSeesOnlineTime = v),
        ),
        SizedBox(height: 18 * scale),
        if (_privacyError != null) _errorBanner(_privacyError!, isDark, scale),
        _primaryButton(
          label: _privacySaving
              ? (l10n?.saving ?? 'Сохранение...')
              : (l10n?.save ?? 'Сохранить'),
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
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : {};
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
          _pcContactsError =
              (AppLocalizations.of(context)?.neUdalosZagruzitKontakty_02a3 ??
              'Fallback');
        });
      }
    }
  }

  Future<void> _deletePcContact(int contactUserId) async {
    try {
      await ApiService().dio.post(
        '/contacts/delete/',
        data: {'user_id': contactUserId},
      );
      _loadPcContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления контакта: $e')));
      }
    }
  }

  void _showAddContactDialog(bool isDark, double scale) {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        title: Text(
          l10n?.addContactTitle ??
              (AppLocalizations.of(context)?.dobavitKontakt_4278 ?? 'Fallback'),
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
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14 * scale,
              ),
              decoration: InputDecoration(
                hintText:
                    l10n?.userNicknameHint ??
                    (AppLocalizations.of(context)?.nikneymPolzovatelya_5610 ??
                        'Fallback'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13 * scale,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10 * scale),
            TextField(
              controller: nameCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14 * scale,
              ),
              decoration: InputDecoration(
                hintText:
                    l10n?.displayNameOptional ??
                    (AppLocalizations.of(
                          context,
                        )?.otobrazhaemoeImyaOptsionalno_bbd1 ??
                        'Fallback'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13 * scale,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n?.cancel ??
                  (AppLocalizations.of(context)?.otmena_987b ?? 'Fallback'),
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black87,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final un = usernameCtrl.text.trim().replaceAll('@', '');
              final cn = nameCtrl.text.trim();
              if (un.isNotEmpty) {
                Navigator.of(ctx).pop();
                try {
                  await ApiService().dio.post(
                    '/contacts/create/',
                    data: {
                      'username': un,
                      if (cn.isNotEmpty) 'custom_name': cn,
                    },
                  );
                  _loadPcContacts();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Не удалось добавить контакт: $e'),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              l10n?.addContact ??
                  (AppLocalizations.of(context)?.dobavit_5eba ?? 'Fallback'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContacts(bool isDark, double scale) {
    if (!_pcContactsLoaded && !_pcContactsLoading) {
      _loadPcContacts();
    }
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader(
              '${l10n?.contacts ?? (AppLocalizations.of(context)?.kontakty_7576 ?? 'Fallback')} (${_pcContacts.length})',
              isDark,
              scale,
            ),
            TextButton.icon(
              onPressed: () => _showAddContactDialog(isDark, scale),
              icon: Icon(
                Icons.person_add_rounded,
                size: 16 * scale,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              label: Text(
                l10n?.addContact ??
                    (AppLocalizations.of(context)?.dobavit_5eba ?? 'Fallback'),
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
                  Icon(
                    Icons.people_outline_rounded,
                    size: 40 * scale,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    l10n?.noContactsYet ??
                        (AppLocalizations.of(
                              context,
                            )?.uVasPokaNetSohranennyh_b64b ??
                            'Fallback'),
                    style: TextStyle(
                      fontSize: 13 * scale,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
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
              final firstName =
                  item['contact_user_first_name']?.toString() ?? '';
              final customName = item['custom_name']?.toString();
              final avatar =
                  item['custom_avatar'] ?? item['contact_user_avatar'];
              final gradient =
                  item['contact_user_avatar_gradient']?.toString() ?? '';

              final displayName = (customName != null && customName.isNotEmpty)
                  ? customName
                  : (firstName.isNotEmpty ? firstName : username);

              return Container(
                padding: EdgeInsets.all(10 * scale),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    // Аватар
                    _buildUserCardAvatar(
                      avatar?.toString(),
                      gradient,
                      displayName,
                      40 * scale,
                    ),
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
                      tooltip: l10n?.call ?? 'Позвонить',
                      onPressed: () {
                        if (widget.onStartCall != null) {
                          widget.onStartCall!(item);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.chat_bubble_rounded, size: 18 * scale),
                      color: isDark ? Colors.white70 : Colors.black87,
                      tooltip: l10n?.sendMessage ?? 'Написать',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.deleteContact ?? 'Удалить контакт',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n?.messages ?? 'Сообщения', isDark, scale),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: l10n?.messageAnimations ?? 'Анимации сообщений',
          description:
              l10n?.messageAnimationsDesc ??
              'Показывать анимации при отправке и получении',
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
          label: l10n?.archivedChats ?? 'Архивированные чаты',
          subtitle: l10n?.archiveManagement ?? 'Управление архивом',
          isDark: isDark,
          scale: scale,
        ),
        SizedBox(height: 12 * scale),
        _infoTile(
          icon: Icons.delete_sweep_rounded,
          label: l10n?.clearHistory ?? 'Очистить историю',
          subtitle: l10n?.clearHistoryDesc ?? 'Удалить все сообщения локально',
          isDark: isDark,
          scale: scale,
          color: Colors.red,
        ),
      ],
    );
  }

  // ── Security ─────────────────────────────────────────────────────────────────

  Widget _buildSecurity(bool isDark, double scale) {
    final l10n = AppLocalizations.of(context);
    if (_securityLoading && !_securityLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          l10n?.twoFactorAuth ?? _securityText('twoFactorTitle'),
          isDark,
          scale,
        ),
        SizedBox(height: 8 * scale),
        _infoTile(
          icon: Icons.verified_user_rounded,
          label: _tfaEnabled
              ? _securityText('tfaEnabled')
              : _securityText('tfaDisabled'),
          subtitle: l10n?.twoFactorAuthDesc ?? _securityText('twoFactorDesc'),
          isDark: isDark,
          scale: scale,
          trailing: FilledButton(
            onPressed: _securityBusy ? null : _requestSecurityTfaCode,
            style: FilledButton.styleFrom(
              backgroundColor: _tfaEnabled
                  ? Colors.redAccent
                  : const Color(0xFF2563EB),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
            ),
            child: Text(
              _tfaEnabled ? _securityText('disable') : _securityText('enable'),
              style: TextStyle(fontSize: 11 * scale),
            ),
          ),
        ),
        if (_pendingTfaAction != null) ...[
          SizedBox(height: 10 * scale),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _securityCodeCtrl,
                  enabled: !_securityBusy,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    letterSpacing: 7 * scale,
                    fontSize: 18 * scale,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9 * scale),
                    ),
                  ),
                  onSubmitted: (_) => _confirmSecurityTfa(),
                ),
              ),
              SizedBox(width: 8 * scale),
              IconButton.filled(
                tooltip: _securityText('confirm'),
                onPressed: _securityBusy ? null : _confirmSecurityTfa,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
        ],
        if (_securityError != null || _securitySuccess != null) ...[
          SizedBox(height: 8 * scale),
          Text(
            _securityError ?? _securitySuccess!,
            style: TextStyle(
              color: _securityError != null
                  ? Colors.redAccent
                  : const Color(0xFF059669),
              fontSize: 11 * scale,
            ),
          ),
        ],
        SizedBox(height: 20 * scale),
        Row(
          children: [
            Expanded(
              child: _sectionHeader(
                l10n?.activeSessions ?? _securityText('activeSessions'),
                isDark,
                scale,
              ),
            ),
            IconButton(
              tooltip: _securityText('refresh'),
              onPressed: _securityBusy
                  ? null
                  : () => _loadSecurity(force: true),
              icon: Icon(Icons.refresh_rounded, size: 17 * scale),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        if (_securitySessions.isEmpty)
          Text(
            _securityText('noSessions'),
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12 * scale,
            ),
          )
        else
          ..._securitySessions.map((session) {
            final current = session['is_current'] == true;
            final agent =
                session['user_agent']?.toString() ??
                _securityText('unknownDevice');
            final ip = session['ip_address']?.toString() ?? '—';
            final id = (session['id'] as num?)?.toInt();
            return Padding(
              padding: EdgeInsets.only(bottom: 8 * scale),
              child: _infoTile(
                icon: agent.toLowerCase().contains('mobile')
                    ? Icons.phone_android_rounded
                    : Icons.computer_rounded,
                label: current
                    ? (l10n?.thisDevice ?? _securityText('thisDevice'))
                    : agent,
                subtitle: current ? '$agent • $ip' : ip,
                isDark: isDark,
                scale: scale,
                trailing: current
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale,
                          vertical: 3 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n?.activeNow ?? _securityText('active'),
                          style: TextStyle(
                            fontSize: 10 * scale,
                            color: const Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : IconButton(
                        tooltip: _securityText('terminate'),
                        onPressed: _securityBusy || id == null
                            ? null
                            : () => _terminateSecuritySession(id),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                          size: 18 * scale,
                        ),
                      ),
              ),
            );
          }),
      ],
    );
  }

  // ── Appearance ───────────────────────────────────────────────────────────────

  Widget _buildAppearance(BuildContext context, bool isDark, double scale) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n?.theme ?? 'Тема', isDark, scale),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: l10n?.darkTheme ?? 'Тёмная тема',
          description:
              l10n?.darkThemeDesc ??
              'Переключить между тёмным и светлым оформлением',
          value: themeProvider.isDarkMode,
          isDark: isDark,
          scale: scale,
          onChanged: (v) => themeProvider.setDarkMode(v),
        ),
        SizedBox(height: 20 * scale),
        _sectionHeader(l10n?.fontSizeText ?? 'Размер шрифта', isDark, scale),
        SizedBox(height: 8 * scale),
        Row(
          children: [
            Text(
              'A',
              style: TextStyle(
                fontSize: 12 * scale,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
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
            Text(
              'A',
              style: TextStyle(
                fontSize: 20 * scale,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        Center(
          child: Text(
            '${_fontSize.round()} px',
            style: TextStyle(
              fontSize: 11 * scale,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      ],
    );
  }

  // ── Language ─────────────────────────────────────────────────────────────────

  Widget _buildLanguage(BuildContext context, bool isDark, double scale) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentCode = localeProvider.locale?.languageCode ?? 'ru';
    return Column(
      children: LocaleProvider.availableLanguages.map((lang) {
        final code = lang['code']!;
        final name = lang['name']!;
        return _radioRow(name, code, currentCode, isDark, scale, (v) {
          localeProvider.setLocale(Locale(code));
          _savePrefs();
        });
      }).toList(),
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────────

  Widget _buildNotifications(bool isDark, double scale) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _switchRow(
          label: l10n?.notifications ?? 'Уведомления',
          description: l10n?.showPopups ?? 'Показывать всплывающие уведомления',
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
          label: l10n?.sound ?? 'Звук',
          description:
              l10n?.soundDesc ?? 'Воспроизводить звук при новом сообщении',
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          l10n?.mainSettings ?? 'Основные настройки',
          isDark,
          scale,
        ),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: l10n?.energySavingMode ?? 'Режим экономии энергии',
          description:
              l10n?.energySavingModeDesc ??
              'Оптимизирует работу приложения для экономии заряда',
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
          label: l10n?.autoSleep ?? 'Автоматический спящий режим',
          description:
              l10n?.autoSleepDesc ??
              'Переводит приложение в спящий режим при неактивности',
          value: _autoSleep,
          isDark: isDark,
          scale: scale,
          onChanged: (v) {
            setState(() => _autoSleep = v);
            _savePrefs();
          },
        ),
        SizedBox(height: 20 * scale),
        _sectionHeader(l10n?.animations ?? 'Анимации', isDark, scale),
        SizedBox(height: 8 * scale),
        _switchRow(
          label: l10n?.messageAnimations ?? 'Анимации сообщений',
          description:
              l10n?.messageAnimationsDesc ??
              'Показывать анимации при отправке и получении',
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
          label: l10n?.reducedMotion ?? 'Упрощённые анимации',
          description:
              l10n?.reducedMotionDesc ??
              'Уменьшает количество анимаций интерфейса',
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32 * scale),
        child: Column(
          children: [
            Icon(
              Icons.construction_rounded,
              size: 32 * scale,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            SizedBox(height: 12 * scale),
            Text(
              l10n?.comingSoon ?? 'Скоро будет доступно',
              style: TextStyle(
                fontSize: 14 * scale,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ── UI Primitive Blocks ───────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildUserCardAvatar(
    String? avatar,
    String gradient,
    String firstName,
    double size,
  ) {
    List<Color> gradColors = [const Color(0xFF2563EB), const Color(0xFF7C3AED)];
    final hexes = RegExp(r'#([0-9a-fA-F]{6})')
        .allMatches(gradient)
        .map((m) => Color(int.parse('FF${m.group(1)}', radix: 16)))
        .toList();
    if (hexes.length >= 2) gradColors = hexes;

    final hasAvatar =
        avatar != null &&
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

  Widget _buildUserCard(
    String firstName,
    String username,
    String? avatar,
    String gradient,
    bool isDark,
    double scale,
  ) {
    List<Color> gradColors = [const Color(0xFF2563EB), const Color(0xFF7C3AED)];
    final hexes = RegExp(r'#([0-9a-fA-F]{6})')
        .allMatches(gradient)
        .map((m) => Color(int.parse('FF${m.group(1)}', radix: 16)))
        .toList();
    if (hexes.length >= 2) gradColors = hexes;

    final hasAvatar =
        avatar != null &&
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
                Text(
                  firstName,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
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
              color: isDark ? Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
            ),
            child: Center(
              child: Icon(
                Icons.person_off_rounded,
                size: 22 * scale,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (AppLocalizations.of(context)?.gostevoyRezhim_6d82 ??
                    'Fallback'),
                style: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                (AppLocalizations.of(
                      context,
                    )?.voyditeDlyaDostupaKAkkauntu_a5c8 ??
                    'Fallback'),
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4 * scale,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2 * scale),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2 * scale,
          color: isDark ? Colors.white30 : Colors.black38,
        ),
      ),
    );
  }

  Widget _menuRow(_SettingsSection section, bool isDark, double scale) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _activeSection = section.id);
          if (section.id == 'security') _loadSecurity();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(vertical: 2 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 10 * scale,
          ),
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
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      section.description,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18 * scale,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
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
            horizontal: 10 * scale,
            vertical: 10 * scale,
          ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
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

  Widget _radioRow(
    String label,
    String value,
    String groupValue,
    bool isDark,
    double scale,
    ValueChanged<String?> onChanged,
  ) {
    return RadioListTile<String>(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14 * scale,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * scale,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
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
              horizontal: 12 * scale,
              vertical: 10 * scale,
            ),
            isDense: true,
          ),
        ),
        if (note != null) ...[
          SizedBox(height: 4 * scale),
          Text(
            note,
            style: TextStyle(
              fontSize: 10 * scale,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * scale,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
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
              horizontal: 12 * scale,
              vertical: 10 * scale,
            ),
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
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
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
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 10 * scale,
      ),
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
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
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Text(
          msg,
          style: TextStyle(fontSize: 12 * scale, color: Colors.red.shade300),
        ),
      ),
    );
  }

  Widget _successBanner(String msg, bool isDark, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
        ),
        child: Text(
          msg,
          style: TextStyle(
            fontSize: 12 * scale,
            color: const Color(0xFF059669),
          ),
        ),
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
                  ? (isDark
                        ? const Color(0xFF2563EB).withOpacity(0.18)
                        : const Color(0xFF2563EB).withOpacity(0.1))
                  : _isHovered
                  ? (isDark
                        ? Colors.white.withOpacity(0.09)
                        : Colors.black.withOpacity(0.06))
                  : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(
                color: _isOpen
                    ? const Color(0xFF2563EB)
                    : (_isHovered
                          ? (isDark ? Colors.white30 : Colors.black38)
                          : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.08))),
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
  State<_XaneoDropdownMenuOverlay> createState() =>
      __XaneoDropdownMenuOverlayState();
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
    final borderColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

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
              ? (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05))
              : Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5 * scale,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
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
