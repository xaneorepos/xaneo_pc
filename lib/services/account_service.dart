import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'crypto_service.dart';
import 'logger_service.dart';
import 'secure_session_storage.dart';

class AccountInfo {
  final int userId;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? avatarGradient;
  final String? firstName;
  final DateTime lastUsedAt;

  const AccountInfo({
    required this.userId,
    required this.username,
    this.email,
    this.avatarUrl,
    this.avatarGradient,
    this.firstName,
    required this.lastUsedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'email': email,
    'avatarUrl': avatarUrl,
    'avatarGradient': avatarGradient,
    'firstName': firstName,
    'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
  };

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'];
    final userId = rawId is int ? rawId : int.parse(rawId.toString());
    return AccountInfo(
      userId: userId,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      avatarGradient: json['avatarGradient']?.toString(),
      firstName: json['firstName']?.toString(),
      lastUsedAt:
          DateTime.tryParse(json['lastUsedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class AccountService {
  static const int maxAccounts = 5;
  static const String _accountsListKey = 'xaneo_accounts_list';
  static const String _activeUserIdKey = 'xaneo_active_user_id_v2';
  static const String _migrationKey = 'xaneo_accounts_secure_migrated_v2';

  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  final SecureSessionStorage _secureStorage = SecureSessionStorage();
  Future<void>? _migration;

  Future<void> _ensureMigrated() {
    return _migration ??= _migrateLegacyAccounts();
  }

  Future<void> _migrateLegacyAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    final raw = prefs.getString(_accountsListKey);
    final metadata = <AccountInfo>[];
    final legacyActiveAccess =
        prefs.getString('xaneo_access_token') ??
        (await _secureStorage.readActiveSession())?.accessToken;
    int? activeUserId;

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final json = Map<String, dynamic>.from(item);
            try {
              final account = AccountInfo.fromJson(json);
              if (account.userId <= 0 || account.username.isEmpty) continue;
              final secrets = SessionSecrets(
                accessToken: json['accessToken']?.toString() ?? '',
                refreshToken: json['refreshToken']?.toString() ?? '',
                x25519Private: json['x25519Private']?.toString() ?? '',
                ed25519Private: json['ed25519Private']?.toString() ?? '',
              );
              if (secrets.isComplete) {
                await _secureStorage.writeAccountSession(
                  account.userId,
                  secrets,
                );
                if (legacyActiveAccess != null &&
                    secrets.accessToken == legacyActiveAccess) {
                  activeUserId = account.userId;
                }
              }
              metadata.add(account);
            } catch (error) {
              Logger.warning(
                'AccountService',
                'Skipping malformed legacy account during migration: $error',
              );
            }
          }
        }
      } catch (error) {
        Logger.warning(
          'AccountService',
          'Legacy account list migration failed: $error',
        );
        rethrow;
      }
    }

