import 'package:flutter/material.dart';
import 'package:sproki/routes/app_routes.dart';

Future<void> showPremiumDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Fortsæt med Premium'),
      content: const Text(
        'Du har brugt dine 7 gratis øvelser. Opgrader for at låse alle øvelser op.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Luk')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.of(context).pushNamed(AppRoutes.premium);
          },
          child: const Text('Opgrader'),
        ),
      ],
    ),
  );
}
