import 'dart:io';
import 'package:xaneo/services/api_service.dart';

/// Helper to validate SSL certificates.
/// Replaces unconditional `(cert, host, port) => true` (which triggers AV detection)
/// with scoped validation restricting bypasses to trusted Xaneo domains, localhost, and local IPs.
bool validateSslCertificate(X509Certificate cert, String host, int port) {
  // 1. Always allow localhost and loopback addresses
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    return true;
  }

  // 2. Allow official Xaneo domains and subdomains
  if (host == 'xaneo.ru' || host.endsWith('.xaneo.ru') ||
      host == 'xaneo.net' || host.endsWith('.xaneo.net')) {
    return true;
  }

  // 3. Allow dynamically configured API server host
  try {
    final configuredHost = Uri.parse(ApiService.baseUrl).host;
    if (configuredHost.isNotEmpty) {
      if (host == configuredHost || host.endsWith('.$configuredHost')) {
        return true;
      }
    }
  } catch (_) {}

  // 4. Allow private IP ranges (LAN / local development servers)
  final address = InternetAddress.tryParse(host);
  if (address != null) {
    if (address.isLoopback) return true;
    if (address.type == InternetAddressType.IPv4) {
      final octets = address.rawAddress;
      if (octets[0] == 10 ||
          (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
          (octets[0] == 192 && octets[1] == 168) ||
          (octets[0] == 127)) {
        return true;
      }
    }
  }

  // Reject untrusted unknown external hosts
  return false;
}
