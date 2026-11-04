import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sproki/data/words_content.dart';
import 'package:sproki/features/progress_insights/data/hive_progress_insights_repository.dart';
import 'package:sproki/models/progress_data.dart';

void main() {
  late Directory directory;
  late Box<ProgressData> box;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('sproki-insights-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ProgressDataAdapter());
    }
    box = await Hive.openBox<ProgressData>('insights-test');
  });

  setUp(() async => box.clear());

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('maps existing Hive data without altering the persisted records', () async {
    final first = DateTime(2026, 11, 1);
    await box.put(
      'and',
      ProgressData(
        wordId: 'and',
        totalAttempts: 3,
        successfulAttempts: 1,
        firstAttempt: first,
        lastAttempt: first,
        sessionDates: [first],
      ),
    );

    final repository = HiveProgressInsightsRepository(
      box,
      words: [
        WordContent(
          id: 'and',
          word: 'And',
          category: 'a-sounds',
          difficulty: 'easy',
          imagePath: '',
          emoji: '',
        ),
      ],
    );
    final result = await repository.load();

    expect(result.totalAttempts, 3);
    expect(result.suggestions.single.word, 'And');
    expect(box.get('and')!.totalAttempts, 3);
    expect(box.length, 1);
  });
}
