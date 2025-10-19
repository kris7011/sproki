import 'package:flutter/material.dart';

class ResultBanner extends StatelessWidget {
  const ResultBanner({
    super.key,
    required this.visible,
    required this.success,
    required this.score,
    required this.onGood,
    required this.onBad,
  });

  final bool visible;
  final bool success;
  final double score;
  final VoidCallback onGood;
  final VoidCallback onBad;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: success ? Colors.green[50] : Colors.red[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(children: [
            Icon(success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green[700] : Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'Flot udtale! Score: ${score.toStringAsFixed(0)}'
                    : 'Prøv igen – du kan godt! Score: ${score.toStringAsFixed(0)}',
                style: TextStyle(
                  color: success ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(children: [
              IconButton(
                  tooltip: 'Marker som korrekt',
                  onPressed: onGood,
                  icon: const Icon(Icons.thumb_up),
                  color: Colors.green[700]),
              IconButton(
                  tooltip: 'Marker som forkert',
                  onPressed: onBad,
                  icon: const Icon(Icons.thumb_down),
                  color: Colors.red[700]),
            ]),
          ]),
        ),
      ),
    );
  }
}
