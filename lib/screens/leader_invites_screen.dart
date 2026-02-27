import 'package:flutter/material.dart';
import 'package:sproki/services/sproki_service.dart';
import 'package:sproki/state/app_state.dart';

class LeaderInvitesScreen extends StatefulWidget {
  const LeaderInvitesScreen({
    super.key,
    required this.service,
    required this.appState,
  });

  final SprokiService service;
  final AppState appState;

  @override
  State<LeaderInvitesScreen> createState() => _LeaderInvitesScreenState();
}

class _LeaderInvitesScreenState extends State<LeaderInvitesScreen> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invites')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _reload,
              child: Text(_loading ? 'Henter…' : 'Opdatér'),
            ),
            const SizedBox(height: 16),
            Text(
              'Role: ${widget.appState.role ?? "-"} | Institution: ${widget.appState.institutionId?.toString() ?? "-"}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'TODO: Her kommer lederens invites-flow.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // TODO: implement endpoint i SprokiService, fx:
      // final invites = await widget.service.listInvites();
      await Future.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
