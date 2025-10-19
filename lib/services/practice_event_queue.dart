import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/report_models.dart';

/// Box content is a list of queued batches. Each batch contains:
///  - id: uuid for dedup/telemetry
///  - childId: path param
///  - events: `List<PracticeEventIn>` (stored as JSON maps)
///  - attempts: int (for backoff)
class PracticeEventQueue {
  static const _boxName = 'sproki_practice_queue';
  static Box? _box;

  static Future<void> ensureBoxesOpened() async {
    _box ??= await Hive.openBox(_boxName);
  }

  static Box get _b {
    final b = _box;
    if (b == null) throw StateError('PracticeEventQueue not initialized');
    return b;
  }

  static Future<String> enqueue(
      String childId, List<PracticeEventIn> events) async {
    final id = const Uuid().v4();
    final payload = {
      'id': id,
      'childId': childId,
      'attempts': 0,
      'events': events.map((e) => e.toJson()).toList(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    await _b.add(payload);
    return id;
  }

  static List<Map<String, dynamic>> snapshot() {
    return _b.values
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  static Future<void> markAttempt(String batchId) async {
    final key = _findKeyById(batchId);
    if (key == null) return;
    final v = Map<String, dynamic>.from(_b.get(key));
    v['attempts'] = (v['attempts'] as int? ?? 0) + 1;
    await _b.put(key, v);
  }

  static Future<void> remove(String batchId) async {
    final key = _findKeyById(batchId);
    if (key != null) await _b.delete(key);
  }

  static dynamic _findKeyById(String id) {
    for (final k in _b.keys) {
      final v = _b.get(k);
      if (v is Map && v['id'] == id) return k;
    }
    return null;
  }

  // Optional utility for debugging
  static String debugDump() => jsonEncode(snapshot());
}
