// lib/services/queue_flush_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sproki/services/sproki_api.dart';
import 'practice_event_queue.dart';

/// Periodisk flush af offline-køen når der er netværk.
/// Simpel backoff via 'attempts'.
class QueueFlushService {
  QueueFlushService(this.api, {this.maxAttempts = 5});
  final SprokiApi api;
  final int maxAttempts;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _periodic;

  void start() {
    _sub ??= Connectivity().onConnectivityChanged.listen((_) => flush());
    _periodic ??= Timer.periodic(const Duration(seconds: 20), (_) => flush());
    unawaited(flush());
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _periodic?.cancel();
    _periodic = null;
  }

  Future<void> flush() async {
    final snapshot = PracticeEventQueue.snapshot();
    if (snapshot.isEmpty) return;

    for (final batch in snapshot) {
      final attempts = (batch['attempts'] as int?) ?? 0;
      if (attempts >= maxAttempts) {
        await PracticeEventQueue.remove(batch['id'] as String);
        continue;
      }

      final delaySec = (1 << attempts) * 3;
      final createdAt = DateTime.tryParse(batch['createdAt'] as String? ?? '');
      if (createdAt != null) {
        final ageSec = DateTime.now().toUtc().difference(createdAt).inSeconds;
        if (ageSec < delaySec) continue;
      }

      final childId = batch['childId'] as String;
      final eventsJson = (batch['events'] as List).cast<Map<String, dynamic>>();

      try {
        await api.addPracticeEvents(childId, eventsJson);
        await PracticeEventQueue.remove(batch['id'] as String);
      } catch (_) {
        await PracticeEventQueue.markAttempt(batch['id'] as String);
      }
    }
  }
}

// helper
void unawaited(Future<void> f) {}
