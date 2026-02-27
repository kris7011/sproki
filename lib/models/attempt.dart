class StartTrainingRequest {
  StartTrainingRequest({
    required this.childId,
    required this.exerciseIds,
  });

  final int childId;
  final List<String> exerciseIds;

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'exercise_ids': exerciseIds,
      };
}

class Attempt {
  Attempt({
    required this.id,
    required this.childId,
    required this.createdAtIso,
    required this.raw,
  });

  final String id;
  final int childId;
  final String createdAtIso;
  final Map<String, dynamic> raw;

  static Attempt fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
        if (v != null) return v.toString();
      }
      return fallback;
    }

    int readInt(List<String> keys, {int fallback = 0}) {
      for (final k in keys) {
        final v = json[k];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
      return fallback;
    }

    final inner = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : (json['attempt'] is Map<String, dynamic>)
            ? (json['attempt'] as Map<String, dynamic>)
            : json;

    final id = readString(['id', 'attempt_id', 'attemptId'], fallback: '');
    final childId = readInt(['child_id', 'childId'], fallback: 0);
    final createdAtIso =
        readString(['created_at', 'createdAt', 'timestamp'], fallback: '');

    return Attempt(
      id: id,
      childId: childId,
      createdAtIso: createdAtIso,
      raw: inner,
    );
  }
}
