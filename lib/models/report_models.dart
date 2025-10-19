import 'dart:convert';

// Non-obvious mapping kept explicit to match backend JSON exactly.

class Scores {
  final double sprogforstaelse; // use ASCII field names in Dart
  final double ordforraad;
  final double kommunikativeStrategier;
  final double rim;
  final double opmaerksomhedPaSkrift;

  const Scores({
    required this.sprogforstaelse,
    required this.ordforraad,
    required this.kommunikativeStrategier,
    required this.rim,
    required this.opmaerksomhedPaSkrift,
  });

  Map<String, dynamic> toJson() => {
        // keep backend keys (with diacritics) as JSON keys:
        'sprogforståelse': sprogforstaelse,
        'ordforråd': ordforraad,
        'kommunikativeStrategier': kommunikativeStrategier,
        'rim': rim,
        'opmærksomhedPåSkrift': opmaerksomhedPaSkrift,
      };
}

class ReportIn {
  final int ageMonths;
  final Scores scores;

  const ReportIn({required this.ageMonths, required this.scores});

  Map<String, dynamic> toJson() => {
        'ageMonths': ageMonths,
        'scores': scores.toJson(),
      };
}

class PlanOut {
  final List<dynamic> priorityAreas;
  final List<dynamic> recommendations;
  final Map<String, dynamic> meta;

  PlanOut({
    required this.priorityAreas,
    required this.recommendations,
    required this.meta,
  });

  factory PlanOut.fromJson(Map<String, dynamic> j) => PlanOut(
        priorityAreas: j['priorityAreas'] as List<dynamic>? ?? const [],
        recommendations: j['recommendations'] as List<dynamic>? ?? const [],
        meta: (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  /// Add this so callers (PlanStore) can persist the plan as a Map.
  Map<String, dynamic> toMap() => {
        'priorityAreas': priorityAreas,
        'recommendations': recommendations,
        'meta': meta,
      };

  String toJsonString() => jsonEncode(toMap());
}

// Payload for practice-events, matches backend exactly.
class PracticeEventIn {
  final String childId;
  final String domain; // must be one of Domains.all
  final String exerciseId; // app-specific slug/id
  final String outcome; // "success" | "fail"
  final double? score; // 0..1
  final Map<String, dynamic>? meta;
  final DateTime? occurredAt; // utc

  PracticeEventIn({
    required this.childId,
    required this.domain,
    required this.exerciseId,
    required this.outcome,
    this.score,
    this.meta,
    this.occurredAt,
  });

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'domain': domain,
        'exerciseId': exerciseId,
        'outcome': outcome,
        if (score != null) 'score': score,
        if (meta != null) 'meta': meta,
        if (occurredAt != null)
          'occurredAt': occurredAt!.toUtc().toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory PracticeEventIn.fromJson(Map<String, dynamic> j) => PracticeEventIn(
        childId: j['childId'] as String,
        domain: j['domain'] as String,
        exerciseId: j['exerciseId'] as String,
        outcome: j['outcome'] as String,
        score: (j['score'] as num?)?.toDouble(),
        meta: (j['meta'] as Map?)?.cast<String, dynamic>(),
        occurredAt: j['occurredAt'] != null
            ? DateTime.parse(j['occurredAt'] as String).toUtc()
            : null,
      );
}
