// lib/services/active_child_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // <-- for ValueNotifier
import 'package:shared_preferences/shared_preferences.dart';

class ActiveChildService {
  ActiveChildService._();
  static final ActiveChildService instance = ActiveChildService._();

  static const _key = 'active_child_id_v1';

  String? _activeId;
  final _controller = StreamController<String?>.broadcast();

  // NEW: listenable for widgets/blocs that expect a ValueListenable
  final ValueNotifier<String?> _notifier = ValueNotifier<String?>(null);
  ValueListenable<String?> get activeChildIdListenable => _notifier;

  /// Synchronous access (may be null until init is done)
  String? get activeChildIdSync => _activeId;

  Stream<String?> get changes => _controller.stream;

  Future<void> ensureInitialized() async {
    final p = await SharedPreferences.getInstance();
    _activeId = p.getString(_key);
    _notifier.value = _activeId; // keep listenable in sync
    _controller.add(_activeId);
  }

  Future<String?> getActiveChildId() async {
    if (_activeId != null) return _activeId;
    final p = await SharedPreferences.getInstance();
    _activeId = p.getString(_key);
    _notifier.value = _activeId;
    _controller.add(_activeId);
    return _activeId;
  }

  Future<void> setActiveChildId(String? id) async {
    final p = await SharedPreferences.getInstance();
    if (id == null) {
      await p.remove(_key);
    } else {
      await p.setString(_key, id);
    }
    _activeId = id;
    _notifier.value = _activeId;
    _controller.add(_activeId);
  }
}
