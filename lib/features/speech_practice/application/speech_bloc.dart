import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/speech_recognition_gateway.dart';
import '../domain/word_matcher.dart';

sealed class SpeechEvent {
  const SpeechEvent();
}

final class SpeechStartRequested extends SpeechEvent {
  const SpeechStartRequested();
}

final class SpeechStopRequested extends SpeechEvent {
  const SpeechStopRequested();
}

final class SpeechTranscriptReceived extends SpeechEvent {
  const SpeechTranscriptReceived(this.transcript, this.session);
  final String transcript;
  final int session;
}

final class SpeechTimeElapsed extends SpeechEvent {
  const SpeechTimeElapsed(this.session);
  final int session;
}

sealed class SpeechState {
  const SpeechState();
}

final class SpeechIdle extends SpeechState {
  const SpeechIdle();
}

final class SpeechStarting extends SpeechState {
  const SpeechStarting();
}

final class SpeechListening extends SpeechState {
  const SpeechListening(this.transcript);
  final String transcript;
}

final class SpeechMatched extends SpeechState {
  const SpeechMatched(this.transcript);
  final String transcript;
}

final class SpeechNoInput extends SpeechState {
  const SpeechNoInput();
}

final class SpeechNotMatched extends SpeechState {
  const SpeechNotMatched();
}

final class SpeechUnavailable extends SpeechState {
  const SpeechUnavailable();
}

final class SpeechFailure extends SpeechState {
  const SpeechFailure();
}

/// Event-driven microphone workflow. Device integration is a repository-style
/// gateway, and nothing is uploaded or logged by this Bloc.
class SpeechBloc extends Bloc<SpeechEvent, SpeechState> {
  SpeechBloc({
    required SpeechRecognitionGateway gateway,
    required String targetWord,
    Duration listeningDuration = const Duration(seconds: 5),
    WordMatcher matcher = const WordMatcher(),
  })  : _gateway = gateway,
        _targetWord = targetWord,
        _listeningDuration = listeningDuration,
        _matcher = matcher,
        super(const SpeechIdle()) {
    on<SpeechEvent>(_handleEvent);
  }

  final SpeechRecognitionGateway _gateway;
  final String _targetWord;
  final Duration _listeningDuration;
  final WordMatcher _matcher;

  Timer? _deadline;
  int _session = 0;
  String _transcript = '';

  bool get isRecording =>
      state is SpeechStarting || state is SpeechListening;

  bool _isCurrent(int session) => !isClosed && _session == session;

  Future<void> _handleEvent(
    SpeechEvent event,
    Emitter<SpeechState> emit,
  ) async {
    if (event is SpeechStartRequested) {
      await _start(emit);
    } else if (event is SpeechStopRequested) {
      await _stop(emit);
    } else if (event is SpeechTranscriptReceived) {
      await _transcriptReceived(event, emit);
    } else if (event is SpeechTimeElapsed) {
      await _timeElapsed(event, emit);
    }
  }

  Future<void> _start(Emitter<SpeechState> emit) async {
    if (isRecording || isClosed) return;

    final session = ++_session;
    _deadline?.cancel();
    _transcript = '';
    emit(const SpeechStarting());

    try {
      if (!await _gateway.initialize()) {
        if (_isCurrent(session)) emit(const SpeechUnavailable());
        return;
      }
      if (!_isCurrent(session)) return;

      await _gateway.start(
        onResult: (text) {
          if (_isCurrent(session)) {
            add(SpeechTranscriptReceived(text, session));
          }
        },
      );
      if (!_isCurrent(session)) return;

      if (state is SpeechStarting) {
        emit(const SpeechListening(''));
      }
      _deadline = Timer(_listeningDuration, () {
        if (_isCurrent(session)) add(SpeechTimeElapsed(session));
      });
    } catch (_) {
      if (_isCurrent(session)) {
        ++_session;
        _deadline?.cancel();
        emit(const SpeechFailure());
        await _stopDevice();
      }
    }
  }

  Future<void> _transcriptReceived(
    SpeechTranscriptReceived event,
    Emitter<SpeechState> emit,
  ) async {
    if (!_isCurrent(event.session) || !isRecording) return;

    _transcript = event.transcript.trim();
    if (_matcher.matches(_transcript, _targetWord)) {
      ++_session;
      _deadline?.cancel();
      emit(SpeechMatched(_transcript));
      await _stopDevice();
    } else {
      emit(SpeechListening(_transcript));
    }
  }

  Future<void> _timeElapsed(
    SpeechTimeElapsed event,
    Emitter<SpeechState> emit,
  ) async {
    if (!_isCurrent(event.session) || !isRecording) return;

    ++_session;
    _deadline?.cancel();
    emit(_transcript.isEmpty
        ? const SpeechNoInput()
        : const SpeechNotMatched());
    await _stopDevice();
  }

  Future<void> _stop(Emitter<SpeechState> emit) async {
    if (!isRecording || isClosed) return;

    ++_session;
    _deadline?.cancel();
    emit(const SpeechIdle());
    await _stopDevice();
  }

  Future<void> _stopDevice() async {
    try {
      await _gateway.stop();
    } catch (_) {
      // State was already finalised. A device shutdown failure must not
      // trigger a second result or crash a disposed screen.
    }
  }

  @override
  Future<void> close() async {
    ++_session;
    _deadline?.cancel();
    await _stopDevice();
    await super.close();
  }
}
