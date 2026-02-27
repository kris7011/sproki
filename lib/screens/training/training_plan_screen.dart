import 'package:flutter/material.dart';

import '../../services/sproki_service.dart';

class TrainingPlanScreen extends StatelessWidget {
  const TrainingPlanScreen({
    super.key,
    required this.service,
  });

  final SprokiService service;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'TrainingPlanScreen: næste step.\n\nVi kobler den op på anbefalede øvelser + attempts.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
