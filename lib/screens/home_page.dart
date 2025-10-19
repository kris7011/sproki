import 'package:flutter/material.dart';
import 'package:sproki/widgets/premium_badge.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sproki'),
        actions: const [
          PremiumBadge(), // ← viser status og kan tappes til PremiumScreen
        ],
      ),
      body: const Center(child: Text('…din app…')),
    );
  }
}
