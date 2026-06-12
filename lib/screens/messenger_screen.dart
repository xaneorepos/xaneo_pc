import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/scale_provider.dart';
import '../widgets/advanced_background.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initMessenger();
  }

  @override
  void dispose() {
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

    // 2. Load profile
    final profileRes = await _apiService.getProfile();
    if (profileRes.success && profileRes.data != null) {
      if (mounted) {
        setState(() {
          _myProfile = profileRes.data;
          _myId = profileRes.data!['id'] as int?;
          _myUsername = profileRes.data!['username'] as String?;
        });
      }
    }

    // 3. Load chats & start polling
    await _loadChats();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _loadChats(silent: true);
      if (_selectedChat != null) {
        _loadMessages(_selectedChat!['chat_id'] as String, silent: true);
      }
    });
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
          // Reverse list for bottom-up scrolling
          _messages = msgList.reversed.toList();
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

    final res = await _apiService.sendMessage(chatId, encryptedText);
    if (res.success && res.data != null) {
      // Store our own plaintext directly — no need to decrypt
      final newMsg = res.data!;
      final id = newMsg['id'] as int;
      _decryptedMessages[id] = text;

      if (mounted) {
        setState(() {
          _messages.add(newMsg);
        });
        _scrollToBottom();
      }
      _loadChats(silent: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
  }

  Future<void> _logout() async {
    await _apiService.logout();
    await _cryptoService.clearKeys();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
              enableGrid: true,
              enableParticles: true,
              enableGeometricShapes: false,
            ),
          ),
          
          // Main layout
          SafeArea(
            child: Row(
              children: [
                // 1. Sidebar (narrow along oX - 80px)
                _buildSidebar(isDark, scale),

                // Vertical Divider
                Container(
                  width: 1,
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                ),

                // 2. Main Chat Panel (takes the rest)
                Expanded(
                  child: _buildChatPanel(isDark, scale),
                ),
              ],
            ),
          ),

          // Search Overlay
          if (_isSearching) _buildSearchOverlay(isDark, scale),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark, double scale) {
    return Container(
      width: 80 * scale,
      color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.4),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo / App Icon
          Container(
            width: 48 * scale,
            height: 48 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.purpleAccent, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.security, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 20),

          // Search button
          _buildSidebarButton(
            icon: Icons.search_rounded,
            tooltip: 'Поиск контактов',
            onTap: () {
              setState(() {
                _isSearching = true;
                _searchResults = [];
              });
            },
            isDark: isDark,
            scale: scale,
          ),
          const SizedBox(height: 12),

          // Chats List (narrow column of avatars)
          Expanded(
            child: _isChatsLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final isSelected = _selectedChat != null && _selectedChat!['chat_id'] == chat['chat_id'];
                      return _buildSidebarChatItem(chat, isSelected, isDark, scale);
                    },
                  ),
          ),

          // Settings / Logout
          _buildSidebarButton(
            icon: Icons.exit_to_app_rounded,
            tooltip: 'Выйти из аккаунта',
            onTap: _logout,
            isDark: isDark,
            scale: scale,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
    required double scale,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48 * scale,
            height: 48 * scale,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Icon(icon, color: color ?? (isDark ? Colors.white70 : Colors.black87), size: 22 * scale),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarChatItem(Map<String, dynamic> chat, bool isSelected, bool isDark, double scale) {
    final chatType = chat['chat_type'] as String?;
    final displayName = chat['chat_display_name'] as String? ?? "Чат";
    final unreadCount = chat['unread_count'] as int? ?? 0;
    
    // Choose display avatar & color
    Widget avatarWidget;
    if (chatType == 'favorites') {
      avatarWidget = CircleAvatar(
        radius: 24 * scale,
        backgroundColor: Colors.blue.withOpacity(0.2),
        child: const Icon(Icons.bookmark_rounded, color: Colors.blueAccent),
      );
    } else {
      final otherUser = chat['other_user'] as Map<String, dynamic>?;
      final initials = displayName.substring(0, displayName.length > 0 ? 1 : 0).toUpperCase();
      avatarWidget = CircleAvatar(
        radius: 24 * scale,
        backgroundColor: Colors.purple.withOpacity(0.2),
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 16 * scale),
        ),
      );
    }

    return Tooltip(
      message: displayName,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _selectChat(chat),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selected border glow
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56 * scale,
                  height: 56 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? Colors.purpleAccent 
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ] : [],
                  ),
                ),
                
                // Avatar itself
                avatarWidget,

                // Unread Count Badge
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // E2EE padlock small indicator
                Positioned(
                  left: 2,
                  bottom: 2,
                  child: Icon(
                    Icons.lock_rounded, 
                    size: 12 * scale, 
                    color: chatType == 'personal' || chatType == 'favorites' 
                        ? Colors.greenAccent 
                        : Colors.orangeAccent
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    final displayName = _selectedChat!['chat_display_name'] as String? ?? "Чат";
    final chatType = _selectedChat!['chat_type'] as String?;
    final isE2EE = chatType == 'personal' || chatType == 'favorites';

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              // Chat title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock_rounded,
                          size: 16 * scale,
                          color: isE2EE ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isE2EE ? "E2EE" : "Symmetric",
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            color: isE2EE ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chatType == 'favorites'
                          ? 'Ваш личный сейф сообщений'
                          : chatType == 'personal'
                              ? 'Зашифровано с помощью ECDH X25519'
                              : 'Зашифровано симметричным ключом сервера',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Close / Refresh buttons
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _loadMessages(_selectedChat!['chat_id'] as String),
                tooltip: 'Обновить сообщения',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['author_id'] == _myId;
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
                  colors: [Colors.purpleAccent, Colors.blueAccent],
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
                    color: Colors.purpleAccent,
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
                hintText: 'Зашифрованное сообщение...',
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
                gradient: LinearGradient(
                  colors: [Colors.purpleAccent, Colors.blueAccent],
                ),
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
                      'Новый E2EE чат',
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
                                    backgroundColor: Colors.purpleAccent.withOpacity(0.2),
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
                                  trailing: const Icon(Icons.message_rounded, color: Colors.purpleAccent),
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
