import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/child.dart';
import '../../services/sproki_service.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({
    super.key,
    required this.service,
  });

  final SprokiService service;

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  late Future<List<Child>> _future;

  bool _checkingInvite = false;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listChildren();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.service.listChildren();
    });

    try {
      await _future;
    } catch (_) {
      // handled by builder
    }
  }

  Future<void> _checkInviteAndMaybeAccept({required bool showFeedback}) async {
    if (_checkingInvite) return;

    setState(() => _checkingInvite = true);

    try {
      final pending = await widget.service
          .pendingInvite()
          .timeout(const Duration(seconds: 4), onTimeout: () => null);

      if (pending == null) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invite-check er ikke slået til på backend endnu.'),
            ),
          );
        }
        return;
      }

      if (!pending.pending) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingen pending invite fundet.')),
          );
        }
        return;
      }

      await widget.service
          .acceptInvite()
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite accepteret ✅')),
          );
        }

        await _reload();
      }
    } catch (e) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite-check fejlede: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingInvite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Child>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return _ErrorState(
            error: snap.error.toString(),
            onRetry: _reload,
            onCheckInvite: _checkingInvite
                ? null
                : () => _checkInviteAndMaybeAccept(showFeedback: true),
            checkingInvite: _checkingInvite,
          );
        }

        final children = snap.data ?? const <Child>[];
        if (children.isEmpty) {
          return _EmptyState(
            onReload: _reload,
            onCheckInvite: _checkingInvite
                ? null
                : () => _checkInviteAndMaybeAccept(showFeedback: true),
            checkingInvite: _checkingInvite,
          );
        }

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = children[i];

              final nameRaw = (c.name).trim();
              final title = nameRaw.isNotEmpty ? nameRaw : 'Barn #${c.id}';

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                title: Text(title),
                subtitle: Text('ID: ${c.id}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/children/${c.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onReload,
    required this.onCheckInvite,
    required this.checkingInvite,
  });

  final Future<void> Function() onReload;
  final Future<void> Function()? onCheckInvite;
  final bool checkingInvite;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.family_restroom, size: 56),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Du har ingen børn tilknyttet endnu.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Som forælder bliver børn typisk tilknyttet via invite fra institutionen.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: onCheckInvite,
              icon: checkingInvite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mark_email_unread_outlined),
              label: Text(checkingInvite ? 'Tjekker invite…' : 'Tjek invite nu'),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Hvis du forventer et barn her, så kontakt institutionen og få sendt en invite.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.onCheckInvite,
    required this.checkingInvite,
  });

  final String error;
  final VoidCallback onRetry;
  final Future<void> Function()? onCheckInvite;
  final bool checkingInvite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Kunne ikke hente børn.'),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Prøv igen'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onCheckInvite,
              icon: checkingInvite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mark_email_unread_outlined),
              label: Text(checkingInvite ? 'Tjekker invite…' : 'Tjek invite nu'),
            ),
          ],
        ),
      ),
    );
  }
}