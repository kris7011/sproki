import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/practice_attempt.dart';
import '../domain/practice_history_repository.dart';

/// Immutable states exposed to the Flutter view.
sealed class PracticeHistoryState {
  const PracticeHistoryState();
}

final class PracticeHistoryInitial extends PracticeHistoryState {
  const PracticeHistoryInitial();
}

final class PracticeHistoryLoading extends PracticeHistoryState {
  const PracticeHistoryLoading();
}

final class PracticeHistoryEmpty extends PracticeHistoryState {
  const PracticeHistoryEmpty();
}

final class PracticeHistoryLoaded extends PracticeHistoryState {
  PracticeHistoryLoaded(List<PracticeAttempt> attempts)
      : attempts = List<PracticeAttempt>.unmodifiable(attempts);

  final List<PracticeAttempt> attempts;
}

final class PracticeHistoryFailure extends PracticeHistoryState {
  const PracticeHistoryFailure();
}

/// Loads existing local attempts without importing Hive into the presentation.
///
/// Only the repository handles persistence. Repeated refreshes while loading
/// are ignored; closing the Cubit during an asynchronous read is safe.
class PracticeHistoryCubit extends Cubit<PracticeHistoryState> {
  PracticeHistoryCubit(this._repository)
      : super(const PracticeHistoryInitial());

  final PracticeHistoryRepository _repository;

  Future<void> load() async {
    if (isClosed || state is PracticeHistoryLoading) return;

    emit(const PracticeHistoryLoading());
    try {
      final attempts = await _repository.loadRecent();
      if (isClosed) return;

      emit(
        attempts.isEmpty
            ? const PracticeHistoryEmpty()
            : PracticeHistoryLoaded(attempts),
      );
    } catch (_) {
      if (!isClosed) emit(const PracticeHistoryFailure());
    }
  }
}
