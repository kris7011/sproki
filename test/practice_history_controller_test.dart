import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/practice_history/application/practice_history_controller.dart';
import 'package:sproki/features/practice_history/domain/practice_attempt.dart';
import 'package:sproki/features/practice_history/domain/practice_history_repository.dart';

class _FakeRepository implements PracticeHistoryRepository {
  _FakeRepository(this.loadAction);
  final Future<List<PracticeAttempt>> Function() loadAction;

  @override
  Future<List<PracticeAttempt>> loadRecent({int limit = 50}) => loadAction();
}

void main() {
  final sample = PracticeAttempt(
    word: 'Kat',
    practicedAt: DateTime(2026, 11, 3),
    wasSuccessful: true,
  );

  test('loads immutable history without leaking storage details', () async {
    final controller = PracticeHistoryController(
      _FakeRepository(() async => [sample]),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(controller.attempts.single.word, 'Kat');
    expect(() => controller.attempts.clear(), throwsUnsupportedError);
  });

  test('reports failures and supports retry', () async {
    var shouldFail = true;
    final controller = PracticeHistoryController(
      _FakeRepository(() async {
        if (shouldFail) {
          throw StateError('storage unavailable');
        }
        return [sample];
      }),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.error, isA<StateError>());
    expect(controller.isLoading, isFalse);

    shouldFail = false;
    await controller.load();
    expect(controller.error, isNull);
    expect(controller.attempts, hasLength(1));
  });
}
