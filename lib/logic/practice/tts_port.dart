// lib/logic/practice/tts_port.dart
abstract class TtsPort {
  Future<void> speak(String text, {double? rate});
  Future<void> dispose();
}
