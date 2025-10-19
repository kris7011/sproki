// lib/blocs/progress_overview/progress_overview_state.dart
import 'package:equatable/equatable.dart';
import '../../models/progress_data.dart';
import '../../data/words_content.dart';

class ProgressOverviewState extends Equatable {
  final bool loading;
  final String? error;
  final String? childId;

  final ProgressData? summary;
  final List<double> successSpark;
  final List<double> attemptsBars;
  final List<WordContent> recommendations;

  const ProgressOverviewState({
    required this.loading,
    required this.error,
    required this.childId,
    required this.summary,
    required this.successSpark,
    required this.attemptsBars,
    required this.recommendations,
  });

  factory ProgressOverviewState.initial() => const ProgressOverviewState(
        loading: true,
        error: null,
        childId: null,
        summary: null,
        successSpark: <double>[],
        attemptsBars: <double>[],
        recommendations: <WordContent>[],
      );

  ProgressOverviewState copyWith({
    bool? loading,
    String? error,
    String? childId,
    ProgressData? summary,
    List<double>? successSpark,
    List<double>? attemptsBars,
    List<WordContent>? recommendations,
    bool clearError = false,
  }) {
    return ProgressOverviewState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      childId: childId ?? this.childId,
      summary: summary ?? this.summary,
      successSpark: successSpark ?? this.successSpark,
      attemptsBars: attemptsBars ?? this.attemptsBars,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        error,
        childId,
        summary,
        successSpark,
        attemptsBars,
        recommendations
      ];
}
