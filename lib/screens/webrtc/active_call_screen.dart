import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/webrtc/call_manager.dart';
import '../../services/api_service.dart';

import 'base_call_screen.dart';
import 'group_active_call_screen.dart';
import 'package:xaneo/l10n/app_localizations.dart';

class ActiveCallScreen extends BaseCallScreen {
  const ActiveCallScreen({super.key});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends BaseCallScreenState<ActiveCallScreen> {

  @override
  Widget build(BuildContext context) {
    final callManager = Provider.of<CallManager>(context);

    // Если звонок является ГРУППОВЫМ — открываем экран группового звонка!
    if (callManager.isGroupCall) {
      return const GroupActiveCallScreen();
    }
    debugPrint('ActiveCallScreen: build called. CallManager state: ${callManager.state}');

    // Если звонок завершен, закрываем экран
    if (callManager.state == CallState.idle) {
      debugPrint('ActiveCallScreen: CallManager state is idle, scheduling pop');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final route = ModalRoute.of(context);
        debugPrint('ActiveCallScreen: post-frame pop check. route.isCurrent: ${route?.isCurrent}');
        if (route != null && route.isCurrent) {
          Navigator.of(context).pop();
          debugPrint('ActiveCallScreen: pop() executed');
        }
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVideo = callManager.callType == 'video';
    
    // Определяем, активна ли демонстрация экрана (у нас или у собеседника)
    final isRemoteScreenSharing = callManager.remoteScreenShareTrack != null;
    final isLocalScreenSharing = callManager.isScreenSharing;
    final isAnyScreenSharing = isRemoteScreenSharing || isLocalScreenSharing;

    return Scaffold(
      backgroundColor: Color(0xFF070A13), // Ultra Deep Space color
      body: Stack(
        children: [
          // ==========================================
          // 1. ЗАДНИЙ ФОН / ОСНОВНОЙ ВИДЕОПОТОК
          // ==========================================
          if (callManager.state == CallState.connected) ...[
            if (isRemoteScreenSharing) ...[
              // Собеседник делится экраном - показываем экран на весь дисплей
              Positioned.fill(
                child: VideoTrackRenderer(
                  callManager.remoteScreenShareTrack!,
                  fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              ),
            ] else if (isLocalScreenSharing) ...[
              // Мы делимся экраном - показываем красивую заглушку презентации
              Positioned.fill(
                child: _buildLocalScreenSharingBanner(callManager),
              ),
            ] else if (isVideo && callManager.remoteVideoTrack != null) ...[
              // Обычный видеовызов - видео собеседника
              Positioned.fill(
                child: VideoTrackRenderer(
                  callManager.remoteVideoTrack!,
                  fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ] else ...[
              // Голосовой звонок (или видео еще не подгрузилось)
              Positioned.fill(
                child: _buildAudioCallBackground(callManager),
              ),
            ],
          ] else ...[
            // Исходящий вызов / Подключение к комнате
            Positioned.fill(
              child: _buildCallingBackground(callManager),
            ),
          ],

          // ==========================================
          // 2. БОКОВАЯ/УГЛОВАЯ ПАНЕЛЬ С ТАЙЛАМИ КАМЕР
          // ==========================================
          // Если идет показ экрана, камеры участников уменьшаются в боковую панель.
          // Если обычный видеозвонок, показываем камеру локального пользователя в PIP (картинка в картинке).
          if (callManager.state == CallState.connected) ...[
            if (isAnyScreenSharing) ...[
              // Показываем камеры участников справа сбоку в виде вертикального столбца
              Positioned(
                top: 24,
                right: 24,
                bottom: 120,
                width: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Тайлик собеседника (камера)
                    if (isVideo && callManager.remoteVideoTrack != null)
                      _buildSidebarTile(
                        track: callManager.remoteVideoTrack!,
                        name: callManager.targetName ?? (AppLocalizations.of(context)?.sobesednik_7025 ?? 'Fallback'),
                      ),
                    const SizedBox(height: 12),
                    // Тайлик нашей камеры
                    if (callManager.localVideoTrack != null && !callManager.isCameraOff)
                      _buildSidebarTile(
                        track: callManager.localVideoTrack!,
                        name: (AppLocalizations.of(context)?.vy_0101 ?? 'Fallback'),
                        isLocal: true,
                      ),
                  ],
                ),
              ),
            ] else if (isVideo && callManager.localVideoTrack != null && !callManager.isCameraOff) ...[
              // Обычный видеозвонок - плавающее PIP окно в верхнем правом углу
              Positioned(
                top: 48,
                right: 24,
                width: 140,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.5),
                    child: VideoTrackRenderer(
                      callManager.localVideoTrack!,
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirrorMode: VideoViewMirrorMode.auto,
                    ),
                  ),
                ),
              ),
            ],
          ],

          // ==========================================
          // 3. ТОП ИНДИКАТОР ПОКАЗА ЭКРАНА
          // ==========================================
          if (isLocalScreenSharing)
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.screen_share_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        (AppLocalizations.of(context)?.vyDelitesSvoimEkranom_16b1 ?? 'Fallback'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ==========================================
          // 4. ИНФОРМАЦИЯ О СОБЕСЕДНИКЕ ВВЕРХУ СЛЕВА
          // ==========================================
          Positioned(
            top: 48,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  callManager.targetName ?? (AppLocalizations.of(context)?.polzovatel_f154 ?? 'Fallback'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(callManager.state),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 5. ПРЕМИАЛЬНАЯ ПАНЕЛЬ УПРАВЛЕНИЯ ВНИЗУ
          // ==========================================
          Positioned(
            bottom: 36,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Микрофон
                    _buildControlCircleButton(
                      onTap: callManager.toggleMicrophone,
                      icon: callManager.isMicrophoneMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      isActive: !callManager.isMicrophoneMuted,
                      activeColor: const Color(0xFF10B981), // Emerald Green
                    ),
                    const SizedBox(width: 16),

                    // Камера
                    if (isVideo) ...[
                      _buildControlCircleButton(
                        onTap: callManager.toggleCamera,
                        icon: callManager.isCameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        isActive: !callManager.isCameraOff,
                        activeColor: const Color(0xFF3B82F6), // Ocean Blue
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Демонстрация экрана (Только для ПК клиента)
                    _buildControlCircleButton(
                      onTap: () async {
                        if (callManager.isScreenSharing) {
                          await callManager.stopScreenShare();
                        } else {
                          try {
                            final source = await showDialog<DesktopCapturerSource>(
                              context: context,
                              builder: (context) => ScreenSelectDialog(),
                            );
                            if (source != null) {
                              await callManager.startScreenShare(source);
                            }
                          } catch (e) {
                            debugPrint('Error showing screen share select dialog: $e');
                          }
                        }
                      },
                      icon: callManager.isScreenSharing
                          ? Icons.stop_screen_share_rounded
                          : Icons.screen_share_rounded,
                      isActive: callManager.isScreenSharing,
                      activeColor: const Color(0xFFF59E0B), // Golden Amber
                    ),
                    const SizedBox(width: 24),

                    // Сброс звонка
                    _buildHangupButton(onTap: () {
                      callManager.hangUp();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(CallState state) {
    switch (state) {
      case CallState.outgoing:
        return (AppLocalizations.of(context)?.ishodyaschiyVyzov_650b ?? 'Fallback');
      case CallState.incoming:
        return (AppLocalizations.of(context)?.vhodyaschiyVyzov_19ff ?? 'Fallback');
      case CallState.connected:
        return (AppLocalizations.of(context)?.podklyucheno_d022 ?? 'Fallback');
      default:
        return '';
    }
  }

  Widget _buildCallingBackground(CallManager callManager) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: callingAnimationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120 + (callingAnimationController.value * 50),
                  height: 120 + (callingAnimationController.value * 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6).withOpacity(0.08 * (1 - callingAnimationController.value)),
                  ),
                ),
                child!,
              ],
            );
          },
          child: CallAvatar(
            avatar: callManager.targetAvatar,
            avatarGradient: callManager.targetGradient,
            hasAvatar: callManager.targetAvatar != null && callManager.targetAvatar!.isNotEmpty,
            username: callManager.targetName ?? 'User',
            size: 110,
          ),
        ),
        SizedBox(height: 36),
        Text(
          (AppLocalizations.of(context)?.ozhidanieOtveta_a984 ?? 'Fallback'),
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildAudioCallBackground(CallManager callManager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CallAvatar(
            avatar: callManager.targetAvatar,
            avatarGradient: callManager.targetGradient,
            hasAvatar: callManager.targetAvatar != null && callManager.targetAvatar!.isNotEmpty,
            username: callManager.targetName ?? 'User',
            size: 120,
          ),
          SizedBox(height: 24),
          Text(
            (AppLocalizations.of(context)?.razgovorPoAudiosvyazi_3ed7 ?? 'Fallback'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalScreenSharingBanner(CallManager callManager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF59E0B).withOpacity(0.1),
            ),
            child: const Icon(
              Icons.screen_share_rounded,
              color: Color(0xFFF59E0B),
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            (AppLocalizations.of(context)?.translyatsiyaVashegoEkranaZapuschena_575a ?? 'Fallback'),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (AppLocalizations.of(context)?.sobesednikViditVseChtoProishodit_c759 ?? 'Fallback'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12.5,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile({
    required VideoTrack track,
    required String name,
    bool isLocal = false,
  }) {
    return Container(
      width: 160,
      height: 105,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: VideoTrackRenderer(
                track,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirrorMode: isLocal ? VideoViewMirrorMode.auto : VideoViewMirrorMode.off,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor.withOpacity(0.2) : Colors.white10,
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? activeColor : Colors.white60,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHangupButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEF4444),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class CallAvatar extends StatelessWidget {
  final String? avatar;
  final String? avatarGradient;
  final bool hasAvatar;
  final String username;
  final double size;

  const CallAvatar({
    super.key,
    this.avatar,
    this.avatarGradient,
    required this.hasAvatar,
    required this.username,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initials = username.isNotEmpty ? username.substring(0, 1).toUpperCase() : "?";
    
    if (avatar != null && avatar!.isNotEmpty) {
      String fullUrl = avatar!;
      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        final uri = Uri.parse(ApiService.baseUrl);
        final origin = "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
        fullUrl = "$origin$avatar";
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(initials),
        ),
      );
    }

    return _buildInitials(initials);
  }

  Widget _buildInitials(String initials) {
    List<Color> colors = [const Color(0xFF2563EB), const Color(0xFF1D4ED8)];
    if (avatarGradient != null && avatarGradient!.contains('|')) {
      try {
        final parts = avatarGradient!.split('|');
        colors = [
          Color(int.parse(parts[0].replaceAll('#', '0xFF'))),
          Color(int.parse(parts[1].replaceAll('#', '0xFF'))),
        ];
      } catch (_) {}
    }

    return Container(
      width: size,
      height: size,
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
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
