import 'package:flutter/material.dart';
import '../models/progress_data.dart';
import '../data/words_content.dart';
import '../screens/word_practice_screen.dart';
import '../services/unlock_service.dart';

class WordCard extends StatelessWidget {
  final WordContent word;
  final ProgressData? progress;
  final bool showLocked; // NYT: Vis låste ord

  const WordCard({
    super.key,
    required this.word,
    this.progress,
    this.showLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final stars = progress?.stars ?? 0;
    final isMastered = progress?.isMastered ?? false;
    final isUnlocked = UnlockService.isWordUnlocked(word.id);

    // Hvis ordet er låst og vi ikke viser låste ord, vis ikke noget
    if (!isUnlocked && !showLocked) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: isUnlocked
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordPracticeScreen(word: word),
                  ),
                );
              }
            : () => _showLockedDialog(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stjerner eller låse-ikon øverst
                if (!isUnlocked)
                  const SizedBox(
                    height: 16,
                    child: Icon(Icons.lock, color: Colors.grey, size: 16),
                  )
                else if (stars > 0)
                  SizedBox(
                    height: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 16),

                // Emoji og tekst
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              word.emoji,
                              style: TextStyle(
                                fontSize: 48,
                                color: isUnlocked
                                    ? null
                                    : Colors.grey.withValues(alpha: 0.5),
                              ),
                            ),
                            if (!isUnlocked)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          word.word,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? null : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress bar eller unlock requirements
                if (!isUnlocked)
                  SizedBox(height: 24, child: _buildUnlockRequirements())
                else if (progress != null && progress!.totalAttempts > 0)
                  SizedBox(
                    height: 24,
                    child: Column(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress!.successRate,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isMastered ? Colors.green : Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(progress!.successRate * 100).round()}%',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockRequirements() {
    final unlockProgress = UnlockService.getUnlockProgress();
    final wordProgress = unlockProgress[word.id];

    if (wordProgress == null) return const SizedBox.shrink();

    final progress = wordProgress['progress'] as double;
    final mastered = wordProgress['masteredRequirements'] as int;
    final total = wordProgress['totalRequirements'] as int;

    return Column(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[400],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$mastered/$total',
          style: const TextStyle(fontSize: 8, color: Colors.grey),
        ),
      ],
    );
  }

  void _showLockedDialog(BuildContext context) {
    final unlockProgress = UnlockService.getUnlockProgress();
    final wordProgress = unlockProgress[word.id];

    if (wordProgress == null) return;

    final mastered = wordProgress['masteredRequirements'] as int;
    final total = wordProgress['totalRequirements'] as int;
    final remaining = total - mastered;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 8),
            Text('${word.word} er låst'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(word.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Mestrer $remaining ord mere for at låse "${word.word}" op!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: mastered / total,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 8),
            Text('$mastered/$total ord mestret'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
