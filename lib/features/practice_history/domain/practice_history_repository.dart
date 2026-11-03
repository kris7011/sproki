import 'practice_attempt.dart';

/// Local source of practice history. Implementations must return newest first.
abstract interface class PracticeHistoryRepository {
  Future<List<PracticeAttempt>> loadRecent({int limit = 50});
}
