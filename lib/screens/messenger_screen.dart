import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../providers/playback_provider.dart';
import '../widgets/advanced_background.dart';
import '../widgets/voice_waveform_slider.dart';
import '../widgets/settings_modal.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/account_service.dart';
import '../services/websocket_service.dart';
import '../services/logger_service.dart';
import '../widgets/custom_toast.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final ApiService _apiService = ApiService();
  final CryptoService _cryptoService = CryptoService();
  final GlobalKey<SettingsButtonState> _settingsKey = GlobalKey<SettingsButtonState>();

  List<dynamic> _chats = [];
  List<dynamic> _archivedChats = [];
  bool _viewingArchive = false;
  Map<String, dynamic>? _selectedChat;
  List<dynamic> _messages = [];
  bool _isChatsLoading = true;
  bool _isMessagesLoading = false;
  
  // Decrypted messages store: message_id -> plaintext
  final Map<int, String> _decryptedMessages = {};

  // Keys cache
  final Map<String, String> _peerPublicKeys = {};
  final Map<String, String> _chatSymmetricKeys = {};

  // Current user info
  Map<String, dynamic>? _myProfile;
  int? _myId;
  String? _myUsername;
  List<AccountInfo> _accounts = [];

  // Предзагруженные профили собеседников (userId -> данные с применённой приватностью)
  final Map<int, Map<String, dynamic>> _userProfileCache = {};

  // Search dialog state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearchLoading = false;

  // Message input controller
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Polling timer
  Timer? _pollingTimer;
  WebSocketService? _webSocketService;
  final Map<String, String> _sentPlaintexts = {};
  double _chatListWidth = 320.0;

  // Typing status variables
  final Map<String, _TypingState> _activeTypingUsers = {};
  Timer? _typingExpiryTimer;
  Timer? _typingTimer;
  bool _isMeTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageTextChanged);
    _startTypingExpiryTimer();
    _loadPreferences();
    _initMessenger();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWidth = prefs.getDouble('chat_list_width');
    if (savedWidth != null && mounted) {
      setState(() {
        _chatListWidth = savedWidth;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageTextChanged);
    _webSocketService?.dispose();
    _pollingTimer?.cancel();
    _typingExpiryTimer?.cancel();
    _typingTimer?.cancel();
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initMessenger() async {
    // 1. Load keys from local storage
    if (!_cryptoService.hasKeys) {
      final loaded = await _cryptoService.loadKeysFromLocalStorage();
      if (!loaded) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
      }
    }

    // 2. Load profile & save current account to switcher list
    final profileRes = await _apiService.getProfile();
    if (profileRes.success && profileRes.data != null) {
      await AccountService().saveCurrentAccount(profileRes.data!);
      if (mounted) {
        setState(() {
          _myProfile = profileRes.data;
          final dynamic rawMyId = profileRes.data!['id'];
          _myId = rawMyId is int ? rawMyId : int.tryParse(rawMyId.toString());
          _myUsername = profileRes.data!['username'] as String?;
        });
      }
    } else {
      if (profileRes.statusCode == 401) {
        if (mounted) {
          await _logout();
          return;
        }
      }
    }

    // Load active accounts list
    final accountsList = await AccountService().getAccounts();
    if (mounted) {
      setState(() {
        _accounts = accountsList;
      });
    }

    // 3. Load chats & start polling
    await _loadChats();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _loadChats(silent: true);
      
      final wsActive = _webSocketService?.isConnected ?? false;
      if (_selectedChat != null && !wsActive) {
        _loadMessages(_selectedChat!['chat_id'] as String, silent: true);
      }
    });
  }

  Future<void> _connectWebSocket(String chatId) async {
    await _webSocketService?.disconnect();
    
    final token = await _apiService.getAccessToken();
    final wsUrl = ApiService.getWebSocketUrl(chatId, token);
    
    _webSocketService = WebSocketService(
      onMessageReceived: (data) => _handleWebSocketMessage(data, chatId),
      onError: (err) {
        print("WS error callback: $err");
        if (mounted && _selectedChat?['chat_id'] == chatId) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _selectedChat?['chat_id'] == chatId && !(_webSocketService?.isConnected ?? false)) {
              _connectWebSocket(chatId);
            }
          });
        }
      },
      onDone: () {
        print("WS done callback");
        if (mounted && _selectedChat?['chat_id'] == chatId) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _selectedChat?['chat_id'] == chatId && !(_webSocketService?.isConnected ?? false)) {
              _connectWebSocket(chatId);
            }
          });
        }
      },
    );
    
    try {
      await _webSocketService!.connect(wsUrl);
    } catch (e) {
      print("Failed to connect to WS: $e");
    }
  }

  Future<void> _handleWebSocketMessage(Map<String, dynamic> data, String activeChatId) async {
    final type = data['type'] as String?;
    if (type == 'encrypted_message' || type == 'todo_list_message' || type == 'poll_message' || type == 'voice_message') {
      final msgChatId = data['chat_id'] as String?;
      if (msgChatId != activeChatId) return;

      final dynamic rawMsgId = data['id'];
      final msgId = rawMsgId is int ? rawMsgId : int.tryParse(rawMsgId.toString());
      if (msgId == null) return;

      final exists = _messages.any((m) => m['id'] == msgId);
      if (exists) return;

      if (type == 'todo_list_message') {
        data['message_type'] = 'todo_list';
        data['author_id'] = data['creator_id'];
      } else if (type == 'poll_message') {
        data['message_type'] = 'poll';
        data['author_id'] = data['creator_id'];
      } else if (type == 'voice_message') {
        data['message_type'] = 'voice';
      } else {
        data['message_type'] ??= 'regular';
      }
      
      final encryptedText = (data['encrypted_text'] ?? data['encrypted_content']) as String?;
      final otherUser = _selectedChat?['other_user'] as Map<String, dynamic>?;
      
      String decryptedText = "";
      if (encryptedText != null && encryptedText.isNotEmpty) {
        if (_sentPlaintexts.containsKey(encryptedText)) {
          decryptedText = _sentPlaintexts[encryptedText]!;
          _sentPlaintexts.remove(encryptedText);
        } else {
          try {
            decryptedText = await _decryptForChat(encryptedText, activeChatId, otherUser);
          } catch (_) {
            decryptedText = "[Ошибка дешифрования]";
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _decryptedMessages[msgId] = decryptedText;
          _messages.insert(0, data);
        });
        _scrollToBottom();
      }
      _loadChats(silent: true);
      
      final isMe = data['author_id']?.toString() == _myId?.toString();
      if (!isMe) {
        _markChatAsRead(activeChatId);
      }
    } else if (type == 'todo_completion_update') {
      final todoMsgId = data['todo_message_id']?.toString();
      final itemIndex = data['item_index'];
      final isCompleted = data['is_completed'] as bool?;
      if (todoMsgId != null && itemIndex != null && isCompleted != null) {
        _updateTodoLocalCompletion(todoMsgId, itemIndex, isCompleted);
      }
    } else if (type == 'poll_vote_update' || type == 'poll_vote') {
      final pollMsgId = data['poll_message_id']?.toString();
      final optionId = data['option_id']?.toString();
      final removeVote = data['remove_vote'] == true;
      final userId = data['user_id']?.toString() ?? data['sender_id']?.toString();
      if (pollMsgId != null && optionId != null) {
        _updatePollLocalVote(pollMsgId, optionId, removeVote, userId ?? '');
      }
    } else if (type == 'chat_list_update' || type == 'new_chat') {
      _loadChats(silent: true);
    } else if (type == 'typing') {
      final userId = data['user_id']?.toString();
      final isTyping = data['is_typing'] == true;
      final action = data['action']?.toString() ?? 'typing';
      final username = data['username']?.toString() ?? '';
      final firstName = data['first_name']?.toString() ?? username;
      
      if (userId != null && userId != _myId?.toString()) {
        setState(() {
          if (isTyping) {
            _activeTypingUsers[userId] = _TypingState(
              username: username,
              firstName: firstName,
              action: action,
              timestamp: DateTime.now(),
            );
          } else {
            _activeTypingUsers.remove(userId);
          }
        });
      }
    }
  }

  void _onMessageTextChanged() {
    final text = _messageController.text;
    if (text.isNotEmpty && !_isMeTyping) {
      _sendTypingStatus(true, 'typing');
    } else if (text.isEmpty && _isMeTyping) {
      _sendTypingStatus(false, 'typing');
    }
    
    if (text.isNotEmpty) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _isMeTyping) {
          _sendTypingStatus(false, 'typing');
        }
      });
    }
  }

  void _sendTypingStatus(bool isTyping, String action) {
    if (_webSocketService != null && _webSocketService!.isConnected) {
      _isMeTyping = isTyping;
      _webSocketService!.sendMessage({
        'type': 'typing',
        'is_typing': isTyping,
        'action': action,
      });
    }
  }

  void _startTypingExpiryTimer() {
    _typingExpiryTimer?.cancel();
    _typingExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      bool changed = false;
      _activeTypingUsers.removeWhere((userId, state) {
        final expired = now.difference(state.timestamp).inSeconds > 5;
        if (expired) changed = true;
        return expired;
      });
      if (changed) {
        setState(() {});
      }
    });
  }

  String? _getTypingStatusText({Map<String, dynamic>? chat}) {
    final targetChat = chat ?? _selectedChat;
    if (targetChat == null) return null;
    if (_selectedChat == null || targetChat['chat_id'] != _selectedChat!['chat_id']) return null;
    
    if (_activeTypingUsers.isEmpty) return null;
    
    final chatType = targetChat['chat_type'] as String?;
    if (chatType == 'personal') {
      final state = _activeTypingUsers.values.first;
      if (state.action == 'recording_voice') {
        return 'записывает голосовое...';
      }
      return 'печатает...';
    } else {
      if (_activeTypingUsers.length == 1) {
        final state = _activeTypingUsers.values.first;
        final name = state.firstName.isNotEmpty ? state.firstName : state.username;
        if (state.action == 'recording_voice') {
          return '$name записывает голосовое...';
        }
        return '$name печатает...';
      } else {
        final names = _activeTypingUsers.values
            .map((s) => s.firstName.isNotEmpty ? s.firstName : s.username)
            .join(', ');
        return '$names печатают...';
      }
    }
  }

  Future<void> _loadChats({bool silent = false}) async {
    if (!silent) {
      setState(() => _isChatsLoading = true);
    }
    final res = await _apiService.getChats();
    if (res.success && res.data != null) {
      final chatList = (res.data!['chats'] as List? ?? [])
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();
      final archivedList = (res.data!['archived_chats'] as List? ?? [])
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();

      if (mounted) {
        setState(() {
          _chats = chatList;
          _archivedChats = archivedList;
          _isChatsLoading = false;
          
          if (_selectedChat != null) {
            final allChats = [...chatList, ...archivedList];
            final updatedChat = allChats.cast<Map<String, dynamic>?>().firstWhere(
                  (c) => c != null && c['chat_id'] == _selectedChat!['chat_id'],
                  orElse: () => null,
                );
            if (updatedChat != null) {
              _selectedChat = updatedChat;
            }
          }
        });
        
        // Decrypt latest message preview in each chat
        for (var chat in [...chatList, ...archivedList]) {
          final lastMsg = chat['last_message'];
          if (lastMsg != null) {
            _decryptSingleMessage(lastMsg, chat['chat_id'] as String, chat['other_user']);
          }
        }
      }
    } else {
      if (mounted) {
        setState(() => _isChatsLoading = false);
      }
    }
  }

  int _getArchivedUnreadCount() {
    int count = 0;
    for (var chat in _archivedChats) {
      final dynamic rawUnread = chat['unread_count'];
      final unreadCount = rawUnread is int ? rawUnread : int.tryParse(rawUnread.toString()) ?? 0;
      count += unreadCount;
    }
    return count;
  }

  Future<void> _toggleArchive(Map<String, dynamic> chat) async {
    final chatId = chat['chat_id'] as String;
    final isArchived = chat['is_archived'] as bool? ?? false;
    final newStatus = !isArchived;

    // Optimistically update the UI status
    setState(() {
      if (newStatus) {
        _chats.removeWhere((c) => c['chat_id'] == chatId);
        chat['is_archived'] = true;
        if (!_archivedChats.any((c) => c['chat_id'] == chatId)) {
          _archivedChats.add(chat);
        }
        if (_selectedChat != null && _selectedChat!['chat_id'] == chatId) {
          _selectedChat = null;
        }
      } else {
        _archivedChats.removeWhere((c) => c['chat_id'] == chatId);
        chat['is_archived'] = false;
        if (!_chats.any((c) => c['chat_id'] == chatId)) {
          _chats.add(chat);
        }
        if (_selectedChat != null && _selectedChat!['chat_id'] == chatId) {
          _selectedChat = null;
        }
      }
    });

    final res = await _apiService.archiveChat(chatId, newStatus);
    if (!res.success) {
      CustomToast.show(
        context,
        newStatus ? 'Не удалось архивировать чат' : 'Не удалось разархивировать чат',
        type: ToastType.error,
      );
      _loadChats(silent: true);
    }
  }

  Widget _buildArchiveFolderItem(BuildContext context, bool isDark, double scale) {
    final unreadCount = _getArchivedUnreadCount();
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _viewingArchive = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.archive_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 20 * scale,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Архив',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5 * scale,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Архивированные чаты',
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: TextStyle(
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMessages(String chatId, {bool silent = false}) async {
    if (!silent) {
      setState(() => _isMessagesLoading = true);
    }
    final res = await _apiService.getMessages(chatId);
    if (res.success && res.data != null) {
      final msgList = res.data!['results'] as List? ?? [];
      if (mounted) {
        setState(() {
          _messages = msgList.toList();
          _isMessagesLoading = false;
        });
        
        // Decrypt all fetched messages
        _decryptAllMessages(_messages, chatId, _selectedChat?['other_user']);
      }
    } else {
      if (mounted) {
        setState(() => _isMessagesLoading = false);
      }
    }
  }

  /// Get the peer's public key hex for personal chats
  Future<String?> _getPeerPublicKey(Map<String, dynamic>? otherUser) async {
    if (otherUser == null) return null;
    final userId = otherUser['id'];
    if (userId == null) return null;
    final userIdStr = userId.toString();

    if (_peerPublicKeys.containsKey(userIdStr)) {
      return _peerPublicKeys[userIdStr];
    }

    // The web client uses userId in the URL: /xsec2/keys/{userId}/
    final res = await _apiService.getUserPublicKey(userIdStr);
    if (res.success && res.data != null) {
      final key = res.data!['x25519_public_key'] as String?;
      if (key != null) {
        _peerPublicKeys[userIdStr] = key;
        return key;
      }
    }
    return null;
  }

  /// Get the server-managed symmetric key for group/channel chats
  Future<String?> _getGroupChatKey(String chatId) async {
    if (_chatSymmetricKeys.containsKey(chatId)) {
      return _chatSymmetricKeys[chatId];
    }

    final res = await _apiService.getChatKey(chatId);
    if (res.success && res.data != null) {
      final key = res.data!['key'] as String?;
      if (key != null) {
        _chatSymmetricKeys[chatId] = key;
        return key;
      }
    }
    return null;
  }

  /// Decrypt a single message based on chat type
  Future<String> _decryptForChat(String encryptedText, String chatId, Map<String, dynamic>? otherUser) async {
    final myUserId = _myId?.toString();

    if (chatId.startsWith('favorites_') || chatId == 'favorites') {
      if (myUserId == null) return "[Нет userId]";
      return await _cryptoService.decryptFavoritesMessage(encryptedText, myUserId);
    }

    if (chatId.startsWith('personal_')) {
      final peerPubKey = await _getPeerPublicKey(otherUser);
      if (peerPubKey == null) return "[Нет ключа]";
      return await _cryptoService.decryptPersonalMessage(encryptedText, peerPubKey, chatId);
    }

    if (chatId.startsWith('group_') || chatId.startsWith('channel_')) {
      final chatKeyHex = await _getGroupChatKey(chatId);
      if (chatKeyHex == null) return "[Нет ключа]";
      return await _cryptoService.decryptGroupMessage(encryptedText, chatKeyHex);
    }

    return "[Неизвестный тип чата]";
  }

  Future<void> _decryptSingleMessage(dynamic msg, String chatId, Map<String, dynamic>? otherUser) async {
    final dynamic rawId = msg['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null || _decryptedMessages.containsKey(id)) return;

    final encryptedText = msg['encrypted_text'] as String?;
    if (encryptedText == null || encryptedText.isEmpty) {
      _decryptedMessages[id] = "";
      return;
    }

    String decrypted;
    try {
      decrypted = await _decryptForChat(encryptedText, chatId, otherUser);
    } catch (_) {
      decrypted = "[Ошибка дешифрования]";
    }

    if (mounted) {
      setState(() {
        _decryptedMessages[id] = decrypted;
      });
    }
  }

  Future<void> _decryptAllMessages(List<dynamic> messages, String chatId, Map<String, dynamic>? otherUser) async {
    for (var msg in messages) {
      final dynamic rawId = msg['id'];
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (id == null || _decryptedMessages.containsKey(id)) continue;

      final encryptedText = msg['encrypted_text'] as String?;
      if (encryptedText == null || encryptedText.isEmpty) {
        _decryptedMessages[id] = "";
        continue;
      }

      String decrypted;
      try {
        decrypted = await _decryptForChat(encryptedText, chatId, otherUser);
      } catch (_) {
        decrypted = "[Ошибка дешифрования]";
      }

      if (mounted) {
        setState(() {
          _decryptedMessages[id] = decrypted;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedChat == null) return;

    if (_isMeTyping) {
      _sendTypingStatus(false, 'typing');
    }
    _typingTimer?.cancel();

    final chatId = _selectedChat!['chat_id'] as String;
    final myUserId = _myId?.toString();
    final otherUser = _selectedChat!['other_user'] as Map<String, dynamic>?;

    _messageController.clear();

    String encryptedText = "";
    try {
      if (chatId.startsWith('favorites_') || chatId == 'favorites') {
        if (myUserId == null) {
          print("Cannot encrypt: myUserId is null");
          return;
        }
        encryptedText = await _cryptoService.encryptFavoritesMessage(text, myUserId);
      } else if (chatId.startsWith('personal_')) {
        final peerPubKey = await _getPeerPublicKey(otherUser);
        if (peerPubKey == null) {
          CustomToast.show(
            context,
            'Не удалось получить ключ шифрования для чата',
            type: ToastType.error,
          );
          return;
        }
        encryptedText = await _cryptoService.encryptPersonalMessage(text, peerPubKey, chatId);
      } else if (chatId.startsWith('group_') || chatId.startsWith('channel_')) {
        final chatKeyHex = await _getGroupChatKey(chatId);
        if (chatKeyHex == null) {
          CustomToast.show(
            context,
            'Не удалось получить ключ шифрования для чата',
            type: ToastType.error,
          );
          return;
        }
        encryptedText = await _cryptoService.encryptGroupMessage(text, chatKeyHex);
      }
    } catch (e) {
      print("Encryption failed: $e");
      return;
    }

    _sentPlaintexts[encryptedText] = text;

    bool sentViaWs = false;
    if (_webSocketService != null && _webSocketService!.isConnected) {
      sentViaWs = _webSocketService!.sendMessage({
        'type': 'encrypted_message',
        'encrypted_text': encryptedText,
      });
    }

    if (!sentViaWs) {
      _sentPlaintexts.remove(encryptedText);
      final res = await _apiService.sendMessage(chatId, encryptedText);
      if (res.success && res.data != null) {
        final newMsg = res.data!;
        final dynamic rawId = newMsg['id'];
        final id = rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0);
        _decryptedMessages[id] = text;

        if (mounted) {
          setState(() {
            _messages.insert(0, newMsg);
          });
          _scrollToBottom();
        }
        _loadChats(silent: true);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markChatAsRead(String chatId) async {
    final res = await _apiService.markMessagesAsRead(chatId);
    if (res.success) {
      if (mounted) {
        setState(() {
          for (var i = 0; i < _chats.length; i++) {
            if (_chats[i]['chat_id'] == chatId) {
              final updated = Map<String, dynamic>.from(_chats[i]);
              updated['unread_count'] = 0;
              _chats[i] = updated;
              break;
            }
          }
          for (var i = 0; i < _archivedChats.length; i++) {
            if (_archivedChats[i]['chat_id'] == chatId) {
              final updated = Map<String, dynamic>.from(_archivedChats[i]);
              updated['unread_count'] = 0;
              _archivedChats[i] = updated;
              break;
            }
          }
        });
      }
    }
  }

  void _selectChat(Map<String, dynamic> chat) {
    if (_selectedChat != null && _selectedChat!['chat_id'] == chat['chat_id']) {
      return;
    }
    
    _typingTimer?.cancel();
    _isMeTyping = false;
    _activeTypingUsers.clear();
    
    setState(() {
      _selectedChat = chat;
      _messages = [];
      _isMessagesLoading = true;
    });
    final chatId = chat['chat_id'] as String;
    _loadMessages(chatId);
    _connectWebSocket(chatId);
    _markChatAsRead(chatId);
    _scrollToBottom();
    _prefetchUserProfile(chat);
  }

  /// Заранее подгружает профиль собеседника (для личных чатов), чтобы модалка
  /// открывалась мгновенно без спиннера. Результат кладём в [_userProfileCache].
  Future<void> _prefetchUserProfile(Map<String, dynamic> chat) async {
    if (chat['chat_type'] != 'personal') return;
    final otherUser = chat['other_user'] as Map<String, dynamic>?;
    if (otherUser == null) return;
    final dynamic rawId = otherUser['id'];
    final int? userId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (userId == null) return;

    final res = await _apiService.getUserById(userId);
    if (res.success && res.data != null) {
      _userProfileCache[userId] = {...otherUser, ...res.data!};
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearchLoading = true);
    final res = await _apiService.searchUsers(query);
    if (res.success && res.data != null) {
      setState(() {
        _searchResults = res.data!['users'] as List? ?? [];
        _isSearchLoading = false;
      });
    } else {
      setState(() => _isSearchLoading = false);
    }
  }

  void _startChatWithUser(Map<String, dynamic> user) {
    final dynamic rawTargetId = user['id'];
    final targetId = rawTargetId is int ? rawTargetId : (int.tryParse(rawTargetId.toString()) ?? 0);
    final targetUsername = user['username'] as String;
    if (_myId == null) return;

    _typingTimer?.cancel();
    _isMeTyping = false;
    _activeTypingUsers.clear();

    // Create unique personal chat ID
    final chatId = "personal_${_myId! < targetId ? '${_myId!}_$targetId' : '${targetId}_$_myId!'}";
    
    final newChat = {
      'chat_id': chatId,
      'chat_type': 'personal',
      'chat_display_name': user['first_name'] ?? targetUsername,
      'other_user': {
        'id': targetId,
        'username': targetUsername,
        'first_name': user['first_name'] ?? targetUsername,
        'avatar_url': user['avatar_url'],
        'avatar_gradient': user['avatar_gradient'] ?? '',
      }
    };

    setState(() {
      _selectedChat = newChat;
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
      
      // Add to front of chats list if not already there
      final existingIndex = _chats.indexWhere((c) => c['chat_id'] == chatId);
      if (existingIndex == -1) {
        _chats.insert(0, newChat);
      } else {
        _chats.removeAt(existingIndex);
        _chats.insert(0, newChat);
      }
      _messages = [];
    });
    
    _loadMessages(chatId);
    _connectWebSocket(chatId);
    _markChatAsRead(chatId);
    _prefetchUserProfile(newChat);
  }

  Future<void> _logout() async {
    await _webSocketService?.disconnect();
    
    // Find the account to remove by the current token, because _myId might be out of sync
    // during an account switch if the new account's token is invalid.
    int? accountToRemove;
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('xaneo_access_token');
    if (currentToken != null) {
      final accounts = await AccountService().getAccounts();
      try {
        final match = accounts.firstWhere((a) => a.accessToken == currentToken);
        accountToRemove = match.userId;
      } catch (_) {}
    }
    accountToRemove ??= _myId;

    await _apiService.logout();
    await _cryptoService.clearKeys();
    
    if (accountToRemove != null) {
      await AccountService().removeAccount(accountToRemove);
    }
    
    _myId = null;
    
    final remainingAccounts = await AccountService().getAccounts();
    if (remainingAccounts.isNotEmpty) {
      await _switchAccount(remainingAccounts.first.userId);
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _switchAccount(int userId) async {
    if (mounted) {
      setState(() {
        _isChatsLoading = true;
        _isMessagesLoading = true;
      });
    }
    
    _pollingTimer?.cancel();
    await _webSocketService?.disconnect();
    
    final success = await AccountService().switchAccount(userId);
    if (success) {
      _selectedChat = null;
      _messages = [];
      _decryptedMessages.clear();
      await _initMessenger();
    } else {
      if (mounted) {
        CustomToast.show(
          context,
          'Не удалось переключить аккаунт',
          type: ToastType.error,
        );
      }
      if (mounted) {
        setState(() {
          _isChatsLoading = false;
          _isMessagesLoading = false;
        });
      }
    }
  }

  String _formatBirthday(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      const months = [
        'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return '';
    }
  }

  /// Модалка с информацией о пользователе. Данные подгружаются с сервера,
  /// который уже применяет настройки приватности (скрытые поля приходят null).
  void _showUserProfileDialog(
    BuildContext context,
    Map<String, dynamic> otherUser,
    String fallbackName,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleProvider = Provider.of<ScaleProvider>(context, listen: false);
    final scale = scaleProvider.scale;

    final dynamic rawId = otherUser['id'];
    final int? userId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final mockTabs = <Map<String, dynamic>>[
      {'title': 'Медиа', 'icon': Icons.image_rounded},
      {'title': 'Файлы', 'icon': Icons.description_rounded},
      {'title': 'Голос', 'icon': Icons.mic_rounded},
      {'title': 'Ссылки', 'icon': Icons.link_rounded},
    ];

    showGeneralDialog(
      context: context,
      barrierLabel: 'UserProfile',
      barrierDismissible: true,
      barrierColor: isDark ? Colors.black.withOpacity(0.85) : Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        final screenSize = MediaQuery.of(context).size;
        final bgColor = isDark ? const Color(0xFF0C0C0C) : Colors.white;
        final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);

        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              width: 360 * scale,
              constraints: BoxConstraints(
                maxHeight: screenSize.height * 0.85,
              ),
              margin: EdgeInsets.all(20 * scale),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.6 : 0.06),
                    blurRadius: 24 * scale,
                    offset: Offset(0, 8 * scale),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(20 * scale, 20 * scale, 20 * scale, 4 * scale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ПРОФИЛЬ',
                          style: TextStyle(
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5 * scale,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontFamily: 'Inter',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(
                              Icons.close_rounded,
                              size: 16 * scale,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20 * scale, 8 * scale, 20 * scale, 20 * scale),
                      child: Builder(
                        builder: (context) {
                          // Профиль предзагружен при открытии чата → берём из кэша,
                          // иначе фолбэк на то, что уже есть в чате.
                          final Map<String, dynamic> data = {
                            ...otherUser,
                            if (userId != null && _userProfileCache.containsKey(userId))
                              ..._userProfileCache[userId]!,
                          };

                          final name = (data['first_name']?.toString().trim().isNotEmpty ?? false)
                              ? data['first_name'].toString()
                              : ((data['username']?.toString().trim().isNotEmpty ?? false)
                                  ? data['username'].toString()
                                  : fallbackName);
                          final username = data['username']?.toString() ?? '';
                          final avatarUrl = (data['avatar_url'] ?? data['avatar'])?.toString();
                          final gradient = data['avatar_gradient']?.toString();
                          final bio = data['bio']?.toString() ?? '';
                          final birthday = _formatBirthday(data['birth_date']?.toString());
                          final age = data['age'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Avatar + name + username
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildAvatar(
                                      avatarUrl,
                                      name,
                                      40 * scale,
                                      scale,
                                      isDark,
                                      avatarGradient: gradient,
                                    ),
                                    SizedBox(height: 14 * scale),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 19 * scale,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    if (username.isNotEmpty) ...[
                                      SizedBox(height: 3 * scale),
                                      Text(
                                        '@$username',
                                        style: TextStyle(
                                          fontSize: 12.5 * scale,
                                          color: isDark ? Colors.white38 : Colors.black45,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 20 * scale),

                              // Details
                              _buildProfileDetails(
                                isDark,
                                scale,
                                bio: bio,
                                username: username,
                                birthday: birthday,
                                age: age is int ? age : (age is num ? age.toInt() : null),
                              ),

                              SizedBox(height: 20 * scale),

                              // Mock shared-media tabs
                              _buildProfileMockTabs(isDark, scale, mockTabs),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileDetails(
    bool isDark,
    double scale, {
    required String bio,
    required String username,
    required String birthday,
    required int? age,
  }) {
    final tiles = <Widget>[];

    void addTile(IconData icon, String value, String label, {bool copyable = true}) {
      if (tiles.isNotEmpty) {
        tiles.add(Divider(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          height: 1,
          indent: 48 * scale,
        ));
      }
      tiles.add(_buildProfileInfoTile(isDark, scale, icon, value, label, copyable: copyable));
    }

    if (bio.isNotEmpty) addTile(Icons.info_outline_rounded, bio, 'О себе', copyable: false);
    if (username.isNotEmpty) {
      addTile(Icons.alternate_email_rounded, '@$username', 'Имя пользователя');
    }
    if (birthday.isNotEmpty) {
      final ageStr = age != null ? ' • $age ${_pluralizeYears(age)}' : '';
      addTile(Icons.cake_outlined, '$birthday$ageStr', 'День рождения', copyable: false);
    }

    if (tiles.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * scale),
        child: Center(
          child: Text(
            'Пользователь скрыл информацию о себе',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * scale,
              color: isDark ? Colors.white38 : Colors.black38,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
        ),
      ),
      padding: EdgeInsets.all(4 * scale),
      child: Column(children: tiles),
    );
  }

  String _pluralizeYears(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'год';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) return 'года';
    return 'лет';
  }

  Widget _buildProfileInfoTile(
    bool isDark,
    double scale,
    IconData icon,
    String value,
    String label, {
    bool copyable = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: copyable
            ? () {
                Clipboard.setData(ClipboardData(text: value));
                CustomToast.show(context, 'Скопировано', type: ToastType.success);
              }
            : null,
        borderRadius: BorderRadius.circular(8 * scale),
        hoverColor: copyable
            ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03))
            : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 10 * scale),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16 * scale,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13.5 * scale,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5 * scale,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              if (copyable)
                Padding(
                  padding: EdgeInsets.only(top: 6 * scale),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14 * scale,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMockTabs(
    bool isDark,
    double scale,
    List<Map<String, dynamic>> tabs,
  ) {
    return Row(
      children: tabs.map((tab) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3 * scale),
            child: Container(
              height: 42 * scale,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 14 * scale,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  SizedBox(width: 5 * scale),
                  Flexible(
                    child: Text(
                      tab['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5 * scale,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAccountSwitcherDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleProvider = Provider.of<ScaleProvider>(context, listen: false);
    final scale = scaleProvider.scale;
    
    showGeneralDialog(
      context: context,
      barrierLabel: "AccountSwitcher",
      barrierDismissible: true,
      barrierColor: isDark ? Colors.black.withOpacity(0.85) : Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final screenSize = MediaQuery.of(context).size;
            final bgColor = isDark ? const Color(0xFF0C0C0C) : Colors.white;
            final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);
            
            return Material(
              type: MaterialType.transparency,
              child: Center(
                child: Container(
                  width: 340 * scale,
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height * 0.75,
                  ),
                  margin: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.6 : 0.06),
                        blurRadius: 24 * scale,
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(20 * scale, 20 * scale, 20 * scale, 12 * scale),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'АККАУНТЫ',
                              style: TextStyle(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5 * scale,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontFamily: 'Inter',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16 * scale,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Accounts List
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                          child: FutureBuilder<List<AccountInfo>>(
                            future: AccountService().getAccounts(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20 * scale),
                                  child: Center(
                                    child: SizedBox(
                                      width: 16 * scale,
                                      height: 16 * scale,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              final accounts = snapshot.data!;
                              
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...accounts.map((acc) {
                                    final isActive = acc.userId == _myId;
                                    
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 2 * scale),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03))
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8 * scale),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isActive
                                                ? null
                                                : () {
                                                    Navigator.of(context).pop();
                                                    _switchAccount(acc.userId);
                                                  },
                                            hoverColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                                            splashColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
                                            highlightColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                                            borderRadius: BorderRadius.circular(8 * scale),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
                                              child: Row(
                                                children: [
                                                  _buildAvatar(
                                                    acc.avatarUrl,
                                                    (acc.firstName != null && acc.firstName!.isNotEmpty) ? acc.firstName! : acc.username,
                                                    16 * scale,
                                                    1.0,
                                                    isDark,
                                                    avatarGradient: acc.avatarGradient,
                                                  ),
                                                  SizedBox(width: 10 * scale),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          (acc.firstName != null && acc.firstName!.isNotEmpty) ? acc.firstName! : acc.username,
                                                          style: TextStyle(
                                                            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                                                            fontSize: 13 * scale,
                                                            color: isDark ? Colors.white70 : Colors.black87,
                                                            fontFamily: 'Inter',
                                                          ),
                                                        ),
                                                        if (acc.firstName != null && acc.firstName!.isNotEmpty) ...[
                                                          SizedBox(height: 1 * scale),
                                                          Text(
                                                            '@${acc.username}',
                                                            style: TextStyle(
                                                              fontSize: 10.5 * scale,
                                                              color: isDark ? Colors.white38 : Colors.black38,
                                                              fontFamily: 'Inter',
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: 8 * scale),
                                                  if (isActive)
                                                    Icon(
                                                      Icons.check_rounded,
                                                      color: isDark ? Colors.white70 : Colors.black87,
                                                      size: 14 * scale,
                                                    )
                                                  else
                                                    GestureDetector(
                                                      onTap: () async {
                                                        await AccountService().removeAccount(acc.userId);
                                                        setModalState(() {});
                                                        final updated = await AccountService().getAccounts();
                                                        setState(() {
                                                          _accounts = updated;
                                                        });
                                                      },
                                                      child: MouseRegion(
                                                        cursor: SystemMouseCursors.click,
                                                        child: Padding(
                                                          padding: EdgeInsets.all(4 * scale),
                                                          child: Icon(
                                                            Icons.close_rounded,
                                                            size: 14 * scale,
                                                            color: isDark ? Colors.white38 : Colors.black38,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  
                                  SizedBox(height: 12 * scale),
                                  
                                  if (accounts.length < 5)
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 8 * scale),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 36 * scale,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark ? Colors.white : Colors.black,
                                            foregroundColor: isDark ? Colors.black : Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6 * scale),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pushNamed('/login');
                                          },
                                          child: Text(
                                            'Добавить аккаунт',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12 * scale,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                                      child: Center(
                                        child: Text(
                                          'Лимит: 5 аккаунтов',
                                          style: TextStyle(
                                            color: isDark ? Colors.white38 : Colors.black38,
                                            fontSize: 11 * scale,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final scaleProvider = Provider.of<ScaleProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final scale = scaleProvider.scale;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Background decoration
          Positioned.fill(
            child: AdvancedBackground(
              isDark: isDark,
              enableGrid: false,
              enableParticles: false,
              enableGeometricShapes: false,
            ),
          ),
          
          // Main layout
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SafeArea(
              child: Row(
                children: [
                  // 1. Chat List Panel (resizable with Liquid Glass effect)
                  Container(
                    width: _chatListWidth * scale,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.black.withOpacity(0.15) 
                          : Colors.white.withOpacity(0.15),
                      border: Border(
                        right: BorderSide(
                          color: isDark 
                              ? Colors.white.withOpacity(0.08) 
                              : Colors.black.withOpacity(0.04),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: _buildChatListPanel(isDark, scale),
                      ),
                    ),
                  ),

                  // Resizable Divider (overlapping transparent zone for dragging)
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _chatListWidth = (_chatListWidth + details.delta.dx / scale).clamp(240.0, 600.0);
                        });
                      },
                      onHorizontalDragEnd: (details) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setDouble('chat_list_width', _chatListWidth);
                      },
                      child: const SizedBox(
                        width: 8,
                      ),
                    ),
                  ),

                  // 2. Main Chat Panel (takes the rest)
                  Expanded(
                    child: _buildChatPanel(isDark, scale),
                  ),
                ],
              ),
            ),
          ),

          // Settings Modal Overlay (hidden button, modal triggered programmatically)
          Positioned.fill(
            child: SettingsButton(
              key: _settingsKey,
              showFloatingButton: false,
            ),
          ),

          // Search Overlay
          if (_isSearching) _buildSearchOverlay(isDark, scale),
        ],
      ),
    );
  }

  Widget _buildChatListPanel(bool isDark, double scale) {
    return Column(
      children: [
        // Header
        Container(
          height: 46 + 18 * scale,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_viewingArchive)
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, size: 20 * scale),
                  tooltip: 'Назад к чатам',
                  onPressed: () {
                    setState(() {
                      _viewingArchive = false;
                    });
                  },
                  color: isDark ? Colors.white70 : Colors.black54,
                )
              else
                IconButton(
                  icon: Icon(Icons.menu_rounded, size: 20 * scale),
                  tooltip: 'Настройки',
                  onPressed: () {
                    _settingsKey.currentState?.openSettings();
                  },
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              const SizedBox(width: 8),
              Text(
                _viewingArchive ? 'Архив' : 'Чаты',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18 * scale,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (!_viewingArchive)
                IconButton(
                  icon: Icon(Icons.search_rounded, size: 20 * scale),
                  tooltip: 'Поиск контактов',
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                      _searchResults = [];
                    });
                  },
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
            ],
          ),
        ),
        
        // Chats List
        Expanded(
          child: _isChatsLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _viewingArchive
                  ? (_archivedChats.isEmpty
                      ? Center(
                          child: Text(
                            'Архив пуст',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 13 * scale,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _archivedChats.length,
                          itemBuilder: (context, index) {
                            final chat = _archivedChats[index];
                            final isSelected = _selectedChat != null && _selectedChat!['chat_id'] == chat['chat_id'];
                            return _buildChatItem(chat, isSelected, isDark, scale);
                          },
                        ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _archivedChats.isNotEmpty ? _chats.length + 1 : _chats.length,
                      itemBuilder: (context, index) {
                        if (_archivedChats.isNotEmpty) {
                          if (index == 0) {
                            return _buildArchiveFolderItem(context, isDark, scale);
                          }
                          final chat = _chats[index - 1];
                          final isSelected = _selectedChat != null && _selectedChat!['chat_id'] == chat['chat_id'];
                          return _buildChatItem(chat, isSelected, isDark, scale);
                        } else {
                          final chat = _chats[index];
                          final isSelected = _selectedChat != null && _selectedChat!['chat_id'] == chat['chat_id'];
                          return _buildChatItem(chat, isSelected, isDark, scale);
                        }
                      },
                    ),
        ),

        // Bottom Account Info
        _buildBottomAccountInfo(isDark, scale),
      ],
    );
  }

  Widget _buildBottomAccountInfo(bool isDark, double scale) {
    String realName = 'Xaneo';
    if (_myProfile != null) {
      final firstName = _myProfile!['first_name'] as String?;
      final profileRealName = _myProfile!['realname'] as String?;
      final username = _myProfile!['username'] as String?;

      if (firstName != null && firstName.trim().isNotEmpty) {
        realName = firstName;
      } else if (profileRealName != null && profileRealName.trim().isNotEmpty) {
        realName = profileRealName;
      } else if (username != null && username.trim().isNotEmpty) {
        realName = username;
      }
    }

    final radius = BorderRadius.circular(16 * scale);
    bool isPressed = false;
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setCardState(() => isPressed = true),
            onTapUp: (_) => setCardState(() => isPressed = false),
            onTapCancel: () => setCardState(() => isPressed = false),
            onTap: () => _showAccountSwitcherDialog(context),
            child: AnimatedScale(
              scale: isPressed ? 0.97 : (isHovered ? 1.02 : 1.0),
              duration: const Duration(milliseconds: 100),
              child: AnimatedOpacity(
                opacity: isPressed ? 0.85 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
                  height: 52 * scale,
                  child: Stack(
                    children: [
                      // 1. Subtle shadow for 3D depth
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 2. Blurred glass layer
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: radius,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06),
                                  width: 1,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          Colors.white.withOpacity(0.08),
                                          Colors.white.withOpacity(0.02),
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.4),
                                          Colors.white.withOpacity(0.15),
                                        ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 3. Specular shine highlight (RadialGradient shader layer)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              gradient: RadialGradient(
                                center: const Alignment(-0.6, -0.5),
                                radius: 0.8,
                                colors: [
                                  Colors.white.withOpacity(isDark ? 0.12 : 0.35),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 4. Content layer
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 14 * scale,
                            right: 14 * scale,
                            top: 6 * scale,
                            bottom: 6 * scale,
                          ),
                          child: Row(
                            children: [
                              // Avatar (smaller, e.g. 30 * scale width/height)
                              _buildAvatar(
                                _myProfile != null ? (_myProfile!['avatar'] as String? ?? _myProfile!['avatar_url'] as String?) : null,
                                realName,
                                15 * scale,
                                1.0,
                                isDark,
                                avatarGradient: _myProfile != null ? _myProfile!['avatar_gradient'] as String? : null,
                              ),
                              const SizedBox(width: 10),
                              // User Real Name (smaller text)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      realName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13 * scale,
                                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _myUsername != null ? '@$_myUsername' : '',
                                      style: TextStyle(
                                        fontSize: 10 * scale,
                                        color: isDark ? Colors.white38 : Colors.black45,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Logout action icon
                              IconButton(
                                icon: Icon(Icons.logout_rounded, size: 16 * scale),
                                tooltip: 'Выйти из аккаунта',
                                onPressed: _logout,
                                color: isDark ? Colors.white54 : Colors.black54,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, bool isSelected, bool isDark, double scale) {
    final chatType = chat['chat_type'] as String?;
    final displayName = _getChatName(chat);
    final dynamic rawUnread = chat['unread_count'];
    final unreadCount = rawUnread is int ? rawUnread : int.tryParse(rawUnread.toString()) ?? 0;
    final lastMsg = chat['last_message'];
    
    String lastMsgText = "Нет сообщений";
    String lastMsgTime = "";
    if (lastMsg != null) {
      final dynamic rawMsgId = lastMsg['id'];
      final msgId = rawMsgId is int ? rawMsgId : int.tryParse(rawMsgId.toString());
      final msgType = lastMsg['message_type'] as String?;

      if (msgType == 'todo_list') {
        lastMsgText = "📋 To-Do лист";
      } else if (msgType == 'poll') {
        lastMsgText = "🗳️ Опрос";
      } else if (msgId != null) {
        lastMsgText = _decryptedMessages[msgId] ?? "[Зашифрованное сообщение]";
        if (lastMsgText.isEmpty) {
          lastMsgText = "📎 Файл";
        }
      } else if (lastMsg['files'] != null && (lastMsg['files'] as List).isNotEmpty) {
        final List files = lastMsg['files'] as List;
        final firstFile = files.first;
        final fileType = firstFile['file_type'] as String? ?? '';
        if (fileType == 'image') {
          lastMsgText = "📷 Фотография";
        } else {
          lastMsgText = "📎 Файл";
        }
      }

      if (lastMsgText.startsWith('{')) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(lastMsgText);
          if (parsed['type'] == 'voice') {
            lastMsgText = "🎤 Голосовое сообщение";
          } else if (parsed['type'] == 'file') {
            lastMsgText = "📎 Файл";
          } else if (parsed['type'] == 'todo_list') {
            lastMsgText = "📋 To-Do лист";
          } else if (parsed['type'] == 'poll') {
            lastMsgText = "🗳️ Опрос";
          }
        } catch (_) {}
      }

      lastMsgTime = _formatMessageTime(lastMsg['created_at'] as String?);
    }
    
    final otherUser = chat['other_user'] as Map<String, dynamic>?;
    final isOnline = otherUser != null && (otherUser['is_online'] as bool? ?? false);
    
    final typingText = _getTypingStatusText(chat: chat);
    String? typingAction;
    if (typingText != null && _activeTypingUsers.isNotEmpty) {
      typingAction = _activeTypingUsers.values.first.action;
    }

    Widget avatarWithStatus = Stack(
      children: [
        if (chatType == 'favorites')
          _buildFavoritesAvatar(22, scale)
        else
          _buildAvatar(
            otherUser?['avatar_url'] as String?,
            displayName,
            22 * scale,
            1.0,
            isDark,
            avatarGradient: otherUser?['avatar_gradient'] as String?,
          ),
        if (chatType == 'personal' && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.black : Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );

    const activeBrandColor = Color(0xFF2563EB);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _selectChat(chat),
        onSecondaryTapDown: (details) {
          final isArchived = chat['is_archived'] as bool? ?? false;
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: [
              PopupMenuItem(
                value: 'archive_toggle',
                child: Text(isArchived ? 'Разархивировать' : 'В архив'),
              ),
            ],
            elevation: 8,
          ).then((value) {
            if (value == 'archive_toggle') {
              _toggleArchive(chat);
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? activeBrandColor.withOpacity(0.15) : activeBrandColor.withOpacity(0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04))
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              avatarWithStatus,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * scale,
                              color: isSelected
                                  ? (isDark ? Colors.white : activeBrandColor)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMsgTime.isNotEmpty)
                          Text(
                            lastMsgTime,
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: typingText != null && typingAction != null
                              ? Row(
                                  children: [
                                    Lottie.asset(
                                      typingAction == 'recording_voice' 
                                          ? 'assets/animations/recording-voice.json'
                                          : 'assets/animations/loading.json',
                                      width: 16 * scale,
                                      height: 16 * scale,
                                      delegates: LottieDelegates(
                                        values: [
                                          ValueDelegate.colorFilter(
                                            const ['**'],
                                            value: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcATop),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        typingText,
                                        style: TextStyle(
                                          fontSize: 13 * scale,
                                          color: const Color(0xFF2563EB),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  lastMsgText,
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    color: isDark ? Colors.white38 : Colors.black45,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: activeBrandColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    String? avatarUrl,
    String displayName,
    double radius,
    double scale,
    bool isDark, {
    String? avatarGradient,
    BorderRadius? borderRadius,
  }) {
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : "?";
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(radius);
    
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return _buildInitialsAvatar(initials, radius, scale, isDark, avatarGradient: avatarGradient, borderRadius: borderRadius);
    }
    
    if (avatarUrl.startsWith('data:image/svg+xml')) {
      try {
        String svgString;
        if (avatarUrl.startsWith('data:image/svg+xml;base64,')) {
          final base64String = avatarUrl.substring('data:image/svg+xml;base64,'.length);
          svgString = utf8.decode(base64.decode(base64String));
        } else {
          final commaIndex = avatarUrl.indexOf(',');
          if (commaIndex != -1) {
            svgString = Uri.decodeComponent(avatarUrl.substring(commaIndex + 1));
          } else {
            svgString = '';
          }
        }
        
        if (svgString.isNotEmpty) {
          if (svgString.contains('<text') && svgString.contains('</text>')) {
            // It's an initials avatar generated by the backend!
            // SvgPicture has major issues centering text baselines.
            // Let's extract the background color and use our pixel-perfect native Flutter implementation instead.
            String? extractedColor;
            final rectMatch = RegExp(r'<rect[^>]*fill="(#[A-Fa-f0-9]{6})"').firstMatch(svgString);
            if (rectMatch != null) {
              extractedColor = rectMatch.group(1);
            } else {
              final pathMatch = RegExp(r'<path[^>]*fill="(#[A-Fa-f0-9]{6})"').firstMatch(svgString);
              if (pathMatch != null) {
                extractedColor = pathMatch.group(1);
              }
            }
            
            String? gradientToUse;
            if (extractedColor != null) {
              gradientToUse = '$extractedColor|$extractedColor';
            } else {
              gradientToUse = avatarGradient;
            }
            
            return _buildInitialsAvatar(initials, radius, scale, isDark, avatarGradient: gradientToUse, borderRadius: borderRadius);
          }

          // Real vector avatars (without text) can safely use SvgPicture
          return ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: SvgPicture.string(
                svgString,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      } catch (e) {
        print("Error parsing SVG avatar: $e");
        return _buildInitialsAvatar(initials, radius, scale, isDark, avatarGradient: avatarGradient, borderRadius: borderRadius);
      }
    }
    
    String fullUrl = avatarUrl;
    if (!avatarUrl.startsWith('http://') && !avatarUrl.startsWith('https://')) {
      final uri = Uri.parse(ApiService.baseUrl);
      final origin = "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
      fullUrl = "$origin$avatarUrl";
    }
    
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: Image.network(
        fullUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading avatar from network: $error");
          return _buildInitialsAvatar(initials, radius, scale, isDark, avatarGradient: avatarGradient, borderRadius: borderRadius);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: radius * 2,
            height: radius * 2,
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, double radius, double scale, bool isDark, {String? avatarGradient, BorderRadius? borderRadius}) {
    final diameter = radius * 2;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(radius);
    
    Gradient? gradient;
    if (avatarGradient != null && avatarGradient.contains('|')) {
      try {
        final colors = avatarGradient.split('|');
        if (colors.length == 2) {
          final color1 = Color(int.parse(colors[0].trim().replaceFirst('#', ''), radix: 16) + 0xFF000000);
          final color2 = Color(int.parse(colors[1].trim().replaceFirst('#', ''), radix: 16) + 0xFF000000);
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          );
        }
      } catch (e) {
        print("Error parsing avatar gradient: $e");
      }
    }

    final color = isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.87);
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        color: gradient == null
            ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
            : null,
        gradient: gradient,
      ),
      child: CustomPaint(
        painter: _InitialsPainter(
          initial: initials,
          color: gradient != null ? Colors.white : color,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  Widget _buildFavoritesAvatar(double radius, double scale) {
    return Container(
      width: radius * 2 * scale,
      height: radius * 2 * scale,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.bookmark_rounded,
          color: Colors.white,
          size: radius * 1.1 * scale,
        ),
      ),
    );
  }

  String _getChatName(Map<String, dynamic> chat) {
    final chatType = chat['chat_type'] as String?;
    if (chatType == 'favorites') {
      return "Избранное";
    }
    
    if (chatType == 'personal') {
      final otherUser = chat['other_user'] as Map<String, dynamic>?;
      if (otherUser != null) {
        final firstName = otherUser['first_name'] as String?;
        final realName = otherUser['realname'] as String?;
        if (firstName != null && firstName.trim().isNotEmpty) return firstName;
        if (realName != null && realName.trim().isNotEmpty) return realName;
        return otherUser['username'] as String? ?? "Пользователь";
      }
    }
    
    return chat['chat_display_name'] as String? ?? "Чат";
  }

  String _formatMessageTime(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return "";
    try {
      final dateTime = DateTime.parse(createdAtStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0 && dateTime.day == now.day) {
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return "$hour:$minute";
      } else {
        final day = dateTime.day.toString().padLeft(2, '0');
        final month = dateTime.month.toString().padLeft(2, '0');
        return "$day.$month";
      }
    } catch (_) {
      return "";
    }
  }

  Widget _buildChatPanel(bool isDark, double scale) {
    if (_selectedChat == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64 * scale, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(
              'Выберите чат для начала общения',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final displayName = _getChatName(_selectedChat!);
    final chatType = _selectedChat!['chat_type'] as String?;
    final otherUser = _selectedChat!['other_user'] as Map<String, dynamic>?;
    final isOnline = otherUser != null && (otherUser['is_online'] as bool? ?? false);

    String statusText = "";
    if (chatType == 'favorites') {
      statusText = "Избранные сообщения";
    } else if (chatType == 'personal') {
      statusText = isOnline ? "в сети" : "не в сети";
    } else if (chatType == 'group') {
      statusText = "группа";
    } else if (chatType == 'channel') {
      statusText = "канал";
    }

    String? typingAction;
    if (_activeTypingUsers.isNotEmpty) {
      typingAction = _activeTypingUsers.values.first.action;
    }

    return Column(
      children: [
        // Chat Header
        Container(
          height: 46 + 18 * scale,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Chat Title & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (chatType == 'personal' && otherUser != null)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showUserProfileDialog(context, otherUser, displayName),
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 2),
                    if (typingAction != null)
                      Row(
                        children: [
                          Lottie.asset(
                            typingAction == 'recording_voice' 
                                ? 'assets/animations/recording-voice.json'
                                : 'assets/animations/loading.json',
                            width: 14 * scale,
                            height: 14 * scale,
                            delegates: LottieDelegates(
                              values: [
                                ValueDelegate.colorFilter(
                                  const ['**'],
                                  value: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcATop),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTypingStatusText() ?? 'печатает...',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: const Color(0xFF2563EB),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: chatType == 'personal' && isOnline
                              ? Colors.green
                              : (isDark ? Colors.white38 : Colors.black38),
                          fontFamily: 'Inter',
                        ),
                      ),
                  ],
                ),
              ),

              // Action buttons: Call, Settings
              if (chatType == 'personal' || chatType == 'group')
                IconButton(
                  icon: Icon(Icons.phone_rounded, size: 20 * scale),
                  tooltip: 'Позвонить',
                  onPressed: () {
                    CustomToast.show(
                      context,
                      'Функция звонков находится в разработке',
                      type: ToastType.info,
                    );
                  },
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              IconButton(
                icon: Icon(Icons.settings_rounded, size: 20 * scale),
                tooltip: 'Настройки чата',
                onPressed: () {
                  CustomToast.show(
                    context,
                    'Настройки чата пока недоступны',
                    type: ToastType.info,
                  );
                },
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: Stack(
            children: [
              _isMessagesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Нет сообщений. Напишите что-нибудь!',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg['author_id']?.toString() == _myId?.toString();
                            return _buildMessageBubble(msg, isMe, isDark, scale);
                          },
                        ),

              // Floating voice-playback bar (только в пределах контента чата)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: _buildVoicePlaybackBar(isDark, scale),
              ),
            ],
          ),
        ),

        // Message Input
        _buildMessageInput(isDark, scale),
      ],
    );
  }

  Widget _buildVoicePlaybackBar(bool isDark, double scale) {
    return Consumer<PlaybackProvider>(
      builder: (context, playback, child) {
        final isVisible = playback.currentAudioUrl != null;
        final isPlaying = playback.isPlaying;
        final title = playback.title;
        final subtitle = playback.subtitle;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (widget, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.6),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: widget,
              ),
            );
          },
          child: !isVisible
              ? const SizedBox.shrink(key: ValueKey('voice_bar_hidden'))
              : Align(
                  key: const ValueKey('voice_bar_visible'),
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      height: 42 * scale,
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xE61C1C20) : const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 6 * scale),
                          // Play / Pause
                          GestureDetector(
                            onTap: () {
                              if (isPlaying) {
                                playback.pause();
                              } else {
                                playback.resume();
                              }
                            },
                            child: Container(
                              width: 30 * scale,
                              height: 30 * scale,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: isDark ? Colors.white : Colors.black87,
                                size: 18 * scale,
                              ),
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          // Title + subtitle
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.isEmpty ? 'Голосовое сообщение' : title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  SizedBox(height: 1 * scale),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : Colors.black45,
                                      fontSize: 11 * scale,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Close
                          GestureDetector(
                            onTap: () => playback.stop(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
                              child: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white38 : Colors.black38,
                                size: 18 * scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, bool isDark, double scale) {
    final dynamic rawId = msg['id'];
    final id = rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0);
    final decryptedText = _decryptedMessages[id] ?? "[Расшифровка...]";
    Map<String, dynamic>? customPayload;
    if (decryptedText.trim().startsWith('{')) {
      try {
        final parsed = jsonDecode(decryptedText);
        if (parsed is Map<String, dynamic>) {
          customPayload = parsed;
        }
      } catch (_) {}
    }
    final authorUsername = msg['author_username'] as String? ?? "Пользователь";
    final timeStr = msg['created_at'] != null 
        ? DateTime.parse(msg['created_at'] as String).toLocal().toString().substring(11, 16)
        : "";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isDark
                      ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.12)]
                      : [Colors.black.withOpacity(0.03), Colors.black.withOpacity(0.06)],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 16),
          ),
          border: Border.all(
            color: isMe 
                ? Colors.transparent 
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name (for group chats if not me)
            if (!isMe && (_selectedChat!['chat_type'] == 'group' || _selectedChat!['chat_type'] == 'channel'))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  authorUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),

            // Decrypted Plaintext
            if (customPayload != null && customPayload['type'] == 'voice')
              _VoiceMessageBubblePlayer(
                payload: customPayload,
                isMe: isMe,
                isDark: isDark,
                scale: scale,
                senderName: isMe
                    ? 'Вы'
                    : (_selectedChat?['chat_type'] == 'personal'
                        ? _getChatName(_selectedChat!)
                        : authorUsername),
              )
            else if (customPayload != null && 
                     (msg['message_type'] == 'todo_list' || msg['message_type'] == 'todo_list_message' || customPayload['is_native'] == true) &&
                     (customPayload['type'] == 'todo_list' || (customPayload['items'] != null && customPayload['title'] != null)))
              _buildTodoWidget(msg, customPayload, isMe, isDark, scale)
            else if (customPayload != null && 
                     (msg['message_type'] == 'poll' || msg['message_type'] == 'poll_message' || customPayload['is_native'] == true) &&
                     (customPayload['type'] == 'poll' || (customPayload['options'] != null && customPayload['question'] != null)))
              _buildPollWidget(msg, customPayload, isMe, isDark, scale)
            else
              Text(
                decryptedText,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                  fontSize: 15 * scale,
                ),
              ),
            
            const SizedBox(height: 4),
            // Timestamp and Lock icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white60 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_rounded, 
                  size: 10, 
                  color: isMe ? Colors.white60 : Colors.grey
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark, double scale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Voice Message Button
          IconButton(
            icon: Icon(Icons.mic_none_rounded, color: isDark ? Colors.white70 : Colors.black54),
            tooltip: 'Голосовое сообщение',
            onPressed: _showVoiceSendDialog,
          ),
          // Todo List Button
          IconButton(
            icon: Icon(Icons.playlist_add_check_rounded, color: isDark ? Colors.white70 : Colors.black54),
            tooltip: 'Список задач (TODO)',
            onPressed: _showTodoSendDialog,
          ),
          // Poll Button
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: isDark ? Colors.white70 : Colors.black54),
            tooltip: 'Создать опрос',
            onPressed: _showPollSendDialog,
          ),
          const SizedBox(width: 4),
          // Text field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Написать сообщение...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          // Send Button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2563EB),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(bool isDark, double scale) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            width: 400 * scale,
            height: 500 * scale,
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Новый чат',
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchResults = [];
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search Input
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Имя пользователя (мин. 5 символов)',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  onChanged: (val) {
                    if (val.trim().length >= 5) {
                      _handleSearch(val);
                    } else {
                      setState(() => _searchResults = []);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Results List
                Expanded(
                  child: _isSearchLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.length < 5
                                    ? 'Введите 5 или более символов'
                                    : 'Пользователи не найдены',
                                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.2),
                                    child: Text(
                                      (user['first_name'] as String? ?? user['username'] as String)[0].toUpperCase(),
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    ),
                                  ),
                                  title: Text(
                                    user['first_name'] ?? user['username'],
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                  subtitle: Text(
                                    '@${user['username']}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: const Icon(Icons.message_rounded, color: Color(0xFF2563EB)),
                                  onTap: () => _startChatWithUser(user),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateTodoLocalCompletion(String todoMsgId, int itemIndex, bool isCompleted) {
    setState(() {
      for (var m in _messages) {
        if (m['message_id']?.toString() == todoMsgId) {
          final currentStatus = Map<String, dynamic>.from(m['completion_status'] ?? {});
          currentStatus[itemIndex.toString()] = isCompleted;
          m['completion_status'] = currentStatus;
          break;
        }
      }
    });
  }

  void _updatePollLocalVote(String pollMsgId, String optionId, bool removeVote, String userId) {
    setState(() {
      for (var m in _messages) {
        if (m['message_id']?.toString() == pollMsgId) {
          final List<String> userVotes = List<String>.from(m['user_votes'] ?? []);
          final isCurrentUser = userId == _myId?.toString();

          if (isCurrentUser) {
            if (removeVote) {
              if (!userVotes.contains(optionId)) {
                // Vote already removed locally, skip duplicate increment/decrement
                break;
              }
              userVotes.remove(optionId);
            } else {
              if (userVotes.contains(optionId)) {
                // Vote already added locally, skip duplicate increment/decrement
                break;
              }
              userVotes.add(optionId);
            }
            m['user_votes'] = userVotes;
          }

          // Update votes_by_option
          final votesByOption = Map<String, dynamic>.from(m['votes_by_option'] ?? {});
          final currentVotes = votesByOption[optionId] is num 
              ? (votesByOption[optionId] as num).toInt() 
              : (int.tryParse(votesByOption[optionId]?.toString() ?? '') ?? 0);
          
          if (removeVote) {
            votesByOption[optionId] = (currentVotes - 1).clamp(0, 999999);
          } else {
            votesByOption[optionId] = currentVotes + 1;
          }
          m['votes_by_option'] = votesByOption;
          break;
        }
      }
    });
  }

  Widget _buildTodoWidget(Map<String, dynamic> msg, Map<String, dynamic> payload, bool isMe, bool isDark, double scale) {
    final title = payload['title']?.toString() ?? 'Список задач';
    final items = payload['items'] as List? ?? [];
    final todoMsgId = msg['message_id']?.toString() ?? '';

    // Handle completion status map
    final completionStatus = msg['completion_status'] is Map 
        ? msg['completion_status'] as Map 
        : (msg['completion_status'] is String && (msg['completion_status'] as String).isNotEmpty 
            ? jsonDecode(msg['completion_status'] as String) as Map 
            : {});

    return Container(
      width: 260 * scale,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                size: 18 * scale,
                color: isMe ? Colors.white : (isDark ? Colors.blue.shade400 : Colors.blue.shade600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final itemText = (item is Map ? item['text'] : item.toString()) ?? '';
            final isCompleted = completionStatus[index.toString()] == true;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: GestureDetector(
                onTap: () {
                  final nextVal = !isCompleted;
                  _updateTodoLocalCompletion(todoMsgId, index, nextVal);
                  // Send WebSocket update
                  _webSocketService?.sendMessage({
                    'type': 'todo_completion_update',
                    'todo_message_id': todoMsgId,
                    'item_index': index,
                    'is_completed': nextVal,
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 18 * scale,
                      height: 18 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted 
                            ? (isMe ? Colors.white : Colors.blue) 
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted 
                              ? (isMe ? Colors.white : Colors.blue) 
                              : (isMe ? Colors.white60 : (isDark ? Colors.white38 : Colors.black38)),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check,
                          color: isCompleted 
                              ? (isMe ? Colors.blue.shade700 : Colors.white) 
                              : Colors.transparent,
                          size: 12 * scale,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        itemText,
                        style: TextStyle(
                          color: isCompleted 
                              ? (isMe ? Colors.white60 : (isDark ? Colors.white38 : Colors.black38)) 
                              : (isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                          fontSize: 13.5 * scale,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPollWidget(Map<String, dynamic> msg, Map<String, dynamic> payload, bool isMe, bool isDark, double scale) {
    final question = payload['question']?.toString() ?? 'Опрос';
    final options = payload['options'] as List? ?? [];
    final isMultipleChoice = payload['is_multiple_choice'] == true;
    final pollMsgId = msg['message_id']?.toString() ?? '';

    // Handle votes map
    final votesByOption = msg['votes_by_option'] is Map
        ? msg['votes_by_option'] as Map
        : (msg['votes_by_option'] is String && (msg['votes_by_option'] as String).isNotEmpty
            ? jsonDecode(msg['votes_by_option'] as String) as Map
            : {});

    // Handle user votes
    final List<String> userVotes = msg['user_votes'] is List
        ? List<String>.from(msg['user_votes'] as List)
        : (msg['user_votes'] is String && (msg['user_votes'] as String).isNotEmpty
            ? List<String>.from(jsonDecode(msg['user_votes'] as String) as List)
            : []);

    // Calculate total votes
    int totalVotes = 0;
    votesByOption.values.forEach((v) {
      if (v is num) {
        totalVotes += v.toInt();
      } else {
        totalVotes += int.tryParse(v.toString()) ?? 0;
      }
    });

    final hasVoted = userVotes.isNotEmpty;

    return Container(
      width: 260 * scale,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            question,
            style: TextStyle(
              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              fontSize: 15.5 * scale,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isMultipleChoice ? 'Множественный выбор' : 'Одиночный выбор',
            style: TextStyle(
              color: isMe ? Colors.white54 : (isDark ? Colors.white38 : Colors.black45),
              fontSize: 10.5 * scale,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (index) {
            final option = options[index];
            final optionId = option['id']?.toString() ?? '';
            final optionText = option['text']?.toString() ?? '';

            final rawVotes = votesByOption[optionId];
            final optionVotes = rawVotes is num ? rawVotes.toInt() : (int.tryParse(rawVotes?.toString() ?? '') ?? 0);
            final double percent = totalVotes > 0 ? (optionVotes / totalVotes) : 0.0;
            final percentText = '${(percent * 100).round()}%';
            final isSelected = userVotes.contains(optionId);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: GestureDetector(
                onTap: () {
                  final nextSelected = !isSelected;
                  _updatePollLocalVote(pollMsgId, optionId, !nextSelected, _myId?.toString() ?? '');
                  // Send WebSocket update
                  _webSocketService?.sendMessage({
                    'type': 'poll_vote',
                    'poll_message_id': pollMsgId,
                    'option_id': optionId,
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Progress background
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            widthFactor: percent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              color: isMe 
                                  ? Colors.white.withOpacity(isSelected ? 0.2 : 0.08)
                                  : (isDark 
                                      ? Colors.white.withOpacity(isSelected ? 0.16 : 0.06)
                                      : Colors.blue.withOpacity(isSelected ? 0.15 : 0.05)),
                            ),
                          ),
                        ),
                      ),
                      // Text & percentage row
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                                ? (isMe ? Colors.white.withOpacity(0.4) : Colors.blue.withOpacity(0.5)) 
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: isMe ? Colors.white : (isDark ? Colors.blue.shade400 : Colors.blue.shade600),
                                      size: 14 * scale,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                  fontSize: 13.5 * scale,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                  fontFamily: 'Inter',
                                ),
                                child: Text(optionText),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : (isDark ? Colors.white60 : Colors.black54),
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                              child: Text(percentText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            totalVotes == 0
                ? 'Нет голосов'
                : '$totalVotes ${_formatVotesCountText(totalVotes)}',
            style: TextStyle(
              color: isMe ? Colors.white54 : (isDark ? Colors.white38 : Colors.black45),
              fontSize: 11 * scale,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  String _formatVotesCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'голос';
    } else if ((count % 10 >= 2 && count % 10 <= 4) && (count % 100 < 10 || count % 100 >= 20)) {
      return 'голоса';
    } else {
      return 'голосов';
    }
  }

  Future<void> _sendCustomMessage(String text) async {
    if (_selectedChat == null) return;

    final chatId = _selectedChat!['chat_id'] as String;
    final myUserId = _myId?.toString();
    final otherUser = _selectedChat!['other_user'] as Map<String, dynamic>?;

    String encryptedText = "";
    try {
      if (chatId.startsWith('favorites_') || chatId == 'favorites') {
        if (myUserId == null) return;
        encryptedText = await _cryptoService.encryptFavoritesMessage(text, myUserId);
      } else if (chatId.startsWith('personal_')) {
        final peerPubKey = await _getPeerPublicKey(otherUser);
        if (peerPubKey == null) return;
        encryptedText = await _cryptoService.encryptPersonalMessage(text, peerPubKey, chatId);
      } else if (chatId.startsWith('group_') || chatId.startsWith('channel_')) {
        final chatKeyHex = await _getGroupChatKey(chatId);
        if (chatKeyHex == null) return;
        encryptedText = await _cryptoService.encryptGroupMessage(text, chatKeyHex);
      }
    } catch (e) {
      Logger.error('MessengerScreen', 'Encryption failed for custom message', e);
      return;
    }

    if (encryptedText.isEmpty) return;

    // Helper to encrypt additional plaintext (like titles or questions) using the same logic
    Future<String> encryptString(String plaintext) async {
      try {
        if (chatId.startsWith('favorites_') || chatId == 'favorites') {
          if (myUserId == null) return "";
          return await _cryptoService.encryptFavoritesMessage(plaintext, myUserId);
        } else if (chatId.startsWith('personal_')) {
          final peerPubKey = await _getPeerPublicKey(otherUser);
          if (peerPubKey == null) return "";
          return await _cryptoService.encryptPersonalMessage(plaintext, peerPubKey, chatId);
        } else if (chatId.startsWith('group_') || chatId.startsWith('channel_')) {
          final chatKeyHex = await _getGroupChatKey(chatId);
          if (chatKeyHex == null) return "";
          return await _cryptoService.encryptGroupMessage(plaintext, chatKeyHex);
        }
      } catch (_) {}
      return "";
    }

    // Save locally
    _sentPlaintexts[encryptedText] = text;

    bool sentViaWs = false;
    if (_webSocketService != null && _webSocketService!.isConnected) {
      Map<String, dynamic>? parsedJson;
      try {
        parsedJson = jsonDecode(text) as Map<String, dynamic>?;
      } catch (_) {}

      if (parsedJson != null && parsedJson['type'] == 'todo_list') {
        final title = parsedJson['title'] as String? ?? 'Без названия';
        final encryptedTitle = await encryptString(title);
        sentViaWs = _webSocketService!.sendMessage({
          'type': 'todo_list_message',
          'encrypted_content': encryptedText,
          'encrypted_title': encryptedTitle,
          'title': title,
          'chat_id': chatId,
        });
      } else if (parsedJson != null && parsedJson['type'] == 'poll') {
        final question = parsedJson['question'] as String? ?? 'Без вопроса';
        final encryptedQuestion = await encryptString(question);
        sentViaWs = _webSocketService!.sendMessage({
          'type': 'poll_message',
          'encrypted_content': encryptedText,
          'encrypted_question': encryptedQuestion,
          'question': question,
          'chat_id': chatId,
        });
      } else {
        sentViaWs = _webSocketService!.sendMessage({
          'type': 'encrypted_message',
          'encrypted_text': encryptedText,
        });
      }
    }

    if (!sentViaWs) {
      _sentPlaintexts.remove(encryptedText);
      final res = await _apiService.sendMessage(chatId, encryptedText);
      if (res.success && res.data != null) {
        final newMsg = res.data!;
        final dynamic rawId = newMsg['id'];
        final id = rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0);
        _decryptedMessages[id] = text;

        if (mounted) {
          setState(() {
            _messages.insert(0, newMsg);
          });
          _scrollToBottom();
        }
        _loadChats(silent: true);
      }
    }
  }

  void _showVoiceSendDialog() {
    int duration = 5;
    _sendTypingStatus(true, 'recording_voice');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отправить голосовое сообщение'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Имитация записи голосового сообщения.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    '0:${duration.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: duration.toDouble(),
                min: 1,
                max: 60,
                onChanged: (val) {
                  setDialogState(() {
                    duration = val.toInt();
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final payload = jsonEncode({
                'type': 'voice',
                'file_id': 'voice_${DateTime.now().millisecondsSinceEpoch}',
                'file_name': 'voice_note.m4a',
                'file_size': 1200 * duration,
                'duration': duration,
              });
              _sendCustomMessage(payload);
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    ).then((_) {
      _sendTypingStatus(false, 'recording_voice');
    });
  }

  void _showTodoSendDialog() {
    final titleController = TextEditingController();
    final List<TextEditingController> itemsControllers = [
      TextEditingController(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleProvider = Provider.of<ScaleProvider>(context, listen: false);
    final scale = scaleProvider.scale;
    final activeBrandColor = const Color(0xFF2563EB);

    showGeneralDialog(
      context: context,
      barrierLabel: "TodoDialog",
      barrierDismissible: true,
      barrierColor: isDark ? Colors.black.withOpacity(0.85) : Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final screenSize = MediaQuery.of(context).size;
            final bgColor = isDark ? const Color(0xFF0C0C0C) : Colors.white;
            final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);

            return Material(
              type: MaterialType.transparency,
              child: Center(
                child: Container(
                  width: 380 * scale,
                  constraints: BoxConstraints(maxHeight: screenSize.height * 0.8),
                  margin: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.6 : 0.06),
                        blurRadius: 24 * scale,
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(20 * scale, 20 * scale, 20 * scale, 12 * scale),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'СОЗДАТЬ TO-DO',
                              style: TextStyle(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5 * scale,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontFamily: 'Inter',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16 * scale,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              TextField(
                                controller: titleController,
                                style: TextStyle(fontSize: 14 * scale),
                                decoration: InputDecoration(
                                  labelText: 'Название списка',
                                  labelStyle: TextStyle(fontSize: 12 * scale),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8 * scale),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8 * scale),
                                    borderSide: BorderSide(color: activeBrandColor),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Пункты:',
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...itemsControllers.asMap().entries.map((e) {
                                final i = e.key;
                                final controller = e.value;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8 * scale),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: controller,
                                          style: TextStyle(fontSize: 14 * scale),
                                          decoration: InputDecoration(
                                            hintText: 'Пункт ${i + 1}',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8 * scale),
                                              borderSide: BorderSide(color: borderColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8 * scale),
                                              borderSide: BorderSide(color: activeBrandColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (itemsControllers.length > 1) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          iconSize: 18 * scale,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                          onPressed: () {
                                            setModalState(() {
                                              itemsControllers.removeAt(i);
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    itemsControllers.add(TextEditingController());
                                  });
                                },
                                icon: Icon(Icons.add, size: 18 * scale),
                                label: Text('Добавить пункт', style: TextStyle(fontSize: 13 * scale)),
                                style: TextButton.styleFrom(
                                  foregroundColor: activeBrandColor,
                                  padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 12 * scale),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: EdgeInsets.all(20 * scale),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                              ),
                              child: Text('Отмена', style: TextStyle(fontSize: 13 * scale)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final title = titleController.text.trim();
                                final lines = itemsControllers
                                    .map((c) => c.text.trim())
                                    .where((l) => l.isNotEmpty)
                                    .toList();
                                if (title.isEmpty || lines.isEmpty) return;

                                Navigator.pop(context);
                                final itemsList = lines.map((l) => {
                                  'text': l,
                                  'completed': false,
                                }).toList();
                                final payload = jsonEncode({
                                  'type': 'todo_list',
                                  'title': title,
                                  'items': itemsList,
                                  'is_native': true,
                                });
                                _sendCustomMessage(payload);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeBrandColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8 * scale),
                                ),
                              ),
                              child: Text('Создать', style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPollSendDialog() {
    final questionController = TextEditingController();
    final List<TextEditingController> optionsControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    bool isMultipleChoice = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleProvider = Provider.of<ScaleProvider>(context, listen: false);
    final scale = scaleProvider.scale;
    final activeBrandColor = const Color(0xFF2563EB);

    showGeneralDialog(
      context: context,
      barrierLabel: "PollDialog",
      barrierDismissible: true,
      barrierColor: isDark ? Colors.black.withOpacity(0.85) : Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final screenSize = MediaQuery.of(context).size;
            final bgColor = isDark ? const Color(0xFF0C0C0C) : Colors.white;
            final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);

            return Material(
              type: MaterialType.transparency,
              child: Center(
                child: Container(
                  width: 380 * scale,
                  constraints: BoxConstraints(maxHeight: screenSize.height * 0.8),
                  margin: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.6 : 0.06),
                        blurRadius: 24 * scale,
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(20 * scale, 20 * scale, 20 * scale, 12 * scale),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'СОЗДАТЬ ОПРОС',
                              style: TextStyle(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5 * scale,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontFamily: 'Inter',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16 * scale,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              TextField(
                                controller: questionController,
                                style: TextStyle(fontSize: 14 * scale),
                                decoration: InputDecoration(
                                  labelText: 'Вопрос',
                                  labelStyle: TextStyle(fontSize: 12 * scale),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8 * scale),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8 * scale),
                                    borderSide: BorderSide(color: activeBrandColor),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Варианты ответа:',
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...optionsControllers.asMap().entries.map((e) {
                                final i = e.key;
                                final controller = e.value;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8 * scale),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: controller,
                                          style: TextStyle(fontSize: 14 * scale),
                                          decoration: InputDecoration(
                                            hintText: 'Вариант ${i + 1}',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8 * scale),
                                              borderSide: BorderSide(color: borderColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8 * scale),
                                              borderSide: BorderSide(color: activeBrandColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (optionsControllers.length > 1) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          iconSize: 18 * scale,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                          onPressed: () {
                                            setModalState(() {
                                              optionsControllers.removeAt(i);
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    optionsControllers.add(TextEditingController());
                                  });
                                },
                                icon: Icon(Icons.add, size: 18 * scale),
                                label: Text('Добавить вариант', style: TextStyle(fontSize: 13 * scale)),
                                style: TextButton.styleFrom(
                                  foregroundColor: activeBrandColor,
                                  padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 12 * scale),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Theme(
                                data: ThemeData(
                                  unselectedWidgetColor: isDark ? Colors.white54 : Colors.black54,
                                ),
                                child: CheckboxListTile(
                                  title: Text('Множественный выбор', style: TextStyle(fontSize: 13 * scale)),
                                  value: isMultipleChoice,
                                  activeColor: activeBrandColor,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (val) {
                                    setModalState(() {
                                      isMultipleChoice = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: EdgeInsets.all(20 * scale),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                              ),
                              child: Text('Отмена', style: TextStyle(fontSize: 13 * scale)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final question = questionController.text.trim();
                                final lines = optionsControllers
                                    .map((c) => c.text.trim())
                                    .where((l) => l.isNotEmpty)
                                    .toList();
                                if (question.isEmpty || lines.isEmpty) return;

                                Navigator.pop(context);
                                final List<Map<String, String>> optionsList = lines
                                    .asMap()
                                    .entries
                                    .map((e) => {'id': 'opt_${e.key}', 'text': e.value})
                                    .toList();
                                final payload = jsonEncode({
                                  'type': 'poll',
                                  'question': question,
                                  'options': optionsList,
                                  'is_multiple_choice': isMultipleChoice,
                                  'is_native': true,
                                });
                                _sendCustomMessage(payload);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeBrandColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8 * scale),
                                ),
                              ),
                              child: Text('Создать', style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// CustomPainter для точного центрирования буквы инициала в аватарке.
/// Вычисляет позицию baseline и cap-height глифа, чтобы визуальный
/// центр заглавной буквы совпадал с центром круга.
class _InitialsPainter extends CustomPainter {
  final String initial;
  final Color color;
  final double fontSize;

  const _InitialsPainter({
    required this.initial,
    required this.color,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Расстояние от верха textPainter до baseline
    final baseline = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    // Cap-height ≈ 0.72 * fontSize для Inter (высота заглавных букв от baseline вверх)
    final capHeight = fontSize * 0.72;
    // Верх глифа (от верха textPainter)
    final glyphTop = baseline - capHeight;
    // Визуальный центр буквы (от верха textPainter)
    final glyphVisualCenter = glyphTop + capHeight / 2;

    // Сдвигаем textPainter так, чтобы glyphVisualCenter попал в size.height / 2
    final dy = size.height / 2 - glyphVisualCenter;
    final dx = (size.width - textPainter.width) / 2;
    textPainter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_InitialsPainter old) =>
      old.initial != initial || old.color != color || old.fontSize != fontSize;
}

/// Снимок состояния плеера для конкретного ГС — чтобы Selector ребилдил
/// бабл только при значимых изменениях именно его трека.
class _VoicePlaybackState {
  final String? currentAudioUrl;
  final bool isPlaying;
  final bool isInitialized;
  final bool isLoading;
  final Duration position;
  final Duration duration;

  const _VoicePlaybackState({
    required this.currentAudioUrl,
    required this.isPlaying,
    required this.isInitialized,
    required this.isLoading,
    required this.position,
    required this.duration,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _VoicePlaybackState &&
          currentAudioUrl == other.currentAudioUrl &&
          isPlaying == other.isPlaying &&
          isInitialized == other.isInitialized &&
          isLoading == other.isLoading &&
          position == other.position &&
          duration == other.duration;

  @override
  int get hashCode =>
      currentAudioUrl.hashCode ^
      isPlaying.hashCode ^
      isInitialized.hashCode ^
      isLoading.hashCode ^
      position.hashCode ^
      duration.hashCode;
}

class _VoiceMessageBubblePlayer extends StatelessWidget {
  final Map<String, dynamic> payload;
  final bool isMe;
  final bool isDark;
  final double scale;
  final String senderName;

  const _VoiceMessageBubblePlayer({
    required this.payload,
    required this.isMe,
    required this.isDark,
    required this.scale,
    required this.senderName,
  });

  /// Абсолютная ссылка на скачивание ГС: host из ApiService.baseUrl
  /// (без суффикса /api/v1) + /api/files/download/<file_id>/.
  String _buildAudioUrl() {
    final fileId = payload['file_id']?.toString() ?? '';
    final uri = Uri.parse(ApiService.baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    final host = '${uri.scheme}://${uri.host}$port';
    final suffix = payload['file_url']?.toString() ?? '/api/files/download/$fileId/';
    if (suffix.startsWith('http')) return suffix;
    final prefix = suffix.startsWith('/') ? '' : '/';
    return '$host$prefix$suffix';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final durationSeconds = payload['duration'] is num
        ? (payload['duration'] as num).toInt()
        : (int.tryParse(payload['duration']?.toString() ?? '') ?? 10);
    final fallbackDuration = Duration(seconds: durationSeconds);
    final mimeType = payload['mime_type']?.toString();
    final audioUrl = _buildAudioUrl();

    final activeWaveColor = isMe ? Colors.white : Colors.blue;
    final inactiveWaveColor =
        isMe ? Colors.white30 : (isDark ? Colors.white24 : Colors.black12);

    return Selector<PlaybackProvider, _VoicePlaybackState>(
      selector: (_, provider) => _VoicePlaybackState(
        currentAudioUrl: provider.currentAudioUrl,
        isPlaying: provider.isPlaying,
        isInitialized: provider.isInitialized,
        isLoading: provider.isLoading,
        position: provider.position,
        duration: provider.duration,
      ),
      shouldRebuild: (prev, next) {
        final isCurrent = next.currentAudioUrl == audioUrl;
        final wasCurrent = prev.currentAudioUrl == audioUrl;
        if (!isCurrent && !wasCurrent) return false;
        return prev != next;
      },
      builder: (context, state, child) {
        final isCurrent = state.currentAudioUrl == audioUrl;
        final isPlaying = isCurrent && state.isPlaying;
        final isInitialized = isCurrent && state.isInitialized;
        final isLoading = isCurrent && state.isLoading;

        final position = isCurrent ? state.position : Duration.zero;
        final duration =
            isCurrent && state.isInitialized && state.duration > Duration.zero
                ? state.duration
                : fallbackDuration;

        final displayDuration =
            isPlaying || (isCurrent && position > Duration.zero)
                ? position
                : duration;

        return Container(
          width: 240 * scale,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: () {
                  if (isLoading) return;
                  context.read<PlaybackProvider>().play(
                        audioUrl,
                        'Голосовое сообщение',
                        senderName,
                        mimeType: mimeType,
                        duration: fallbackDuration,
                      );
                },
                child: Container(
                  width: 38 * scale,
                  height: 38 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMe
                        ? Colors.white.withOpacity(0.2)
                        : (isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.06)),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: EdgeInsets.all(10 * scale),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isMe
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isMe
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          size: 24 * scale,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Waveform & Duration Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceWaveformSlider(
                      position: position,
                      duration: duration,
                      isActive: isCurrent && isInitialized,
                      barsCount: 18,
                      activeColor: activeWaveColor,
                      inactiveColor: inactiveWaveColor,
                      onSeek: isCurrent && isInitialized
                          ? (pos) => context.read<PlaybackProvider>().seek(pos)
                          : null,
                      onSeekPreview: isCurrent && isInitialized
                          ? (pos) =>
                              context.read<PlaybackProvider>().seekPreview(pos)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    // Duration text
                    Text(
                      isPlaying || (isCurrent && position > Duration.zero)
                          ? '${_formatDuration(displayDuration)} / ${_formatDuration(duration)}'
                          : 'Голосовое сообщение • ${_formatDuration(duration)}',
                      style: TextStyle(
                        color: isMe
                            ? Colors.white60
                            : (isDark ? Colors.white38 : Colors.black45),
                        fontSize: 11 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypingState {
  final String username;
  final String firstName;
  final String action;
  final DateTime timestamp;

  _TypingState({
    required this.username,
    required this.firstName,
    required this.action,
    required this.timestamp,
  });
}


