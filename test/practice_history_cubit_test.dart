import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/practice_history/application/practice_history_cubit.dart';
import 'package:sproki/features/practice_history/domain/practice_attempt.dart';
import 'package:sproki/features/practice_history/domain/practice_history_repository.dart';

class _FakeRepository implements PracticeHistoryRepository {
  _FakeRepository(this.loadAction);

  final Future<List<PracticeAttempt>> Function() loadAction;
  int calls = 0;

  @override
  Future<List<PracticeAttempt>> loadRecent({int limit = 50}) {
    calls++;
    return loadAction();
  }
}

void main() {
  final sample = PracticeAttempt(
    word: 'Kat',
    practicedAt: DateTime(2026, 11, 3),
    wasSuccessful: true,
  );

  test('loads attempts into an immutable state through its state stream', () async {
    final cubit = PracticeHistoryCubit(
      _FakeRepository(() async => [sample]),
    );
    addTearDown(cubit.close);

    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<PracticeHistoryLoading>(),
        isA<PracticeHistoryLoaded>().having(
          (state) => state.attempts.single.word,
          'practiced word',
          'Kat',
        ),
      ]),
    );
    await cubit.load();
    await observed;

    final loaded = cubit.state as PracticeHistoryLoaded;
    expect(() => loaded.attempts.clear(), throwsUnsupportedError);
  });

  test('emits loading then empty for an unused device', () async {
    final cubit = PracticeHistoryCubit(_FakeRepository(() async => []));
    addTearDown(cubit.close);

    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<PracticeHistoryLoading>(),
        isA<PracticeHistoryEmpty>(),
      ]),
    );
    await cubit.load();
    await observed;
  });

  test('reports failure without leaking exceptions and supports retry', () async {
    var shouldFail = true;
    final cubit = PracticeHistoryCubit(
      _FakeRepository(() async {
        if (shouldFail) {
          shouldFail = false;
          throw StateError('Internal storage detail');
        }
        return [sample];
      }),
    );
    addTearDown(cubit.close);

    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<PracticeHistoryLoading>(),
        isA<PracticeHistoryFailure>(),
        isA<PracticeHistoryLoading>(),
        isA<PracticeHistoryLoaded>(),
      ]),
    );

    await cubit.load();
    await cubit.load();
    await observed;
  });

  test('does not emit after a Cubit was closed during a read', () async {
    final pending = Completer<List<PracticeAttempt>>();
    final cubit = PracticeHistoryCubit(_FakeRepository(() => pending.future));

    final loading = cubit.load();
    expect(cubit.state, isA<PracticeHistoryLoading>());

    await cubit.close();
    pending.complete([sample]);
    await loading;
    expect(cubit.isClosed, isTrue);
  });

  test('deduplicates overlapping refresh requests', () async {
    final pending = Completer<List<PracticeAttempt>>();
    final repository = _FakeRepository(() => pending.future);
    final cubit = PracticeHistoryCubit(repository);
    addTearDown(cubit.close);

    final first = cubit.load();
    final second = cubit.load();

    expect(repository.calls, 1);
    expect(cubit.state, isA<PracticeHistoryLoading>());

    pending.complete([sample]);
    await Future.wait([first, second]);
    expect(cubit.state, isA<PracticeHistoryLoaded>());
  });
}
