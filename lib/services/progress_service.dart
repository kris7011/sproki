// lib/services/progress_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sproki/services/sproki_api.dart';
import 'package:sproki/services/practice_queue_service.dart';

/// Simpel mestring via Exponential Moving Average (EMA).
/// Vi tracker to niveauer pr. barn:
///  - pr domæne: key = `"$childId::domain::<domainNorm>"`
///  - pr øvelse: key = `"$childId::exercise::<exerciseId>"`
///
/// Struktur i boksen:
///   { 'ema': double 0..1, 'count': int, 'lastUpdated': iso8601 }
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const String _boxName = 'mastery_v1';
  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(_boxName);
  }

  Box get _b {
    final b = _box;
    if (b == null) {
      throw StateError('ProgressService not initialized. Call init() first.');
    }
    return b;
  }

  ValueListenable<Box> listenable() => _b.listenable();

  static String normalize(String s) {
    final lower = s.toLowerCase().trim();
    return lower
        .replaceAll('æ', 'ae')
        .replaceAll('ø', 'o')
        .replaceAll('å', 'a')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9:_\\-]'), '');
  }

  String _domainKey(String childId, String domain) =>
      '$childId::domain::${normalize(domain)}';

  String _exerciseKey(String childId, String exerciseId) =>
      '$childId::exercise::$exerciseId';

  double getDomainMastery(String childId, String domain) {
    final k = _domainKey(childId, domain);
    final map = _b.get(k);
    if (map is Map) {
      final ema = map['ema'];
      if (ema is num) return ema.toDouble().clamp(0.0, 1.0);
    }
    return 0.0;
  }

  double getExerciseMastery(String childId, String exerciseId) {
    final k = _exerciseKey(childId, exerciseId);
    final map = _b.get(k);
    if (map is Map) {
      final ema = map['ema'];
      if (ema is num) return ema.toDouble().clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Opdater EMA efter et svar. `score`: 0..1
  Future<void> updateOnAnswer({
    required String childId,
    required String domain,
    required String exerciseId,
    required num score, // accepterer num; castes til double
    double alpha = 0.3,
  }) async {
    final s = score.toDouble().clamp(0.0, 1.0);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // Domæne
    final dk = _domainKey(childId, domain);
    final dm = Map<String, dynamic>.from((_b.get(dk) as Map?) ?? const {});
    final dPrev = (dm['ema'] as num?)?.toDouble() ?? 0.0;
    final dCount = (dm['count'] as int?) ?? 0;
    final dNew = alpha * s + (1 - alpha) * dPrev;
    dm['ema'] = dNew.clamp(0.0, 1.0);
    dm['count'] = dCount + 1;
    dm['lastUpdated'] = nowIso;
    await _b.put(dk, dm);

    // Øvelse
    final ek = _exerciseKey(childId, exerciseId);
    final em = Map<String, dynamic>.from((_b.get(ek) as Map?) ?? const {});
    final ePrev = (em['ema'] as num?)?.toDouble() ?? 0.0;
    final eCount = (em['count'] as int?) ?? 0;
    final eNew = alpha * s + (1 - alpha) * ePrev;
    em['ema'] = eNew.clamp(0.0, 1.0);
    em['count'] = eCount + 1;
    em['lastUpdated'] = nowIso;
    await _b.put(ek, em);
  }

  /// Til UI: `{percent: 0..100, attempts: int}`
  Map<String, dynamic> domainProgress(String childId, String domain) {
    final dk = _domainKey(childId, domain);
    final map = _b.get(dk);
    if (map is Map) {
      final ema = (map['ema'] as num?)?.toDouble() ?? 0.0;
      final cnt = (map['count'] as int?) ?? 0;
      return {
        'percent': (ema * 100.0).clamp(0.0, 100.0),
        'attempts': cnt,
      };
    }
    return const {'percent': 0.0, 'attempts': 0};
  }

  /// Sender forsøg til backend; fallback til lokal kø hvis det fejler.
  static Future<void> recordAttempt({
    required String childId,
    required String wordId,
    required String word,
    required double scorePercent, // 0..100
    required bool wasSuccessful,
  }) async {
    final score01 = (scorePercent / 100.0).clamp(0.0, 1.0);

    final event = <String, dynamic>{
      'childId': childId,
      'domain': 'ordforråd',
      'exerciseId': 'word:$wordId',
      'outcome': wasSuccessful ? 'success' : 'fail',
      'score': score01,
      'meta': {'word': word, 'scorePercent': scorePercent},
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final api = SprokiApi();
      await api.addPracticeEvents(childId, [event]);
    } catch (e) {
      // Fallback til kø
      await PracticeQueueService.instance.enqueue(event);
    }
  }
}
