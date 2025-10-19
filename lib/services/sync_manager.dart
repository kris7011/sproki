// services/sync_manager.dart
import 'package:sproki/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncManager {
  SyncManager._internal();
  static final instance = SyncManager._internal();
  SupabaseSyncService get _svc => SupabaseSyncService(Supabase.instance.client);

  Future<void> syncAll() async {
    // Pull først
    await _svc.pullChildProfiles();
    await _svc.pullProgress();
    await _svc.pullWordAttempts();
    await _svc.pullCategoryAttempts();

    // Push bagefter
    await _svc.pushChildProfiles();
    await _svc.pushProgress();
    await _svc.pushWordAttempts();
    await _svc.pushCategoryAttempts();
  }
}
