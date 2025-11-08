// lib/services/sync_manager.dart
import 'dart:async';
import 'package:sproki/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sproki/services/practice_queue_service.dart';
import 'package:sproki/services/plan_store.dart';
import 'package:sproki/services/sproki_api.dart';
import 'package:sproki/services/active_child_service.dart';

class SyncManager {
  SyncManager._internal();
  static final instance = SyncManager._internal();
  SupabaseSyncService get _svc => SupabaseSyncService(Supabase.instance.client);

  bool _running = false;
  Object? lastError;

  Future<void> syncAll() async {
    if (_running) return; // drop overlap
    _running = true;
    lastError = null;

    try {
      // 0) Flush evt. lokalt køede practice events (best effort)
      try {
        await PracticeQueueService.instance.flush();
      } catch (_) {}

      // 1) Supabase pull
      await _svc.pullChildProfiles();
      await _svc.pullProgress();
      await _svc.pullWordAttempts();
      await _svc.pullCategoryAttempts();

      // 2) Supabase push
      await _svc.pushChildProfiles();
      await _svc.pushProgress();
      await _svc.pushWordAttempts();
      await _svc.pushCategoryAttempts();

      // 3) Hent nyeste plan fra backend og gem lokalt
      final childId = ActiveChildService.instance.activeChildIdSync;
      if (childId != null && childId.isNotEmpty) {
        try {
          final api = SprokiApi(); // læser SPROKI_API_BASE fra dart-define
          final plan = await api.getPlanMap(childId);
          await PlanStore.savePlan(childId, plan);
        } catch (e) {
          // Plan-fejl må ikke vælte hele sync
          lastError = e;
        }
      }
    } catch (e) {
      lastError = e;
      rethrow;
    } finally {
      _running = false;
    }
  }
}
