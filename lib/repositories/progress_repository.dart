// lib/repositories/progress_repository.dart
import 'package:hive/hive.dart';
import '../constants/hive_boxes.dart';
import '../models/progress_data.dart';
import '../models/word_attempt.dart';
import '../data/words_content.dart'; // indeholder WordContent + WordsRepo
import '../services/recommendation_service.dart';

class ProgressRepository {
  ProgressRepository({RecommendationService? recommendationService})
      : _recs = recommendationService ?? const RecommendationService();

  final RecommendationService _recs;

  Box<ProgressData> get _progressBox =>
      Hive.box<ProgressData>(HiveBoxes.progressData);
  Box<WordAttempt> get _attemptsBox =>
      Hive.box<WordAttempt>(HiveBoxes.wordAttempts);

  ProgressData? getSummary(String childId) => _progressBox.get(childId);

  List<double> successSpark(String childId, {int days = 14}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final buckets = List.generate(days, (_) => <WordAttempt>[]);

    for (final a in _attemptsBox.values) {
      if (a.childId != childId) continue;
      final d = DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < days) buckets[idx].add(a);
    }

    return buckets.map((list) {
      if (list.isEmpty) return 0.0;
      final ok = list.where((e) => e.score >= 0.8).length;
      return ok / list.length;
    }).toList(growable: false);
  }

  List<double> attemptsBars(String childId, {int days = 14}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final counts = List.filled(days, 0);

    for (final a in _attemptsBox.values) {
      if (a.childId != childId) continue;
      final d = DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < days) counts[idx] += 1;
    }

    final maxC = counts.fold<int>(0, (m, v) => v > m ? v : m);
    if (maxC == 0) return List.filled(days, 0.0);
    return counts.map((c) => c / maxC).toList(growable: false);
  }

  Future<List<WordContent>> recommendations(String childId,
      {int take = 5}) async {
    final recs = await _recs.nextWordsToPractice(childId: childId, take: take);

    final targetIds = recs.map((r) => r.wordId.toString()).toSet();

    // Brug WordsRepo som "single source of truth"
    final catalog = WordsRepo.instance.all;

    final existing =
        catalog.where((w) => targetIds.contains(w.id.toString())).toList();

    if (existing.length < take) {
      final backfill = catalog
          .where((w) => w.isStarterWord && !existing.any((e) => e.id == w.id))
          .take(take - existing.length);
      existing.addAll(backfill);
    }

    if (existing.length < take) {
      final remaining = catalog
          .where((w) => !existing.any((e) => e.id == w.id))
          .take(take - existing.length);
      existing.addAll(remaining);
    }

    return existing.take(take).toList(growable: false);
  }
}
