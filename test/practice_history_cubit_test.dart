import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
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

  blocTest<PracticeHistoryCubit, PracticeHistoryState>(
    'loads local attempts into an immutable state',
    build: () => PracticeHistoryCubit(
      _FakeRepository(() async => [sample]),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PracticeHistoryLoading>(),
      isA<PracticeHistoryLoaded>().having(
        (state) => state.attempts.single.word,
        'practiced word',
        'Kat',
      ),
    ],
    verify: (cubit) {
      final loaded = cubit.state as PracticeHistoryLoaded;
      expect(() => loaded.attempts.clear(), throwsUnsupportedError);
    },
  );

  blocTest<PracticeHistoryCubit, PracticeHistoryState>(
    'emits empty state when there are no attempts',
    build: () => PracticeHistoryCubit(_FakeRepository(() async => [])),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PracticeHistoryLoading>(),
      isA<PracticeHistoryEmpty>(),
    ],
  );

  blocTest<PracticeHistoryCubit, PracticeHistoryState>(
    'exposes failure without leaking an exception and supports retry',
    build: () {
      var fail = true;
      return PracticeHistoryCubit(
        _FakeRepository(() async {
          if (fail) {
            fail = false;
            throw StateError('Storage detail must not reach the UI');
          }
          return [sample];
        }),
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => [
      isA<PracticeHistoryLoading>(),
      isA<PracticeHistoryFailure>(),
      isA<PracticeHistoryLoading>(),
      isA<PracticeHistoryLoaded>(),
    ],
  );

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
