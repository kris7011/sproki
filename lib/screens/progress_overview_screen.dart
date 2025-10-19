// lib/screens/progress_overview_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:sproki/utils/chart_widgets.dart';

import '../blocs/progress_overview/progress_overview_cubit.dart';
import '../blocs/progress_overview/progress_overview_state.dart';
import '../repositories/progress_repository.dart';
import '../data/words_content.dart';
import 'word_practice_screen.dart';

class ProgressOverviewScreen extends StatelessWidget {
  const ProgressOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProgressOverviewCubit(ProgressRepository())..init(),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fremgang'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportPdf(context),
          ),
        ],
      ),
      body: BlocBuilder<ProgressOverviewCubit, ProgressOverviewState>(
        builder: (context, state) {
          if (state.childId == null || state.childId!.isEmpty) {
            return const _Empty('Vælg et barn for at se fremgang.');
          }
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return _ErrorBox(
              msg: state.error!,
              onRetry: () => context.read<ProgressOverviewCubit>().refresh(),
            );
          }

          final summary = state.summary;
          return RefreshIndicator(
            onRefresh: () => context.read<ProgressOverviewCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  totalStars: summary?.totalStars ?? 0,
                  avgSuccess:
                      (summary?.averageSuccessRate ?? 0.0).clamp(0.0, 1.0),
                  mastered: summary?.masteredWords ?? 0,
                ),
                const SizedBox(height: 12),
                _ChartCard(
                  title: 'Succesrate (14 dage)',
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Sparkline(values: state.successSpark),
                  ),
                ),
                const SizedBox(height: 12),
                _ChartCard(
                  title: 'Forsøg pr. dag (14 dage)',
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: BarChartMini(bins: state.attemptsBars),
                  ),
                ),
                const SizedBox(height: 16),
                _RecommendationsCard(
                  picks: state.recommendations,
                  onPractice: (wc) => _openPractice(context, wc),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openPractice(BuildContext context, WordContent wc) async {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordPracticeScreen(word: wc)),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final state = context.read<ProgressOverviewCubit>().state;
    try {
      final child = state.childId ?? 'ukendt';
      final totalStars = state.summary?.totalStars ?? 0;
      final mastered = state.summary?.masteredWords ?? 0;
      final avg =
          ((state.summary?.averageSuccessRate ?? 0) * 100).toStringAsFixed(0);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Header(level: 0, child: pw.Text('Sproki – Rapport')),
            pw.Paragraph(text: 'Barn: $child'),
            pw.Paragraph(text: 'Total stjerner: $totalStars'),
            pw.Paragraph(text: 'Mestrer: $mastered'),
            pw.Paragraph(text: 'Gns. succes: $avg%'),
            pw.SizedBox(height: 16),
            pw.Paragraph(
              text:
                  'Anbefalede ord: ${state.recommendations.map((e) => e.word).join(", ")}',
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/sproki_rapport_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await doc.save());

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF gemt: ${file.path}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke generere PDF: $e')),
      );
    }
  }
}

// --- UI småkomponenter (samme som før) ---
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalStars,
    required this.avgSuccess,
    required this.mastered,
  });
  final int totalStars;
  final double avgSuccess;
  final int mastered;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _Metric(icon: Icons.star, label: 'Stjerner', value: '$totalStars'),
      _Metric(
          icon: Icons.check_circle,
          label: 'Succes',
          value: '${(avgSuccess * 100).toStringAsFixed(0)}%'),
      _Metric(icon: Icons.military_tech, label: 'Mestrer', value: '$mastered'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 8,
          children: chips.map((w) => SizedBox(width: 180, child: w)).toList(),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.indigo[700]),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ])
    ]);
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.picks, required this.onPractice});
  final List<WordContent> picks;
  final void Function(WordContent) onPractice;

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.lightbulb_outline),
          title: Text('Anbefalinger'),
          subtitle:
              Text('Øv et “starter-ord” for at få personlige anbefalinger.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.lightbulb),
              title: Text('Anbefalinger'),
              subtitle: Text('Vi foreslår disse ord som næste skridt.'),
            ),
            const Divider(height: 1),
            ...picks.map((w) => ListTile(
                  leading: Text(w.emoji.isNotEmpty ? w.emoji : '🔤',
                      style: const TextStyle(fontSize: 22)),
                  title: Text(w.word),
                  subtitle:
                      Text('${w.category} • sværhedsgrad: ${w.difficulty}'),
                  trailing: FilledButton(
                    onPressed: () => onPractice(w),
                    child: const Text('Øv nu'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[700], fontWeight: FontWeight.w600)),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.msg, required this.onRetry});
  final String msg;
  final FutureOr<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Fejl',
                style: TextStyle(
                    color: Colors.red[800], fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[800])),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Prøv igen'),
            )
          ]),
        ),
      ),
    );
  }
}
