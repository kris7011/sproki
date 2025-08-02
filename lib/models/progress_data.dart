import 'package:hive/hive.dart';

part 'progress_data.g.dart';

@HiveType(typeId: 2)
class ProgressData extends HiveObject {
  @HiveField(0)
  String wordId;

  @HiveField(1)
  int totalAttempts;

  @HiveField(2)
  int successfulAttempts;

  @HiveField(3)
  DateTime firstAttempt;

  @HiveField(4)
  DateTime lastAttempt;

  @HiveField(5)
  bool isUnlocked;

  @HiveField(6)
  double bestScore;

  @HiveField(7)
  List<DateTime> sessionDates;

  ProgressData({
    required this.wordId,
    this.totalAttempts = 0,
    this.successfulAttempts = 0,
    required this.firstAttempt,
    required this.lastAttempt,
    this.isUnlocked = true,
    this.bestScore = 0.0,
    required this.sessionDates,
  });

  // Beregn success rate
  double get successRate =>
      totalAttempts > 0 ? successfulAttempts / totalAttempts : 0.0;

  // Er ordet mestret? (80% success rate med min 5 forsøg)
  bool get isMastered => successRate >= 0.8 && totalAttempts >= 5;

  // Få stjerner (0-3) baseret på performance
  int get stars {
    if (!isMastered) return 0;
    if (successRate >= 0.95) return 3;
    if (successRate >= 0.90) return 2;
    return 1;
  }
}
