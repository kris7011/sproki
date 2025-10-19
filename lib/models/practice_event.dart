// lib/models/practice_event.dart
class PracticeEvent {
  final String childId;
  final String domain; // skal matche backendens DOMAINS
  final String exerciseId; // fx "word_pronunciation"
  final String outcome; // "success" | "fail"
  final double? score; // 0..1
  final Map<String, dynamic>? meta;
  final DateTime occurredAt;

  PracticeEvent({
    required this.childId,
    required this.domain,
    required this.exerciseId,
    required this.outcome,
    this.score,
    this.meta,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'domain': domain,
        'exerciseId': exerciseId,
        'outcome': outcome,
        if (score != null) 'score': score,
        if (meta != null) 'meta': meta,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
      };
}
