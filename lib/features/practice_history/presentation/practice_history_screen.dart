import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../application/practice_history_cubit.dart';
import '../domain/practice_history_repository.dart';

/// Shows attempts already stored on this device; never contacts a server.
class PracticeHistoryScreen extends StatelessWidget {
  const PracticeHistoryScreen({super.key, required this.repository});

  final PracticeHistoryRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PracticeHistoryCubit(repository)..load(),
      child: const _PracticeHistoryView(),
    );
  }
}

class _PracticeHistoryView extends StatelessWidget {
  const _PracticeHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Øvelseshistorik'),
        actions: [
          IconButton(
            tooltip: 'Opdater historik',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PracticeHistoryCubit>().load(),
          ),
        ],
      ),
      body: BlocBuilder<PracticeHistoryCubit, PracticeHistoryState>(
        builder: (context, state) {
          if (state is PracticeHistoryLoading ||
              state is PracticeHistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PracticeHistoryFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Kunne ikke hente øvelseshistorikken.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          context.read<PracticeHistoryCubit>().load(),
                      child: const Text('Prøv igen'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PracticeHistoryEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ingen øvelser endnu. Prøv et ord for at komme i gang.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is PracticeHistoryLoaded) {
            final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.attempts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final attempt = state.attempts[index];
                return ListTile(
                  leading: Icon(
                    attempt.wasSuccessful
                        ? Icons.check_circle_outline
                        : Icons.replay,
                    color: attempt.wasSuccessful
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(attempt.word),
                  subtitle: Text(dateFormat.format(attempt.practicedAt)),
                  trailing: Text(
                    attempt.wasSuccessful ? 'Godkendt' : 'Øv videre',
                  ),
                );
              },
            );
          }

          // The sealed state hierarchy is exhaustive above.
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
