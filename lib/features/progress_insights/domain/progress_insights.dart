/// Read-only observations from completed word practice sessions.
class WordProgressEntry {
  const WordProgressEntry({
    required this.wordId,
    required this.totalAttempts,
    required this.successfulAttempts,
    required this.isUnlocked,
    required this.lastAttempt,
  });

  final String wordId;
  final int totalAttempts;
  final int successfulAttempts;
  final bool isUnlocked;
  final DateTime lastAttempt;

  double get successRate => totalAttempts == 0
      ? 0
      : successfulAttempts.clamp(0, totalAttempts) / totalAttempts;

  bool get isMastered => totalAttempts >= 5 && successRate >= 0.8;
}

class SuggestedWord {
  const SuggestedWord({
    required this.wordId,
    required this.word,
    required this.totalAttempts,
    required this.successRate,
  });

  final String wordId;
  final String word;
  final int totalAttempts;
  final double successRate;
}

class ProgressInsights {
  ProgressInsights({
    required this.attemptedWords,
    required this.totalAttempts,
    required this.successfulAttempts,
    required this.masteredWords,
    required List<SuggestedWord> suggestions,
  }) : suggestions = List<SuggestedWord>.unmodifiable(suggestions);

  final int attemptedWords;
  final int totalAttempts;
  final int successfulAttempts;
  final int masteredWords;
  final List<SuggestedWord> suggestions;

  double get successRate =>
      totalAttempts == 0 ? 0 : successfulAttempts / totalAttempts;
}

/// Transparent, illustrative suggestions based on observed practice counts.
/// Not a clinical evaluation or a speech-therapy recommendation.
class ProgressInsightsCalculator {
  const ProgressInsightsCalculator();

  ProgressInsights calculate(
    Iterable<WordProgressEntry> entries,
    Map<String, String> knownWords, {
    int suggestionLimit = 5,
  }) {
    if (suggestionLimit < 0) {
      throw RangeError.value(suggestionLimit, 'suggestionLimit');
    }

    final valid = entries.where(
      (entry) =>
          entry.totalAttempts > 0 &&
          entry.successfulAttempts >= 0 &&
          entry.successfulAttempts <= entry.totalAttempts,
    ).toList();

    final candidates = valid
        .where(
          (entry) =>
              entry.isUnlocked &&
              !entry.isMastered &&
              knownWords.containsKey(entry.wordId),
        )
        .toList()
      ..sort((left, right) {
        // Lower observed success rate first; ties favour fewer attempts.
        final rate = left.successRate.compareTo(right.successRate);
        if (rate != 0) return rate;
        final count = left.totalAttempts.compareTo(right.totalAttempts);
        if (count != 0) return count;
        return left.wordId.compareTo(right.wordId);
      });

    return ProgressInsights(
      attemptedWords: valid.length,
      totalAttempts: valid.fold(0, (sum, entry) => sum + entry.totalAttempts),
      successfulAttempts: valid.fold(
        0,
        (sum, entry) => sum + entry.successfulAttempts,
      ),
      masteredWords: valid.where((entry) => entry.isMastered).length,
      suggestions: [
        for (final entry in candidates.take(suggestionLimit))
          SuggestedWord(
            wordId: entry.wordId,
            word: knownWords[entry.wordId]!,
            totalAttempts: entry.totalAttempts,
            successRate: entry.successRate,
          ),
      ],
    );
  }
}
