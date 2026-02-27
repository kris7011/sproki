import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiBasePathResolver {
  static Future<String> resolve({
    required String baseUrl,
    required List<String> candidates, // fx ["", "/api"]
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(baseUrl),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (code) =>
            code != null && code < 500, // vi vil se 404 vs 401/200
      ),
    );

    for (final raw in candidates) {
      final p = _normalizeBasePath(raw);

      // 1) Prøv openapi (typisk findes den altid i FastAPI)
      final ok1 = await _exists(dio, '$p/openapi.json');
      if (ok1) {
        debugPrint('ApiBasePathResolver: using basePath="$p" (openapi ok)');
        return p;
      }

      // 2) Prøv docs som fallback
      final ok2 = await _exists(dio, '$p/docs');
      if (ok2) {
        debugPrint('ApiBasePathResolver: using basePath="$p" (docs ok)');
        return p;
      }
    }

    // Hvis intet matcher, returner første – men log tydeligt
    final fallback =
        _normalizeBasePath(candidates.isNotEmpty ? candidates.first : '');
    debugPrint(
        'ApiBasePathResolver: could not detect basePath, fallback="$fallback"');
    return fallback;
  }

  static Future<bool> _exists(Dio dio, String path) async {
    try {
      final res = await dio.get(path);

      // 200/204/3xx => findes
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 400) {
        return true;
      }

      // 401/403 => findes (men kræver auth)
      if (res.statusCode == 401 || res.statusCode == 403) {
        return true;
      }

      // 404 => findes ikke
      return false;
    } catch (_) {
      return false;
    }
  }

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static String _normalizeBasePath(String path) {
    var p = path.trim();
    if (p.isEmpty) return '';
    if (!p.startsWith('/')) p = '/$p';
    while (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }
}
