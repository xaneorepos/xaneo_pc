import 'dart:convert';
import 'dart:io';
import 'dart:async';
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
      print("WS CONNECTING TO: $url");
      
      // Создаем HttpClient с фильтрованной проверкой SSL сертификатов
      final client = HttpClient();
      client.badCertificateCallback = validateSslCertificate;
      
      _socket = await WebSocket.connect(url, customClient: client).timeout(const Duration(seconds: 10));
      print("WS CONNECTED SUCCESS");
      
      _subscription = _socket!.listen(
        (data) {
          if (_isDisposed) return;
          try {
            if (data is String) {
              final parsed = jsonDecode(data) as Map<String, dynamic>;
              onMessageReceived(parsed);
            }
          } catch (e) {
            print("WS parse message error: $e");
          }
        },
        onError: (err) {
          print("WS error: $err");
          if (!_isDisposed && onError != null) {
            onError!(err);
          }
        },
        onDone: () {
          print("WS connection done/closed");
          if (!_isDisposed && onDone != null) {
            onDone!();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("WS connect failed: $e");
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
        print("WS send failed: $e");
        return false;
      }
    } else {
      print("WS send warning: not connected");
      return false;
    }
  }
  
  /// Закрыть соединение
  Future<void> disconnect() async {
    print("WS DISCONNECTING");
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
