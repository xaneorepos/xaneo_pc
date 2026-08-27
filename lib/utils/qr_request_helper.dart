Map<String, String> buildQrRequestHeaders({
  required String baseUrl,
  required String csrfToken,
  required String userAgent,
}) {
  final apiUri = Uri.parse(baseUrl);
  final origin = '${apiUri.scheme}://${apiUri.authority}';
  return {
    'User-Agent': userAgent,
    'Content-Type': 'application/json',
    'X-CSRFToken': csrfToken,
    // Django performs strict Referer validation for unsafe HTTPS requests.
    'Origin': origin,
    'Referer': '$origin/qr-login/',
  };
}
