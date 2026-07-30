import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'package:xaneo/l10n/app_localizations.dart';
import 'package:xaneo/utils/win32_overlay_helper.dart';

class NotificationOverlayScreen extends StatefulWidget {
  final int windowId;
  final Map<String, dynamic> arguments;

  const NotificationOverlayScreen({
    super.key,
    required this.windowId,
    required this.arguments,
  });

  @override
  State<NotificationOverlayScreen> createState() => _NotificationOverlayScreenState();
}

class _NotificationOverlayScreenState extends State<NotificationOverlayScreen> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  bool _isReplying = false;
  bool _isSending = false;
  Timer? _closeTimer;
  bool _isHovered = false;

  late String _chatId;
  late String _title;
  late String _body;
  String? _avatar;
  String? _gradient;
  late bool _isCall;
  String? _callType;

  @override
  void initState() {
    super.initState();
    final type = widget.arguments['type']?.toString();
    _isCall = type == 'call_incoming';
    
    _chatId = widget.arguments['chat_id']?.toString() ?? '';
    _title = widget.arguments['title']?.toString() ?? (_isCall ? (AppLocalizations.of(context)?.vhodyaschiyVyzov_d2f3 ?? 'Fallback') : (AppLocalizations.of(context)?.novoeSoobschenie_1d49 ?? 'Fallback'));
    _body = widget.arguments['body']?.toString() ?? '';
    _avatar = widget.arguments['avatar']?.toString();
    _gradient = widget.arguments['gradient']?.toString();
    _callType = widget.arguments['call_type']?.toString() ?? 'audio';

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    _initWindowSettings();

    // Регистрируем слушатель событий от главного окна
    DesktopMultiWindow.setMethodHandler((MethodCall call, int fromWindowId) async {
      if (call.method == 'cancel_call_notification') {
        _closeNotification();
      }
      return null;
    });

    if (!_isCall) {
      _startCloseTimer();
    }
  }

  void _initWindowSettings() async {
    await windowManager.ensureInitialized();
    // Сначала настраиваем все свойства окна ДО его отображения
    await windowManager.setAsFrameless();
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setHasShadow(true);
    // Скрываем из таскбара/dock/alt-tab — как в Telegram
    await windowManager.setSkipTaskbar(true);
    // Запрещаем перетаскивание/ресайз — это уведомление, а не окно
    await windowManager.setResizable(false);
    await windowManager.setMovable(false);
    // Применяем расширенные стили Win32 (WS_EX_TOOLWINDOW + WS_EX_NOACTIVATE) на Windows
    applyOverlayStyleWin32();
  }

  void _startCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(seconds: 5), () {
      if (!_isHovered && !_isReplying) {
        _closeNotification();
      }
    });
  }

  void _resetCloseTimer() {
    _closeTimer?.cancel();
    if (!_isHovered && !_isReplying && !_isCall) {
      _startCloseTimer();
    }
  }

  Future<void> _closeNotification() async {
    await _slideController.reverse();
    WindowController.fromWindowId(widget.windowId).close();
  }

  void _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await DesktopMultiWindow.invokeMethod(0, 'reply_message', {
        'chat_id': _chatId,
        'text': text,
      });
    } catch (e) {
      debugPrint('Error sending reply: $e');
    }

    _closeNotification();
  }

  void _acceptCall() async {
    try {
      await DesktopMultiWindow.invokeMethod(0, 'accept_call');
    } catch (e) {
      debugPrint('Error accepting call: $e');
    }
    _closeNotification();
  }

  void _declineCall() async {
    try {
      await DesktopMultiWindow.invokeMethod(0, 'decline_call');
    } catch (e) {
      debugPrint('Error declining call: $e');
    }
    _closeNotification();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _replyController.dispose();
    _replyFocusNode.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
          _closeTimer?.cancel();
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
          _resetCloseTimer();
        },
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _isCall ? _buildCallLayout() : _buildMessageLayout(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageLayout() {
    return Column(
      children: [
        // Header & content row
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _closeNotification,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white10,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                    ),
                    if (!_isReplying)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isReplying = true;
                          });
                          _replyFocusNode.requestFocus();
                          _closeTimer?.cancel();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (AppLocalizations.of(context)?.otvetit_e568 ?? 'Fallback'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isReplying)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white10, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _replyController,
                      focusNode: _replyFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: (AppLocalizations.of(context)?.vashOtvet_40c2 ?? 'Fallback'),
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendReply(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      )
                    : GestureDetector(
                        onTap: _sendReply,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCallLayout() {
    final typeText = _callType == 'video' ? (AppLocalizations.of(context)?.videovyzov_3353 ?? 'Fallback') : (AppLocalizations.of(context)?.audiovyzov_bbb5 ?? 'Fallback');
    final callIcon = _callType == 'video' ? Icons.videocam_rounded : Icons.phone_in_talk_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _body, // Имя звонящего передается в body
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(callIcon, size: 13, color: const Color(0xFF10B981)),
                        const SizedBox(width: 5),
                        Text(
                          typeText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _declineCall,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call_end_rounded, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 6),
                        Text(
                          (AppLocalizations.of(context)?.otklonit_8b0d ?? 'Fallback'),
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _acceptCall,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 6),
                        Text(
                          (AppLocalizations.of(context)?.otvetit_e568 ?? 'Fallback'),
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    List<Color> colors = [const Color(0xFF2563EB), const Color(0xFF1D4ED8)];
    if (_gradient != null && _gradient!.contains('|')) {
      try {
        final parts = _gradient!.split('|');
        colors = [
          Color(int.parse(parts[0].replaceAll('#', '0xFF'))),
          Color(int.parse(parts[1].replaceAll('#', '0xFF'))),
        ];
      } catch (_) {}
    }

    final avatarText = _isCall ? _body : _title;
    final initials = avatarText.isNotEmpty ? avatarText.substring(0, 1).toUpperCase() : "?";

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
