import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:fixnum/fixnum.dart';
import '../generated/grpc/chat_service.pbgrpc.dart';
import '../generated/grpc/presence_service.pbgrpc.dart';

class XaneoGrpcService {
  static final XaneoGrpcService _instance = XaneoGrpcService._internal();
  factory XaneoGrpcService() => _instance;
  XaneoGrpcService._internal();

  ClientChannel? _chatChannel;
  ClientChannel? _presenceChannel;

  ChatWebServiceClient? _chatClient;
  PresenceServiceClient? _presenceClient;

  bool _isInitialized = false;
  String? _accessToken;

  bool get isInitialized => _isInitialized;

  void init({
    String host = 'xaneo.ru',
    int chatPort = 443,
    int presencePort = 443,
    bool useTls = true,
    String? accessToken,
  }) {
    _accessToken = accessToken;
    if (_isInitialized) return;

    final credentials = useTls
        ? const ChannelCredentials.secure()
        : const ChannelCredentials.insecure();

    _chatChannel = ClientChannel(
      host,
      port: chatPort,
      options: ChannelOptions(credentials: credentials),
    );
    _chatClient = ChatWebServiceClient(_chatChannel!);

    _presenceChannel = ClientChannel(
      host,
      port: presencePort,
      options: ChannelOptions(credentials: credentials),
    );
    _presenceClient = PresenceServiceClient(_presenceChannel!);

    _isInitialized = true;
    final transport = useTls ? 'TLS' : 'plaintext';
    print(
      '🚀 [Xaneo PC gRPC] Channels configured for '
      '$host:$chatPort (Chat) & $presencePort (Presence), transport=$transport',
    );
  }

  void updateAccessToken(String? accessToken) {
    _accessToken = accessToken;
  }

  CallOptions _callOptions(Duration timeout) {
    final token = _accessToken;
    return CallOptions(
      timeout: timeout,
      metadata: token == null || token.isEmpty
          ? const <String, String>{}
          : <String, String>{'authorization': 'Bearer $token'},
    );
  }

  /// Stream message history for a chat over gRPC
  Stream<MessageItem>? getMessageHistory(
    String chatId, {
    int limit = 50,
    String beforeMessageId = '',
  }) {
    if (!_isInitialized || _chatClient == null) {
      print('⚠️ [gRPC] Client not initialized. Call init() first.');
      return null;
    }

    final req = HistoryRequest()
      ..chatId = chatId
      ..limit = limit
      ..beforeMessageId = beforeMessageId;

    print('🚀 [gRPC Stream] Requesting chat history');
    return _chatClient!.getMessageHistory(
      req,
      options: _callOptions(const Duration(seconds: 15)),
    );
  }

  /// Fast Mark As Read via gRPC
  Future<bool> markAsRead(String chatId, String userId) async {
    if (!_isInitialized || _chatClient == null) return false;

    try {
      final req = MarkAsReadRequest()
        ..chatId = chatId
        ..userId = userId;

      final res = await _chatClient!.markAsRead(
        req,
        options: _callOptions(const Duration(seconds: 3)),
      );
      print('📖 [gRPC ACK] Marked messages as read: count=${res.markedCount}');
      return res.success;
    } catch (e) {
      print('⚠️ [gRPC Offline] markAsRead fallback to REST: $e');
      return false;
    }
  }

  /// Send Presence Ping (Online / Typing / Idle)
  Future<bool> sendPresence(
    String userId,
    String status, {
    String chatId = '',
  }) async {
    if (!_isInitialized || _presenceClient == null) return false;

    try {
      final req = PresencePing()
        ..userId = userId
        ..status = status
        ..chatId = chatId
        ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch);

      final res = await _presenceClient!.sendPresence(
        req,
        options: _callOptions(const Duration(seconds: 3)),
      );
      return res.success;
    } catch (e) {
      print('⚠️ [gRPC Offline] sendPresence failed: $e');
      return false;
    }
  }

  /// Subscribe to contact presence updates (Server Streaming)
  Stream<PresenceUpdate>? streamPresenceUpdates(
    String userId,
    List<String> contactIds,
  ) {
    if (!_isInitialized || _presenceClient == null) return null;

    final req = PresenceSubscription()
      ..userId = userId
      ..contactIds.addAll(contactIds);

    return _presenceClient!.streamPresenceUpdates(
      req,
      options: _callOptions(const Duration(minutes: 30)),
    );
  }

  void dispose() {
    _chatChannel?.shutdown();
    _presenceChannel?.shutdown();
    _chatChannel = null;
    _presenceChannel = null;
    _chatClient = null;
    _presenceClient = null;
    _accessToken = null;
    _isInitialized = false;
  }
}
