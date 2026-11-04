import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/progress_insights.dart';
import '../domain/progress_insights_repository.dart';

sealed class ProgressInsightsState {
  const ProgressInsightsState();
}

final class ProgressInsightsInitial extends ProgressInsightsState {
  const ProgressInsightsInitial();
}

final class ProgressInsightsLoading extends ProgressInsightsState {
  const ProgressInsightsLoading();
}

final class ProgressInsightsEmpty extends ProgressInsightsState {
  const ProgressInsightsEmpty();
}

final class ProgressInsightsLoaded extends ProgressInsightsState {
  const ProgressInsightsLoaded(this.insights);
  final ProgressInsights insights;
}

final class ProgressInsightsFailure extends ProgressInsightsState {
  const ProgressInsightsFailure();
}

/// Presentation state and refresh workflow; no direct Hive dependency.
class ProgressInsightsCubit extends Cubit<ProgressInsightsState> {
  ProgressInsightsCubit(this._repository)
      : super(const ProgressInsightsInitial());

  final ProgressInsightsRepository _repository;

  Future<void> refresh() async {
    if (isClosed || state is ProgressInsightsLoading) return;

    emit(const ProgressInsightsLoading());
    try {
      final insights = await _repository.load();
      if (isClosed) return;
      emit(
        insights.totalAttempts == 0
            ? const ProgressInsightsEmpty()
            : ProgressInsightsLoaded(insights),
      );
    } catch (_) {
      if (!isClosed) emit(const ProgressInsightsFailure());
    }
  }
}
