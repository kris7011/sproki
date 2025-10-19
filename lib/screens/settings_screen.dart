import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('App Indstillinger'),
        backgroundColor: const Color(0xFF80CBC4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Lyd & Feedback'),
              subtitle: const Text('Juster talehastighed, volumen og haptik'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Sprog'),
              subtitle: const Text('Dansk (standard)'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: true,
              onChanged: (_) {},
              secondary: const Icon(Icons.lock),
              title: const Text('Børnelås'),
              subtitle: const Text('Beskyttede indstillinger for forældre'),
            ),
          ),
        ],
      ),
    );
  }
}
