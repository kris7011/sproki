// lib/logic/practice/tts_speaker.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sproki/logic/practice/tts_port.dart';

class TtsSpeaker implements TtsPort {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  static const double normalRate = 0.6;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.setLanguage("da-DK");
    await _tts.setSpeechRate(normalRate);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _ready = true;
  }

  @override
  Future<void> speak(String text, {double? rate}) async {
    await _init();
    if (rate != null) await _tts.setSpeechRate(rate);
    await _tts.stop();
    await _tts.speak(text);
    if (rate != null) await _tts.setSpeechRate(normalRate);
  }

  @override
  Future<void> dispose() => _tts.stop();
}
