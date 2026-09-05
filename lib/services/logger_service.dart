import 'dart:io';

class Logger {
  static File? _logFile;

  /// Initialize file logging
  static Future<void> init() async {
    try {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final dir = Directory('$home/.xaneo');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _logFile = File('${dir.path}/app.log');
      } else {
        _logFile = File('${Directory.systemTemp.path}/xaneo_app.log');
      }

      // Handle log rotation / size limiting (max 2MB)
      if (await _logFile!.exists()) {
        final stat = await _logFile!.stat();
        if (stat.size > 2 * 1024 * 1024) {
          await _logFile!.writeAsString(
            '--- Log cleared due to size limit ---\n',
          );
        } else {
          final existingLog = await _logFile!.readAsString();
          final sanitizedLog = _sanitize(existingLog);
          if (sanitizedLog != existingLog) {
            await _logFile!.writeAsString(sanitizedLog);
          }
          await _logFile!.writeAsString(
            '\n--- App Session Started: ${DateTime.now().toIso8601String()} ---\n',
            mode: FileMode.append,
          );
        }
      } else {
        await _logFile!.writeAsString(
          '--- App Session Started: ${DateTime.now().toIso8601String()} ---\n',
        );
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

  static void error(
    String tag,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(
      'ERROR',
      tag,
      '$message${error != null ? " | Error: $error" : ""}${stackTrace != null ? "\n$stackTrace" : ""}',
    );
  }

  static void _log(String level, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [$level] [$tag] ${_sanitize(message)}';
    print(logLine);
    try {
      _logFile?.writeAsStringSync('$logLine\n', mode: FileMode.append);
    } catch (_) {
      // Ignore write failures to prevent crash in read-only filesystems
    }
  }

  /// Removes credentials and user-specific identifiers before a message is
  /// printed or persisted. Logging must never become another secrets store.
  static String _sanitize(String message) {
    var sanitized = message;

    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[^\s,|]+', caseSensitive: false),
      'Bearer <redacted>',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(https?://[^\s?]+)\?[^\s|]+', caseSensitive: false),
      (match) => '${match.group(1)}?<redacted-query>',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'([?&](?:access_token|refresh_token|token|secret|signature|key|auth|poll_secret|code)=)[^&\s|]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}<redacted>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\b'),
      '<redacted-jwt>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
        caseSensitive: false,
      ),
      '<redacted-id>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Fa-f0-9]{32,}\b'),
      '<redacted-hex>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        caseSensitive: false,
      ),
      '<redacted-email>',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'\b(user|username|chat|chatId|messageId|fileId|publicFp|candidateFp|myPublicFp|peerPublicFp|defaultKeyFp)\s*[:=]\s*([^\s,|]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=<redacted>',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'''\b["']?(password|token|secret|accessToken|refreshToken|pollSecret|privateKey|server_epoch_key)["']?\s*[:=]\s*([^\s,|}]+)''',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=<redacted>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\bserver_epoch_key\s+directly:\s*[^\s,|]+',
        caseSensitive: false,
      ),
      'server_epoch_key=<redacted>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'/home/[^/\s]+'),
      '/home/<redacted>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'[A-Z]:\\Users\\[^\\\s]+', caseSensitive: false),
      r'C:\Users\<redacted>',
    );

    return sanitized;
  }
}