    await prefs.setString(
      _accountsListKey,
      jsonEncode(metadata.map((account) => account.toJson()).toList()),
    );
    if (activeUserId != null) {
      await prefs.setInt(_activeUserIdKey, activeUserId);
    }
    await prefs.setBool(_migrationKey, true);
  }

  Future<List<AccountInfo>> getAccounts() async {
    await _ensureMigrated();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsListKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final accounts = <AccountInfo>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          accounts.add(AccountInfo.fromJson(Map<String, dynamic>.from(item)));
        } catch (error) {
          Logger.warning(
            'AccountService',
            'Ignoring malformed account: $error',
          );
        }
      }
      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return accounts;
    } catch (error) {
      Logger.warning(
        'AccountService',
        'Failed to read account metadata: $error',
      );
      return [];
    }
  }

  Future<int?> getActiveUserId() async {
    await _ensureMigrated();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeUserIdKey);
  }

  Future<void> _saveAccounts(List<AccountInfo> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountsListKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }

  Future<bool> saveCurrentAccount(Map<String, dynamic> profile) async {
    await _ensureMigrated();
    final activeSecrets = await _secureStorage.readActiveSession();
    if (activeSecrets == null || !activeSecrets.isComplete) {
      Logger.warning(
        'AccountService',
        'Cannot save current account: active secure session is incomplete',
      );
      return false;
    }

    final rawUserId = profile['id'];
    final userId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');
    final username = profile['username']?.toString() ?? '';
    if (userId == null || userId <= 0 || username.isEmpty) return false;

    final accounts = await getAccounts();
    final exists = accounts.any((item) => item.userId == userId);
    if (!exists && accounts.length >= maxAccounts) return false;

    final account = AccountInfo(
      userId: userId,
      username: username,
      email: profile['email']?.toString(),
      avatarUrl:
          profile['avatar']?.toString() ?? profile['avatar_url']?.toString(),
      avatarGradient: profile['avatar_gradient']?.toString(),
      firstName:
          profile['first_name']?.toString() ?? profile['realname']?.toString(),
      lastUsedAt: DateTime.now().toUtc(),
    );

    accounts.removeWhere((item) => item.userId == userId);
    accounts.insert(0, account);
    await _secureStorage.writeAccountSession(userId, activeSecrets);
    await _saveAccounts(accounts.take(maxAccounts).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeUserIdKey, userId);
    return true;
  }

  /// Validates the target credentials before publishing them as active.
  Future<bool> switchAccount(int userId) async {
    await _ensureMigrated();
    final accounts = await getAccounts();
    AccountInfo? target;
    for (final account in accounts) {
      if (account.userId == userId) {
        target = account;
        break;
      }
    }
    if (target == null) return false;

    final stored = await _secureStorage.readAccountSession(userId);
    if (stored == null || !stored.isComplete) return false;

    final refreshed = await ApiService().refreshCredentials(
      stored.refreshToken,
    );
    if (refreshed == null) return false;
    final prepared = stored.copyWith(
      accessToken: refreshed.accessToken,
      refreshToken: refreshed.refreshToken,
    );
    final profile = await ApiService().getProfileWithAccessToken(
      prepared.accessToken,
    );
    if (!profile.success || profile.data?['id']?.toString() != '$userId') {
      return false;
    }

    await ApiService().beginSessionCommit();
    try {
      await _secureStorage.writeAccountSession(userId, prepared);
      await _secureStorage.writeActiveSession(prepared);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeUserIdKey, userId);
      await CryptoService().loadKeysFromLocalStorage();
      await ApiService().clearCookies();

      accounts.removeWhere((item) => item.userId == userId);
      accounts.insert(
        0,
        AccountInfo(
          userId: target.userId,
          username: target.username,
          email: target.email,
          avatarUrl: target.avatarUrl,
          avatarGradient: target.avatarGradient,
          firstName: target.firstName,
          lastUsedAt: DateTime.now().toUtc(),
        ),
      );
      await _saveAccounts(accounts);
      return true;
    } finally {
      ApiService().endSessionCommit();
    }
  }

  Future<void> restoreAccount(int? userId) async {
    if (userId == null) return;
    final secrets = await _secureStorage.readAccountSession(userId);
    if (secrets == null) return;
    await ApiService().beginSessionCommit();
    try {
      await _secureStorage.writeActiveSession(secrets);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeUserIdKey, userId);
      await CryptoService().loadKeysFromLocalStorage();
    } finally {
      ApiService().endSessionCommit();
    }
  }

  Future<void> removeAccount(int userId, {bool revoke = true}) async {
    await _ensureMigrated();
    final secrets = await _secureStorage.readAccountSession(userId);
    if (revoke && secrets != null && secrets.refreshToken.isNotEmpty) {
      final revoked = await ApiService().revokeRefreshToken(
        secrets.refreshToken,
      );
      if (!revoked) {
        throw StateError('REFRESH_TOKEN_REVOKE_FAILED');
      }
    }
    final accounts = await getAccounts();
    accounts.removeWhere((item) => item.userId == userId);
    await _saveAccounts(accounts);
    await _secureStorage.deleteAccountSession(userId);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_activeUserIdKey) == userId) {
      await prefs.remove(_activeUserIdKey);
    }
  }

  Future<void> updateAccessToken(
    String previousRefreshToken,
    String newAccessToken, [
    String? newRefreshToken,
  ]) async {
    final activeUserId = await getActiveUserId();
    if (activeUserId == null) return;
    final stored = await _secureStorage.readAccountSession(activeUserId);
    if (stored == null || stored.refreshToken != previousRefreshToken) return;
    await _secureStorage.writeAccountSession(
      activeUserId,
      stored.copyWith(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      ),
    );
  }
}
