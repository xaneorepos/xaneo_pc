import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart';

import 'base_call_screen.dart';
import '../../services/webrtc/call_manager.dart';
import 'package:xaneo/l10n/app_localizations.dart';

/// Экран активного ГРУППОВОГО звонка в стиле веб-версии
class GroupActiveCallScreen extends BaseCallScreen {
  const GroupActiveCallScreen({super.key});

  @override
  State<GroupActiveCallScreen> createState() => _GroupActiveCallScreenState();
}

class _GroupActiveCallScreenState extends BaseCallScreenState<GroupActiveCallScreen> {
  @override
  Widget build(BuildContext context) {
    final callManager = Provider.of<CallManager>(context);

    // Если звонок завершен - закрываем экран
    if (callManager.state == CallState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    final groupName = callManager.targetName ?? (AppLocalizations.of(context)?.gruppovoyZvonok_dac1 ?? 'Fallback');
    final isConnected = callManager.state == CallState.connected;

    return Scaffold(
      backgroundColor: Color(0xFF0F172A), // Modern Slate-900 background
      body: Stack(
        children: [
          // ==========================================
          // 1. ОСНОВНАЯ СЕТКА УЧАСТНИКОВ (GRID LAYOUT)
          // ==========================================
          if (isConnected) ...[
            Positioned.fill(
              top: 80,
              bottom: 135,
              left: 24,
              right: 24,
              child: _buildParticipantsGrid(callManager),
            ),
          ] else ...[
            // Экран подключения к групповому звонку
            Positioned.fill(
              child: _buildConnectingState(callManager, groupName),
            ),
          ],

          // ==========================================
          // 2. ВЕРХНЯЯ И НИЖНЯЯ ПАНЕЛИ ИЗ BASE SCREEN
          // ==========================================
          buildCallHeader(
            context: context,
            title: groupName,
            subtitle: isConnected ? (AppLocalizations.of(context)?.gruppovoyZvonok_dac1 ?? 'Fallback') : (AppLocalizations.of(context)?.podklyuchenieKZvonku_e2cf ?? 'Fallback'),
            onMinimize: () {
              Navigator.of(context).pop();
            },
          ),

          buildCallControls(
            callManager: callManager,
            onToggleAudio: () => callManager.toggleMicrophone(),
            onToggleVideo: () => callManager.toggleCamera(),
            onToggleScreenShare: () => callManager.toggleScreenShare(),
            onHangup: () => callManager.endCall(),
          ),
        ],
      ),
    );
  }

  /// Экран подключения
  Widget _buildConnectingState(CallManager callManager, String groupName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.1).animate(
              CurvedAnimation(parent: callingAnimationController, curve: Curves.easeInOut),
            ),
            child: BaseCallAvatar(
              avatar: callManager.targetAvatar,
              avatarGradient: callManager.targetGradient,
              username: groupName,
              size: 110,
            ),
          ),
          SizedBox(height: 24),
          Text(
            groupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (AppLocalizations.of(context)?.podklyuchenieKVeschaniyu_038b ?? 'Fallback'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Построение адаптивной сетки участников
  Widget _buildParticipantsGrid(CallManager callManager) {
    final List<Widget> participantTiles = [];

    // 1. Локальный тайл (Собственная камера / Видеопоток пользователя)
    participantTiles.add(_buildParticipantCard(
      name: (AppLocalizations.of(context)?.vy_0101 ?? 'Fallback'),
      isLocal: true,
      isVideoOn: !callManager.isCameraOff,
      videoTrack: callManager.localVideoTrack,
      avatar: null,
      avatarGradient: null,
      isMuted: callManager.isMicrophoneMuted,
    ));

    // 2. Добавляем КАЖДОГО реально подключенного участника звонка
    final participantsMap = callManager.groupParticipants;
    if (participantsMap.isNotEmpty) {
      participantsMap.forEach((uid, pData) {
        participantTiles.add(_buildParticipantCard(
          name: pData['name']?.toString() ?? '${AppLocalizations.of(context)?.uchastnik_cffb ?? 'Participant'} $uid',
          isLocal: false,
          isVideoOn: callManager.remoteVideoTrack != null,
          videoTrack: callManager.remoteVideoTrack,
          avatar: pData['avatar']?.toString(),
          avatarGradient: pData['gradient']?.toString(),
          isMuted: false,
        ));
      });
    } else {
      // Плейсхолдер вещания при входящем/исходящем звонке до получения списка участников
      participantTiles.add(_buildParticipantCard(
        name: callManager.targetName ?? (AppLocalizations.of(context)?.uchastnik_cffb ?? 'Fallback'),
        isLocal: false,
        isVideoOn: callManager.remoteVideoTrack != null,
        videoTrack: callManager.remoteVideoTrack,
        avatar: callManager.targetAvatar,
        avatarGradient: callManager.targetGradient,
        isMuted: false,
      ));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 960,
          maxHeight: 520,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            int crossAxisCount = 1;
            int rowCount = 1;

            final count = participantTiles.length;
            if (count >= 7) {
              crossAxisCount = 4;
              rowCount = (count / 4).ceil();
            } else if (count >= 5) {
              crossAxisCount = 3;
              rowCount = (count / 3).ceil();
            } else if (count >= 2) {
              crossAxisCount = 2;
              rowCount = (count / 2).ceil();
            } else {
              crossAxisCount = 1;
              rowCount = 1;
            }

            const spacing = 16.0;
            final totalHorizontalSpacing = spacing * (crossAxisCount - 1);
            final totalVerticalSpacing = spacing * (rowCount - 1);

            final tileWidth = (availableWidth - totalHorizontalSpacing) / crossAxisCount;
            final tileHeight = (availableHeight - totalVerticalSpacing) / rowCount;

            final childAspectRatio = count == 1 ? 1.77 : (tileWidth / tileHeight).clamp(1.4, 2.2);

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: participantTiles.length,
              itemBuilder: (context, index) => participantTiles[index],
            );
          },
        ),
      ),
    );
  }

  /// Карточка одного участника группового звонка
  Widget _buildParticipantCard({
    required String name,
    required bool isLocal,
    required bool isVideoOn,
    required VideoTrack? videoTrack,
    required String? avatar,
    required String? avatarGradient,
    required bool isMuted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Видеопоток участника (если камера включена)
          if (isVideoOn && videoTrack != null)
            Positioned.fill(
              child: VideoTrackRenderer(
                videoTrack,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            // Заглушка с аватаркой участника
            Positioned.fill(
              child: Container(
                color: const Color(0xFF151D2A),
                child: Center(
                  child: BaseCallAvatar(
                    avatar: avatar,
                    avatarGradient: avatarGradient,
                    username: name,
                    size: 72,
                  ),
                ),
              ),
            ),

          // Нижная полупрозрачная плашка с именем и индикаторами
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLocal && name != (AppLocalizations.of(context)?.vy_0101 ?? 'Fallback')) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (AppLocalizations.of(context)?.vy_479c ?? 'Fallback'),
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Индикатор выключенного микрофона
                if (isMuted)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
