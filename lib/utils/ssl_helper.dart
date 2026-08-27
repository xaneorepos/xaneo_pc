import 'dart:io';

const String _configuredApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://xaneo.ru/api/v1',
  ),
);

bool isConfiguredPrivateBackendHost(String host) {
  final configuredHost = Uri.tryParse(_configuredApiBaseUrl)?.host;
  if (configuredHost == null || host != configuredHost) return false;

  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    return true;
  }

  final address = InternetAddress.tryParse(host);
  if (address == null || address.type != InternetAddressType.IPv4) {
    return false;
  }
  final octets = address.rawAddress;
  return octets[0] == 10 ||
      (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
      (octets[0] == 192 && octets[1] == 168) ||
      octets[0] == 127;
}

String findProxyForConfiguredBackend(Uri uri) {
  if (isConfiguredPrivateBackendHost(uri.host)) return 'DIRECT';
  return HttpClient.findProxyFromEnvironment(uri);
}

/// Invalid certificates are accepted only for the explicitly configured
/// private development backend. Public hosts always use the platform trust.
bool validateSslCertificate(X509Certificate cert, String host, int port) {
  return isConfiguredPrivateBackendHost(host);
}
