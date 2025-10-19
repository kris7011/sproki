// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:sproki/config/env.dart';
import 'package:sproki/services/sproki_api.dart';
import 'package:sproki/widgets/plan_badge.dart';

import '../routes/app_routes.dart';
import '../services/sync_manager.dart';
import '../services/active_child_service.dart';
import '../services/plan_store.dart';
import '../services/progress_service.dart';

import '../data/words_content.dart';
import '../screens/word_practice_screen.dart';
import '../screens/category_exercise_screen.dart';
import '../screens/rhyme_practice_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _syncing = false;
  String? _activeChildId;

  @override
  void initState() {
    super.initState();
    _activeChildId = ActiveChildService.instance.activeChildIdSync;
    ActiveChildService.instance.activeChildIdListenable.addListener(_onActive);
  }

  @override
  void dispose() {
    ActiveChildService.instance.activeChildIdListenable
        .removeListener(_onActive);
    super.dispose();
  }

  void _onActive() {
    setState(() {
      _activeChildId = ActiveChildService.instance.activeChildIdSync;
    });
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await SyncManager.instance.syncAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Synkronisering gennemført')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Sync-fejl: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // Domæne-router
  Future<void> _openExerciseForDomain(String domain) async {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll('æ', 'ae')
        .replaceAll('ø', 'o')
        .replaceAll('å', 'a')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();

    final key = norm(domain);

    if (key == 'ordforrad') {
      final all = WordsRepo.instance.all;
      if (all.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingen ord tilgængelige endnu')),
        );
        return;
      }
      final w = all.first;
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WordPracticeScreen(word: w)),
      );
      return;
    }

    if (key == 'rim') {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RhymePracticeScreen()),
      );
      return;
    }

    // fallback: kategorisering / generisk
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryExerciseScreen()),
    );
  }

  // Hent plan igen (fix: baseUrl + Map-return)
  Future<void> _refreshPlan() async {
    final id = _activeChildId ?? '';
    if (id.isEmpty) return;
    try {
      final api = SprokiApi(baseUrl: Env.apiBaseUrl);
      final planMap = await api.getPlanMap(id);
      await PlanStore.savePlan(id, planMap);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan opdateret')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke hente plan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Lyt både til PlanStore og lokal mestring – så bliver “Anbefalede øvelser”
    // dynamiske når barnet øver.
    return ValueListenableBuilder(
      valueListenable: PlanStore.listenable(),
      builder: (_, __, ___) {
        return ValueListenableBuilder(
          valueListenable: ProgressService.instance.listenable(),
          builder: (_, ____, _____) {
            final childId = _activeChildId ?? '';
            final hasChild = childId.isNotEmpty;
            final plan = hasChild ? PlanStore.getPlan(childId) : null;
            final hasPlan = plan != null;

            // Ekstraher og sorter “targets” (ikke-grønne), men
            // skjul domæner hvor lokal mestring >= 70 %
            final List<Map<String, dynamic>> targets = [];
            if (hasPlan) {
              final rawList = (plan['priorityAreas'] as List?) ?? const [];
              for (final item in rawList) {
                final m = Map<String, dynamic>.from(item as Map);
                final zone = (m['zone'] as String? ?? '').toLowerCase().trim();

                final domain = (m['domain'] as String? ?? '');
                final prog =
                    ProgressService.instance.domainProgress(childId, domain);
                final masteryPct = (prog['percent'] as num?)?.toDouble() ?? 0.0;

                if (masteryPct >= 70.0) {
                  // Barnet er stærkt lokalt – spring over i anbefalinger
                  continue;
                }

                m['localMastery'] = masteryPct;
                if (zone != 'grøn' && zone != 'gron') {
                  targets.add(m);
                }
              }

              int zoneRank(String z) {
                z = z.toLowerCase().trim();
                if (z == 'rød' || z == 'rod') return 0;
                if (z == 'gul') return 1;
                return 2;
              }

              targets.sort((a, b) {
                final zr = zoneRank('${a['zone']}')
                    .compareTo(zoneRank('${b['zone']}'));
                if (zr != 0) return zr;
                final la = (a['localMastery'] as num?)?.toDouble() ?? 0.0;
                final lb = (b['localMastery'] as num?)?.toDouble() ?? 0.0;
                return la.compareTo(lb);
              });
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Sproki'),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                actions: [
                  const PlanBadge(),
                  IconButton(
                    tooltip: 'Opdatér plan',
                    onPressed: _refreshPlan,
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: 'Vælg barn',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.selectChild),
                    icon: const Icon(Icons.family_restroom),
                  ),
                  IconButton(
                    tooltip: 'Synkroniser nu',
                    onPressed: _syncing ? null : _syncNow,
                    icon: _syncing
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.sync),
                  ),
                ],
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!hasChild)
                      Card(
                        color: Colors.yellow[50],
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Intet barn valgt'),
                          subtitle:
                              const Text('Vælg et barn for at komme i gang'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.selectChild),
                        ),
                      ),
                    if (hasChild && !hasPlan) ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: const Text('Upload sprogtest'),
                          subtitle: const Text(
                            'Få personlige øvelser baseret på barnets behov',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.parentReportUpload,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Når du har uploadet en rapport, vil de relevante øvelser dukke op her.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                    if (hasChild && hasPlan && targets.isEmpty) ...[
                      Card(
                        color: Colors.green[50],
                        child: const ListTile(
                          leading: Icon(Icons.verified, color: Colors.green),
                          title: Text('Alt ser stærkt ud!'),
                          subtitle: Text(
                              'Upload en ny rapport, når I får en opdatering.'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.parentReportUpload),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Upload ny rapport'),
                      ),
                    ],
                    if (hasChild && hasPlan && targets.isNotEmpty) ...[
                      const Text(
                        'Anbefalede øvelser',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...targets.map((m) {
                        final domain = (m['domain'] as String? ?? '').trim();
                        final zone = (m['zone'] as String? ?? '').trim();
                        final score = (m['score'] is num)
                            ? (m['score'] as num).toStringAsFixed(1)
                            : '${m['score']}';
                        final goal = (m['shortTermGoal'] is num)
                            ? (m['shortTermGoal'] as num).toStringAsFixed(1)
                            : '${m['shortTermGoal']}';
                        final mastery =
                            (m['localMastery'] as num?)?.toDouble() ?? 0.0;

                        final z = zone.toLowerCase();
                        Color iconColor = Colors.green;
                        if (z == 'rød' || z == 'rod') iconColor = Colors.red;
                        if (z == 'gul') iconColor = Colors.orange;

                        return Card(
                          child: ListTile(
                            leading:
                                Icon(Icons.play_circle_fill, color: iconColor),
                            title: Text(domain.isEmpty ? 'Øvelse' : domain),
                            subtitle: Text(
                              'Score: $score  •  Mål: $goal  •  Zone: $zone  •  Mestring: ${mastery.toStringAsFixed(0)}%',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openExerciseForDomain(domain),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.parentReportUpload),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Upload ny rapport (opdater plan)'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
