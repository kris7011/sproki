import 'package:hive/hive.dart';

import '../../../models/word_attempt.dart';
import '../domain/practice_attempt.dart';
import '../domain/practice_history_repository.dart';

/// Read-only adapter for the existing local attempts box.
///
/// No migration or change to the persisted Hive adapter is required.
class HivePracticeHistoryRepository implements PracticeHistoryRepository {
  const HivePracticeHistoryRepository(this._box);

  final Box<WordAttempt> _box;

  @override
  Future<List<PracticeAttempt>> loadRecent({int limit = 50}) async {
    if (limit < 0) {
      throw RangeError.value(limit, 'limit', 'Must not be negative');
    }
    final attempts = _box.values
        .map(
          (attempt) => PracticeAttempt(
            word: attempt.targetWord,
            practicedAt: attempt.attemptTime,
            wasSuccessful: attempt.wasSuccessful,
          ),
        )
        .toList()
      ..sort((a, b) => b.practicedAt.compareTo(a.practicedAt));

    return List<PracticeAttempt>.unmodifiable(attempts.take(limit));
  }
}
