import 'package:flutter_test/flutter_test.dart';
import 'package:xaneo/utils/qr_request_helper.dart';

void main() {
  test('QR POST headers satisfy Django HTTPS CSRF validation', () {
    final headers = buildQrRequestHeaders(
      baseUrl: 'https://192.168.1.42/api/v1',
      csrfToken: 'csrf-token',
      userAgent: 'XaneoPC/test',
    );

    expect(headers['X-CSRFToken'], 'csrf-token');
    expect(headers['Origin'], 'https://192.168.1.42');
    expect(headers['Referer'], 'https://192.168.1.42/qr-login/');
  });

  test('QR POST headers retain a configured non-default port', () {
    final headers = buildQrRequestHeaders(
      baseUrl: 'https://192.168.1.42:8443/api/v1/',
      csrfToken: 'csrf-token',
      userAgent: 'XaneoPC/test',
    );

    expect(headers['Origin'], 'https://192.168.1.42:8443');
    expect(headers['Referer'], 'https://192.168.1.42:8443/qr-login/');
  });
}
