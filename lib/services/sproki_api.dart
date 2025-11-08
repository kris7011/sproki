// lib/services/sproki_api.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Læs base URL fra --dart-define, ellers fallback til prod.
const _baseFromEnv = String.fromEnvironment(
  'SPROKI_API_BASE',
  defaultValue: 'https://sproki-backend.onrender.com',
);

class SprokiApi {
  SprokiApi({String? baseUrl}) : baseUrl = baseUrl ?? _baseFromEnv;
  final String baseUrl;

  static const _defaultTimeout = Duration(seconds: 12);

  Future<Map<String, dynamic>> getPlanMap(String childId) async {
    final uri = Uri.parse('$baseUrl/children/$childId/plan');
    final res = await http.get(uri).timeout(_defaultTimeout);
    if (res.statusCode != 200) {
      throw Exception('Fejl fra backend (${res.statusCode}): ${res.body}');
    }
    return (json.decode(res.body) as Map).cast<String, dynamic>();
  }

  Future<void> upsertChild(String childId, {String? name}) async {
    final uri =
        Uri.parse('$baseUrl/children/$childId').replace(queryParameters: {
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
    final res = await http.post(uri).timeout(_defaultTimeout);
    if (res.statusCode != 200) {
      throw Exception('Kunne ikke upserte barn: ${res.statusCode} ${res.body}');
    }
  }

  Future<Map<String, dynamic>> uploadReportPdfBytes({
    required String childId,
    required String filename,
    required Uint8List bytes,
    void Function(double progress)? onProgress, // ikke brugt her
  }) async {
    final uri = Uri.parse('$baseUrl/children/$childId/reports/upload');
    final req = http.MultipartRequest('POST', uri)
      ..files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await req.send().timeout(_defaultTimeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('Upload fejlede: ${res.statusCode} ${res.body}');
    }
    return (json.decode(res.body) as Map).cast<String, dynamic>();
  }

  /// Batch post af practice-events. Hver event er et `Map<String, dynamic>`.
  Future<void> addPracticeEvents(
      String childId, List<Map<String, dynamic>> events) async {
    final uri = Uri.parse('$baseUrl/children/$childId/practice-events');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'events': events}),
        )
        .timeout(_defaultTimeout);
    if (res.statusCode != 200) {
      throw Exception('Practice-events fejlede: ${res.statusCode} ${res.body}');
    }
  }
}
