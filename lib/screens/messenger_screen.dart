import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../widgets/advanced_background.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/account_service.dart';
import '../services/websocket_service.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final ApiService _apiService = ApiService();
  final CryptoService _cryptoService = CryptoService();

  List<dynamic> _chats = [];
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
    _initMessenger();
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
      final chatList = res.data!['chats'] as List? ?? [];
      if (mounted) {
        setState(() {
          _chats = chatList;
          _isChatsLoading = false;
        });
        
        // Decrypt latest message preview in each chat
        for (var chat in chatList) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось получить ключ шифрования для чата')),
          );
          return;
        }
        encryptedText = await _cryptoService.encryptPersonalMessage(text, peerPubKey, chatId);
      } else if (chatId.startsWith('group_') || chatId.startsWith('channel_')) {
        final chatKeyHex = await _getGroupChatKey(chatId);
        if (chatKeyHex == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось получить ключ шифрования для чата')),
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
    await _apiService.logout();
    await _cryptoService.clearKeys();
    await _webSocketService?.disconnect();
    
    if (_myId != null) {
      await AccountService().removeAccount(_myId!);
    }
    
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось переключить аккаунт'),
            backgroundColor: Colors.red,
          ),
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
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Row(
                children: [
                  Icon(Icons.supervised_user_circle_rounded, color: isDark ? Colors.white : Colors.black87),
                  const SizedBox(width: 8),
                  const Text('Управление аккаунтами'),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: FutureBuilder<List<AccountInfo>>(
                  future: AccountService().getAccounts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final accounts = snapshot.data!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...accounts.map((acc) {
                          final isActive = acc.userId == _myId;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB).withOpacity(0.2),
                                child: Text(
                                  acc.username.substring(0, acc.username.isNotEmpty ? 1 : 0).toUpperCase(),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(acc.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: acc.email != null ? Text(acc.email!) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isActive)
                                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz_rounded),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _switchAccount(acc.userId);
                                      },
                                      tooltip: 'Войти',
                                    ),
                                  if (!isActive)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () async {
                                        await AccountService().removeAccount(acc.userId);
                                        setState(() {}); // refresh dialog
                                      },
                                      tooltip: 'Удалить сессию',
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        if (accounts.length < 5) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Добавить аккаунт'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed('/login');
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Достигнут лимит в 5 аккаунтов',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Закрыть', style: TextStyle(color: Colors.grey)),
                ),
              ],
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
                  // 1. Chat List Panel (resizable)
                  Container(
                    width: _chatListWidth * scale,
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                    child: _buildChatListPanel(isDark, scale),
                  ),

                  // Resizable Divider
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _chatListWidth = (_chatListWidth + details.delta.dx / scale).clamp(240.0, 600.0);
                        });
                      },
                      child: Container(
                        width: 8,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 1,
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                          ),
                        ),
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
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
          child: Row(
            children: [
              // Active User Profile / Switcher Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showAccountSwitcherDialog(context),
                  child: Tooltip(
                    message: 'Сменить аккаунт (${_myUsername ?? "..."})',
                    child: Container(
                      width: 40 * scale,
                      height: 40 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (_myUsername != null && _myUsername!.isNotEmpty)
                              ? _myUsername!.substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _myProfile != null ? (_myProfile!['realname'] ?? _myProfile!['username'] ?? "Xaneo") : "Xaneo",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15 * scale,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Search button
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
              // Logout button
              IconButton(
                icon: Icon(Icons.exit_to_app_rounded, size: 20 * scale),
                tooltip: 'Выйти из аккаунта',
                onPressed: _logout,
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
        
        // Horizontal divider
        Container(
          height: 1,
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
        
        // Chats List
        Expanded(
          child: _isChatsLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    final isSelected = _selectedChat != null && _selectedChat!['chat_id'] == chat['chat_id'];
                    return _buildChatItem(chat, isSelected, isDark, scale);
                  },
                ),
        ),
      ],
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
          CircleAvatar(
            radius: 22 * scale,
            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            child: const Icon(Icons.bookmark_rounded, color: Color(0xFF2563EB), size: 22),
          )
        else
          _buildAvatar(
            otherUser?['avatar_url'] as String?,
            displayName,
            22,
            scale,
            isDark,
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? activeBrandColor.withOpacity(0.15) : activeBrandColor.withOpacity(0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildAvatar(String? avatarUrl, String displayName, double radius, double scale, bool isDark) {
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : "?";
    
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return _buildInitialsAvatar(initials, radius, scale, isDark);
    }
    
    if (avatarUrl.startsWith('data:image/svg+xml;base64,')) {
      try {
        final base64String = avatarUrl.substring('data:image/svg+xml;base64,'.length);
        final svgString = utf8.decode(base64.decode(base64String));
        return ClipOval(
          child: Container(
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
      } catch (e) {
        print("Error parsing base64 SVG avatar: $e");
        return _buildInitialsAvatar(initials, radius, scale, isDark);
      }
    } else if (avatarUrl.startsWith('data:image/svg+xml')) {
      return _buildInitialsAvatar(initials, radius, scale, isDark);
    }
    
    String fullUrl = avatarUrl;
    if (!avatarUrl.startsWith('http://') && !avatarUrl.startsWith('https://')) {
      final uri = Uri.parse(ApiService.baseUrl);
      final origin = "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
      fullUrl = "$origin$avatarUrl";
    }
    
    return ClipOval(
      child: Image.network(
        fullUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading avatar from network: $error");
          return _buildInitialsAvatar(initials, radius, scale, isDark);
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

  Widget _buildInitialsAvatar(String initials, double radius, double scale, bool isDark) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: (radius * 0.7) * scale,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              // Chat Title & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Функция звонков находится в разработке')),
                    );
                  },
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              IconButton(
                icon: Icon(Icons.settings_rounded, size: 20 * scale),
                tooltip: 'Настройки чата',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Настройки чата пока недоступны')),
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
