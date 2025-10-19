import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/progress_service.dart';

/// Lille (udvidbar) dansk rim-ordbog. Nøglen er “målordet” (prompt),
/// værdien er en liste af ord der rimer på nøglen.
const Map<String, List<String>> _rhymeDict = {
  'bil': ['pil', 'fil'],
  'hat': ['kat', 'skat', 'mat'],
  'hus': ['mus', 'lus'],
  'sol': ['stol'], // nær-rim er ok
  'sko': ['gro', 'to'],
  'dag': ['lag', 'flag'],
  'kat': ['hat', 'skat'],
  'lam': ['kam', 'jam'],
  'bog': ['sprog'], // nær-rim/assonans – udvid som du vil
  'bold': ['kold', 'sold'],
  'bus': ['kus', 'lus', 'mus'],
  'ris': ['gris', 'mis', 'vis'],
  'hund': ['mund', 'blund'],
  'fugl': ['hjul'], // nær-rim
};

/// Samling af *ikke*-rim-ord (til distraktorer)
const List<String> _distractorsPool = [
  'banan',
  'æble',
  'tog',
  'kage',
  'bord',
  'brev',
  'vand',
  'mønt',
  'lys',
  'blomst',
  'gulerod',
  'ost',
  'tårn',
  'måne',
  'træ',
];

class RhymePracticeScreen extends StatefulWidget {
  const RhymePracticeScreen({super.key});

  @override
  State<RhymePracticeScreen> createState() => _RhymePracticeScreenState();
}

class _RhymePracticeScreenState extends State<RhymePracticeScreen> {
  final _rnd = Random();

  // Flow state
  late String _prompt; // fx “bil”
  late List<String> _options; // 4 knapper med blandede ord
  late Set<String> _correct; // hvilke af _options er rigtige
  int _round = 0;
  final int _totalRounds = 6;

  // UI state
  String? _selected; // sidst valgte ord
  bool _locked = false; // lås når der er svaret

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  void _nextRound() {
    final prompts = _rhymeDict.keys.toList();
    _prompt = prompts[_rnd.nextInt(prompts.length)];
    _buildOptionsFor(_prompt);
    _round += 1;
    _selected = null;
    _locked = false;
    setState(() {});
  }

  void _buildOptionsFor(String prompt) {
    final rhymes = List<String>.from(_rhymeDict[prompt] ?? const []);
    rhymes.shuffle(_rnd);

    // 1–2 korrekte (hvis muligt)
    final wantCorrect = rhymes.isEmpty ? 0 : (_rnd.nextBool() ? 2 : 1);
    final correct = rhymes.take(wantCorrect.clamp(1, rhymes.length)).toSet();

    // Distraktorer må ikke være i korrekte eller være selve prompten
    final pool = _distractorsPool
        .where((w) => w != prompt && !correct.contains(w))
        .toList()
      ..shuffle(_rnd);

    // Fyld op til 4 muligheder
    final options = <String>[
      ...correct,
      ...pool.take(4 - correct.length),
    ]..shuffle(_rnd);

    // Sikring: i *meget* små datasæt kan korrekt blive tom – så tving én ind
    if (correct.isEmpty) {
      final fallback = (rhymes.isNotEmpty ? rhymes.first : null);
      if (fallback != null) {
        if (!options.contains(fallback)) {
          options[_rnd.nextInt(options.length)] = fallback;
        }
        correct.add(fallback);
      }
    }

    _options = options;
    _correct = correct;
  }

  Future<void> _onAnswer(String choice) async {
    if (_locked) return;
    _locked = true;
    _selected = choice;
    setState(() {});

    final isCorrect = _correct.contains(choice);

    // Opdatér lokal mestring (EMA)
    final childId = ActiveChildService.instance.activeChildIdSync ?? 'local';
    await ProgressService.instance.updateOnAnswer(
      childId: childId,
      domain: 'rim',
      exerciseId: 'rhyme:$_prompt', // én øvelse pr. prompt
      score: isCorrect ? 1.0 : 0.0,
      alpha: 0.35,
    );

    // Lille delay så barnet når at se feedback
    await Future.delayed(const Duration(milliseconds: 700));

    if (_round >= _totalRounds) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Godt gået!'),
          content: const Text('Du har gennemført en runde med rim.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Luk'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      _nextRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final mastery = ProgressService.instance.domainProgress(
      ActiveChildService.instance.activeChildIdSync ?? 'local',
      'rim',
    );
    final masteryPct =
        (mastery['percent'] as num?)?.toDouble().clamp(0.0, 100.0) ?? 0.0;
    final attempts = (mastery['attempts'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rim'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 20),
            child: Text('${_round.clamp(1, _totalRounds)}/$_totalRounds',
                style: const TextStyle(fontSize: 12)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: cs.primaryContainer.withValues(alpha: .25),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fremskridt i rim',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: masteryPct / 100.0),
                  const SizedBox(height: 4),
                  Text(
                    'Mestring: ${masteryPct.toStringAsFixed(0)}%  •  Forsøg: $attempts',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.surfaceContainerHighest.withValues(alpha: .25),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Text('Hvad rimer på:',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text(_prompt,
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _options.map((opt) {
              final isChosen = _selected == opt;
              final isRight = _correct.contains(opt);
              final Color? bg = !_locked
                  ? cs.surfaceContainerHighest.withValues(alpha: .18)
                  : isChosen
                      ? (isRight ? Colors.green[200] : Colors.red[200])
                      : cs.surfaceContainerHighest.withValues(alpha: .18);

              return SizedBox(
                width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () => _onAnswer(opt),
                  child: Text(opt, style: const TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
