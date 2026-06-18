import 'dart:io';
import 'dart:math' as math;

class Logger {
  static File? _logFile;

  /// Initialize file logging
  static Future<void> init() async {
    try {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final dir = Directory('$home/.xaneo_pc');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _logFile = File('${dir.path}/app.log');
      } else {
        _logFile = File('${Directory.systemTemp.path}/xaneo_pc_app.log');
      }

      // Handle log rotation / size limiting (max 2MB)
      if (await _logFile!.exists()) {
        final stat = await _logFile!.stat();
        if (stat.size > 2 * 1024 * 1024) {
          await _logFile!.writeAsString('--- Log cleared due to size limit ---\n');
        } else {
          await _logFile!.writeAsString('\n--- App Session Started: ${DateTime.now().toIso8601String()} ---\n', mode: FileMode.append);
        }
      } else {
        await _logFile!.writeAsString('--- App Session Started: ${DateTime.now().toIso8601String()} ---\n');
      }
    } catch (e) {
      print('Failed to initialize file logger: $e');
    }
  }

  static void info(String tag, String message) {
    _log('INFO', tag, message);
  }

  static void warning(String tag, String message, [dynamic error]) {
    _log('WARN', tag, '$message${error != null ? " | Error: $error" : ""}');
  }

  static void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', tag, '$message${error != null ? " | Error: $error" : ""}${stackTrace != null ? "\n$stackTrace" : ""}');
  }

  static void _log(String level, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [$level] [$tag] $message';
    print(logLine);
    try {
      _logFile?.writeAsStringSync('$logLine\n', mode: FileMode.append);
    } catch (_) {
      // Ignore write failures to prevent crash in read-only filesystems
    }
  }
}
