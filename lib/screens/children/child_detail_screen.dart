import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../models/report.dart';
import '../../services/sproki_service.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({
    super.key,
    required this.service,
    required this.childId,
  });

  final SprokiService service;
  final int childId;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  bool _loading = true;
  bool _posting = false;
  String? _error;

  ChildReportAnalysis? _report;
  List<ExerciseItem> _exercises = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        widget.service.latestReport(widget.childId),
        widget.service.recommendedExercises(widget.childId),
      ]);

      final report = results[0] as ChildReportAnalysis;
      final exercises = results[1] as List<ExerciseItem>;

      if (!mounted) return;

      setState(() {
        _report = report;
        _exercises = exercises;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _postAttemptDialog(ExerciseItem e) async {
    if (_posting) return;

    // Capture messenger BEFORE await
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(e.title),
        content: const Text('Simuler et forsøg: var det korrekt?'),
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

    setState(() {
      _posting = true;
    });

    try {
      final attemptId = await widget.service.postAttempt(
        childId: widget.childId,
        exerciseId: e.id,
        correct: ok,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Gemte attempt: $attemptId')),
      );
    } catch (err) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Kunne ikke gemme attempt: $err')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  Future<void> _startTraining() async {
    if (_posting) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _posting = true;
    });

    try {
      final attemptId = await widget.service.startTraining(
        childId: widget.childId,
        exerciseIds: _exercises.map((x) => x.id).toList(),
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Træning startet (attempt: $attemptId)')),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Kunne ikke starte træning: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childId = widget.childId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Barn $childId'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(error: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      Text('Rapport',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _ReportBlock(report: _report),
                      const SizedBox(height: 24),
                      Text('Øvelser',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (_exercises.isEmpty)
                        const Text('Ingen anbefalede øvelser lige nu.')
                      else
                        ..._exercises.map(
                          (e) => Card(
                            child: ListTile(
                              title: Text(e.title),
                              subtitle:
                                  Text('${e.domainName} (${e.domainCode})'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  _posting ? null : () => _postAttemptDialog(e),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_loading || _posting) ? null : _startTraining,
            child: Text(_posting ? 'Arbejder…' : 'Start træning'),
          ),
        ),
      ),
    );
  }
}

class _ReportBlock extends StatelessWidget {
  const _ReportBlock({required this.report});

  final ChildReportAnalysis? report;

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return const Text('Ingen rapport endnu.');
    }

    final r = report!;
    if (r.domains.isEmpty) {
      return const Text('Rapporten har ingen domæner.');
    }

    return Column(
      children: r.domains.map((d) {
        final ptg =
            d.pointsToGreen == null ? '' : ' (mangler ${d.pointsToGreen})';
        return ListTile(
          dense: true,
          title: Text('${d.domainName}: ${d.rawScore}'),
          subtitle: Text('Zone: ${d.zone}$ptg'),
        );
      }).toList(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Kunne ikke hente data.'),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Prøv igen'),
            ),
          ],
        ),
      ),
    );
  }
}
