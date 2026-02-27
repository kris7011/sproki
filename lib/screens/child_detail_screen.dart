import 'package:flutter/material.dart';
import 'package:sproki/models/child.dart';
import 'package:sproki/models/exercise.dart';
import 'package:sproki/models/report.dart';
import 'package:sproki/services/sproki_service.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({
    super.key,
    required this.child,
    required this.service,
  });

  final Child child;
  final SprokiService service;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final child = widget.child;

    return Scaffold(
      appBar: AppBar(title: Text(child.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Rapport', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          FutureBuilder<ChildReportAnalysis>(
            future: widget.service.latestReport(child.id),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text('Kunne ikke hente rapport: ${snap.error}');
              }
              final r = snap.data!;
              return Column(
                children: r.domains.map((d) {
                  final ptg = d.pointsToGreen == null
                      ? ''
                      : ' (mangler ${d.pointsToGreen})';
                  return ListTile(
                    dense: true,
                    title: Text('${d.domainName}: ${d.rawScore}'),
                    subtitle: Text('Zone: ${d.zone}$ptg'),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Øvelser', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          FutureBuilder<List<ExerciseItem>>(
            future: widget.service.recommendedExercises(child.id),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text('Kunne ikke hente øvelser: ${snap.error}');
              }
              final ex = snap.data ?? [];
              if (ex.isEmpty) {
                return const Text('Ingen anbefalede øvelser lige nu.');
              }

              return Column(
                children: ex.map((e) {
                  return Card(
                    child: ListTile(
                      title: Text(e.title),
                      subtitle: Text('${e.domainName} (${e.domainCode})'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        // Capture messenger BEFORE any await, so we don't use context across async gaps
                        final messenger = ScaffoldMessenger.of(context);

                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(e.title),
                            content: const Text(
                                'Simuler et forsøg: var det korrekt?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Forkert'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Korrekt'),
                              ),
                            ],
                          ),
                        );

                        if (ok == null) return;

                        final res = await widget.service.postAttempt(
                          childId: child.id,
                          exerciseId: e.id,
                          correct: ok,
                        );

                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Gemte attempt: $res')),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
