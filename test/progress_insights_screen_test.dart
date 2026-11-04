import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sproki/features/progress_insights/domain/progress_insights.dart';
import 'package:sproki/features/progress_insights/domain/progress_insights_repository.dart';
import 'package:sproki/features/progress_insights/presentation/progress_insights_screen.dart';

class _FakeRepository implements ProgressInsightsRepository {
  _FakeRepository(this.insights);

  ProgressInsights insights;
  int calls = 0;

  @override
  Future<ProgressInsights> load() async {
    calls++;
    return insights;
  }
}

void main() {
  testWidgets('shows a helpful empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProgressInsightsScreen(
          repository: _FakeRepository(
            ProgressInsights(
              attemptedWords: 0,
              totalAttempts: 0,
              successfulAttempts: 0,
              masteredWords: 0,
              suggestions: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Der er endnu ingen registrerede'), findsOneWidget);
  });

  testWidgets('shows suggestions and refreshes from a repository', (tester) async {
    final repository = _FakeRepository(
      ProgressInsights(
        attemptedWords: 1,
        totalAttempts: 3,
        successfulAttempts: 1,
        masteredWords: 0,
        suggestions: const [
          SuggestedWord(
            wordId: 'and',
            word: 'and',
            totalAttempts: 3,
            successRate: 1 / 3,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: ProgressInsightsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prøv disse ord igen'), findsOneWidget);
    expect(find.byKey(const Key('insight-and')), findsOneWidget);

    await tester.tap(find.byTooltip('Opdater øveforslag'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });
}
