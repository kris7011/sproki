import 'package:hive/hive.dart';

part 'word_attempt.g.dart';

@HiveType(typeId: 3)
class WordAttempt extends HiveObject {
  WordAttempt({
    required this.childId,
    required this.wordId,
    required this.word,
    required this.score, // 0..1
    required this.createdAt,
    required this.firstAttempt,
    required this.lastAttempt,
    required this.sessionDates,
  });

  @HiveField(0)
  String childId;
  @HiveField(1)
  String wordId;
  @HiveField(2)
  String word;
  @HiveField(3)
  double score; // 0..1
  @HiveField(4)
  DateTime createdAt;
  @HiveField(5)
  DateTime firstAttempt;
  @HiveField(6)
  DateTime lastAttempt;
  @HiveField(7)
  List<DateTime> sessionDates;
}
