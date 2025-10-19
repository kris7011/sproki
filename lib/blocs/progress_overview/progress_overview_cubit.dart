import 'dart:async'; // <-- for unawaited
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/progress_repository.dart';
import '../../services/active_child_service.dart';
import 'progress_overview_state.dart';

class ProgressOverviewCubit extends Cubit<ProgressOverviewState> {
  ProgressOverviewCubit(this._repo) : super(ProgressOverviewState.initial());

  final ProgressRepository _repo;
  bool _listening = false;

  Future<void> init() async {
    final id = ActiveChildService.instance.activeChildIdSync;
    emit(state.copyWith(childId: id, loading: true, clearError: true));
    await _load();

    if (!_listening) {
      ActiveChildService.instance.activeChildIdListenable
          .addListener(_onChildChange);
      _listening = true;
    }
  }

  void _onChildChange() {
    final id = ActiveChildService.instance.activeChildIdSync;
    emit(state.copyWith(childId: id, loading: true, clearError: true));
    unawaited(_load());
  }

  /// Bruges af UI (RefreshIndicator + fejlknap)
  Future<void> refresh() async {
    await _load();
  }

  Future<void> _load() async {
    final id = state.childId;
    if (id == null || id.isEmpty) {
      emit(state.copyWith(
        loading: false,
        summary: null,
        successSpark: const [],
        attemptsBars: const [],
        recommendations: const [],
        clearError: true,
      ));
      return;
    }

    try {
      final summary = _repo.getSummary(id);
      final spark = _repo.successSpark(id, days: 14);
      final bars = _repo.attemptsBars(id, days: 14);
      final recs = await _repo.recommendations(id, take: 5);

      emit(state.copyWith(
        loading: false,
        summary: summary,
        successSpark: spark,
        attemptsBars: bars,
        recommendations: recs,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Kunne ikke indlæse data: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    if (_listening) {
      ActiveChildService.instance.activeChildIdListenable
          .removeListener(_onChildChange);
      _listening = false;
    }
    return super.close();
  }
}
