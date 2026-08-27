import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionSecrets {
  final String accessToken;
  final String refreshToken;
  final String x25519Private;
  final String ed25519Private;

  const SessionSecrets({
    required this.accessToken,
    required this.refreshToken,
    required this.x25519Private,
    required this.ed25519Private,
  });

  bool get isComplete =>
      accessToken.isNotEmpty &&
      refreshToken.isNotEmpty &&
      x25519Private.isNotEmpty;

  SessionSecrets copyWith({
    String? accessToken,
    String? refreshToken,
    String? x25519Private,
    String? ed25519Private,
  }) {
    return SessionSecrets(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      x25519Private: x25519Private ?? this.x25519Private,
      ed25519Private: ed25519Private ?? this.ed25519Private,
    );
  }

  Map<String, dynamic> toJson() => {
    'access': accessToken,
    'refresh': refreshToken,
    'x25519_private': x25519Private,
    'ed25519_private': ed25519Private,
  };

  factory SessionSecrets.fromJson(Map<String, dynamic> json) {
    return SessionSecrets(
      accessToken: json['access']?.toString() ?? '',
      refreshToken: json['refresh']?.toString() ?? '',
      x25519Private: json['x25519_private']?.toString() ?? '',
      ed25519Private: json['ed25519_private']?.toString() ?? '',
    );
  }
}

/// Stores authentication material and private E2EE keys in the operating
/// system credential store. SharedPreferences is used only as a one-time
/// migration source for legacy installations.
class SecureSessionStorage {
  static const _activeBundleKey = 'xaneo.secure.active_session.v2';
  static const _accountBundlePrefix = 'xaneo.secure.account.v2.';
  static const _legacyMigrationKey = 'xaneo_secure_active_migrated_v2';

  static final SecureSessionStorage _instance = SecureSessionStorage._();
  factory SecureSessionStorage() => _instance;
  SecureSessionStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<void>? _legacyMigration;

  String _accountKey(int userId) => '$_accountBundlePrefix$userId';

  Future<void> migrateLegacyActiveSessionIfNeeded() {
    return _legacyMigration ??= _migrateLegacyActiveSession();
  }

  Future<void> _migrateLegacyActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_legacyMigrationKey) == true) return;

    final existing = await _storage.read(key: _activeBundleKey);
    if (existing == null || existing.isEmpty) {
      final legacy = SessionSecrets(
        accessToken: prefs.getString('xaneo_access_token') ?? '',
        refreshToken: prefs.getString('xaneo_refresh_token') ?? '',
        x25519Private: prefs.getString('xsec2_x25519_private') ?? '',
        ed25519Private: prefs.getString('xsec2_ed25519_private') ?? '',
      );
      if (legacy.isComplete) await writeActiveSession(legacy);
    }

    await prefs.remove('xaneo_access_token');
    await prefs.remove('xaneo_refresh_token');
    await prefs.remove('xsec2_x25519_private');
    await prefs.remove('xsec2_ed25519_private');
    await prefs.setBool(_legacyMigrationKey, true);
  }

  Future<SessionSecrets?> readActiveSession() async {
    await migrateLegacyActiveSessionIfNeeded();
    return _readBundle(_activeBundleKey);
  }

  Future<void> writeActiveSession(SessionSecrets secrets) {
    return _writeBundle(_activeBundleKey, secrets);
  }

  Future<void> clearActiveSession() => _storage.delete(key: _activeBundleKey);

  Future<SessionSecrets?> readAccountSession(int userId) {
    return _readBundle(_accountKey(userId));
  }

  Future<void> writeAccountSession(int userId, SessionSecrets secrets) {
    return _writeBundle(_accountKey(userId), secrets);
  }

  Future<void> deleteAccountSession(int userId) {
    return _storage.delete(key: _accountKey(userId));
  }

  Future<SessionSecrets?> _readBundle(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return SessionSecrets.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeBundle(String key, SessionSecrets secrets) {
    return _storage.write(key: key, value: jsonEncode(secrets.toJson()));
  }
}
