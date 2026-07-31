import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/ssl_helper.dart';

/// Сервис для работы с WebSocket соединениями (чат, обновления)
class WebSocketService {
  WebSocket? _socket;
  StreamSubscription? _subscription;
  bool _isDisposed = false;
  
  // Callback-функции для событий
  final Function(Map<String, dynamic>) onMessageReceived;
  final Function(Object)? onError;
  final Function()? onDone;
  
  WebSocketService({
    required this.onMessageReceived,
    this.onError,
    this.onDone,
  });
  
  /// Проверить, активно ли соединение
  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;
  
  /// Установить соединение по WebSocket URL
  Future<void> connect(String url) async {
    if (_isDisposed) return;
    await disconnect();
    
    try {
      // Создаем HttpClient с фильтрованной проверкой SSL сертификатов
      final client = HttpClient();
      client.badCertificateCallback = validateSslCertificate;
      
      _socket = await WebSocket.connect(url, customClient: client).timeout(const Duration(seconds: 10));
      
      _subscription = _socket!.listen(
        (data) {
          if (_isDisposed) return;
          try {
            if (data is String) {
              final parsed = jsonDecode(data) as Map<String, dynamic>;
              onMessageReceived(parsed);
            }
          } catch (e) {
            debugPrint("WS parse message error: $e");
          }
        },
        onError: (err) {
          debugPrint("WS error: $err");
          if (!_isDisposed && onError != null) {
            onError!(err);
          }
        },
        onDone: () {
          if (!_isDisposed && onDone != null) {
            onDone!();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("WS connect failed: $e");
      if (!_isDisposed && onError != null) {
        onError!(e);
      }
      rethrow;
    }
  }
  
  /// Отправить JSON-сообщение
  bool sendMessage(Map<String, dynamic> message) {
    if (isConnected) {
      try {
        _socket!.add(jsonEncode(message));
        return true;
      } catch (e) {
        debugPrint("WS send failed: $e");
        return false;
      }
    } else {
      return false;
    }
  }
  
  /// Закрыть соединение
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }
  
  /// Уничтожить сервис
  void dispose() {
    _isDisposed = true;
    disconnect();
  }
}
