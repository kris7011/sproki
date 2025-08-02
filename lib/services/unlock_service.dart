import '../data/words_content.dart';
import '../services/progress_service.dart';

class UnlockService {
  // Tjek om et ord er unlocked
  static bool isWordUnlocked(String wordId) {
    final word = initialWords.firstWhere((w) => w.id == wordId);

    // Starter words er altid unlocked
    if (word.isStarterWord) return true;

    // Tjek om alle required words er mestret
    for (final requiredWordId in word.requiredWords) {
      final progress = ProgressService.getProgress(requiredWordId);
      if (progress == null || !progress.isMastered) {
        return false;
      }
    }

    return true;
  }

  // Få alle unlocked ord
  static List<WordContent> getUnlockedWords() {
    return initialWords.where((word) => isWordUnlocked(word.id)).toList();
  }

  // Få alle locked ord
  static List<WordContent> getLockedWords() {
    return initialWords.where((word) => !isWordUnlocked(word.id)).toList();
  }

  // Tjek hvilke nye ord der blev unlocked efter en success
  static List<WordContent> checkNewUnlocks(String justMasteredWordId) {
    final newUnlocks = <WordContent>[];

    for (final word in initialWords) {
      if (!word.isStarterWord &&
          word.requiredWords.contains(justMasteredWordId) &&
          isWordUnlocked(word.id)) {
        newUnlocks.add(word);
      }
    }

    return newUnlocks;
  }

  // Få progress mod næste unlock
  static Map<String, dynamic> getUnlockProgress() {
    final lockedWords = getLockedWords();
    final unlockProgress = <String, Map<String, dynamic>>{};

    for (final word in lockedWords) {
      int masteredRequirements = 0;
      int totalRequirements = word.requiredWords.length;

      for (final requiredWordId in word.requiredWords) {
        final progress = ProgressService.getProgress(requiredWordId);
        if (progress != null && progress.isMastered) {
          masteredRequirements++;
        }
      }

      unlockProgress[word.id] = {
        'word': word,
        'progress': masteredRequirements / totalRequirements,
        'masteredRequirements': masteredRequirements,
        'totalRequirements': totalRequirements,
        'nextToUnlock': masteredRequirements == totalRequirements - 1,
      };
    }

    return unlockProgress;
  }
}
