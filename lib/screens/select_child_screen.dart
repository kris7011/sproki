import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/hive_boxes.dart';
import '../models/child_profile.dart';
import '../services/active_child_service.dart';

class SelectChildScreen extends StatefulWidget {
  const SelectChildScreen({super.key});

  @override
  State<SelectChildScreen> createState() => _SelectChildScreenState();
}

class _SelectChildScreenState extends State<SelectChildScreen> {
  late final Box<ChildProfile> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<ChildProfile>(HiveBoxes.childProfiles);
  }

  Future<void> _createChildFlow() async {
    final nameCtl = TextEditingController();
    DateTime? birth;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: const Text('Opret barn'),
          content: SingleChildScrollView(
            // ← gør dialogens indhold scrollbart på små skærme
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                    labelText: 'Navn',
                    hintText: 'Fx Alma',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        birth == null
                            ? 'Fødselsdato: ikke valgt'
                            : 'Fødselsdato: ${birth!.day.toString().padLeft(2, '0')}-${birth!.month.toString().padLeft(2, '0')}-${birth!.year}',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate:
                              DateTime(now.year - 5, now.month, now.day),
                          firstDate: DateTime(2000),
                          lastDate: now,
                        );
                        if (!ctx.mounted) return;
                        if (picked != null) setStateSB(() => birth = picked);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Vælg'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annullér'),
            ),
            FilledButton(
              onPressed: () {
                final n = nameCtl.text.trim();
                if (n.isEmpty || birth == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Udfyld navn og vælg fødselsdato')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Opret'),
            ),
          ],
        ),
      ),
    );

    if (created != true) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final child = ChildProfile(
      name: nameCtl.text.trim(),
      birthDate: birth!,
      challengeAreas: const <String>[],
      createdAt: DateTime.now(),
    );

    await _box.put(id, child);
    await ActiveChildService.instance.setActiveChildId(id);

    if (!mounted) return;
    Navigator.of(context).pop(); // tilbage til forrige skærm
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vælg barn'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (_, Box<ChildProfile> box, __) {
            final keys = box.keys.map((e) => e.toString()).toList();

            // TOM TILSTAND → scroll-sikkert layout
            if (keys.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Spacer(),
                            const Icon(Icons.child_care,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'Ingen børn fundet',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Opret et barn for at gemme fremskridt.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _createChildFlow,
                              icon: const Icon(Icons.add),
                              label: const Text('Opret barn'),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            // LISTE TILSTAND → rigtig scrollende liste
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: keys.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (itemCtx, i) {
                final id = keys[i];
                final p = box.get(id);
                if (p == null) return const SizedBox.shrink();
                return ListTile(
                  leading: const Icon(Icons.face),
                  title: Text(p.name),
                  subtitle: Text(
                    'Født: ${p.birthDate.day.toString().padLeft(2, '0')}-'
                    '${p.birthDate.month.toString().padLeft(2, '0')}-${p.birthDate.year}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await ActiveChildService.instance.setActiveChildId(id);
                    if (!itemCtx.mounted) {
                      return; // brug det lokale BuildContext
                    }
                    Navigator.of(itemCtx).pop(); // og brug itemCtx her
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createChildFlow,
        icon: const Icon(Icons.add),
        label: const Text('Opret barn'),
      ),
    );
  }
}
