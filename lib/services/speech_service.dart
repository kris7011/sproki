import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize();
    }
    return _isInitialized;
  }

  static Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'da_DK',
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords.toLowerCase());
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        onDevice: false,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static bool get isListening => _speech.isListening;
  static bool get isAvailable => _isInitialized;
}
