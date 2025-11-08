import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sproki/constants/hive_boxes.dart';
import 'package:sproki/models/child_profile.dart';
import 'package:sproki/routes/app_routes.dart';
import 'package:sproki/services/active_child_service.dart';
// import 'package:sproki/services/plan_store.dart'; // enable når plan fra backend er klar

import 'package:sproki/api/api_client.dart';

class ParentReportUploadScreen extends StatefulWidget {
  const ParentReportUploadScreen({super.key});

  @override
  State<ParentReportUploadScreen> createState() =>
      _ParentReportUploadScreenState();
}

class _ParentReportUploadScreenState extends State<ParentReportUploadScreen> {
  // <-- Tilføjet: enkel API-klient
  final api = ApiClient();

  final _form = GlobalKey<FormState>();

  final _ageYearsCtrl = TextEditingController(text: '5');
  final _ageMonthsCtrl = TextEditingController(text: '8');
  final _rimScoreCtrl = TextEditingController(text: '55');
  final _udtaleScoreCtrl = TextEditingController(text: '43');

  bool _busy = false;
  String? _activeChildId;
  late final VoidCallback _activeChildListener;
  late final Box<ChildProfile> _childBox;

  Map<String, dynamic>? _lastUpload; // {"ok":true,"report_ids":[...]}
  Map<String, dynamic>? _lastLatest; // {"child_id": "...", "summary":[...]}
  String? _error;

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
    _ageYearsCtrl.dispose();
    _ageMonthsCtrl.dispose();
    _rimScoreCtrl.dispose();
    _udtaleScoreCtrl.dispose();
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
      if (!mounted) return;
      setState(
          () => _activeChildId = ActiveChildService.instance.activeChildIdSync);
    }
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Påkrævet' : null;
  String? _isInt(String? v) {
    if (_req(v) != null) return 'Påkrævet';
    return int.tryParse(v!.trim()) == null ? 'Ugyldigt tal' : null;
  }

  String? _isDouble(String? v) {
    if (_req(v) != null) return 'Påkrævet';
    return double.tryParse(v!.trim()) == null ? 'Ugyldigt tal' : null;
  }

  Future<void> _uploadJsonReport() async {
    await _ensureChildSelected();
    if (_activeChildId == null || _activeChildId!.isEmpty) return;
    if (!_form.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
      _lastUpload = null;
    });

    try {
      final res = await api.postReport(
        childId: _activeChildId!,
        ageYears: int.parse(_ageYearsCtrl.text),
        ageMonths: int.parse(_ageMonthsCtrl.text),
        items: [
          {'category': 'rim', 'score': double.parse(_rimScoreCtrl.text)},
          {'category': 'udtale', 'score': double.parse(_udtaleScoreCtrl.text)},
        ],
      );
      if (!mounted) return;
      setState(() => _lastUpload = res);

      // Hvis backend senere returnerer plan, kan vi gemme den lokalt:
      // final plan = res['plan'];
      // if (plan is Map<String, dynamic>) {
      //   await PlanStore.savePlan(_activeChildId!, plan);
      // }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload OK (ids: ${res['report_ids']})')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fetchLatest() async {
    await _ensureChildSelected();
    if (_activeChildId == null || _activeChildId!.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
      _lastLatest = null;
    });

    try {
      final res = await api.getLatestSummary(_activeChildId!);
      if (!mounted) return;
      setState(() => _lastLatest = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prof = _activeProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload rapport (JSON)')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Barnets header
            Card(
              child: ListTile(
                leading: const Icon(Icons.child_care),
                title: Text(prof?.name ?? 'Intet barn valgt'),
                subtitle: Text(
                  prof == null
                      ? 'Vælg et barn for at fortsætte'
                      : 'Født: ${prof.birthDate.day.toString().padLeft(2, '0')}-'
                          '${prof.birthDate.month.toString().padLeft(2, '0')}-${prof.birthDate.year}',
                ),
                trailing: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(context, AppRoutes.selectChild);
                    if (!mounted) return;
                    setState(() => _activeChildId =
                        ActiveChildService.instance.activeChildIdSync);
                  },
                  icon: const Icon(Icons.family_restroom),
                  label: Text(prof == null ? 'Vælg barn' : 'Skift barn'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Alder', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageYearsCtrl,
                    decoration: const InputDecoration(labelText: 'År'),
                    keyboardType: TextInputType.number,
                    validator: _isInt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ageMonthsCtrl,
                    decoration: const InputDecoration(labelText: 'Måneder'),
                    keyboardType: TextInputType.number,
                    validator: _isInt,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text('Scores', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rimScoreCtrl,
                    decoration: const InputDecoration(labelText: 'rim'),
                    keyboardType: TextInputType.number,
                    validator: _isDouble,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _udtaleScoreCtrl,
                    decoration: const InputDecoration(labelText: 'udtale'),
                    keyboardType: TextInputType.number,
                    validator: _isDouble,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _uploadJsonReport,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _fetchLatest,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Hent latest'),
                ),
              ],
            ),

            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style:
                      theme.textTheme.bodyMedium!.copyWith(color: Colors.red)),
            ],

            // Resultater
            const SizedBox(height: 16),
            if (_lastUpload != null) ...[
              Text('Upload-respons', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              _JsonView(_lastUpload!),
            ],
            if (_lastLatest != null) ...[
              const SizedBox(height: 16),
              Text('Latest summary', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              _JsonView(_lastLatest!),
            ],
          ],
        ),
      ),
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView(this.map);
  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(map);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(pretty, style: const TextStyle(fontFamily: 'monospace')),
      ),
    );
  }
}
