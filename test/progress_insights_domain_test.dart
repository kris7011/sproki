import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/progress_insights/domain/progress_insights.dart';

void main() {
  final now = DateTime(2026, 11, 4);

  WordProgressEntry record(
    String id, {
    required int attempts,
    required int successes,
    bool unlocked = true,
  }) {
    return WordProgressEntry(
      wordId: id,
      totalAttempts: attempts,
      successfulAttempts: successes,
      isUnlocked: unlocked,
      lastAttempt: now,
    );
  }

  const calculator = ProgressInsightsCalculator();

  test('provides an empty summary for no prior practice', () {
    final result = calculator.calculate([], {});
    expect(result.totalAttempts, 0);
    expect(result.successRate, 0);
    expect(result.suggestions, isEmpty);
  });

  test('ranks unlocked known words, excludes mastered and unknown words', () {
    final result = calculator.calculate(
      [
        record('mastered', attempts: 5, successes: 4),
        record('middle', attempts: 3, successes: 1),
        record('few', attempts: 1, successes: 0),
        record('locked', attempts: 2, successes: 0, unlocked: false),
        record('unknown', attempts: 1, successes: 0),
        record('low', attempts: 2, successes: 0),
      ],
      {
        'mastered': 'Fugl',
        'middle': 'Sol',
        'few': 'And',
        'locked': 'Arm',
        'low': 'Mus',
      },
    );

    expect(result.attemptedWords, 6);
    expect(result.totalAttempts, 14);
    expect(result.successfulAttempts, 5);
    expect(result.masteredWords, 1);
    expect(
      result.suggestions.map((suggestion) => suggestion.wordId).toList(),
      ['few', 'low', 'middle'],
    );
    expect(() => result.suggestions.clear(), throwsUnsupportedError);
  });

  test('ignores corrupted attempt counts rather than exposing invalid ratios', () {
    final result = calculator.calculate(
      [
        record('bad', attempts: 1, successes: 5),
        record('zero', attempts: 0, successes: 0),
        record('good', attempts: 3, successes: 2),
      ],
      {'bad': 'Fejl', 'good': 'God'},
    );

    expect(result.attemptedWords, 1);
    expect(result.totalAttempts, 3);
    expect(result.successRate, closeTo(2 / 3, 0.0001));
    expect(result.suggestions.single.wordId, 'good');
  });

  test('limits recommendations, and rejects negative limits', () {
    final records = [
      record('a', attempts: 1, successes: 0),
      record('b', attempts: 1, successes: 0),
    ];
    expect(
      calculator.calculate(records, {'a': 'And', 'b': 'Bil'}, suggestionLimit: 1)
          .suggestions,
      hasLength(1),
    );
    expect(
      () => calculator.calculate(records, {}, suggestionLimit: -1),
      throwsRangeError,
    );
  });
}
