import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sproki/features/practice_history/data/hive_practice_history_repository.dart';
import 'package:sproki/models/word_attempt.dart';

void main() {
  late Directory directory;
  late Box<WordAttempt> box;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('sproki-history-test-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WordAttemptAdapter());
    }
    box = await Hive.openBox<WordAttempt>('history-test');
  });

  setUp(() async => box.clear());

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('maps existing Hive attempts into newest-first immutable snapshots', () async {
    await box.add(
      WordAttempt(
        wordId: 'a',
        targetWord: 'Mus',
        accuracyScore: 0.5,
        attemptTime: DateTime(2026, 11, 1),
        sessionId: 1,
        wasSuccessful: false,
      ),
    );
    await box.add(
      WordAttempt(
        wordId: 'b',
        targetWord: 'Sol',
        accuracyScore: 1.0,
        attemptTime: DateTime(2026, 11, 3),
        sessionId: 2,
        wasSuccessful: true,
      ),
    );
    final repository = HivePracticeHistoryRepository(box);
    final recent = await repository.loadRecent(limit: 1);

    expect(recent, hasLength(1));
    expect(recent.single.word, 'Sol');
    expect(recent.single.wasSuccessful, isTrue);
    expect(() => recent.clear(), throwsUnsupportedError);
  });

  test('rejects negative history limits', () async {
    final repository = HivePracticeHistoryRepository(box);
    await expectLater(
      repository.loadRecent(limit: -1),
      throwsRangeError,
    );
  });
}
