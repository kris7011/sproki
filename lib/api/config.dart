// lib/api/config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// Evt. override via --dart-define=API_BASE_URL=...
const _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

class ApiConfig {
  static String resolveBaseUrl() {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;

    if (kIsWeb) {
      // Brug samme host som siden (127.0.0.1 eller localhost), men port 8080 til API
      final host = Uri.base.host; // fx "127.0.0.1" eller "localhost"
      final scheme = Uri.base.scheme; // "http" i dev
      final proto = scheme.isEmpty ? 'http' : scheme;
      return '$proto://$host:8080';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }

    // iOS simulator, macOS, Windows, Linux
    return 'http://127.0.0.1:8080';
  }

  static const Duration defaultTimeout = Duration(seconds: 15);
}
