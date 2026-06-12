import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API сервис для Xaneo PC с поддержкой автоматического сохранения сессионных кук (через Dio)
class ApiService {
  // Базовый URL сервера (настраивается)
  static String _baseUrl = 'https://192.168.3.65/api/v1';
  
  // User-Agent для идентификации приложения
  static const String _userAgent = 'XaneoPC/1.0 xaneo-app';
  
  // Ключи для хранения токенов
  static const String _accessTokenKey = 'xaneo_access_token';
  static const String _refreshTokenKey = 'xaneo_refresh_token';
  
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  // Dio instance
  late final Dio _dio;
  
  // CookieJar instance
  final CookieJar _cookieJar = CookieJar();
  
  // Геттер для базового URL
  static String get baseUrl => _baseUrl;
  
  /// Установить базовый URL (для настройки)
  static void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/$'), '');
    _instance._dio.options.baseUrl = _baseUrl;
  }
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (status) => status != null && status < 600,
    ));
    
    _dio.interceptors.add(CookieManager(_cookieJar));
    
    // Явная настройка для обхода SSL с самоподписанными сертификатами/несовпадением IP
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }
  
  /// Получить Options с базовыми заголовками
  Options _getOptions({String? contentType, Map<String, dynamic>? extraHeaders}) {
    final headers = <String, dynamic>{
      'User-Agent': _userAgent,
      'Accept': 'application/json',
      ...?extraHeaders,
    };
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    return Options(headers: headers);
  }
  
  /// Получить Options с авторизацией
  Future<Options> _getAuthOptions() async {
    final token = await getAccessToken();
    final extraHeaders = <String, dynamic>{};
    if (token != null) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    return _getOptions(
      contentType: 'application/json',
      extraHeaders: extraHeaders,
    );
  }
  
  // ==================== АВТОРИЗАЦИЯ ====================
  
  /// Вход в систему
  /// Возвращает Map с данными пользователя или ошибкой
  Future<ApiResponse> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login/',
        options: _getOptions(contentType: 'application/json'),
        data: {
          'username': username,
          'password': password,
        },
      );
      
      return _handleDioResponse(response, isAuthRequest: true);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка подключения к серверу: $e',
      );
    }
  }
  
  // ==================== РЕГИСТРАЦИЯ С ПОДТВЕРЖДЕНИЕМ EMAIL ====================
  
  /// Проверить доступность имени пользователя (username)
  Future<ApiResponse> checkUsername(String username) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/auth/check-username/',
        queryParameters: {'username': username},
        options: _getOptions(),
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка проверки имени пользователя: $e',
      );
    }
  }
  
  /// Проверить доступность email
  Future<ApiResponse> checkEmail(String email) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/auth/check-email/',
        queryParameters: {'email': email},
        options: _getOptions(),
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка проверки email: $e',
      );
    }
  }
  
  /// Отправить код подтверждения на email
  /// Возвращает ApiResponse с success: true если код отправлен
  Future<ApiResponse> sendVerificationCode({
    required String email,
    required String username,
  }) async {
    try {
      final urlStr = '$_baseUrl/auth/send-verification-code/';
      final data = {
        'email': email,
        'username': username,
      };
      final options = _getOptions(contentType: 'application/json');
      
      print('DEBUG API: POST to $urlStr');
      print('DEBUG API: Request Body: $data');
      print('DEBUG API: Request Headers: ${options.headers}');
      final cookiesBefore = await _cookieJar.loadForRequest(Uri.parse(urlStr));
      print('DEBUG API: Cookies before request: $cookiesBefore');
      
      final response = await _dio.post(
        urlStr,
        options: options,
        data: data,
      );
      
      print('DEBUG API: Response Code: ${response.statusCode}');
      print('DEBUG API: Response Headers: ${response.headers}');
      print('DEBUG API: Response Body: ${response.data}');
      final cookiesAfter = await _cookieJar.loadForRequest(Uri.parse(urlStr));
      print('DEBUG API: Cookies after request: $cookiesAfter');
      
      return _handleDioResponse(response);
    } catch (e) {
      print('DEBUG API: Error in sendVerificationCode: $e');
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
      final urlStr = '$_baseUrl/auth/verify-email-code/';
      final data = {
        'email': email,
        'code': code,
      };
      final options = _getOptions(contentType: 'application/json');
      
      print('DEBUG API: POST to $urlStr');
      print('DEBUG API: Request Body: $data');
      print('DEBUG API: Request Headers: ${options.headers}');
      final cookiesBefore = await _cookieJar.loadForRequest(Uri.parse(urlStr));
      print('DEBUG API: Cookies before request: $cookiesBefore');
      
      final response = await _dio.post(
        urlStr,
        options: options,
        data: data,
      );
      
      print('DEBUG API: Response Code: ${response.statusCode}');
      print('DEBUG API: Response Headers: ${response.headers}');
      print('DEBUG API: Response Body: ${response.data}');
      final cookiesAfter = await _cookieJar.loadForRequest(Uri.parse(urlStr));
      print('DEBUG API: Cookies after request: $cookiesAfter');
      
      return _handleDioResponse(response);
    } catch (e) {
      print('DEBUG API: Error in verifyEmailCode: $e');
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
      final urlStr = '$_baseUrl/auth/register/';
      final data = {
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
        'birth_date': birthDate,
        'email_verified': true, // Обязательно true после подтверждения кода
        if (firstName != null) 'realname': firstName,
      };
      final options = _getOptions(contentType: 'application/json');
      
      print('DEBUG API: POST to $urlStr');
      print('DEBUG API: Request Body: $data');
      print('DEBUG API: Request Headers: ${options.headers}');
      final cookiesBefore = await _cookieJar.loadForRequest(Uri.parse(urlStr));
      print('DEBUG API: Cookies before request: $cookiesBefore');
      
      final response = await _dio.post(
        urlStr,
        options: options,
        data: data,
      );
      
      print('DEBUG API: Response Code: ${response.statusCode}');
      print('DEBUG API: Response Headers: ${response.headers}');
      print('DEBUG API: Response Body: ${response.data}');
      final cookiesAfter = await _cookieJar.loadForRequest(Uri.parse(urlStr));
      print('DEBUG API: Cookies after request: $cookiesAfter');
      
      final result = _handleDioResponse(response, isAuthRequest: true);
      
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
      print('DEBUG API: Error in register: $e');
      return ApiResponse(
        success: false,
        error: 'Ошибка регистрации: $e',
      );
    }
  }
  
  /// Получение JWT токена
  Future<ApiResponse> obtainToken(String username, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/token/',
        options: _getOptions(contentType: 'application/json'),
        data: {
          'username': username,
          'password': password,
        },
      );
      
      final result = _handleDioResponse(response);
      
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
      
      final response = await _dio.post(
        '$_baseUrl/auth/token/refresh/',
        options: _getOptions(contentType: 'application/json'),
        data: {
          'refresh': refreshToken,
        },
      );
      
      final result = _handleDioResponse(response);
      
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
      
      final response = await _dio.post(
        '$_baseUrl/auth/token/verify/',
        options: _getOptions(contentType: 'application/json'),
        data: {'token': token},
      );
      
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка проверки токена: $e',
      );
    }
  }
  
  // ==================== XSEC-2 CRYPTO ENDPOINTS ====================
  
  /// Загрузить публичные ключи и зашифрованный blob на сервер
  Future<ApiResponse> uploadKeys({
    required String x25519PublicKey,
    required String ed25519PublicKey,
    required Map<String, dynamic> encryptedBlob,
    Map<String, dynamic>? recoveryBlob,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '$_baseUrl/xsec2/upload-keys/',
        options: options,
        data: {
          'x25519_public_key': x25519PublicKey,
          'ed25519_public_key': ed25519PublicKey,
          'encrypted_blob': encryptedBlob,
          if (recoveryBlob != null) 'recovery_blob': recoveryBlob,
        },
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка отправки ключей на сервер: $e',
      );
    }
  }

  /// Получить свои зашифрованные ключи с сервера
  Future<ApiResponse> getMyKeys() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '$_baseUrl/xsec2/my-keys/',
        options: options,
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка получения ключей с сервера: $e',
      );
    }
  }

  /// Получить публичные ключи собеседника по имени пользователя
  Future<ApiResponse> getUserPublicKey(String username) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '$_baseUrl/xsec2/keys/$username/',
        options: options,
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка получения публичного ключа пользователя: $e',
      );
    }
  }

  /// Получить симметричный ключ чата для групповых чатов / каналов
  Future<ApiResponse> getChatKey(String chatId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '$_baseUrl/xsec2/keys/chat/$chatId/',
        options: options,
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка получения ключа чата: $e',
      );
    }
  }

  // ==================== MESSAGING ENDPOINTS ====================

  /// Получить список чатов
  Future<ApiResponse> getChats() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '$_baseUrl/chats/',
        options: options,
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка получения списка чатов: $e',
      );
    }
  }

  /// Получить список сообщений в чате
  Future<ApiResponse> getMessages(String chatId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '$_baseUrl/encrypted-messages/',
        options: options,
        queryParameters: {'chat_id': chatId},
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка получения сообщений: $e',
      );
    }
  }

  /// Отправить зашифрованное сообщение
  Future<ApiResponse> sendMessage(String chatId, String encryptedText) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '$_baseUrl/encrypted-messages/',
        options: options,
        data: {
          'chat_id': chatId,
          'encrypted_text': encryptedText,
        },
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка отправки сообщения: $e',
      );
    }
  }

  /// Поиск пользователей, групп, каналов
  Future<ApiResponse> searchUsers(String query) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '$_baseUrl/user/search/',
        options: options,
        queryParameters: {'q': query},
      );
      return _handleDioResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Ошибка поиска: $e',
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
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '$_baseUrl/user/profile/',
        options: options,
      );
      
      return _handleDioResponse(response);
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
  
  /// Обработка ответа сервера
  ApiResponse _handleDioResponse(Response response, {bool isAuthRequest = false}) {
    final statusCode = response.statusCode ?? 500;
    
    // Пытаемся получить данные
    Map<String, dynamic>? data;
    if (response.data != null) {
      if (response.data is Map) {
        data = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (_) {
          // Игнорируем, если не JSON
        }
      }
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
        if (isAuthRequest) {
          errorMessage = 'Неверные учетные данные';
        } else if (errorMessage == 'Неизвестная ошибка') {
          errorMessage = 'Требуется авторизация (401)';
        }
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
      final response = await _dio.get(
        '$_baseUrl/system/info/',
        options: _getOptions(),
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
