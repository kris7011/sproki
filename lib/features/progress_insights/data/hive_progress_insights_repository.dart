import 'package:hive/hive.dart';

import '../../../data/words_content.dart';
import '../../../models/progress_data.dart';
import '../domain/progress_insights.dart';
import '../domain/progress_insights_repository.dart';

/// Adapts the existing per-word Hive box without a schema migration.
class HiveProgressInsightsRepository implements ProgressInsightsRepository {
  HiveProgressInsightsRepository(
    this._box, {
    ProgressInsightsCalculator calculator = const ProgressInsightsCalculator(),
    List<WordContent>? words,
  })  : _calculator = calculator,
        _wordNames = Map<String, String>.unmodifiable({
          for (final word in words ?? initialWords) word.id: word.word,
        });

  final Box<ProgressData> _box;
  final ProgressInsightsCalculator _calculator;
  final Map<String, String> _wordNames;

  @override
  Future<ProgressInsights> load() async {
    // Snapshot mutable Hive records; the domain never retains live Hive objects.
    final entries = [
      for (final record in _box.values)
        WordProgressEntry(
          wordId: record.wordId,
          totalAttempts: record.totalAttempts,
          successfulAttempts: record.successfulAttempts,
          isUnlocked: record.isUnlocked,
          lastAttempt: record.lastAttempt,
        ),
    ];
    return _calculator.calculate(entries, _wordNames);
  }
}
