import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_version_info.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String _repoUrl = 'https://api.github.com/repos/xaneorepos/xaneo_pc/releases/latest';
  static const String _ignoredVersionKey = 'xaneo_ignored_version';
  static const String _lastCheckedKey = 'xaneo_last_update_check';

  /// Запросить информацию о последней версии с GitHub Releases
  Future<AppVersionInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_repoUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'XaneoPC-App-UpdateChecker',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AppVersionInfo.fromGitHubJson(data);
      }
    } catch (e) {
      // Игнорируем ошибки сети при фоновой проверке
    }
    return null;
  }

  /// Получить текущую версию приложения из PackageInfo
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Проверить, есть ли новая доступная версия
  /// [force] - игнорировать задержку 24ч и сохранённую пропущенную версию
  Future<AppVersionInfo?> checkForUpdates({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!force) {
      final lastCheckMs = prefs.getInt(_lastCheckedKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      // Если с момента последней проверки прошло меньше 12 часов, пропускаем
      if (nowMs - lastCheckMs < 12 * 3600 * 1000) {
        return null;
      }
    }

    final latestRelease = await fetchLatestRelease();
    if (latestRelease == null) return null;

    final currentVersion = await getCurrentVersion();
    await prefs.setInt(_lastCheckedKey, DateTime.now().millisecondsSinceEpoch);

    if (isVersionNewer(currentVersion, latestRelease.version)) {
      if (!force) {
        final ignoredVersion = prefs.getString(_ignoredVersionKey);
        if (ignoredVersion == latestRelease.version) {
          return null; // Пользователь пропустил эту версию
        }
      }
      return latestRelease;
    }

    return null;
  }

  /// Пропустить текущую версию обновления
  Future<void> ignoreVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ignoredVersionKey, version);
  }

  /// Сравнение семантических версий (SemVer). Возвращает true, если remote > current
  static bool isVersionNewer(String current, String remote) {
    try {
      final currentParts = current.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final remoteParts = remote.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (remoteParts.length < 3) {
        remoteParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }
}
