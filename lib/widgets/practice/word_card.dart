import 'package:flutter/material.dart';
import 'package:sproki/data/words_content.dart';

class WordCard extends StatelessWidget {
  const WordCard({super.key, required this.word});
  final WordContent word;

  @override
  Widget build(BuildContext context) {
    Widget tag(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(children: [
            Container(
              width: 78,
              height: 78,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(word.emoji.isNotEmpty ? word.emoji : '🔤',
                  style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.word,
                        style: const TextStyle(
                            fontSize: 32,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    Row(children: [
                      tag(word.category),
                      const SizedBox(width: 8),
                      tag('sværhedsgrad: ${word.difficulty}'),
                      if (word.isStarterWord) ...[
                        const SizedBox(width: 8),
                        tag('starter')
                      ],
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
