import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version_info.dart';
import '../services/update_service.dart';

/// Аккуратная ненавязчивая плашка обновления над профилем пользователя
class UpdateBannerWidget extends StatelessWidget {
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

  Future<void> _openUpdateUrl() async {
    final urlStr = updateInfo.downloadUrl ?? updateInfo.htmlUrl;
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E212B).withAlpha(230)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 16 * scale,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  'Доступна v${updateInfo.version}',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  UpdateService().ignoreVersion(updateInfo.version);
                  onDismiss();
                },
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
          if (updateInfo.releaseNotes.isNotEmpty) ...[
            SizedBox(height: 4 * scale),
            Text(
              updateInfo.releaseNotes.split('\n').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11 * scale,
                color: isDark ? Colors.white60 : Colors.black54,
                fontFamily: 'Inter',
              ),
            ),
          ],
          SizedBox(height: 8 * scale),
          SizedBox(
            width: double.infinity,
            height: 28 * scale,
            child: ElevatedButton(
              onPressed: _openUpdateUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black87,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
              ),
              child: Text(
                'Обновить',
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
