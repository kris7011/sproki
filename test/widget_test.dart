import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/practice_history/domain/practice_attempt.dart';
import 'package:sproki/features/practice_history/domain/practice_history_repository.dart';
import 'package:sproki/features/practice_history/presentation/practice_history_screen.dart';

class _FakeHistoryRepository implements PracticeHistoryRepository {
  _FakeHistoryRepository(this.attempts);

  final List<PracticeAttempt> attempts;

  @override
  Future<List<PracticeAttempt>> loadRecent({int limit = 50}) async =>
      attempts.take(limit).toList();
}

void main() {
  testWidgets('shows a clear empty state when nothing has been practiced', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeHistoryScreen(
          repository: _FakeHistoryRepository(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Øvelseshistorik'), findsOneWidget);
    expect(find.textContaining('Ingen øvelser endnu'), findsOneWidget);
    expect(find.byTooltip('Opdater historik'), findsOneWidget);
  });

  testWidgets('shows locally saved attempts without displaying child details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeHistoryScreen(
          repository: _FakeHistoryRepository([
            PracticeAttempt(
              word: 'Sol',
              practicedAt: DateTime(2026, 11, 3, 10, 30),
              wasSuccessful: true,
            ),
            PracticeAttempt(
              word: 'Mus',
              practicedAt: DateTime(2026, 11, 2, 8),
              wasSuccessful: false,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sol'), findsOneWidget);
    expect(find.text('Mus'), findsOneWidget);
    expect(find.text('Godkendt'), findsOneWidget);
    expect(find.text('Øv videre'), findsOneWidget);
    expect(find.text('03.11.2026 10:30'), findsOneWidget);
  });
}
