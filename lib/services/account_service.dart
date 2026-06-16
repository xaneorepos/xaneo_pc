import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';

class AccountInfo {
  final int userId;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String accessToken;
  final String refreshToken;
  final String x25519Private;
  final String ed25519Private;
  final String? avatarGradient;
  final String? firstName;

  AccountInfo({
    required this.userId,
    required this.username,
    this.email,
    this.avatarUrl,
    required this.accessToken,
    required this.refreshToken,
    required this.x25519Private,
    required this.ed25519Private,
    this.avatarGradient,
    this.firstName,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'email': email,
    'avatarUrl': avatarUrl,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'x25519Private': x25519Private,
    'ed25519Private': ed25519Private,
    'avatarGradient': avatarGradient,
    'firstName': firstName,
  };

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
    userId: json['userId'] as int,
    username: json['username'] as String,
    email: json['email'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    x25519Private: json['x25519Private'] as String,
    ed25519Private: json['ed25519Private'] as String,
    avatarGradient: json['avatarGradient'] as String?,
    firstName: json['firstName'] as String?,
  );
}

class AccountService {
  static const String _accountsListKey = 'xaneo_accounts_list';
  
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  /// Получить список всех сохраненных аккаунтов
  Future<List<AccountInfo>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_accountsListKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => AccountInfo.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Сохранить список аккаунтов в SharedPreferences
  Future<void> _saveAccounts(List<AccountInfo> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsListKey, jsonStr);
  }

  /// Сохранить текущий вошедший аккаунт в списке (или обновить его токены)
  Future<bool> saveCurrentAccount(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('xaneo_access_token');
    final refreshToken = prefs.getString('xaneo_refresh_token');
    final x25519Private = prefs.getString('xsec2_x25519_private');
    final ed25519Private = prefs.getString('xsec2_ed25519_private');

    if (accessToken == null || refreshToken == null || x25519Private == null || ed25519Private == null) {
      return false;
    }

    final userId = profile['id'] as int;
    final username = profile['username'] as String;
    final email = profile['email'] as String?;
    final avatarUrl = profile['avatar'] as String? ?? profile['avatar_url'] as String?;
    final avatarGradient = profile['avatar_gradient'] as String?;
    final firstName = profile['first_name'] as String? ?? profile['realname'] as String?;

    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.userId == userId);
    
    // Лимит: не более 5 аккаунтов
    if (index == -1 && accounts.length >= 5) {
      return false;
    }

    final account = AccountInfo(
      userId: userId,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      accessToken: accessToken,
      refreshToken: refreshToken,
      x25519Private: x25519Private,
      ed25519Private: ed25519Private,
      avatarGradient: avatarGradient,
      firstName: firstName,
    );

    if (index != -1) {
      accounts[index] = account; // Обновляем
    } else {
      accounts.add(account); // Добавляем новый
    }

    await _saveAccounts(accounts);
    return true;
  }

  /// Переключение на аккаунт
  Future<bool> switchAccount(int userId) async {
    final accounts = await getAccounts();
    final targetIndex = accounts.indexWhere((a) => a.userId == userId);
    if (targetIndex == -1) return false;

    // 1. Попробуем обновить текущий аккаунт перед выходом, если он существует
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('xaneo_access_token');
    if (currentToken != null) {
      try {
        final profileRes = await ApiService().getProfile();
        if (profileRes.success && profileRes.data != null) {
          await saveCurrentAccount(profileRes.data!);
        }
      } catch (_) {}
    }

    // Заново читаем актуальный список
    final updatedAccounts = await getAccounts();
    final accountToLoad = updatedAccounts.firstWhere((a) => a.userId == userId);

    // 2. Сначала очищаем старые ключи (это удаляет ключи из SharedPreferences)
    await CryptoService().clearKeys();

    // 3. Очищаем старые куки сессии
    await ApiService().clearCookies();

    // 4. Устанавливаем новые токены и ключи в стандартные настройки
    await prefs.setString('xaneo_access_token', accountToLoad.accessToken);
    await prefs.setString('xaneo_refresh_token', accountToLoad.refreshToken);
    await prefs.setString('xsec2_x25519_private', accountToLoad.x25519Private);
    await prefs.setString('xsec2_ed25519_private', accountToLoad.ed25519Private);

    // 5. Загружаем новые ключи в память CryptoService
    await CryptoService().loadKeysFromLocalStorage();

    // 6. Продлеваем токен, если он истек
    await ApiService().refreshToken();

    return true;
  }

  /// Удалить аккаунт (разлогин из одного аккаунта)
  Future<void> removeAccount(int userId) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.userId == userId);
    await _saveAccounts(accounts);
  }

  /// Обновить access и (при наличии) refresh токены для аккаунта с указанным refresh токеном
  Future<void> updateAccessToken(String refreshToken, String newAccessToken, [String? newRefreshToken]) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.refreshToken == refreshToken);
    if (index != -1) {
      final oldAccount = accounts[index];
      accounts[index] = AccountInfo(
        userId: oldAccount.userId,
        username: oldAccount.username,
        email: oldAccount.email,
        avatarUrl: oldAccount.avatarUrl,
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? oldAccount.refreshToken,
        x25519Private: oldAccount.x25519Private,
        ed25519Private: oldAccount.ed25519Private,
        avatarGradient: oldAccount.avatarGradient,
        firstName: oldAccount.firstName,
      );
      await _saveAccounts(accounts);
    }
  }
}
