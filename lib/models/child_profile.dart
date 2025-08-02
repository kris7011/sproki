import 'package:hive/hive.dart';

part 'child_profile.g.dart';

@HiveType(typeId: 0)
class ChildProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime birthDate;

  @HiveField(2)
  List<String> challengeAreas;

  @HiveField(3)
  String currentLevel;

  @HiveField(4)
  DateTime createdAt;

  ChildProfile({
    required this.name,
    required this.birthDate,
    required this.challengeAreas,
    this.currentLevel = 'beginner',
    required this.createdAt,
  });
}
