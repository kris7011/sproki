// lib/widgets/paywall_gate.dart
import 'package:flutter/material.dart';
import 'package:sproki/routes/app_routes.dart';
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/paywall_service.dart';

enum PaywallDecision { allowed, locked }

class PaywallGate {
  static const _paywall = PaywallService();

  /// Returnerer true hvis barnet må fortsætte, ellers false (og viser dialog).
  static Future<bool> ensureNotLocked(BuildContext context) async {
    // Find aktivt barn (sync → async fallback)
    var childId = ActiveChildService.instance.activeChildIdSync;
    childId ??= await ActiveChildService.instance.getActiveChildId();
    if (childId == null || childId.isEmpty) return true; // ingen valgt → tillad

    final locked = await _paywall.isLockedForChildAsync(childId);
    if (!locked) return true;

    if (!context.mounted) return false;
    final goPremium = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Få ubegrænset adgang'),
        content: const Text(
          'Du har brugt alle gratis forsøg for dette barn. '
          'Opgrader til Premium for ubegrænset adgang til øvelser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Luk'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se Premium'),
          ),
        ],
      ),
    );

    if (!context.mounted) return false;
    if (goPremium == true) {
      Navigator.of(context).pushNamed(AppRoutes.premium);
    }
    return false;
  }

  /// Registrér ét forsøg for akt. barn (til tælling i paywall).
  static Future<void> recordAttemptForActiveChild() async {
    var childId = ActiveChildService.instance.activeChildIdSync;
    childId ??= await ActiveChildService.instance.getActiveChildId();
    if (childId == null || childId.isEmpty) return;
    await _paywall.recordAttempt(childId);
  }
}
