import 'dart:io';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import 'ssl_helper.dart';

class LocalProxy {
  static HttpServer? _server;
  static int _requestSequence = 0;

  static String _urlForLog(String value) {
    try {
      final uri = Uri.parse(value);
      final port = uri.hasPort ? ':${uri.port}' : '';
      final origin = uri.host.isEmpty ? '' : '${uri.scheme}://${uri.host}$port';
      return '$origin${uri.path}';
    } catch (_) {
      return '<invalid-url>';
    }
  }

  static Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen((HttpRequest request) async {
        final targetUrl = request.uri.queryParameters['url'];
        final requestId = ++_requestSequence;

        if (targetUrl == null) {
          Logger.warning(
            'MediaProxy',
            'request=$requestId rejected: missing target URL',
          );
          request.response.statusCode = 400;
          await request.response.close();
          return;
        }

        HttpClient? client;
        try {
          final range = request.headers.value(HttpHeaders.rangeHeader);
          Logger.info(
            'MediaProxy',
            'request=$requestId start method=${request.method} '
                'target=${_urlForLog(targetUrl)} range=${range ?? '<none>'}',
          );

          client = HttpClient();
          // Filtered SSL certificate validation
          client.badCertificateCallback = validateSslCertificate;

          Uri targetUri = Uri.parse(targetUrl);

          // Get fresh token from ApiService and inject it into the request URL
          final freshToken = await ApiService().getAccessToken();
          if (freshToken != null && freshToken.isNotEmpty) {
            final newParams = Map<String, String>.from(
              targetUri.queryParameters,
            );
            newParams['token'] = freshToken;
            targetUri = targetUri.replace(queryParameters: newParams);
          }

          final clientRequest = await client.getUrl(targetUri);

          // Propagate headers (especially Range for video)
          request.headers.forEach((name, values) {
            if (name.toLowerCase() == 'host') return;
            clientRequest.headers.set(name, values.join(','));
          });

          if (freshToken != null && freshToken.isNotEmpty) {
            clientRequest.headers.set('Authorization', 'Bearer $freshToken');
          }

          final clientResponse = await clientRequest.close();

          Logger.info(
            'MediaProxy',
            'request=$requestId upstream status=${clientResponse.statusCode} '
                'contentType=${clientResponse.headers.contentType ?? '<none>'} '
                'contentLength=${clientResponse.contentLength} '
                'contentRange=${clientResponse.headers.value(HttpHeaders.contentRangeHeader) ?? '<none>'}',
          );

          request.response.statusCode = clientResponse.statusCode;
          clientResponse.headers.forEach((name, values) {
            request.response.headers.set(name, values.join(','));
          });

          await clientResponse.pipe(request.response);
          Logger.info('MediaProxy', 'request=$requestId completed');
        } catch (e, stackTrace) {
          Logger.error(
            'MediaProxy',
            'request=$requestId failed target=${_urlForLog(targetUrl)}',
            e,
            stackTrace,
          );
          try {
            request.response.statusCode = 500;
            await request.response.close();
          } catch (_) {}
        } finally {
          client?.close(force: true);
        }
      });
      Logger.info(
        'MediaProxy',
        'started on http://${_server!.address.address}:${_server!.port}',
      );
    } catch (e, stackTrace) {
      Logger.error('MediaProxy', 'failed to start', e, stackTrace);
    }
  }

  static String getProxyUrl(String targetUrl, {String? jwtToken, String? ext}) {
    if (_server == null) {
      Logger.warning(
        'MediaProxy',
        'proxy unavailable; using target directly: ${_urlForLog(targetUrl)}',
      );
      return targetUrl;
    }

    String path = '/media';
    if (ext != null) {
      path = '/media$ext';
    } else {
      final lower = targetUrl.toLowerCase();
      if (lower.contains('.m4a')) {
        path = '/audio.m4a';
      } else if (lower.contains('.mp3')) {
        path = '/audio.mp3';
      } else if (lower.contains('.mp4')) {
        path = '/video.mp4';
      } else if (lower.contains('.m3u8')) {
        path = '/video.m3u8';
      }
    }

    final uri = Uri(
      scheme: 'http',
      host: _server!.address.address,
      port: _server!.port,
      path: path,
      queryParameters: {
        'url': targetUrl,
        if (jwtToken != null) 'token': jwtToken,
      },
    );
    return uri.toString();
  }
}
