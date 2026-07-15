import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/webrtc/call_manager.dart';
import '../../services/api_service.dart';
import 'active_call_screen.dart';
import 'package:xaneo_pc/main.dart';

class IncomingCallDialog extends StatefulWidget {
  const IncomingCallDialog({super.key});

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callManager = Provider.of<CallManager>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-pop only if the call is ended (state is idle)
    if (callManager.state == CallState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    final isVideo = callManager.callType == 'video';
    final bgColor = isDark ? const Color(0xFF0C0C0C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title / Tag
              Text(
                'ВХОДЯЩИЙ ВЫЗОВ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),

              // Animated Pulsing Avatar
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80 + (_pulseController.value * 35),
                          height: 80 + (_pulseController.value * 35),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withOpacity(0.12 * (1 - _pulseController.value)),
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
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Caller Name
              Text(
                callManager.targetName ?? 'Неизвестный',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),

              // Call Type Description
              Text(
                isVideo ? 'Видеозвонок...' : 'Голосовой звонок...',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11.5,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 28),

              // Actions (Accept / Decline)
              Row(
                children: [
                  // Decline Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        callManager.rejectIncomingCall();
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_end_rounded, color: Color(0xFFEF4444), size: 15),
                              SizedBox(width: 6),
                              Text(
                                'Отклонить',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Accept Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('IncomingCallDialog: Accept button clicked');
                        debugPrint('IncomingCallDialog: navigatorKey.currentState is ${navigatorKey.currentState}');
                        
                        try {
                          debugPrint('IncomingCallDialog: Popping dialog modal...');
                          Navigator.of(context).pop();
                        } catch (e) {
                          debugPrint('IncomingCallDialog: Error popping dialog: $e');
                        }

                        try {
                          debugPrint('IncomingCallDialog: Starting acceptIncomingCall asynchronously...');
                          callManager.acceptIncomingCall();
                        } catch (e) {
                          debugPrint('IncomingCallDialog: Error starting accept: $e');
                        }

                        try {
                          debugPrint('IncomingCallDialog: Pushing ActiveCallScreen...');
                          navigatorKey.currentState?.push(
                            MaterialPageRoute(
                              builder: (context) => const ActiveCallScreen(),
                            ),
                          );
                          debugPrint('IncomingCallDialog: ActiveCallScreen pushed');
                        } catch (e) {
                          debugPrint('IncomingCallDialog: Error pushing screen: $e');
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                                color: const Color(0xFF10B981),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ответить',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
