import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/words_content.dart';
import '../../../screens/word_practice_screen.dart';
import '../application/progress_insights_cubit.dart';
import '../domain/progress_insights.dart';
import '../domain/progress_insights_repository.dart';

/// An explainable overview using only local, already stored practice progress.
class ProgressInsightsScreen extends StatelessWidget {
  const ProgressInsightsScreen({super.key, required this.repository});

  final ProgressInsightsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProgressInsightsCubit(repository)..refresh(),
      child: const _ProgressInsightsView(),
    );
  }
}

class _ProgressInsightsView extends StatelessWidget {
  const _ProgressInsightsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forslag til næste øvelse'),
        actions: [
          IconButton(
            tooltip: 'Opdater øveforslag',
            onPressed: () => context.read<ProgressInsightsCubit>().refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ProgressInsightsCubit, ProgressInsightsState>(
        builder: (context, state) {
          if (state is ProgressInsightsInitial ||
              state is ProgressInsightsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProgressInsightsFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Kunne ikke indlæse dine øveforslag.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        context.read<ProgressInsightsCubit>().refresh(),
                    child: const Text('Prøv igen'),
                  ),
                ],
              ),
            );
          }

          if (state is ProgressInsightsEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Der er endnu ingen registrerede øvelser. '
                  'Prøv nogle ord, og vend tilbage for at se forslag.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is ProgressInsightsLoaded) {
            return _InsightsContent(
              insights: state.insights,
              onRefresh: () =>
                  context.read<ProgressInsightsCubit>().refresh(),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({
    required this.insights,
    required this.onRefresh,
  });

  final ProgressInsights insights;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final catalog = {
      for (final word in initialWords) word.id: word,
    };

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Baseret på øvelser på denne enhed. '
            'Forslagene er automatiske og ikke en faglig vurdering.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  _Metric(label: 'Øvede ord', value: '${insights.attemptedWords}'),
                  _Metric(label: 'Forsøg', value: '${insights.totalAttempts}'),
                  _Metric(label: 'Mestret', value: '${insights.masteredWords}'),
                  _Metric(
                    label: 'Gennemført',
                    value: '${(insights.successRate * 100).round()}%',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prøv disse ord igen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Ord med få forsøg eller lavere registreret træfsikkerhed '
            'vises først. Listen rummer højst fem ord.',
          ),
          const SizedBox(height: 8),
          if (insights.suggestions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Ingen ord har aktuelt behov for gentagelse.'),
              ),
            ),
          ...insights.suggestions.map((suggestion) {
            final word = catalog[suggestion.wordId];
            return Card(
              child: ListTile(
                key: Key('insight-${suggestion.wordId}'),
                title: Text(suggestion.word),
                subtitle: Text(
                  '${suggestion.totalAttempts} forsøg · '
                  '${(suggestion.successRate * 100).round()}% gennemført',
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: word == null
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => WordPracticeScreen(word: word),
                          ),
                        );
                        if (context.mounted) {
                          await onRefresh();
                        }
                      },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
      ],
    );
  }
}
