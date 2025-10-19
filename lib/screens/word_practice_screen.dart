import 'dart:math';
import 'package:flutter/material.dart';

import 'package:sproki/config/env.dart';
import 'package:sproki/data/words_content.dart'; // WordsRepo + WordContent
import 'package:sproki/routes/app_routes.dart';
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/plan_store.dart';
import 'package:sproki/services/practice_reporter.dart';
import 'package:sproki/services/progress_service.dart';
import 'package:sproki/services/sproki_api.dart';

/// En ord-øvelsesskærm med:
/// - session uden gentagelser (kan seedes med [word])
/// - logging til backend
/// - lokal mestring (EMA)
/// - progress-bar
/// - visning af tips fra plan (for valgt domæne)
class WordPracticeScreen extends StatefulWidget {
  const WordPracticeScreen({
    super.key,
    this.word, // <- kompatibel med eksisterende kald
    this.sessionSize = 8,
    this.domain = 'ordforråd',
  });

  final WordContent? word;
  final int sessionSize;
  final String domain;

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  late final _reporter = PracticeReporter(SprokiApi(baseUrl: Env.apiBaseUrl));
  final _rand = Random();

  late List<WordContent> _sessionWords;
  int _index = 0; // 0.._sessionWords.length-1
  bool _busy = false;

  String? _childId;

  // Tips hentet fra seneste plan for domænet
  List<String> _domainTips = const [];

  @override
  void initState() {
    super.initState();
    _childId = ActiveChildService.instance.activeChildIdSync;
    _init();
  }

  Future<void> _init() async {
    // progress service
    await ProgressService.instance.init();

    // session-ord (seed med evt. startord)
    _sessionWords = _buildSessionWords(widget.sessionSize, seed: widget.word);

    // tips fra plan
    _domainTips = _loadTipsForDomain(_childId, widget.domain);

    if (mounted) setState(() {});
  }

  List<WordContent> _buildSessionWords(int count, {WordContent? seed}) {
    final all = List<WordContent>.from(WordsRepo.instance.all);
    all.shuffle(_rand);

    if (all.isEmpty) return const [];

    // Fjern seed fra all (hvis findes), og placer først
    final picked = <WordContent>[];
    if (seed != null) {
      picked.add(seed);
      all.removeWhere((w) => w.id == seed.id);
    }

    // Fyld resten op uden dubletter
    for (final w in all) {
      if (picked.length >= count) break;
      picked.add(w);
    }
    return picked;
  }

  /// Hent “tips” fra PlanStore for valgt domæne (ignorerer diakritik)
  List<String> _loadTipsForDomain(String? childId, String domain) {
    if (childId == null || childId.isEmpty) return const [];
    final plan = PlanStore.getPlan(childId);
    if (plan == null) return const [];
    final normalize = ProgressService.normalize;

    // priorityAreas (indeholder tips per item)
    final areas = (plan['priorityAreas'] as List?) ?? const [];
    for (final a in areas) {
      if (a is Map) {
        final dom = '${a['domain'] ?? ''}';
        if (normalize(dom) == normalize(domain)) {
          final tips = (a['tips'] as List?) ?? const [];
          return tips.map((e) => e.toString()).toList();
        }
      }
    }

    // fallback: recommendations
    final recs = (plan['recommendations'] as List?) ?? const [];
    for (final r in recs) {
      if (r is Map) {
        final dom = '${r['domain'] ?? ''}';
        if (normalize(dom) == normalize(domain)) {
          final tips = (r['tips'] as List?) ?? const [];
          return tips.map((e) => e.toString()).toList();
        }
      }
    }
    return const [];
  }

  WordContent? get _current => (_index >= 0 && _index < _sessionWords.length)
      ? _sessionWords[_index]
      : null;

  Future<void> _submit(bool success) async {
    final item = _current;
    final childId = _childId;
    if (item == null || childId == null || childId.isEmpty) return;

    final exerciseId = 'word:${item.id}';
    final domain = widget.domain;

    setState(() => _busy = true);
    try {
      // 1) Backend-logging
      await _reporter.report(
        domain: domain.toLowerCase(),
        exerciseId: exerciseId,
        success: success,
        score: success ? 1.0 : 0.0,
        meta: {'word': item.word, 'category': item.category},
      );

      // 2) Lokal mestring (EMA)
      await ProgressService.instance.updateOnAnswer(
        childId: childId,
        domain: domain,
        exerciseId: exerciseId,
        score: success ? 1.0 : 0.0,
      );
    } catch (_) {
      // “best effort”
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    // 3) Næste opgave eller slut
    if (!mounted) return;
    if (_index + 1 < _sessionWords.length) {
      setState(() => _index += 1);
    } else {
      _finishSession();
    }
  }

  void _finishSession() {
    final domain = widget.domain;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final childId = _childId ?? '';
        final prog = ProgressService.instance.domainProgress(childId, domain);
        final percent = (prog['percent'] as num?)?.toDouble() ?? 0.0;
        final attempts = (prog['attempts'] as int?) ?? 0;

        return AlertDialog(
          title: const Text('Godt klaret! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sessionen for "$domain" er færdig.'),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: percent / 100.0),
              const SizedBox(height: 8),
              Text(
                  'Mestring: ${percent.toStringAsFixed(0)}%  •  Forsøg: $attempts'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // tilbage til hovedmenu – ryd stacken for at undgå tom side
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.mainMenu,
                  (route) => false,
                );
              },
              child: const Text('Til hovedmenu'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // ny session (seed evt. med samme startord igen)
                setState(() {
                  _index = 0;
                  _sessionWords =
                      _buildSessionWords(widget.sessionSize, seed: widget.word);
                });
              },
              child: const Text('Ny session'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _current;
    final childId = _childId ?? '';
    final domain = widget.domain;

    // Progress til header
    final prog = (childId.isEmpty)
        ? const {'percent': 0.0, 'attempts': 0}
        : ProgressService.instance.domainProgress(childId, domain);
    final percent = (prog['percent'] as num?)?.toDouble() ?? 0.0;
    final attempts = (prog['attempts'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Øvelse – $domain'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              '${_index + 1}/${_sessionWords.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
      body: item == null
          ? const Center(child: Text('Ingen ord at øve lige nu'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- Progress header for domænet ---
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fremskridt i $domain',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: percent / 100.0),
                          const SizedBox(height: 4),
                          Text(
                            'Mestring: ${percent.toStringAsFixed(0)}%  •  Forsøg: $attempts',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Tips fra planen ---
                  if (_domainTips.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tips',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ..._domainTips.map((t) => Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• '),
                                    Expanded(child: Text(t)),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // --- Selve opgaven ---
                  Expanded(
                    child: Card(
                      elevation: 1,
                      child: Center(
                        child: Text(
                          item.word,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Kategori: ${item.category}',
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),

                  // --- Svar-knapper ---
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : () => _submit(false),
                          icon: const Icon(Icons.close),
                          label: const Text('Forkert'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : () => _submit(true),
                          icon: const Icon(Icons.check),
                          label: const Text('Rigtigt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
    );
  }
}
