import 'package:flutter/material.dart';

class PracticeHeader extends StatelessWidget {
  const PracticeHeader({
    super.key,
    required this.stars,
    required this.successRatePct,
    required this.bestScore,
    required this.onPrev,
    required this.onNext,
  });

  final int stars;
  final int successRatePct;
  final int bestScore;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String label, String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: Colors.indigo[700]),
            const SizedBox(width: 6),
            Text('$label: ',
                style: TextStyle(
                    color: Colors.grey[700], fontWeight: FontWeight.w600)),
            Text(value,
                style: TextStyle(
                    color: Colors.indigo[800], fontWeight: FontWeight.bold)),
          ]),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        chip(Icons.star, 'Stjerner', '$stars'),
        const SizedBox(width: 8),
        chip(Icons.check_circle, 'Succes', '$successRatePct%'),
        const SizedBox(width: 8),
        chip(Icons.insights, 'Bedste', '$bestScore'),
        const Spacer(),
        IconButton(
            tooltip: 'Forrige ord',
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left)),
        IconButton(
            tooltip: 'Næste ord',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right)),
      ]),
    );
  }
}
