// lib/services/sproki_api.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Meget enkel API-klient til Sproki backend.
/// Husk at give `baseUrl` når du laver instansen.
class SprokiApi {
  SprokiApi({required this.baseUrl});
  final String baseUrl;

  /// Hent plan som Map (bruges af MainMenu).
  Future<Map<String, dynamic>> getPlanMap(String childId) async {
    final uri = Uri.parse('$baseUrl/children/$childId/plan');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Fejl fra backend (${res.statusCode}): ${res.body}');
    }
    return (json.decode(res.body) as Map).cast<String, dynamic>();
  }

  /// Upsert barn (id som path-param; valgfrit name som query-param)
  Future<void> upsertChild(String childId, {String? name}) async {
    final uri =
        Uri.parse('$baseUrl/children/$childId').replace(queryParameters: {
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
    final res = await http.post(uri);
    if (res.statusCode != 200) {
      throw Exception('Kunne ikke upserte barn: ${res.statusCode} ${res.body}');
    }
  }

  /// Upload PDF-rapport (multipart). Returnerer hele responsen som Map.
  Future<Map<String, dynamic>> uploadReportPdfBytes({
    required String childId,
    required String filename,
    required Uint8List bytes,
    void Function(double progress)? onProgress, // (0..1) – ikke brugt her
  }) async {
    final uri = Uri.parse('$baseUrl/children/$childId/reports/upload');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename, contentType: null));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('Upload fejlede: ${res.statusCode} ${res.body}');
    }
    return (json.decode(res.body) as Map).cast<String, dynamic>();
  }

  /// Batch post af practice-events (valgfritt brugt)
  Future<void> addPracticeEvents(
      String childId, List<Map<String, dynamic>> events) async {
    final uri = Uri.parse('$baseUrl/children/$childId/practice-events');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'events': events}),
    );
    if (res.statusCode != 200) {
      throw Exception('Practice-events fejlede: ${res.statusCode} ${res.body}');
    }
  }
}
