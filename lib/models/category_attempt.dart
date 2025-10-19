import 'package:hive/hive.dart';

part 'category_attempt.g.dart';

@HiveType(typeId: 4)
class CategoryAttempt extends HiveObject {
  CategoryAttempt({
    required this.childId,
    required this.wordId,
    required this.chosenCategory,
    required this.correctCategory,
    required this.wasCorrect,
    required this.createdAt,
  });

  @HiveField(0)
  String childId;
  @HiveField(1)
  String wordId;
  @HiveField(2)
  String chosenCategory;
  @HiveField(3)
  String correctCategory;
  @HiveField(4)
  bool wasCorrect;
  @HiveField(5)
  DateTime createdAt;
}
