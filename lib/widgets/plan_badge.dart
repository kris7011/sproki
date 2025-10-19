import 'package:flutter/material.dart';
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/plan_store.dart';

/// Lille indikator i AppBar der viser, om aktivt barn har en gemt plan.
class PlanBadge extends StatelessWidget {
  const PlanBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: PlanStore.listenable(),
      builder: (_, __, ___) {
        final id = ActiveChildService.instance.activeChildIdSync ?? '';
        final hasPlan = id.isNotEmpty && PlanStore.getPlan(id) != null;

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            hasPlan ? Icons.verified : Icons.info_outline,
            size: 20,
            color: hasPlan ? Colors.lightGreen : Colors.orange,
          ),
        );
      },
    );
  }
}
