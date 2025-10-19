// lib/screens/category_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:sproki/widgets/paywall_gate.dart';
import '../data/words_content.dart' show WordContent, WordsRepo;
import '../services/category_exercise_service.dart';
import '../services/active_child_service.dart';

class CategoryExerciseScreen extends StatefulWidget {
  const CategoryExerciseScreen({super.key});
  @override
  State<CategoryExerciseScreen> createState() => _CategoryExerciseScreenState();
}

class _CategoryExerciseScreenState extends State<CategoryExerciseScreen> {
  late final CategoryExerciseService _svc;
  late final List<WordContent> _pool;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _svc = CategoryExerciseService();
    _pool = List<WordContent>.from(
      WordsRepo.instance.all.where((w) => w.category.trim().isNotEmpty),
    )..shuffle();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ok = await PaywallGate.ensureNotLocked(context);
      if (!mounted) return;
      if (!ok) {
        Navigator.of(context).maybePop();
        return;
      }
      await PaywallGate.recordAttemptForActiveChild();
    });
  }

  WordContent get _current => _pool[_idx % _pool.length];

  List<String> _optionsFor(WordContent w) {
    final cats = _pool.map((e) => e.category).toSet().toList()..shuffle();
    final other = cats.where((c) => c != w.category).take(2).toList();
    final opts = <String>{w.category, ...other}.toList()..shuffle();
    return opts;
  }

  Future<void> _pick(String chosen) async {
    final correct = _current.category;
    final wasCorrect = chosen == correct;

    await _svc.saveAttempt(
      wordId: _current.id,
      chosenCategory: chosen,
      correctCategory: correct,
      wasCorrect: wasCorrect,
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasCorrect
              ? 'Korrekt! ${_current.word} hører til "$correct"'
              : 'Ikke helt. Korrekt var "$correct"',
        ),
      ),
    );

    setState(() => _idx += 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_pool.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kategorisering')),
        body: const Center(child: Text('Ingen ord med kategorier fundet.')),
      );
    }

    final w = _current;
    final opts = _optionsFor(w);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorisering'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          Builder(
            builder: (ctx) {
              final id = ActiveChildService.instance.activeChildIdSync ?? '';
              return IconButton(
                tooltip: 'Min score',
                icon: const Icon(Icons.insights),
                onPressed: () {
                  final st = _svc.statsForChild(id);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Rigtige: ${st['correct']}/${st['total']}'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Text(w.emoji.isNotEmpty ? w.emoji : '🔤',
                      style: const TextStyle(fontSize: 42)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      w.word,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ...opts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _pick(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(c, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Spørgsmål ${(_idx % _pool.length) + 1} af ${_pool.length}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ]),
        ),
      ),
    );
  }
}
