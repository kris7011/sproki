import 'package:hive/hive.dart';
import '../constants/hive_boxes.dart';

class UserService {
  static const _kChildNameKey = 'child_name';
  static const _kOnboardingKey = 'onboarding_completed';

  static Future<void> saveChildName(String name) async {
    final box = Hive.box(HiveBoxes.settings);
    await box.put(_kChildNameKey, name);
  }

  static Future<String?> getCachedChildName() async {
    final box = Hive.box(HiveBoxes.settings);
    return box.get(_kChildNameKey) as String?;
  }

  static Future<void> setOnboardingCompleted([bool value = true]) async {
    final box = Hive.box(HiveBoxes.settings);
    await box.put(_kOnboardingKey, value);
  }

  static Future<bool> isOnboardingCompleted() async {
    final box = Hive.box(HiveBoxes.settings);
    return (box.get(_kOnboardingKey) as bool?) ?? false;
  }
}
