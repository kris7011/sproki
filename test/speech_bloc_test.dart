import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/speech_practice/application/speech_bloc.dart';
import 'package:sproki/features/speech_practice/domain/speech_recognition_gateway.dart';

class _FakeSpeechGateway implements SpeechRecognitionGateway {
  bool available = true;
  bool failStart = false;
  int startCount = 0;
  int stopCount = 0;
  void Function(String)? onResult;
  Completer<bool>? pendingInitialization;

  @override
  Future<bool> initialize() async =>
      pendingInitialization == null
          ? available
          : await pendingInitialization!.future;

  @override
  Future<void> start({required void Function(String) onResult}) async {
    if (failStart) throw StateError('device unavailable');
    startCount++;
    this.onResult = onResult;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  void recognize(String text) {
    onResult?.call(text);
  }
}

void main() {
  test('emits starting, listening and a single successful result', () async {
    final gateway = _FakeSpeechGateway();
    final bloc = SpeechBloc(gateway: gateway, targetWord: 'and');
    addTearDown(bloc.close);

    final observed = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SpeechStarting>(),
        isA<SpeechListening>(),
        isA<SpeechListening>().having(
          (state) => state.transcript,
          'partial transcript',
          'jeg',
        ),
        isA<SpeechMatched>().having(
          (state) => state.transcript,
          'matching transcript',
          'jeg siger and',
        ),
      ]),
    );
    bloc.add(const SpeechStartRequested());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    gateway.recognize('jeg');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    gateway.recognize('jeg siger and');
    await observed;
    expect(gateway.stopCount, 1);
  });

  test('no microphone capability emits unavailable without starting', () async {
    final gateway = _FakeSpeechGateway()..available = false;
    final bloc = SpeechBloc(gateway: gateway, targetWord: 'and');
    addTearDown(bloc.close);
    final observed = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SpeechStarting>(),
        isA<SpeechUnavailable>(),
      ]),
    );
    bloc.add(const SpeechStartRequested());
    await observed;
    expect(gateway.startCount, 0);
  });

  test('failed device start reports a recoverable error', () async {
    final gateway = _FakeSpeechGateway()..failStart = true;
    final bloc = SpeechBloc(gateway: gateway, targetWord: 'and');
    addTearDown(bloc.close);
    final observed = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SpeechStarting>(),
        isA<SpeechFailure>(),
      ]),
    );
    bloc.add(const SpeechStartRequested());
    await observed;
  });

  test('timeout without transcript creates one no-input state', () async {
    final gateway = _FakeSpeechGateway();
    final bloc = SpeechBloc(
      gateway: gateway,
      targetWord: 'and',
      listeningDuration: const Duration(milliseconds: 35),
    );
    addTearDown(bloc.close);

    final observed = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SpeechStarting>(),
        isA<SpeechListening>(),
        isA<SpeechNoInput>(),
      ]),
    );
    bloc.add(const SpeechStartRequested());
    await observed;
    expect(gateway.stopCount, 1);
  });

  test('nonmatching transcripts time out without a false success', () async {
    final gateway = _FakeSpeechGateway();
    final bloc = SpeechBloc(
      gateway: gateway,
      targetWord: 'and',
      listeningDuration: const Duration(milliseconds: 45),
    );
    addTearDown(bloc.close);

    final observed = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SpeechStarting>(),
        isA<SpeechListening>(),
        isA<SpeechListening>(),
        isA<SpeechNotMatched>(),
      ]),
    );
    bloc.add(const SpeechStartRequested());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    gateway.recognize('random');
    await observed;
  });

  test('cancelling a starting session prevents a late callback', () async {
    final gateway = _FakeSpeechGateway()
      ..pendingInitialization = Completer<bool>();
    final bloc = SpeechBloc(gateway: gateway, targetWord: 'and');
    addTearDown(bloc.close);

    final observed = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SpeechStarting>(),
        isA<SpeechIdle>(),
      ]),
    );
    bloc.add(const SpeechStartRequested());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(const SpeechStopRequested());
    await observed;

    gateway.pendingInitialization!.complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(gateway.startCount, 0);
  });

  test('closing cancels timers and ignores late device results', () async {
    final gateway = _FakeSpeechGateway();
    final bloc = SpeechBloc(
      gateway: gateway,
      targetWord: 'and',
      listeningDuration: const Duration(milliseconds: 15),
    );
    bloc.add(const SpeechStartRequested());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await bloc.close();
    gateway.recognize('and');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.isClosed, isTrue);
  });
}
