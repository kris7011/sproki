// Minimal, dependency-light API client for the Sproki backend.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _http;
  Duration timeout;

  String? _bearer; // Set only if backend requires Supabase auth

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    Duration? timeout,
  })  : baseUrl = (baseUrl ?? ApiConfig.resolveBaseUrl())
            .replaceAll(RegExp(r'/$'), ''),
        _http = httpClient ?? http.Client(),
        timeout = timeout ?? ApiConfig.defaultTimeout;

  // Call this when/if you enable auth (REQUIRE_SUPABASE=1).
  void setAuthToken(String? token) {
    final t = token?.trim();
    _bearer = (t == null || t.isEmpty) ? null : t;
  }

  Map<String, String> _jsonHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_bearer != null) headers['Authorization'] = 'Bearer $_bearer';
    return headers;
  }

  T _decode<T>(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) {
        // ignore: unnecessary_cast
        return ({} as T);
      }
      final decoded = json.decode(res.body);
      return decoded as T;
    }
    throw ApiException(
      statusCode: res.statusCode,
      body: res.body,
      uri: res.request?.url.toString(),
    );
  }

  // ---- Public endpoints ----

  Future<bool> health() async {
    final uri = Uri.parse('$baseUrl/health');
    final res = await _http.get(uri).timeout(timeout);
    final map = _decode<Map<String, dynamic>>(res);
    return map['ok'] == true;
  }

  Future<Map<String, dynamic>> pprPing() async {
    final uri = Uri.parse('$baseUrl/ppr/ping');
    final res = await _http.get(uri, headers: _jsonHeaders()).timeout(timeout);
    return _decode<Map<String, dynamic>>(res);
  }

  /// POST /reports/{child_id}
  /// items: e.g. [{'category':'rim','score':55}, {'category':'udtale','score':43}]
  Future<Map<String, dynamic>> postReport({
    required String childId,
    required int ageYears,
    required int ageMonths,
    required List<Map<String, dynamic>> items,
  }) async {
    final uri = Uri.parse('$baseUrl/reports/$childId');
    final body = json.encode({
      'age_years': ageYears,
      'age_months': ageMonths,
      'items': items,
    });
    final res = await _http
        .post(uri, headers: _jsonHeaders(), body: body)
        .timeout(timeout);
    return _decode<Map<String, dynamic>>(res);
  }

  /// GET /reports/{child_id}/latest
  Future<Map<String, dynamic>> getLatestSummary(String childId) async {
    final uri = Uri.parse('$baseUrl/reports/$childId/latest');
    final res = await _http.get(uri, headers: _jsonHeaders()).timeout(timeout);
    return _decode<Map<String, dynamic>>(res);
  }

  void close() => _http.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  final String? uri;

  ApiException({required this.statusCode, required this.body, this.uri});

  @override
  String toString() => 'ApiException($statusCode) ${uri ?? ''} $body';
}

// Global instance for convenience
final ApiClient api = ApiClient();
