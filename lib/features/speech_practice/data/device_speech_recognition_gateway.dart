import '../../../services/speech_service.dart';
import '../domain/speech_recognition_gateway.dart';

/// Bridges the existing device plugin facade without changing its API.
class DeviceSpeechRecognitionGateway implements SpeechRecognitionGateway {
  const DeviceSpeechRecognitionGateway();

  @override
  Future<bool> initialize() => SpeechService.initialize();

  @override
  Future<void> start({required void Function(String) onResult}) =>
      SpeechService.startListening(onResult: onResult);

  @override
  Future<void> stop() => SpeechService.stopListening();
}
