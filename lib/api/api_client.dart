import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    String? basePath, // fx "/api" eller "" (tom)
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 180),
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: normalizeBaseUrl(baseUrl),

            // Render cold start kan godt tage > 20 sek første gang
            connectTimeout: connectTimeout,

            // Bump gerne lidt ved cold starts (du kan sætte den tilbage senere)
            receiveTimeout: receiveTimeout,

            headers: const {
              'Accept': 'application/json',
            },
          ),
        ) {
    final normalizedBasePath = normalizeBasePath(basePath);

    // Debug: se præcis hvad clienten kører med
    debugPrint('ApiClient baseUrl="${_dio.options.baseUrl}"');
    debugPrint('ApiClient basePath="$normalizedBasePath"');

    // Sørger for at alle requests får prefix (hvis angivet)
    _dio.interceptors.add(_BasePathInterceptor(normalizedBasePath));

    // Auth først (så debug logger de endelige headers)
    _dio.interceptors.add(_SupabaseAuthInterceptor(_dio));

    // Logging (request/response/error + timings)
    _dio.interceptors.add(_DioDebugInterceptor());

    // Retry på timeouts / midlertidige net-fejl (kun safe methods som default)
    _dio.interceptors.add(_RetryInterceptor(_dio));

    // Fail-fast hint ved “forkert base path” (kun logging)
    _dio.interceptors.add(_WrongBasePathHintInterceptor(normalizedBasePath));
  }

  final Dio _dio;

  Dio get dio => _dio;

  // Brug den her hvis du vil “hot swap” base path efter startup (simpelt)
  ApiClient copyWithBasePath(String? basePath) {
    return ApiClient(
      baseUrl: _dio.options.baseUrl,
      basePath: basePath,
      connectTimeout:
          _dio.options.connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout:
          _dio.options.receiveTimeout ?? const Duration(seconds: 180),
    );
  }

  // Gør dem offentlige så du kan genbruge dem (fx i main/basepath resolver)
  static String normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static String normalizeBasePath(String? path) {
    var p = (path ?? '').trim();
    if (p.isEmpty) return '';
    if (!p.startsWith('/')) p = '/$p';
    while (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p; // fx "/api"
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

    // Sørg for leading slash
    if (!path.startsWith('/')) path = '/$path';

    // Hvis path allerede starter med basePath, så gør ingenting
    if (path == _basePath || path.startsWith('$_basePath/')) {
      options.path = path; // hold den normalized
      handler.next(options);
      return;
    }

    final before = options.path;
    options.path = '$_basePath$path';

    if (kDebugMode) {
      debugPrint('ApiClient basePath rewrite: "$before" -> "${options.path}"');
    }

    handler.next(options);
  }
}

class _SupabaseAuthInterceptor extends Interceptor {
  _SupabaseAuthInterceptor(this._dio);

  final Dio _dio;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      options.headers.remove('Authorization');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    // Kun refresh ved 401
    if (status != 401) {
      handler.next(err);
      return;
    }

    final req = err.requestOptions;
    final alreadyRetried = (req.extra['retried_401'] as bool?) ?? false;

    if (alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      await _refreshSessionOnce();

      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) {
        handler.next(err);
        return;
      }

      final newReq = _cloneRequestOptions(req);
      newReq.extra['retried_401'] = true;
      newReq.headers['Authorization'] = 'Bearer $token';

      final res = await _dio.fetch<dynamic>(newReq);
      handler.resolve(res);
    } catch (e) {
      handler.next(e is DioException ? e : err);
    }
  }

  Future<void> _refreshSessionOnce() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value();
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      await Supabase.instance.client.auth.refreshSession();
      _refreshCompleter?.complete();
    } catch (e) {
      _refreshCompleter?.completeError(e);
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  RequestOptions _cloneRequestOptions(RequestOptions o) {
    return RequestOptions(
      path: o.path,
      method: o.method,
      baseUrl: o.baseUrl,
      queryParameters: Map<String, dynamic>.from(o.queryParameters),
      data: o.data,
      headers: Map<String, dynamic>.from(o.headers),
      extra: Map<String, dynamic>.from(o.extra),
      contentType: o.contentType,
      responseType: o.responseType,
      followRedirects: o.followRedirects,
      validateStatus: o.validateStatus,
      receiveDataWhenStatusError: o.receiveDataWhenStatusError,
      sendTimeout: o.sendTimeout,
      receiveTimeout: o.receiveTimeout,
      connectTimeout: o.connectTimeout,
      listFormat: o.listFormat,
    );
  }
}

class _DioDebugInterceptor extends Interceptor {
  static const int _maxChars = 2000;

