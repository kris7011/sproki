// lib/screens/plan_screen.dart
import 'package:flutter/material.dart';
import 'package:sproki/services/sproki_api.dart';
import 'package:sproki/services/thresholds.dart';
import 'package:sproki/services/active_child_service.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late Future<Map<String, dynamic>> _future;
  final _api = SprokiApi();

  String get _childId =>
      ActiveChildService.instance.activeChildIdSync ?? 'local-default';

  @override
  void initState() {
    super.initState();
    _future = _api.getPlanMap(_childId);
  }

  Color _zoneColor(String z) {
    switch (z) {
      case 'rød':
        return Colors.red;
      case 'gul':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _api.getPlanMap(_childId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sproki Plan'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Text('Kunne ikke hente plan: ${snap.error}'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Prøv igen'),
                    ),
                  ),
                ],
              );
            }

            final plan = snap.data!;
            final areas = (plan['priorityAreas'] as List).cast<Map>();
            final ageMonths = plan['meta']?['ageMonths'];
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: areas.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return Card(
                    child: ListTile(
                      title: const Text('Plan (seneste rapport)'),
                      subtitle: Text(
                          'Alder (mdr): $ageMonths • mode: ${plan['meta']?['mode']}'),
                    ),
                  );
                }
                final a = areas[idx - 1].cast<String, dynamic>();
                final domain = a['domain'] as String;
                final score = (a['score'] as num).toDouble();
                final zone = a['zone'] as String;
                final dist = (a['distToGreen'] as num).toDouble();
                final goal = (a['shortTermGoal'] as num).toDouble();
                final tips = (a['tips'] as List).cast<String>();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _zoneColor(zone),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                domain,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(score.toStringAsFixed(1)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Zone: $zone • mangler: ${dist.toStringAsFixed(1)} • kort mål: ${goal.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        if (tips.isNotEmpty) ...[
                          const Text('Tips:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ...tips.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $t'),
                              )),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
