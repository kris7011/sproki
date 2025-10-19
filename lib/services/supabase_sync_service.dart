// lib/services/supabase_sync_service.dart
import 'dart:math' as math;
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/hive_boxes.dart';
import '../models/child_profile.dart';
import '../models/progress_data.dart';
import '../models/word_attempt.dart';
import '../models/category_attempt.dart';

class SupabaseSyncService {
  SupabaseSyncService(this.client);

  final SupabaseClient client;

  // -------------------- Auth helper --------------------
  String? uid() => Supabase.instance.client.auth.currentUser?.id;

  Map<String, dynamic> _withUserId(Map<String, dynamic> row) {
    final u = uid();
    if (u == null) return row; // kør “anonymt” hvis ingen bruger (lokal-only)
    // Bevar eksisterende user_id hvis sat; ellers indsæt.
    return row.containsKey('user_id') && row['user_id'] != null
        ? row
        : {...row, 'user_id': u};
  }

  // ========================= CHILD PROFILES =========================
  Future<void> pullChildProfiles() async {
    final box = Hive.box<ChildProfile>(HiveBoxes.childProfiles);

    // Filtrér på user_id hvis login findes (RLS vil typisk også håndhæve dette)
    final query = client.from('child_profiles').select();
    final data = await _safeSelect(() {
      final u = uid();
      return u == null ? query : query.eq('user_id', u);
    });

    for (final row in data) {
      final map = row as Map<String, dynamic>;
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final name = (map['name'] ?? '') as String;
      final birthDate = _parseDate(map['birth_date']);
      final challengeAreas = (map['challenge_areas'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final createdAt = _parseDate(map['created_at']) ?? DateTime.now();

      if (name.isEmpty || birthDate == null) continue;

      await box.put(
        id,
        ChildProfile(
          name: name,
          birthDate: birthDate,
          challengeAreas: challengeAreas,
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> pushChildProfiles() async {
    final box = Hive.box<ChildProfile>(HiveBoxes.childProfiles);
    if (box.isEmpty) return;

    final payload = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final localId = key.toString();
      final p = box.get(key);
      if (p == null) continue;

      final maybeUuid = _toUuidOrNull(localId);
      payload.add({
        if (maybeUuid != null) 'id': maybeUuid,
        'name': p.name,
        'birth_date': p.birthDate.toIso8601String(),
        'challenge_areas': p.challengeAreas,
        'created_at': p.createdAt.toIso8601String(),
        // user_id injiceres i _upsertChunked
      });
    }

    await _upsertChunked('child_profiles', payload);
  }

  // ============================ PROGRESS ============================
  Future<void> pullProgress() async {
    final box = Hive.box<ProgressData>(HiveBoxes.progressData);

    final query = client.from('progress_data').select();
    final data = await _safeSelect(() {
      final u = uid();
      return u == null ? query : query.eq('user_id', u);
    });

    for (final row in data) {
      final map = row as Map<String, dynamic>;
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;

      await box.put(
        id,
        ProgressData(
          childId: (map['child_id'] ?? '').toString(),
          totalStars: (map['total_stars'] ?? 0) as int,
          masteredWords: (map['mastered_words'] ?? 0) as int,
          averageSuccessRate: (map['avg_success_rate'] ?? 0).toDouble(),
          createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
        ),
      );
    }
  }

  Future<void> pushProgress() async {
    final box = Hive.box<ProgressData>(HiveBoxes.progressData);
    if (box.isEmpty) return;

    final payload = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final localId = key.toString();
      final p = box.get(key);
      if (p == null) continue;

      final maybeUuid = _toUuidOrNull(localId);
      payload.add({
        if (maybeUuid != null) 'id': maybeUuid,
        'child_id': p.childId,
        'total_stars': p.totalStars,
        'mastered_words': p.masteredWords,
        'avg_success_rate': p.averageSuccessRate,
        'created_at': p.createdAt.toIso8601String(),
        // user_id injiceres i _upsertChunked
      });
    }

    await _upsertChunked('progress_data', payload);
  }

  // ========================= WORD ATTEMPTS ==========================
  Future<void> pullWordAttempts() async {
    final box = Hive.box<WordAttempt>(HiveBoxes.wordAttempts);

    final query = client.from('word_attempts').select();
    final data = await _safeSelect(() {
      final u = uid();
      return u == null ? query : query.eq('user_id', u);
    });

    for (final row in data) {
      final map = row as Map<String, dynamic>;
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final childId = (map['child_id'] ?? '').toString();
      final wordId = (map['word_id'] ?? '').toString();
      final word = (map['word'] ?? '').toString();

      if (childId.isEmpty || wordId.isEmpty || word.isEmpty) continue;

      final score = (map['score'] ?? 0).toDouble();
      final createdAt = _parseDate(map['created_at']) ?? DateTime.now();
      final firstAttempt = _parseDate(map['first_attempt']) ?? createdAt;
      final lastAttempt = _parseDate(map['last_attempt']) ?? firstAttempt;
      final sessionDates =
          _parseDateList(map['session_dates']) ?? <DateTime>[createdAt];

      await box.put(
        id,
        WordAttempt(
          childId: childId,
          wordId: wordId,
          word: word,
          score: score,
          createdAt: createdAt,
          firstAttempt: firstAttempt,
          lastAttempt: lastAttempt,
          sessionDates: sessionDates,
        ),
      );
    }
  }

  Future<void> pushWordAttempts() async {
    final box = Hive.box<WordAttempt>(HiveBoxes.wordAttempts);
    if (box.isEmpty) return;

    final payload = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final localId = key.toString();
      final w = box.get(key);
      if (w == null) continue;

      final maybeUuid = _toUuidOrNull(localId);
      payload.add({
        if (maybeUuid != null) 'id': maybeUuid,
        'child_id': w.childId,
        'word_id': w.wordId,
        'word': w.word,
        'score': w.score,
        'created_at': w.createdAt.toIso8601String(),
        'first_attempt': w.firstAttempt.toIso8601String(),
        'last_attempt': w.lastAttempt.toIso8601String(),
        'session_dates':
            w.sessionDates.map((d) => d.toIso8601String()).toList(),
        // user_id injiceres i _upsertChunked
      });
    }

    await _upsertChunked('word_attempts', payload);
  }

  // ======================= CATEGORY ATTEMPTS ========================
  Future<void> pullCategoryAttempts() async {
    final box = Hive.box<CategoryAttempt>(HiveBoxes.categoryAttempts);

    final query = client.from('category_attempts').select();
    final data = await _safeSelect(() {
      final u = uid();
      return u == null ? query : query.eq('user_id', u);
    });

    for (final row in data) {
      final map = row as Map<String, dynamic>;
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final childId = (map['child_id'] ?? '').toString();
      final wordId = (map['word_id'] ?? '').toString();
      final chosen = (map['chosen_category'] ?? '').toString();
      final correct = (map['correct_category'] ?? '').toString();
      final wasCorrect = (map['was_correct'] ?? false) as bool;
      final createdAt = _parseDate(map['created_at']) ?? DateTime.now();

      if (childId.isEmpty || wordId.isEmpty) continue;

      await box.put(
        id,
        CategoryAttempt(
          childId: childId,
          wordId: wordId,
          chosenCategory: chosen,
          correctCategory: correct,
          wasCorrect: wasCorrect,
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> pushCategoryAttempts() async {
    final box = Hive.box<CategoryAttempt>(HiveBoxes.categoryAttempts);
    if (box.isEmpty) return;

    final payload = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final localId = key.toString();
      final a = box.get(key);
      if (a == null) continue;

      final maybeUuid = _toUuidOrNull(localId);
      payload.add({
        if (maybeUuid != null) 'id': maybeUuid,
        'child_id': a.childId,
        'word_id': a.wordId,
        'chosen_category': a.chosenCategory,
        'correct_category': a.correctCategory,
        'was_correct': a.wasCorrect,
        'created_at': a.createdAt.toIso8601String(),
        // user_id injiceres i _upsertChunked
      });
    }

    await _upsertChunked('category_attempts', payload);
  }

  // ============================ HELPERS =============================
  Future<List<dynamic>> _safeSelect(
    Future<PostgrestList> Function() run, {
    int retries = 2,
  }) async {
    int attempts = 0;
    Object? lastErr;
    while (attempts <= retries) {
      try {
        final res = await run();
        return (res as List?) ?? const <dynamic>[];
      } catch (e, st) {
        lastErr = e;
        attempts += 1;
        final delayMs = 200 * math.pow(2, attempts).toInt();
        // ignore: avoid_print
        print('[_safeSelect] attempt $attempts/$retries failed: $e\n$st');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    if (lastErr != null) {
      // ignore: avoid_print
      print('[_safeSelect] all retries exhausted. Last error: $lastErr');
    }
    return const <dynamic>[];
  }

  Future<void> _upsertChunked(
    String table,
    List<Map<String, dynamic>> rows, {
    int chunkSize = 500,
  }) async {
    if (rows.isEmpty) return;
    for (var i = 0; i < rows.length; i += chunkSize) {
      final slice = rows
          .sublist(i, math.min(i + chunkSize, rows.length))
          .map(_withUserId)
          .toList(growable: false);
      await client.from(table).upsert(slice);
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  List<DateTime>? _parseDateList(dynamic v) {
    if (v == null) return null;
    if (v is List<DateTime>) return v;
    if (v is List) {
      return v.map(_parseDate).whereType<DateTime>().toList(growable: false);
    }
    return null;
  }

  String? _toUuidOrNull(String value) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$',
    );
    return uuid.hasMatch(value) ? value : null;
  }
}
