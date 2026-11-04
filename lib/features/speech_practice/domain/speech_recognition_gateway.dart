/// Abstraction around device speech services so app logic can be tested.
abstract interface class SpeechRecognitionGateway {
  Future<bool> initialize();

  Future<void> start({required void Function(String) onResult});

  Future<void> stop();
}
