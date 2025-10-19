// test/practice_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';

import 'package:sproki/data/words_content.dart';
import 'package:sproki/logic/practice/practice_cubit.dart';
import 'package:sproki/logic/practice/practice_state.dart';
import 'package:sproki/logic/practice/tts_port.dart';
import 'package:sproki/models/word_attempt.dart';
import 'package:sproki/services/paywall_service.dart';

class _FakePaywall extends PaywallService {
  const _FakePaywall();
  @override
  Future<bool> isLockedForChildAsync(String _) async => false;
  @override
  Future<void> recordAttempt(String _) async {}
}

class _FakeTts implements TtsPort {
  @override
  Future<void> dispose() async {}
  @override
  Future<void> speak(String text, {double? rate}) async {}
}

void main() {
  setUpAll(() async {
    // Initialiser in-memory Hive for tests
    await setUpTestHive();

    // Registrér din adapter (typeId skal matche din model)
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(WordAttemptAdapter());
    }
  });

  tearDownAll(() async {
    await tearDownTestHive();
  });

  test('startFlow ender i scored og tæller forsøg', () async {
    final start = const WordContent(id: 'w_cat', word: 'kat', category: 'dyr');
    final cubit = PracticeCubit(
      startWord: start,
      paywall: const _FakePaywall(),
      tts: _FakeTts(),
    );

    expect(cubit.state.phase, PracticePhase.idle);

    await cubit.startFlow();

    expect(cubit.state.phase, PracticePhase.scored);
    expect(cubit.state.totalAttempts, 1);
    expect(cubit.state.score, inInclusiveRange(60, 100));
  });
}
