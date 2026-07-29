import 'package:flutter/material.dart';
import '../models/app_version_info.dart';
import 'update_modal.dart';
import 'package:xaneo/l10n/app_localizations.dart';


/// Компактная анимированная плашка уведомления об обновлении над профилем пользователя
class UpdateBannerWidget extends StatefulWidget {
  final AppVersionInfo updateInfo;
  final bool isDark;
  final double scale;
  final VoidCallback onDismiss;

  const UpdateBannerWidget({
    super.key,
    required this.updateInfo,
    required this.isDark,
    required this.scale,
    required this.onDismiss,
  });

  @override
  State<UpdateBannerWidget> createState() => _UpdateBannerWidgetState();
}

class _UpdateBannerWidgetState extends State<UpdateBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }


  void _openDetailsModal(BuildContext context) {
    XaneoUpdateModal.open(context, widget.updateInfo);
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isDark = widget.isDark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDetailsModal(context),
              borderRadius: BorderRadius.circular(12 * scale),
              hoverColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
              child: Ink(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
                decoration: BoxDecoration(
                  color: isDark
                      ? Color(0xFF1E212B).withAlpha(240)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 15),
                      blurRadius: 8 * scale,
                      offset: Offset(0, 3 * scale),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6 * scale),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(20)
                            : const Color(0xFF1F2937),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        size: 14 * scale,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)?.updateAvailable ?? "Доступно обновление"} v${widget.updateInfo.version}',
                            style: TextStyle(
                              fontSize: 12.5 * scale,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2 * scale),
                          Text(
                            AppLocalizations.of(context)?.clickToViewChanges ?? 'Нажмите для просмотра изменений',
                            style: TextStyle(
                              fontSize: 10.5 * scale,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _handleDismiss,
                      borderRadius: BorderRadius.circular(12 * scale),
                      child: Padding(
                        padding: EdgeInsets.all(4 * scale),
                        child: Icon(
                          Icons.close,
                          size: 16 * scale,
                          color: isDark ? Colors.white54 : Colors.black45,

                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
