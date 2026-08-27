import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaneo/utils/ssl_helper.dart';

void main() {
  test(
    'configured private API bypasses stale system proxy only for its host',
    () {
      expect(isConfiguredPrivateBackendHost('192.168.1.42'), isTrue);
      expect(
        findProxyForConfiguredBackend(Uri.parse('https://192.168.1.42/')),
        'DIRECT',
      );
      expect(isConfiguredPrivateBackendHost('192.168.1.43'), isFalse);
      expect(isConfiguredPrivateBackendHost('xaneo.ru'), isFalse);
    },
  );

  test('public API keeps environment proxy behavior', () {
    final uri = Uri.parse('https://xaneo.ru/api/v1/');
    expect(
      findProxyForConfiguredBackend(uri),
      HttpClient.findProxyFromEnvironment(uri),
    );
  });
}
