import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sproki/config/env.dart';
import 'package:sproki/constants/hive_boxes.dart';
import 'package:sproki/models/child_profile.dart';
import 'package:sproki/routes/app_routes.dart';
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/plan_store.dart';
import 'package:sproki/services/sproki_api.dart';

class ParentReportUploadScreen extends StatefulWidget {
  const ParentReportUploadScreen({super.key});

  @override
  State<ParentReportUploadScreen> createState() =>
      _ParentReportUploadScreenState();
}

class _ParentReportUploadScreenState extends State<ParentReportUploadScreen> {
  final _api = SprokiApi(baseUrl: Env.apiBaseUrl); // <-- required

  PlatformFile? _picked;
  double _progress = 0.0;
  bool _loading = false;
  Map<String, dynamic>?
      _uploadResponse; // {ok, reportId, createdAt, scores, plan, ...}

  String? _activeChildId;
  late final VoidCallback _activeChildListener;
  late final Box<ChildProfile> _childBox;

  @override
  void initState() {
    super.initState();
    _childBox = Hive.box<ChildProfile>(HiveBoxes.childProfiles);

    _activeChildId = ActiveChildService.instance.activeChildIdSync;
    _activeChildListener = () {
      if (!mounted) return;
      setState(() {
        _activeChildId = ActiveChildService.instance.activeChildIdSync;
      });
    };
    ActiveChildService.instance.activeChildIdListenable
        .addListener(_activeChildListener);
  }

  @override
  void dispose() {
    ActiveChildService.instance.activeChildIdListenable
        .removeListener(_activeChildListener);
    super.dispose();
  }

  ChildProfile? get _activeProfile {
    final id = _activeChildId;
    if (id == null || id.isEmpty) return null;
    return _childBox.get(id);
  }

