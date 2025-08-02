import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      await _flutterTts.setLanguage("da-DK"); // Dansk
      await _flutterTts.setSpeechRate(0.5); // Langsom for børn
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.2); // Lidt højere tone for børn
      _isInitialized = true;
    }
  }

  static Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}
