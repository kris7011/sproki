import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiSmokeTest {
  ApiSmokeTest._(this._dio);

  final Dio _dio;

  static ApiSmokeTest create({
    required Future<String?> Function() accessTokenProvider,
  }) {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const apiBasePath =
        String.fromEnvironment('API_BASE_PATH', defaultValue: '');

    final baseUrl = _normalizeBaseUrl(apiBaseUrl);
    final basePath = _normalizeBasePath(apiBasePath);

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,

        // Smoke test må ikke hænge. Backend cold start kan være langsom,
        // men vi tager hellere "best effort" end at blokere app start.
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),

        headers: const {'Accept': 'application/json'},

        // 404 på ukendt endpoint skal ikke kaste af sig selv (vi håndterer status manuelt)
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    // BasePath + auth først, så logger ser “det endelige”
    dio.interceptors.add(_BasePathInterceptor(basePath));
    dio.interceptors.add(_AuthInterceptor(accessTokenProvider));
    dio.interceptors.add(_SmokeLogInterceptor());

    return ApiSmokeTest._(dio);
  }

  bool shouldRun() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return apiBaseUrl.trim().isNotEmpty;
  }

  Future<void> run() async {
    if (!kDebugMode) return;

    debugPrint('==============================');
    debugPrint('🚀 API SMOKE TEST START');
    debugPrint('API_BASE_URL = ${_dio.options.baseUrl}');
    debugPrint('==============================');

    // Hard timeouts pr request (så den aldrig kan hænge pga. retries/connection issues)
    const healthTimeout = Duration(seconds: 35);
    const meTimeout = Duration(seconds: 35);

    // 1) /health (best effort) - må gerne fejle hvis backend sover
    await _bestEffort('GET /health', () async {
      final res = await _dio.get<dynamic>(
        '/health',
        options: Options(
          sendTimeout: healthTimeout,
          receiveTimeout: healthTimeout,
        ),
      );

      if ((res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300) {
        debugPrint('✔ /health OK: ${res.statusCode}');
      } else {
        debugPrint('⚠️  /health non-2xx (ignored): ${res.statusCode}');
      }
    });

    // 2) /me (must) - hvis denne fejler er auth/baseUrl/basePath typisk problemet
    final meRes = await _dio.get<dynamic>(
      '/me',
      options: Options(
        sendTimeout: meTimeout,
        receiveTimeout: meTimeout,
      ),
    );

    final code = meRes.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw DioException(
        requestOptions: meRes.requestOptions,
        response: meRes,
        type: DioExceptionType.badResponse,
        message: 'SmokeTest: /me failed: $code',
      );
    }

    debugPrint('✔ /me OK: $code');

    debugPrint('==============================');
    debugPrint('🏁 API SMOKE TEST END (OK)');
    debugPrint('==============================');
  }

  Future<void> _bestEffort(String label, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('⚠️  $label failed (ignored): $e');
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

class _BasePathInterceptor extends Interceptor {
  _BasePathInterceptor(this._basePath);

  final String _basePath;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_basePath.isEmpty) {
      handler.next(options);
      return;
    }

    var path = options.path.trim();
    if (path.isEmpty) {
      handler.next(options);
      return;
    }

    // Absolut url -> gør ingenting
    if (path.startsWith('http')) {
      handler.next(options);
      return;
    }

    if (!path.startsWith('/')) path = '/$path';

    if (path == _basePath || path.startsWith('$_basePath/')) {
      options.path = path;
      handler.next(options);
      return;
    }

    options.path = '$_basePath$path';
    handler.next(options);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._accessTokenProvider);

  final Future<String?> Function() _accessTokenProvider;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _accessTokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.remove('Authorization');
      }
    } catch (_) {
      // Hvis token provider fejler, så lad request gå uden auth.
      options.headers.remove('Authorization');
    }

    handler.next(options);
  }
}

class _SmokeLogInterceptor extends Interceptor {
  static const int _maxChars = 2000;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['ts_ms'] = DateTime.now().millisecondsSinceEpoch;

    debugPrint('--- SMOKE DIO REQUEST ---');
    debugPrint('${options.method} ${options.baseUrl}${options.path}');

    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }
    debugPrint('headers: $headers');

    if (options.data != null) {
      debugPrint('body: ${_truncate(options.data.toString())}');
    }

    debugPrint('-------------------------');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = (response.requestOptions.extra['ts_ms'] as int?) ?? 0;
    final tookMs =
        start == 0 ? -1 : DateTime.now().millisecondsSinceEpoch - start;

    debugPrint('--- SMOKE DIO RESPONSE ---');
    debugPrint(
      '${response.statusCode} (${tookMs}ms) '
      '${response.requestOptions.method} '
      '${response.requestOptions.baseUrl}${response.requestOptions.path}',
    );

    if (response.data != null) {
      debugPrint('data: ${_truncate(response.data.toString())}');
    }

    debugPrint('--------------------------');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    final start = (req.extra['ts_ms'] as int?) ?? 0;
    final tookMs =
        start == 0 ? -1 : DateTime.now().millisecondsSinceEpoch - start;

    debugPrint('--- SMOKE DIO ERROR ---');
    debugPrint(
      '${err.response?.statusCode ?? '(no status)'} (${tookMs}ms) '
      '${req.method} ${req.baseUrl}${req.path}',
    );

    final headers = Map<String, dynamic>.from(req.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }
    debugPrint('requestHeaders: $headers');

    debugPrint('type: ${err.type}');
    debugPrint('message: ${err.message}');

    final res = err.response;
    if (res != null && res.data != null) {
      debugPrint('responseData: ${_truncate(res.data.toString())}');
    }

    debugPrint('-----------------------');
    handler.next(err);
  }

  String _truncate(String s) {
    if (s.length <= _maxChars) return s;
    return '${s.substring(0, _maxChars)}... (truncated ${s.length - _maxChars} chars)';
  }
}