  bool _shouldSuppress404Log(RequestOptions options, DioException err) {
    final suppress = (options.extra['suppress_404_log'] as bool?) ?? false;
    final status = err.response?.statusCode;
    return suppress && status == 404;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['ts_ms'] = DateTime.now().millisecondsSinceEpoch;

    debugPrint('--- DIO REQUEST ---');
    debugPrint('${options.method} ${options.baseUrl}${options.path}');

    if (options.queryParameters.isNotEmpty) {
      debugPrint('query: ${options.queryParameters}');
    }

    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }
    debugPrint('headers: $headers');

    if (options.data != null) {
      debugPrint('body: ${_truncate(options.data.toString())}');
    }

    debugPrint('-------------------');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = (response.requestOptions.extra['ts_ms'] as int?) ?? 0;
    final tookMs =
        start == 0 ? -1 : DateTime.now().millisecondsSinceEpoch - start;

    debugPrint('--- DIO RESPONSE ---');
    debugPrint(
      '${response.statusCode} (${tookMs}ms) '
      '${response.requestOptions.method} '
      '${response.requestOptions.baseUrl}${response.requestOptions.path}',
    );

    if (response.data != null) {
      debugPrint('data: ${_truncate(response.data.toString())}');
    }

    debugPrint('--------------------');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;

    // ✅ Undgå spam ved 404-probing (pending invite endpoints etc.)
    if (_shouldSuppress404Log(req, err)) {
      handler.next(err);
      return;
    }

    final start = (req.extra['ts_ms'] as int?) ?? 0;
    final tookMs =
        start == 0 ? -1 : DateTime.now().millisecondsSinceEpoch - start;

    debugPrint('--- DIO ERROR ---');
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
    if (res != null) {
      debugPrint('responseHeaders: ${res.headers.map}');
      if (res.data != null) {
        debugPrint('responseData: ${_truncate(res.data.toString())}');
      }
    }

    debugPrint('---------------');
    handler.next(err);
  }

  String _truncate(String s) {
    if (s.length <= _maxChars) return s;
    return '${s.substring(0, _maxChars)}... (truncated ${s.length - _maxChars} chars)';
  }
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  bool _isSafeMethod(RequestOptions req) {
    final m = req.method.toUpperCase();
    return m == 'GET' || m == 'HEAD' || m == 'OPTIONS';
  }

  bool _shouldRetry(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    final status = e.response?.statusCode;
    if (status == 502 || status == 503 || status == 504) return true;

    return false;
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;

    // Default: retry kun safe methods.
    // Hvis du vil retry'e en POST, skal du sætte Options(extra: {'idempotent': true})
    final allowRetry =
        _isSafeMethod(req) || ((req.extra['idempotent'] as bool?) ?? false);

    if (!allowRetry) {
      handler.next(err);
      return;
    }

    final retries = (req.extra['retries'] as int?) ?? 0;

    if (!_shouldRetry(err) || retries >= 2) {
      handler.next(err);
      return;
    }

    final delayMs = retries == 0 ? 600 : 1200;
    debugPrint(
      'DIO RETRY: ${req.method} ${req.baseUrl}${req.path} in ${delayMs}ms (attempt ${retries + 1}/2)',
    );

    await Future.delayed(Duration(milliseconds: delayMs));

    try {
      final newReq = _cloneRequestOptions(req);
      newReq.extra['retries'] = retries + 1;

      final res = await _dio.fetch<dynamic>(newReq);
      handler.resolve(res);
    } catch (e) {
      handler.next(e is DioException ? e : err);
    }
  }

  RequestOptions _cloneRequestOptions(RequestOptions o) {
    return RequestOptions(
      path: o.path,
      method: o.method,
      baseUrl: o.baseUrl,
      queryParameters: Map<String, dynamic>.from(o.queryParameters),
      data: o.data,
      headers: Map<String, dynamic>.from(o.headers),
      extra: Map<String, dynamic>.from(o.extra),
      contentType: o.contentType,
      responseType: o.responseType,
      followRedirects: o.followRedirects,
      validateStatus: o.validateStatus,
      receiveDataWhenStatusError: o.receiveDataWhenStatusError,
      sendTimeout: o.sendTimeout,
      receiveTimeout: o.receiveTimeout,
      connectTimeout: o.connectTimeout,
      listFormat: o.listFormat,
    );
  }
}

class _WrongBasePathHintInterceptor extends Interceptor {
  _WrongBasePathHintInterceptor(this._basePath);

  final String _basePath;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final req = err.requestOptions;

    if (_basePath.isNotEmpty && status == 404) {
      final p = req.path;
      if (!p.startsWith(_basePath) && !p.startsWith('$_basePath/')) {
        debugPrint(
          '⚠️ ApiClient hint: 404 on "${req.baseUrl}$p" but API_BASE_PATH="$_basePath". '
          'This looks like missing basePath prefix (expected "$_basePath/...").',
        );
      }
    }

    handler.next(err);
  }
}
