import 'package:hive/hive.dart';
import '../models/progress_data.dart';
import '../models/word_attempt.dart';

class ProgressService {
  static Box<ProgressData>? _progressBox;
  static Box<WordAttempt>? _attemptsBox;

  static Future<void> initialize() async {
    _progressBox = Hive.box<ProgressData>('progress');
    _attemptsBox = Hive.box<WordAttempt>('attempts');
  }

  // Gem et forsøg og opdater progress
  static Future<void> recordAttempt({
    required String wordId,
    required String targetWord,
    required bool wasSuccessful,
    double accuracyScore = 0.0,
  }) async {
    if (_progressBox == null || _attemptsBox == null) {
      await initialize();
    }

    final now = DateTime.now();

    // Gem attempt
    final attempt = WordAttempt(
      wordId: wordId,
      targetWord: targetWord,
      accuracyScore: accuracyScore,
      attemptTime: now,
      sessionId: now.millisecondsSinceEpoch ~/ 1000,
      wasSuccessful: wasSuccessful,
    );

    await _attemptsBox!.add(attempt);

    // Opdater eller opret progress
    ProgressData? progress = _progressBox!.get(wordId);

    if (progress == null) {
      progress = ProgressData(
        wordId: wordId,
        totalAttempts: 1,
        successfulAttempts: wasSuccessful ? 1 : 0,
        firstAttempt: now,
        lastAttempt: now,
        isUnlocked: true,
        bestScore: accuracyScore,
        sessionDates: [now],
      );
    } else {
      progress.totalAttempts++;
      if (wasSuccessful) progress.successfulAttempts++;
      progress.lastAttempt = now;
      progress.bestScore = accuracyScore > progress.bestScore
          ? accuracyScore
          : progress.bestScore;

      // Tilføj session hvis det er en ny dag
      final today = DateTime(now.year, now.month, now.day);
      final lastSessionDay = progress.sessionDates.isNotEmpty
          ? DateTime(
              progress.sessionDates.last.year,
              progress.sessionDates.last.month,
              progress.sessionDates.last.day,
            )
          : DateTime(1970);

      if (today != lastSessionDay) {
        progress.sessionDates.add(now);
      }
    }

    await _progressBox!.put(wordId, progress);
  }

  // Hent progress for et ord
  static ProgressData? getProgress(String wordId) {
    if (_progressBox == null) return null;
    return _progressBox!.get(wordId);
  }

  // Hent alle progress data
  static List<ProgressData> getAllProgress() {
    if (_progressBox == null) return [];
    return _progressBox!.values.toList();
  }

  // Beregn samlet statistik
  static Map<String, dynamic> getOverallStats() {
    final allProgress = getAllProgress();

    if (allProgress.isEmpty) {
      return {
        'totalWords': 0,
        'masteredWords': 0,
        'totalAttempts': 0,
        'totalSessions': 0,
        'averageSuccessRate': 0.0,
        'totalStars': 0,
      };
    }

    int totalAttempts = 0;
    int totalSuccessful = 0;
    int masteredWords = 0;
    int totalStars = 0;
    Set<DateTime> allSessionDates = {};

    for (final progress in allProgress) {
      totalAttempts += progress.totalAttempts;
      totalSuccessful += progress.successfulAttempts;
      if (progress.isMastered) masteredWords++;
      totalStars += progress.stars;
      allSessionDates.addAll(
        progress.sessionDates.map((d) => DateTime(d.year, d.month, d.day)),
      );
    }

    return {
      'totalWords': allProgress.length,
      'masteredWords': masteredWords,
      'totalAttempts': totalAttempts,
      'totalSessions': allSessionDates.length,
      'averageSuccessRate': totalAttempts > 0
          ? totalSuccessful / totalAttempts
          : 0.0,
      'totalStars': totalStars,
    };
  }
}
