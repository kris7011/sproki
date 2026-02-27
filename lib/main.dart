import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sproki_app.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('${details.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('UNHANDLED (platform): $error');
      debugPrint('$stack');
      return true;
    };

    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const apiBasePath = String.fromEnvironment('API_BASE_PATH');

    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (apiBaseUrl.isEmpty) {
      throw Exception('Missing --dart-define=API_BASE_URL=...');
    }
    if (supabaseUrl.isEmpty) {
      throw Exception('Missing --dart-define=SUPABASE_URL=...');
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('Missing --dart-define=SUPABASE_ANON_KEY=...');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    runApp(
      SprokiApp(
        apiBaseUrl: apiBaseUrl,
        apiBasePath: apiBasePath,
      ),
    );
  }, (error, stack) {
    debugPrint('UNHANDLED (zone): $error');
    debugPrint('$stack');
  });
}