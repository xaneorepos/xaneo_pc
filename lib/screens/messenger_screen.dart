import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../widgets/advanced_background.dart';
import '../widgets/settings_modal.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/account_service.dart';
import '../services/websocket_service.dart';
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

  @override
  void initState() {
    super.initState();
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
    _webSocketService?.dispose();
    _pollingTimer?.cancel();
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
          _myId = profileRes.data!['id'] as int?;
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
    if (type == 'encrypted_message') {
      final msgChatId = data['chat_id'] as String?;
      if (msgChatId != activeChatId) return;
      
      final msgId = data['id'] as int?;
      if (msgId == null) return;
      
      final exists = _messages.any((m) => m['id'] == msgId);
      if (exists) return;
      
      final encryptedText = data['encrypted_text'] as String?;
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
    } else if (type == 'chat_list_update' || type == 'new_chat') {
      _loadChats(silent: true);
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
      count += (chat['unread_count'] as int? ?? 0);
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
    final id = msg['id'] as int?;
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
      final id = msg['id'] as int?;
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
        final id = newMsg['id'] as int;
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

  void _selectChat(Map<String, dynamic> chat) {
    if (_selectedChat != null && _selectedChat!['chat_id'] == chat['chat_id']) {
      return;
    }
    
    setState(() {
      _selectedChat = chat;
      _messages = [];
      _isMessagesLoading = true;
    });
    _loadMessages(chat['chat_id'] as String);
    _connectWebSocket(chat['chat_id'] as String);
    _scrollToBottom();
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
    final targetId = user['id'] as int;
    final targetUsername = user['username'] as String;
    if (_myId == null) return;

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
    final unreadCount = chat['unread_count'] as int? ?? 0;
    final lastMsg = chat['last_message'];
    
    String lastMsgText = "Нет сообщений";
    String lastMsgTime = "";
    if (lastMsg != null) {
      final msgId = lastMsg['id'] as int?;
      if (msgId != null) {
        lastMsgText = _decryptedMessages[msgId] ?? "[Зашифрованное сообщение]";
        if (lastMsgText.isEmpty) {
          lastMsgText = "📎 Файл";
        }
      }
      lastMsgTime = _formatMessageTime(lastMsg['created_at'] as String?);
    }
    
    final otherUser = chat['other_user'] as Map<String, dynamic>?;
    final isOnline = otherUser != null && (otherUser['is_online'] as bool? ?? false);
    
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
                          child: Text(
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
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: chatType == 'personal' && isOnline
                            ? Colors.green
                            : (isDark ? Colors.white38 : Colors.black38),
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
          child: _isMessagesLoading
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
        ),

        // Message Input
        _buildMessageInput(isDark, scale),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, bool isDark, double scale) {
    final id = msg['id'] as int;
    final decryptedText = _decryptedMessages[id] ?? "[Расшифровка...]";
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
