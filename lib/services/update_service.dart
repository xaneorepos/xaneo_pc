import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
    final tempDir = await getTemporaryDirectory();
    final uri = Uri.parse(url);
    final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'xaneo_update';
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
          onProgress(progress, '$label: $mbReceived MB / $mbTotal MB (${(progress * 100).toInt()}%)');
        } else {
          final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
          onProgress(0.5, '$label: $mbReceived MB...');
        }
      },
    );

    final file = File(savePath);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    debugPrint('[UPDATE_SERVICE] Download finished. Saved to: $savePath (Size: $fileSize bytes)');

    onProgress(1.0, launchingInstallerLabel ?? 'Запуск установки...');

    if (Platform.isLinux) {
      final lowerPath = savePath.toLowerCase();
      final chmodRes = await Process.run('chmod', ['+x', savePath]);
      debugPrint('[UPDATE_SERVICE] chmod +x exitCode: ${chmodRes.exitCode}, stderr: ${chmodRes.stderr}');

      if (lowerPath.contains('.deb')) {
        debugPrint('[UPDATE_SERVICE] Launching DEB package with xdg-open...');
        try {
          final p = await Process.start('xdg-open', [savePath], mode: ProcessStartMode.detached);
          debugPrint('[UPDATE_SERVICE] xdg-open launched, PID: ${p.pid}');
        } catch (e) {
          debugPrint('[UPDATE_SERVICE] xdg-open failed: $e, trying gdebi...');
          final p = await Process.start('gdebi', [savePath], mode: ProcessStartMode.detached);
          debugPrint('[UPDATE_SERVICE] gdebi launched, PID: ${p.pid}');
        }
      } else if (lowerPath.contains('.appimage')) {
        bool hasFuse = false;
        String ldconfigCmd = 'ldconfig';
        for (final p in ['/sbin/ldconfig', '/usr/sbin/ldconfig', 'ldconfig']) {
          if (File(p).existsSync()) {
            ldconfigCmd = p;
            break;
          }
        }

        try {
          final res = await Process.run(ldconfigCmd, ['-p']);
          if (res.stdout.toString().contains('libfuse.so.2')) {
            hasFuse = true;
          }
        } catch (e) {
          debugPrint('[UPDATE_SERVICE] Error checking ldconfig libfuse: $e');
        }

        if (!hasFuse) {
          if (File('/lib/x86_64-linux-gnu/libfuse.so.2').existsSync() ||
              File('/usr/lib/x86_64-linux-gnu/libfuse.so.2').existsSync() ||
              File('/lib64/libfuse.so.2').existsSync() ||
              File('/usr/lib64/libfuse.so.2').existsSync()) {
            hasFuse = true;
          }
        }

        final args = hasFuse ? <String>[] : <String>['--appimage-extract-and-run'];
        final runWorkDir = '${tempDir.path}/appimage_run_${DateTime.now().millisecondsSinceEpoch}';
        try {
          await Directory(runWorkDir).create(recursive: true);
        } catch (_) {}

        final cleanEnv = Map<String, String>.from(Platform.environment)
          ..['GDK_PIXBUF_MODULE_FILE'] = '/dev/null'
          ..['GIO_MODULE_DIR'] = '/dev/null';

        try {
          final p = await Process.start(
            savePath,
            args,
            workingDirectory: runWorkDir,
            environment: cleanEnv,
            mode: ProcessStartMode.detached,
          );
          debugPrint('[UPDATE_SERVICE] AppImage process started, PID: ${p.pid}');
        } catch (e) {
          debugPrint('[UPDATE_SERVICE] Primary AppImage start failed: $e. Retrying with --appimage-extract-and-run...');
          try {
            final p = await Process.start(
              savePath,
              ['--appimage-extract-and-run'],
              workingDirectory: runWorkDir,
              environment: cleanEnv,
              mode: ProcessStartMode.detached,
            );
            debugPrint('[UPDATE_SERVICE] Fallback AppImage extract-and-run started, PID: ${p.pid}');
          } catch (e2) {
            debugPrint('[UPDATE_SERVICE] Fallback failed: $e2. Opening via xdg-open...');
            await Process.start('xdg-open', [savePath], mode: ProcessStartMode.detached);
          }
        }
      } else {
        debugPrint('[UPDATE_SERVICE] Launching unknown binary: $savePath...');
        try {
          final p = await Process.start(savePath, [], mode: ProcessStartMode.detached);
          debugPrint('[UPDATE_SERVICE] Binary launched PID: ${p.pid}');
        } catch (e) {
          debugPrint('[UPDATE_SERVICE] Binary launch failed: $e. Fallback to xdg-open...');
          await Process.start('xdg-open', [savePath], mode: ProcessStartMode.detached);
        }
      }
    } else if (Platform.isWindows) {
      debugPrint('[UPDATE_SERVICE] Launching Windows installer: $savePath...');
      final p = await Process.start(savePath, ['/S'], mode: ProcessStartMode.detached);
      debugPrint('[UPDATE_SERVICE] Windows installer launched PID: ${p.pid}');
    } else if (Platform.isMacOS) {
      debugPrint('[UPDATE_SERVICE] Preparing macOS installer: $savePath...');
      try {
        await Process.run('xattr', ['-d', 'com.apple.quarantine', savePath]);
        await Process.run('xattr', ['-cr', savePath]);
      } catch (e) {
        debugPrint('[UPDATE_SERVICE] xattr warning: $e');
      }
      final p = await Process.start('open', [savePath], mode: ProcessStartMode.detached);
      debugPrint('[UPDATE_SERVICE] macOS open launched PID: ${p.pid}');
    }
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
