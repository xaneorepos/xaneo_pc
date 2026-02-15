import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API сервис для Xaneo PC
/// Обеспечивает безопасное подключение к серверу Xaneo
class ApiService {
  // Базовый URL сервера (настраивается)
  static String _baseUrl = 'http://192.168.3.58:8000/api/v1';
  
  // User-Agent для идентификации приложения
  static const String _userAgent = 'XaneoPC/1.0';
  
  // Ключи для хранения токенов
  static const String _accessTokenKey = 'xaneo_access_token';
  static const String _refreshTokenKey = 'xaneo_refresh_token';
  
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Геттер для базового URL
  static String get baseUrl => _baseUrl;
  
  /// Установить базовый URL (для настройки)
  static void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/$'), '');
  }
  
  /// Получить заголовки для запросов
  Map<String, String> _getHeaders({String? contentType}) {
    final headers = <String, String>{
      'User-Agent': _userAgent,
      'Accept': 'application/json',
    };
    
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    
    return headers;
  }
  
  /// Получить заголовки с авторизацией
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = _getHeaders(contentType: 'application/json');
    final token = await getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  // ==================== АВТОРИЗАЦИЯ ====================
  
  /// Вход в систему
  /// Возвращает Map с данными пользователя или ошибкой
  Future<ApiResponse> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: _getHeaders(contentType: 'application/json'),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      return _handleResponse(response, isAuthRequest: true);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка подключения к серверу: $e',
      );
    }
  }
  
  // ==================== РЕГИСТРАЦИЯ С ПОДТВЕРЖДЕНИЕМ EMAIL ====================

  /// Отправить код подтверждения на email
  /// Возвращает ApiResponse с success: true если код отправлен
  Future<ApiResponse> sendVerificationCode({
    required String email,
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/send-verification-code/'),
        headers: _getHeaders(contentType: 'application/json'),
        body: jsonEncode({
          'email': email,
          'username': username,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка отправки кода: $e',
      );
    }
  }

  /// Проверить код подтверждения email
  /// Возвращает ApiResponse с success: true если код верный
  Future<ApiResponse> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-email-code/'),
        headers: _getHeaders(contentType: 'application/json'),
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка проверки кода: $e',
      );
    }
  }

  /// Регистрация нового пользователя (после подтверждения email)
  /// Требует, что email был подтверждён через verifyEmailCode
  Future<ApiResponse> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String birthDate,
    String? firstName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: _getHeaders(contentType: 'application/json'),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'birth_date': birthDate,
          'email_verified': true, // Обязательно true после подтверждения кода
          if (firstName != null) 'realname': firstName,
        }),
      );

      final result = _handleResponse(response, isAuthRequest: true);

      // Сохраняем токены при успешной регистрации
      if (result.success && result.data != null) {
        if (result.data!['access'] != null) {
          await saveAccessToken(result.data!['access'] as String);
        }
        if (result.data!['refresh'] != null) {
          await saveRefreshToken(result.data!['refresh'] as String);
        }
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка регистрации: $e',
      );
    }
  }
  
  /// Получение JWT токена
  Future<ApiResponse> obtainToken(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/'),
        headers: _getHeaders(contentType: 'application/json'),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      final result = _handleResponse(response);
      
      // Сохраняем токены
      if (result.success && result.data != null) {
        if (result.data!['access'] != null) {
          await saveAccessToken(result.data!['access'] as String);
        }
        if (result.data!['refresh'] != null) {
          await saveRefreshToken(result.data!['refresh'] as String);
        }
      }
      
      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка получения токена: $e',
      );
    }
  }
  
  /// Обновление access токена
  Future<ApiResponse> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return ApiResponse(
          success: false,
          error: 'Refresh токен не найден',
        );
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/refresh/'),
        headers: _getHeaders(contentType: 'application/json'),
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );
      
      final result = _handleResponse(response);
      
      if (result.success && result.data != null && result.data!['access'] != null) {
        await saveAccessToken(result.data!['access'] as String);
      }
      
      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка обновления токена: $e',
      );
    }
  }
  
  /// Проверка валидности токена
  Future<ApiResponse> verifyToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'Токен не найден',
        );
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/verify/'),
        headers: _getHeaders(contentType: 'application/json'),
        body: jsonEncode({'token': token}),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка проверки токена: $e',
      );
    }
  }
  
  /// Выход из системы
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
  
  // ==================== ПРОФИЛЬ ====================
  
  /// Получить профиль пользователя
  Future<ApiResponse> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/profile/'),
        headers: await _getAuthHeaders(),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка получения профиля: $e',
      );
    }
  }
  
  // ==================== ХРАНЕНИЕ ТОКЕНОВ ====================
  
  /// Сохранить access токен
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }
  
  /// Получить access токен
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
  
  /// Сохранить refresh токен
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }
  
  /// Получить refresh токен
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  /// Проверить, авторизован ли пользователь
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }
  
  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================
  
  /// Обработка ответа сервера
  ApiResponse _handleResponse(http.Response response, {bool isAuthRequest = false}) {
    final statusCode = response.statusCode;
    
    // Пытаемся распарсить JSON
    Map<String, dynamic>? data;
    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Если не JSON, возвращаем как есть
    }
    
    // Успешные статусы
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse(
        success: true,
        data: data,
        statusCode: statusCode,
      );
    }
    
    // Обработка ошибок
    String errorMessage = 'Неизвестная ошибка';
    
    if (data != null) {
      // Стандартные ошибки Django REST Framework
      if (data['detail'] != null) {
        errorMessage = data['detail'].toString();
      } else if (data['error'] != null) {
        errorMessage = data['error'].toString();
      } else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      } else if (data['non_field_errors'] != null) {
        errorMessage = (data['non_field_errors'] as List).join(', ');
      } else {
        // Ошибки по полям
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            errors.add('$key: ${value.join(', ')}');
          } else {
            errors.add('$key: $value');
          }
        });
        if (errors.isNotEmpty) {
          errorMessage = errors.join('\n');
        }
      }
    }
    
    // Специфичные ошибки по статусам
    switch (statusCode) {
      case 401:
        errorMessage = 'Неверные учетные данные';
        break;
      case 403:
        errorMessage = 'Доступ запрещён';
        break;
      case 404:
        errorMessage = 'Ресурс не найден';
        break;
      case 500:
        errorMessage = 'Ошибка сервера';
        break;
    }
    
    return ApiResponse(
      success: false,
      error: errorMessage,
      data: data,
      statusCode: statusCode,
    );
  }
  
  /// Проверка доступности сервера
  Future<bool> checkServerAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/info/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Результат API запроса
class ApiResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final int? statusCode;
  
  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });
  
  @override
  String toString() {
    if (success) {
      return 'ApiResponse(success: true, data: $data)';
    }
    return 'ApiResponse(success: false, error: $error, statusCode: $statusCode)';
  }
}
