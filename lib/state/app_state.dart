import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/sproki_service.dart';

class AppState extends ChangeNotifier {
  AppState({required this.service}) {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      // IMPORTANT:
      // Supabase triggers token refresh events regularly. That must NOT cause /me reloads.
      switch (event) {
        // Reload on actual auth/account state changes
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userUpdated:
          reload();
          break;

        // Ignore noise that should not cause routing changes or /me spam
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.passwordRecovery:
        case AuthChangeEvent.mfaChallengeVerified:
        case AuthChangeEvent.initialSession:
          break;

        // Future-proof: if Supabase adds or changes events, we don't break compilation
        default:
          break;
      }
    });

    reload();
  }

  final SprokiService service;
  StreamSubscription<AuthState>? _sub;

  bool _loading = true;
  String? _role;
  int? _institutionId;

  bool _reloading = false;
  Completer<void>? _reloadCompleter;

  String? _inviteCheckedForUserId;
  bool _inviteCheckInFlight = false;

  bool get loading => _loading;
  String? get role => _role;
  int? get institutionId => _institutionId;

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentSession?.user.id;

  Future<void> reload() async {
    if (_reloading) {
      return _reloadCompleter?.future ?? Future.value();
    }

    _reloading = true;
    _reloadCompleter = Completer<void>();

    _loading = true;
    notifyListeners();

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _role = null;
      _institutionId = null;

      _loading = false;
      notifyListeners();

      _reloading = false;
      _reloadCompleter?.complete();
      return;
    }

    try {
      // Hard timeout: boot må aldrig hænge på cold start
      final me = await service.me().timeout(const Duration(seconds: 12));

      _role = me.role;
      _institutionId = me.institutionId;
    } catch (_) {
      // Vigtigt: vi afslutter loading uanset hvad,
      // ellers bliver routeren hængende på /boot.
      _role = null;
      _institutionId = null;
    } finally {
      _loading = false;
      notifyListeners();

      _reloading = false;
      _reloadCompleter?.complete();
    }
  }

  // Call this from HomeScreen (NOT from reload/boot)
  void checkInviteInBackground() {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    if (_inviteCheckInFlight) return;
    if (_inviteCheckedForUserId == userId) return;

    _inviteCheckInFlight = true;

    () async {
      try {
        // Keep opt-in behavior to avoid unstable endpoints spamming/locking UI.
        _inviteCheckedForUserId = userId;
        return;

        // --- Re-enable later when backend is stable:
        // final pending = await service
        //     .pendingInvite()
        //     .timeout(const Duration(seconds: 4), onTimeout: () => null);
        //
        // _inviteCheckedForUserId = userId;
        //
        // if (pending == null) return;
        // if (!pending.pending) return;
        //
        // await service.acceptInvite().timeout(const Duration(seconds: 8));
        //
        // final me = await service.me().timeout(const Duration(seconds: 8));
        // _role = me.role;
        // _institutionId = me.institutionId;
        // notifyListeners();
      } catch (_) {
        _inviteCheckedForUserId = userId;
      } finally {
        _inviteCheckInFlight = false;
      }
    }();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
