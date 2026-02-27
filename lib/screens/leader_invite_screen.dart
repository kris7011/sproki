import 'package:flutter/material.dart';

import '../services/sproki_service.dart';
import '../state/app_state.dart';

class LeaderInviteScreen extends StatefulWidget {
  const LeaderInviteScreen({
    super.key,
    required this.service,
    required this.appState,
  });

  final SprokiService service;
  final AppState appState;

  @override
  State<LeaderInviteScreen> createState() => _LeaderInviteScreenState();
}

class _LeaderInviteScreenState extends State<LeaderInviteScreen> {
  final _email = TextEditingController();

  String _role = 'FORAELDER';
  bool _loading = false;
  String? _error;

  static const _allowedRoles = <String>{'FORAELDER', 'PPR', 'PERSONALE'};

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final institutionId = widget.appState.institutionId;
    if (institutionId == null || institutionId <= 0) {
      setState(() => _error = 'Du mangler institution_id på din bruger.');
      return;
    }

    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _error = 'Email er påkrævet');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final inv = await widget.service.createInvite(
        email: email,
        role: _role,
        institutionId: institutionId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite sendt til ${inv.email} (${inv.role})'),
        ),
      );

      _email.clear();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _loading;

    final roleValue = _allowedRoles.contains(_role) ? _role : 'FORAELDER';

    return Scaffold(
      appBar: AppBar(title: const Text('Inviter bruger')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: !disabled,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Rolle',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: roleValue,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'FORAELDER', child: Text('Forælder')),
                    DropdownMenuItem(value: 'PPR', child: Text('PPR')),
                    DropdownMenuItem(
                        value: 'PERSONALE', child: Text('Personale')),
                  ],
                  onChanged: disabled
                      ? null
                      : (v) => setState(() => _role = v ?? 'FORAELDER'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: disabled ? null : _sendInvite,
                    child: Text(_loading ? 'Sender…' : 'Send invite'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
