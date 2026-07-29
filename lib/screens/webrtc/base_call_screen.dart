import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/webrtc/call_manager.dart';
import '../../services/api_service.dart';
import 'package:xaneo/l10n/app_localizations.dart';

/// Базовый класс для экранов звонков (одиночного и группового)
abstract class BaseCallScreen extends StatefulWidget {
  const BaseCallScreen({super.key});
}

abstract class BaseCallScreenState<T extends BaseCallScreen> extends State<T> with SingleTickerProviderStateMixin {
  late AnimationController callingAnimationController;

  @override
  void initState() {
    super.initState();
    callingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    callingAnimationController.dispose();
    super.dispose();
  }

  /// Общий виджет верхней панели (имя, таймер, кнопка сворачивания)
  Widget buildCallHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onMinimize,
  }) {
    return Positioned(
      top: 24,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981), // Emerald green pulse
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onMinimize != null)
            IconButton(
              onPressed: onMinimize,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
              tooltip: (AppLocalizations.of(context)?.svernut_ca9f ?? 'Fallback'),
            ),
        ],
      ),
    );
  }

  /// Общая нижняя панель кнопок управления
  Widget buildCallControls({
    required CallManager callManager,
    required VoidCallback onToggleAudio,
    required VoidCallback onToggleVideo,
    required VoidCallback onToggleScreenShare,
    required VoidCallback onHangup,
  }) {
    final isMicOn = !callManager.isMicrophoneMuted;
    final isCamOn = !callManager.isCameraOff;
    final isScreenSharing = callManager.isScreenSharing;

    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Кнопка микрофона
              buildControlCircleButton(
                onTap: onToggleAudio,
                icon: isMicOn ? FontAwesomeIcons.microphone : FontAwesomeIcons.microphoneSlash,
                isActive: isMicOn,
                activeColor: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              // Кнопка камеры
              buildControlCircleButton(
                onTap: onToggleVideo,
                icon: isCamOn ? FontAwesomeIcons.video : FontAwesomeIcons.videoSlash,
                isActive: isCamOn,
                activeColor: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              // Демонстрация экрана
              buildControlCircleButton(
                onTap: onToggleScreenShare,
                icon: FontAwesomeIcons.desktop,
                isActive: isScreenSharing,
                activeColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 24),
              // Кнопка сброса (Красная)
              buildHangupButton(onTap: onHangup),
            ],
          ),
        ),
      ),
    );
  }

  /// Кнопка управления
  Widget buildControlCircleButton({
    required VoidCallback onTap,
    required dynamic icon,
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
            child: FaIcon(
              icon,
              color: isActive ? activeColor : Colors.white60,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Кнопка сброса звонка
  Widget buildHangupButton({required VoidCallback onTap}) {
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

/// Виджет аватарки
class BaseCallAvatar extends StatelessWidget {
  final String? avatar;
  final String? avatarGradient;
  final String username;
  final double size;

  const BaseCallAvatar({
    super.key,
    this.avatar,
    this.avatarGradient,
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
