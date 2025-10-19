import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Vi gemmer plan pr. barnId som JSON-string i en dedikeret Hive box.
class PlanStore {
  static const _boxName = 'plans_box';
  static Box<String>? _box;

  // Bruges til at trigge UI-rebuilds når plan ændres
  static final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  /// Kald fra main(): await PlanStore.init();
  static Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  /// Lyt i UI (ValueListenableBuilder) for at få rebuild ved ændringer
  static ValueListenable<int> listenable() => _tick;

  /// Gemmer/overskriver planen for et barn
  static Future<void> savePlan(
      String childId, Map<String, dynamic> plan) async {
    final b = _box;
    if (b == null) throw StateError('PlanStore.init() ikke kaldt endnu');
    final jsonStr = jsonEncode(plan);
    await b.put(childId, jsonStr);
    _tick.value++; // notify lyttere
  }

  /// Hent planen for et barn, eller null hvis ingen
  static Map<String, dynamic>? getPlan(String childId) {
    final b = _box;
    if (b == null) throw StateError('PlanStore.init() ikke kaldt endnu');
    final jsonStr = b.get(childId);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr);
      if (map is Map<String, dynamic>) return map;
      return Map<String, dynamic>.from(map as Map);
    } catch (_) {
      return null;
    }
  }

  /// Slet planen for et barn
  static Future<void> clearPlan(String childId) async {
    final b = _box;
    if (b == null) throw StateError('PlanStore.init() ikke kaldt endnu');
    await b.delete(childId);
    _tick.value++;
  }

  /// Slet alle planer (debug/hard reset)
  static Future<void> clearAll() async {
    final b = _box;
    if (b == null) throw StateError('PlanStore.init() ikke kaldt endnu');
    await b.clear();
    _tick.value++;
  }
}
