/// Immutable, UI-facing snapshot; it does not expose the Hive model.
class PracticeAttempt {
  const PracticeAttempt({
    required this.word,
    required this.practicedAt,
    required this.wasSuccessful,
  });

  final String word;
  final DateTime practicedAt;
  final bool wasSuccessful;
}
