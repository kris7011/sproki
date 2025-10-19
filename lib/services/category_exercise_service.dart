import 'package:hive/hive.dart';

import '../constants/hive_boxes.dart';
import '../models/category_attempt.dart';
import '../services/active_child_service.dart';

class CategoryExerciseService {
  CategoryExerciseService();

  Box<CategoryAttempt> get _box =>
      Hive.box<CategoryAttempt>(HiveBoxes.categoryAttempts);

  Future<void> saveAttempt({
    required String wordId,
    required String chosenCategory,
    required String correctCategory,
    required bool wasCorrect,
  }) async {
    final childId =
        ActiveChildService.instance.activeChildIdSync ?? 'local-default';
    final attempt = CategoryAttempt(
      childId: childId,
      wordId: wordId,
      chosenCategory: chosenCategory,
      correctCategory: correctCategory,
      wasCorrect: wasCorrect,
      createdAt: DateTime.now(),
    );
    // brug wordId+timestamp som unik nøgle, så upsert ikke overskriver ved offline sync
    final key = '${attempt.wordId}_${attempt.createdAt.microsecondsSinceEpoch}';
    await _box.put(key, attempt);
  }

  /// Simpel statistik til evt. badge/score
  Map<String, int> statsForChild(String childId) {
    int total = 0;
    int correct = 0;
    for (final a in _box.values) {
      if (a.childId != childId) continue;
      total += 1;
      if (a.wasCorrect) correct += 1;
    }
    return {'total': total, 'correct': correct};
  }
}
