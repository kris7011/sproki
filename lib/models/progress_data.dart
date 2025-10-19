import 'package:hive/hive.dart';

part 'progress_data.g.dart';

@HiveType(typeId: 2) // <- SKIFT hvis du allerede bruger 2
class ProgressData {
  /// Reference til barn i cloud (også brugt lokalt af os)
  @HiveField(0)
  final String childId;

  @HiveField(1)
  final int totalStars;

  @HiveField(2)
  final int masteredWords;

  @HiveField(3)
  final double averageSuccessRate;

  @HiveField(4)
  final DateTime createdAt;

  const ProgressData({
    required this.childId,
    required this.totalStars,
    required this.masteredWords,
    required this.averageSuccessRate,
    required this.createdAt,
  });
}
