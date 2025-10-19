// lib/logic/practice/practice_cubit.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:bloc/bloc.dart';
import 'package:sproki/data/words_content.dart';
import 'package:sproki/logic/practice/practice_state.dart';
import 'package:sproki/logic/practice/tts_port.dart';
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/paywall_service.dart';
import 'package:sproki/services/progress_service.dart';

class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit({
    required WordContent startWord,
    required this.paywall,
    required this.tts,
  }) : super(
          PracticeState.initial(
            List<WordContent>.from(WordsRepo.instance.all),
            List<WordContent>.from(WordsRepo.instance.all)
                .indexWhere((w) => w.id == startWord.id),
          ),
        );

  final PaywallService paywall;
  final TtsPort tts;

  Future<bool> ensureUnlocked() async {
    final childId =
        ActiveChildService.instance.activeChildIdSync ?? 'local-default';
    return !(await paywall.isLockedForChildAsync(childId));
  }

  void nextWord() {
    if (state.words.isEmpty) return;
    final i = (state.index + 1) % state.words.length;
    emit(state.copyWith(
      index: i,
      phase: PracticePhase.idle,
      score: 0,
      success: false,
    ));
  }

  void prevWord() {
    if (state.words.isEmpty) return;
    final i = (state.index - 1 + state.words.length) % state.words.length;
    emit(state.copyWith(
      index: i,
      phase: PracticePhase.idle,
      score: 0,
      success: false,
    ));
  }

  Future<void> speak() => tts.speak(state.current.word);
  Future<void> speakSlow() => tts.speak(state.current.word, rate: 0.4);

  Future<void> startFlow() async {
    emit(state.copyWith(phase: PracticePhase.countingDown, countdown: 3));
    for (int i = 3; i >= 1; i--) {
      emit(state.copyWith(countdown: i));
      await Future.delayed(const Duration(milliseconds: 750));
    }

    emit(state.copyWith(phase: PracticePhase.listening));
    await Future.delayed(const Duration(seconds: 2));

    final randomScore = 60 + math.Random().nextInt(41); // 60..100
    await registerResult(
      score: randomScore.toDouble(),
      success: randomScore >= 80,
    );
  }

  Future<void> registerResult({
    required double score,
    required bool success,
  }) async {
    final newTotal = state.totalAttempts + 1;
    final newSuccess = state.successfulAttempts + (success ? 1 : 0);
    final best = score > state.bestScore ? score : state.bestScore;

    emit(state.copyWith(
      phase: PracticePhase.scored,
      score: score.clamp(0, 100),
      success: success,
      totalAttempts: newTotal,
      successfulAttempts: newSuccess,
      bestScore: best,
    ));

    try {
      final childId =
          ActiveChildService.instance.activeChildIdSync ?? 'local-default';

      // Store as 0..1 for EMA
      await ProgressService.instance.updateOnAnswer(
        childId: childId,
        domain: 'ordforråd', // this cubit is for word practice
        exerciseId: 'word:${state.current.id}',
        score: (score / 100.0).clamp(0.0, 1.0),
        alpha: 0.35,
      );

      await paywall.recordAttempt(childId);
    } catch (_) {}
  }

  Future<void> markGood() => registerResult(
      score: (state.score < 90 ? 90 : state.score), success: true);

  Future<void> markBad() => registerResult(
      score: (state.score > 60 ? 60 : state.score), success: false);

  @override
  Future<void> close() async {
    await tts.dispose();
    return super.close();
  }
}
