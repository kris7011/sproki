import 'package:hive/hive.dart';

import '../constants/hive_boxes.dart';
import '../models/word_attempt.dart';

class WordRecommendation {
  const WordRecommendation({required this.wordId, required this.priority});
  final String wordId;
  final double priority; // højere = vigtigere
}

class RecommendationService {
  const RecommendationService();

  Box<WordAttempt> get _attempts =>
      Hive.box<WordAttempt>(HiveBoxes.wordAttempts);

  /// Simple heuristik:
  ///  - Ord uden forsøg prioriteres højt
  ///  - Ord med lav success-rate prioriteres
  ///  - Ord med få forsøg prioriteres over ord der allerede “sidder fast”
  Future<List<WordRecommendation>> nextWordsToPractice({
    required String childId,
    int take = 5,
  }) async {
    // Saml forsøg pr. wordId
    final Map<String, List<WordAttempt>> byWord = {};
    for (final a in _attempts.values) {
      if (a.childId != childId) continue;
      byWord.putIfAbsent(a.wordId, () => <WordAttempt>[]).add(a);
    }

    // Lav prioritering
    final List<WordRecommendation> out = [];
    if (byWord.isEmpty) {
      // Ingen data endnu -> lad UI falde tilbage til starter-ord
      return out;
    }

    byWord.forEach((wordId, list) {
      final n = list.length;
      final ok = list.where((e) => e.score >= 0.8).length;
      final sr = n == 0 ? 0.0 : ok / n;

      // Prioritet: 1) Få forsøg 2) Lav SR
      // fx  v = (1 - sr) * 0.7 + (1 / (1+n)) * 0.3
      final priority = (1 - sr) * 0.7 + (1 / (1 + n)) * 0.3;
      out.add(WordRecommendation(wordId: wordId, priority: priority));
    });

    out.sort((a, b) => b.priority.compareTo(a.priority));
    if (out.length > take) return out.sublist(0, take);
    return out;
  }
}
