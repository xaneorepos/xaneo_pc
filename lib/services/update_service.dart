import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_version_info.dart';
import 'linux_package_updater.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String _repoUrl =
      'https://api.github.com/repos/xaneorepos/xaneo_pc/releases/latest';
  static const String _ignoredVersionKey = 'xaneo_ignored_version';
  static const String _lastCheckedKey = 'xaneo_last_update_check';

  /// Запросить информацию о последней версии с GitHub Releases
  Future<AppVersionInfo?> fetchLatestRelease() async {
    try {
      final response = await http
          .get(
            Uri.parse(_repoUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'XaneoPC-App-UpdateChecker',
            },
          )
          .timeout(const Duration(seconds: 10));

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
    const overrideVer = String.fromEnvironment('OVERRIDE_VERSION');
    if (overrideVer.isNotEmpty) {
      return overrideVer;
    }
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (_) {
      return '1.0.14';
    }
  }

  /// Проверить, есть ли новая доступная версия
  /// [force] - игнорировать задержку 12ч и сохранённую пропущенную версию
  Future<AppVersionInfo?> checkForUpdates({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (force) {
      await prefs.remove(_ignoredVersionKey);
      await prefs.remove(_lastCheckedKey);
    } else {
      final lastCheckMs = prefs.getInt(_lastCheckedKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      // Если с момента последней проверки прошло меньше 12 часов, пропускаем
      if (nowMs - lastCheckMs < 12 * 3600 * 1000) {
        return null;
      }

      final ignoredVersion = prefs.getString(_ignoredVersionKey);
      if (ignoredVersion != null) {
        // Если версия была скрыта/пропущена
        return null;
      }
    }

    final latestRelease = await fetchLatestRelease();
    if (latestRelease == null) return null;

    final currentVersion = await getCurrentVersion();
    await prefs.setInt(_lastCheckedKey, DateTime.now().millisecondsSinceEpoch);

    if (isVersionNewer(currentVersion, latestRelease.version)) {
      return latestRelease;
    }

    return null;
  }

  /// Сбросить статус скрытия обновления
  Future<void> resetIgnoredVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ignoredVersionKey);
    await prefs.remove(_lastCheckedKey);
  }

  /// Пропустить текущую версию обновления
  Future<void> ignoreVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ignoredVersionKey, version);
  }

  /// Скачать обновление прямо в приложении и запустить его установку
  Future<void> downloadAndInstall({
    required String url,
    required Function(double progress, String statusText) onProgress,
    String? downloadingLabel,
    String? launchingInstallerLabel,
  }) async {
    final tempDir = await (await getTemporaryDirectory()).createTemp(
      'xaneo-update-',
    );
    final uri = Uri.parse(url);
    final filename = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'xaneo_update';
    final savePath = '${tempDir.path}/$filename';

    final label = downloadingLabel ?? 'Загрузка';

    final dio = Dio();
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
          onProgress(
            progress,
            '$label: $mbReceived MB / $mbTotal MB (${(progress * 100).toInt()}%)',
          );
        } else {
          final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
          onProgress(0.5, '$label: $mbReceived MB...');
        }
      },
    );

    final file = File(savePath);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    debugPrint('[UPDATE_SERVICE] Download finished (size: $fileSize bytes)');

    onProgress(1.0, launchingInstallerLabel ?? 'Запуск установки...');

    if (Platform.isLinux) {
      await LinuxPackageUpdater.install(savePath);
      // The old process may have inherited paths from a mounted AppImage.
      // Restart through the installed launcher using a clean environment.
      final environment = Map<String, String>.from(Platform.environment);
      for (final key in [
        'APPIMAGE',
        'APPDIR',
        'ARGV0',
        'OWD',
        'LD_LIBRARY_PATH',
        'LD_PRELOAD',
        'GDK_PIXBUF_MODULE_FILE',
        'GDK_PIXBUF_MODULEDIR',
        'GIO_MODULE_DIR',
        'GTK_PATH',
        'GTK_EXE_PREFIX',
        'GTK_DATA_PREFIX',
      ]) {
        environment.remove(key);
      }
      // main.dart holds a single-instance socket until this process exits.
      // A direct launch here would only focus the old instance and terminate.
      await Process.start(
        '/bin/sh',
        [
          '-c',
          r'while kill -0 "$1" 2>/dev/null; do sleep 0.2; done; '
              r'shift; exec "$@"',
          'xaneo-update-restart',
          '$pid',
          '/usr/bin/xaneo',
        ],
        workingDirectory: Platform.environment['HOME'] ?? '/',
        environment: environment,
        includeParentEnvironment: false,
        mode: ProcessStartMode.detached,
      );
    } else if (Platform.isWindows) {
      debugPrint('[UPDATE_SERVICE] Launching Windows installer...');
      final p = await Process.start(savePath, [
        '/S',
      ], mode: ProcessStartMode.detached);
      debugPrint('[UPDATE_SERVICE] Windows installer launched PID: ${p.pid}');
    } else if (Platform.isMacOS) {
      debugPrint('[UPDATE_SERVICE] Preparing macOS installer...');
      try {
        await Process.run('xattr', ['-d', 'com.apple.quarantine', savePath]);
        await Process.run('xattr', ['-cr', savePath]);
      } catch (e) {
        debugPrint('[UPDATE_SERVICE] xattr warning: $e');
      }
      final p = await Process.start('open', [
        savePath,
      ], mode: ProcessStartMode.detached);
      debugPrint('[UPDATE_SERVICE] macOS open launched PID: ${p.pid}');
    }
  }

  /// Сравнение семантических версий (SemVer). Возвращает true, если remote > current
  static bool isVersionNewer(String current, String remote) {
    try {
      final currentParts = current
          .split('+')[0]
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final remoteParts = remote
          .split('+')[0]
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

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
