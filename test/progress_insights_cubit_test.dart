import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/progress_insights/application/progress_insights_cubit.dart';
import 'package:sproki/features/progress_insights/domain/progress_insights.dart';
import 'package:sproki/features/progress_insights/domain/progress_insights_repository.dart';

class _Repository implements ProgressInsightsRepository {
  _Repository(this.onLoad);
  final Future<ProgressInsights> Function() onLoad;
  int calls = 0;

  @override
  Future<ProgressInsights> load() {
    calls++;
    return onLoad();
  }
}

ProgressInsights _insights(int attempts) => ProgressInsights(
  attemptedWords: attempts == 0 ? 0 : 1,
  totalAttempts: attempts,
  successfulAttempts: 0,
  masteredWords: 0,
  suggestions: const [],
);

void main() {
  test('emits loading then empty for a new user', () async {
    final cubit = ProgressInsightsCubit(_Repository(() async => _insights(0)));
    addTearDown(cubit.close);
    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ProgressInsightsLoading>(),
        isA<ProgressInsightsEmpty>(),
      ]),
    );
    await cubit.refresh();
    await observed;
  });

  test('emits immutable loaded insight snapshots', () async {
    final cubit = ProgressInsightsCubit(_Repository(() async => _insights(3)));
    addTearDown(cubit.close);
    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ProgressInsightsLoading>(),
        isA<ProgressInsightsLoaded>(),
      ]),
    );
    await cubit.refresh();
    await observed;
    expect((cubit.state as ProgressInsightsLoaded).insights.totalAttempts, 3);
  });

  test('shows a recoverable error without leaking storage details', () async {
    var fail = true;
    final cubit = ProgressInsightsCubit(_Repository(() async {
      if (fail) {
        fail = false;
        throw StateError('confidential storage error');
      }
      return _insights(2);
    }));
    addTearDown(cubit.close);

    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ProgressInsightsLoading>(),
        isA<ProgressInsightsFailure>(),
        isA<ProgressInsightsLoading>(),
        isA<ProgressInsightsLoaded>(),
      ]),
    );
    await cubit.refresh();
    await cubit.refresh();
    await observed;
  });

  test('ignores overlapping refresh and async completion after close', () async {
    final pending = Completer<ProgressInsights>();
    final repository = _Repository(() => pending.future);
    final cubit = ProgressInsightsCubit(repository);

    final first = cubit.refresh();
    await cubit.refresh();
    expect(repository.calls, 1);
    expect(cubit.state, isA<ProgressInsightsLoading>());

    await cubit.close();
    pending.complete(_insights(2));
    await first;
    expect(cubit.isClosed, isTrue);
  });
}
