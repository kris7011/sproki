import 'package:equatable/equatable.dart';
import 'package:sproki/data/words_content.dart';

enum PracticePhase {
  idle,
  countingDown,
  listening,
  scored,
}

class PracticeState extends Equatable {
  final List<WordContent> words;
  final int index;
  final PracticePhase phase;
  final int countdown; // 3..1
  final double score; // 0..100
  final bool success; // sidst var succes
  final int totalAttempts;
  final int successfulAttempts;
  final double bestScore;

  const PracticeState({
    required this.words,
    required this.index,
    required this.phase,
    required this.countdown,
    required this.score,
    required this.success,
    required this.totalAttempts,
    required this.successfulAttempts,
    required this.bestScore,
  });

  WordContent get current => words.isEmpty
      ? const WordContent(id: 'empty', word: '', category: '')
      : words[index.clamp(0, words.length - 1)];

  double get successRate =>
      totalAttempts == 0 ? 0 : successfulAttempts / totalAttempts;

  int get stars {
    if (successRate >= 0.95 && totalAttempts >= 5) return 3;
    if (successRate >= 0.90 && totalAttempts >= 5) return 2;
    if (successRate >= 0.80 && totalAttempts >= 5) return 1;
    return 0;
  }

  PracticeState copyWith({
    List<WordContent>? words,
    int? index,
    PracticePhase? phase,
    int? countdown,
    double? score,
    bool? success,
    int? totalAttempts,
    int? successfulAttempts,
    double? bestScore,
  }) {
    return PracticeState(
      words: words ?? this.words,
      index: index ?? this.index,
      phase: phase ?? this.phase,
      countdown: countdown ?? this.countdown,
      score: score ?? this.score,
      success: success ?? this.success,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successfulAttempts: successfulAttempts ?? this.successfulAttempts,
      bestScore: bestScore ?? this.bestScore,
    );
  }

  static PracticeState initial(List<WordContent> words, int startIndex) {
    final safeIndex = words.isEmpty ? 0 : startIndex.clamp(0, words.length - 1);
    return PracticeState(
      words: List.unmodifiable(words),
      index: safeIndex,
      phase: PracticePhase.idle,
      countdown: 3,
      score: 0,
      success: false,
      totalAttempts: 0,
      successfulAttempts: 0,
      bestScore: 0,
    );
  }

  @override
  List<Object?> get props => [
        words,
        index,
        phase,
        countdown,
        score,
        success,
        totalAttempts,
        successfulAttempts,
        bestScore
      ];
}
