import 'package:hive/hive.dart';

part 'child_profile.g.dart';

@HiveType(typeId: 1) // <- SKIFT hvis du allerede bruger 1 til noget andet
class ChildProfile {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final DateTime birthDate;

  @HiveField(2)
  final List<String> challengeAreas;

  /// Bruges både lokalt og når vi sender/opfanger fra Supabase
  @HiveField(3)
  final DateTime createdAt;

  const ChildProfile({
    required this.name,
    required this.birthDate,
    required this.challengeAreas,
    required this.createdAt,
  });
}
