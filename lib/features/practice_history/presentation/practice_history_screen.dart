import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../application/practice_history_controller.dart';
import '../domain/practice_history_repository.dart';

/// Shows attempts already stored on this device; never contacts a server.
class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key, required this.repository});

  final PracticeHistoryRepository repository;

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  late final PracticeHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PracticeHistoryController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Øvelseshistorik'),
        actions: [
          IconButton(
            tooltip: 'Opdater historik',
            icon: const Icon(Icons.refresh),
            onPressed: _controller.load,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null) {
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
                      onPressed: _controller.load,
                      child: const Text('Prøv igen'),
                    ),
                  ],
                ),
              ),
            );
          }

          final attempts = _controller.attempts;
          if (attempts.isEmpty) {
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

          final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: attempts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
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
        },
      ),
    );
  }
}
