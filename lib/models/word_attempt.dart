import 'package:hive/hive.dart';

part 'word_attempt.g.dart';

@HiveType(typeId: 1)
class WordAttempt extends HiveObject {
  @HiveField(0)
  String wordId;

  @HiveField(1)
  String targetWord;

  @HiveField(2)
  double accuracyScore;

  @HiveField(3)
  DateTime attemptTime;

  @HiveField(4)
  int sessionId;

  @HiveField(5)
  bool wasSuccessful;

  WordAttempt({
    required this.wordId,
    required this.targetWord,
    required this.accuracyScore,
    required this.attemptTime,
    required this.sessionId,
    required this.wasSuccessful,
  });
}
