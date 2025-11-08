// lib/services/practice_queue_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sproki/services/sproki_api.dart';

/// Gemmer practice-events lokalt hvis netværk fejler.
/// Struktur: hver item er `Map<String, dynamic>` klar til `SprokiApi.addPracticeEvents`.
class PracticeQueueService {
  PracticeQueueService._();
  static final PracticeQueueService instance = PracticeQueueService._();

  static const _boxName = 'practice_queue_v1';
  Box? _box;
  Timer? _timer;
  bool _flushing = false;

  Future<void> init({Duration interval = const Duration(seconds: 20)}) async {
    _box ??= await Hive.openBox(_boxName);
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => flush());
  }

  Box get _b {
    final b = _box;
    if (b == null) {
      throw StateError(
          'PracticeQueueService not initialized. Call init() first.');
    }
    return b;
  }

  Future<void> enqueue(Map<String, dynamic> event) async {
    await _b.add(event);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[practice-queue] enqueued, size=${_b.length}');
    }
  }

  Future<void> flush({int maxBatch = 25}) async {
    if (_flushing) return;
    if (_b.isEmpty) return;

    _flushing = true;
    try {
      // Gruppér events pr. barnId – men vores events indeholder childId i payload.
      // Simpelt: tag første batch og brug dets childId (backend kræver path-param).
      final take = _b.values.take(maxBatch).toList();
      if (take.isEmpty) return;

      final childId = (take.first as Map)['childId'] as String;
      final events = take.cast<Map<String, dynamic>>();

      final api = SprokiApi(); // bruger dart-define base
      await api.addPracticeEvents(childId, events);

      // Slet de afsendte entries (første N)
      final keys = _b.keys.take(events.length).toList();
      await _b.deleteAll(keys);

      if (kDebugMode) {
        // ignore: avoid_print
        print(
            '[practice-queue] flushed ${events.length} events; left=${_b.length}');
      }
    } catch (e) {
      // Backoff styres af periodic timer; vi gør intet her.
      if (kDebugMode) {
        // ignore: avoid_print
        print('[practice-queue] flush failed: $e');
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _box?.close();
    _box = null;
  }
}
