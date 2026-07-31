import 'dart:io';

/// Модель информации об обновлении приложения
class AppVersionInfo {
  final String version;
  final String releaseNotes;
  final String htmlUrl;
  final DateTime? publishedAt;
  final String? downloadUrl;

  AppVersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.htmlUrl,
    this.publishedAt,
    this.downloadUrl,
  });

  factory AppVersionInfo.fromGitHubJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    // Очищаем тег от символа 'v' в начале (например 'v1.1.loc_0' -> '1.1.loc_0')
    final versionClean = tagName.startsWith('v') || tagName.startsWith('V')
        ? tagName.substring(1)
        : tagName;

    String? download;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null && assets.isNotEmpty) {
      final List<String> urls = [];
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final browserDownloadUrl = asset['browser_download_url'] as String?;
          if (browserDownloadUrl != null && browserDownloadUrl.isNotEmpty) {
            urls.add(browserDownloadUrl);
          }
        }
      }

      if (urls.isNotEmpty) {
        if (Platform.isLinux) {
          download = urls.firstWhere((u) => u.toLowerCase().endsWith('.appimage'),
              orElse: () => urls.firstWhere((u) => u.toLowerCase().endsWith('.deb'),
                  orElse: () => urls.firstWhere((u) => u.toLowerCase().endsWith('.rpm'),
                      orElse: () => urls.first)));
        } else if (Platform.isWindows) {
          download = urls.firstWhere((u) => u.toLowerCase().endsWith('.exe'),
              orElse: () => urls.firstWhere((u) => u.toLowerCase().endsWith('.zip'),
                  orElse: () => urls.first));
        } else if (Platform.isMacOS) {
          download = urls.firstWhere((u) => u.toLowerCase().endsWith('.dmg'),
              orElse: () => urls.firstWhere((u) => u.toLowerCase().endsWith('.zip'),
                  orElse: () => urls.first));
        } else {
          download = urls.first;
        }
      }
    }

    DateTime? pubDate;
    final pubStr = json['published_at'] as String?;
    if (pubStr != null) {
      pubDate = DateTime.tryParse(pubStr);
    }

    return AppVersionInfo(
      version: versionClean.isEmpty ? '1.0.14' : versionClean,
      releaseNotes: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? 'https://github.com/xaneorepos/xaneo_pc/releases/latest',
      publishedAt: pubDate,
      downloadUrl: download,
    );
  }
}
