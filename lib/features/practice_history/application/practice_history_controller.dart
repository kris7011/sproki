import 'package:flutter/foundation.dart';

import '../domain/practice_attempt.dart';
import '../domain/practice_history_repository.dart';

/// Owns loading, refresh and error states without coupling widgets to Hive.
class PracticeHistoryController extends ChangeNotifier {
  PracticeHistoryController(this._repository);

  final PracticeHistoryRepository _repository;

  bool _disposed = false;
  bool _isLoading = false;
  Object? _error;
  List<PracticeAttempt> _attempts = const [];

  bool get isLoading => _isLoading;
  Object? get error => _error;
  List<PracticeAttempt> get attempts => _attempts;

  Future<void> load() async {
    if (_isLoading || _disposed) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recent = await _repository.loadRecent();
      if (_disposed) {
        return;
      }
      _attempts = List<PracticeAttempt>.unmodifiable(recent);
    } catch (error) {
      if (_disposed) {
        return;
      }
      _error = error;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