  Future<void> _ensureChildSelected() async {
    if (_activeChildId != null && _activeChildId!.isNotEmpty) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vælg barn'),
        content:
            const Text('Vælg venligst et barn før du uploader en sprogtest.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Luk')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vælg barn')),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.pushNamed(context, AppRoutes.selectChild);
    }
    if (mounted) {
      setState(() {
        _activeChildId = ActiveChildService.instance.activeChildIdSync;
      });
    }
  }

  Future<void> _pickPdf() async {
    await _ensureChildSelected();
    if (_activeChildId == null || _activeChildId!.isEmpty) return;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: true, // bed om bytes (mobil+web)
    );
    if (!mounted) return;

    if (res == null || res.files.isEmpty) return;
    setState(() => _picked = res.files.single);
  }

  Future<void> _upload() async {
    await _ensureChildSelected();
    if (_activeChildId == null || _activeChildId!.isEmpty) return;

    if (_picked == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vælg først en PDF')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _progress = 0.0;
      _uploadResponse = null;
    });

    try {
      final profile = _activeProfile;
      final childName = (profile?.name.trim().isNotEmpty ?? false)
          ? profile!.name.trim()
          : null;

      // (1) Upsert child (positional childId først)
      await _api.upsertChild(_activeChildId!, name: childName);

      // (2) Filnavn + bytes
      final filename = _picked!.name;
      final bytes = _picked!.bytes;
      if (!mounted) return;

      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kunne ikke læse filens data. Prøv igen.')),
        );
        return;
      }

      // (3) Upload
      final data = await _api.uploadReportPdfBytes(
        childId: _activeChildId!,
        filename: filename,
        bytes: bytes,
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      );

      // (4) Gem plan lokalt hvis den findes
      final planAny = data['plan'];
      if (planAny is Map<String, dynamic>) {
        await PlanStore.savePlan(_activeChildId!, planAny);
      } else {
        debugPrint('Ingen/ugyldig plan i upload-responsen (plan=$planAny)');
      }

      if (!mounted) return;
      setState(() => _uploadResponse = Map<String, dynamic>.from(data));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload gennemført (#${data['reportId']})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _progress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _picked?.name ?? 'Ingen fil valgt';
    final plan = _uploadResponse?['plan'] is Map
        ? Map<String, dynamic>.from(_uploadResponse!['plan'] as Map)
        : null;
    final scores = _uploadResponse?['scores'] is Map
        ? Map<String, dynamic>.from(_uploadResponse!['scores'] as Map)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload sprogtest (forældre)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Barn-card ---
          _ChildHeaderCard(
            profile: _activeProfile,
            onChange: () async {
              await Navigator.pushNamed(context, AppRoutes.selectChild);
              if (!mounted) return;
              setState(() {
                _activeChildId = ActiveChildService.instance.activeChildIdSync;
              });
            },
          ),
          const SizedBox(height: 16),

          const Text(
            '1) Vælg PDF fra børnehave / testudfører',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(fileName)),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loading ? null : _pickPdf,
                icon: const Icon(Icons.attach_file),
                label: const Text('Vælg PDF'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _upload,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload & analyzér'),
          ),
          if (_loading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          ],

          // --- Resultat/output ---
          const SizedBox(height: 24),
          if (scores != null) ...[
            const Text(
              'Udledte scorer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _ScoreTile(
              label: 'Sprogforståelse',
              value: scores['sprogforståelse'] ?? scores['sprogforstaelse'],
            ),
            _ScoreTile(
                label: 'Ordforråd',
                value: scores['ordforråd'] ?? scores['ordforrad']),
            _ScoreTile(
              label: 'Kommunikative strategier',
              value: scores['kommunikativeStrategier'],
            ),
            _ScoreTile(label: 'Rim', value: scores['rim']),
            _ScoreTile(
              label: 'Opmærksomhed på skrift',
              value: scores['opmærksomhedPåSkrift'] ??
                  scores['opmaerksomhedPaSkrift'],
            ),
          ],

          const SizedBox(height: 24),
          if (plan != null) ...[
            const Text(
              'Anbefalinger til forældre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _PlanView(plan: plan),
            const SizedBox(height: 16),

            // ⬇︎ Rettelse: Gå altid til navngivet mainMenu og ryd stacken
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.mainMenu,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Gå til anbefalede øvelser'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChildHeaderCard extends StatelessWidget {
  const _ChildHeaderCard({required this.profile, required this.onChange});
  final ChildProfile? profile;
  final Future<void> Function() onChange;

  @override
  Widget build(BuildContext context) {
    final has = profile != null;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.child_care),
        title: Text(has ? profile!.name : 'Intet barn valgt'),
        subtitle: Text(
          has
              ? 'Født: ${profile!.birthDate.day.toString().padLeft(2, '0')}-${profile!.birthDate.month.toString().padLeft(2, '0')}-${profile!.birthDate.year}'
              : 'Vælg et barn for at fortsætte',
        ),
        trailing: FilledButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.family_restroom),
          label: Text(has ? 'Skift barn' : 'Vælg barn'),
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.label, required this.value});
  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    String display;
    if (value is num) {
      display = (value as num).toStringAsFixed(1);
    } else if (value is String) {
      display = value;
    } else {
      display = '—';
    }
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing:
          Text(display, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});
  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    final priority = (plan['priorityAreas'] as List?) ?? const [];
    final recs = (plan['recommendations'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prioriterede områder',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...priority.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final domain = (m['domain'] as String? ?? '').trim();
          final zone = (m['zone'] as String? ?? '').trim();
          final goal = m['shortTermGoal'];
          final score = m['score'];
          final tips = (m['tips'] as List? ?? const [])
              .map((e) => e.toString())
              .toList();

          final goalTxt =
              goal is num ? goal.toStringAsFixed(1) : (goal?.toString() ?? '—');
          final scoreTxt = score is num
              ? score.toStringAsFixed(1)
              : (score?.toString() ?? '—');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${domain.isEmpty ? 'Område' : domain} — ${zone.isEmpty ? '?' : zone}'
                        .toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Score: $scoreTxt  •  Kortsigtet mål: $goalTxt'),
                  const SizedBox(height: 8),
                  if (tips.isNotEmpty) const Text('Tips:'),
                  ...tips.map((t) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(t)),
                        ],
                      )),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text('Top-anbefalinger',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recs.map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          final domain = (m['domain'] as String? ?? '').trim();
          final tips = (m['tips'] as List? ?? const [])
              .map((e) => e.toString())
              .toList();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(domain.isEmpty ? 'Anbefaling' : domain,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...tips.map((t) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(t)),
                        ],
                      )),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
