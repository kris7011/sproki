import 'package:hive/hive.dart';

import '../constants/hive_boxes.dart';
import '../models/category_attempt.dart';

class CategoryService {
  /// Gem ét kategoriserings-forsøg
  static Future<void> recordCategoryAttempt({
    required String childId,
    required String wordId,
    required String chosenCategory,
    required String correctCategory,
    required bool wasCorrect,
  }) async {
    final box = Hive.box<CategoryAttempt>(HiveBoxes.categoryAttempts);

    final attempt = CategoryAttempt(
      childId: childId,
      wordId: wordId,
      chosenCategory: chosenCategory,
      correctCategory: correctCategory,
      wasCorrect: wasCorrect,
      createdAt: DateTime.now(),
    );

    await box.add(attempt);
  }
}
