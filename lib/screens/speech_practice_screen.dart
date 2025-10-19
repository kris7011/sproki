import 'package:flutter/material.dart';

class SpeechPracticeScreen extends StatelessWidget {
  const SpeechPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FF),
      appBar: AppBar(
        title: const Text('Øv udtale'),
        backgroundColor: const Color(0xFF90CAF9),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.mic),
          ),
        ],
      ),
      body: const SafeArea(
        child: Center(
          child: Card(
            margin: EdgeInsets.all(24),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.record_voice_over, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Lad os træne udtale!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
