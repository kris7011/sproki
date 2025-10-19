// lib/services/practice_reporter.dart
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/models/report_models.dart';
import 'package:sproki/services/sproki_api.dart';

class PracticeReporter {
  PracticeReporter(this._api);
  final SprokiApi _api;

  Future<void> report({
    required String domain,
    required String exerciseId,
    required bool success,
    double? score,
    Map<String, dynamic>? meta,
  }) async {
    final childId = ActiveChildService.instance.activeChildIdSync;
    if (childId == null || childId.isEmpty) return;

    final evt = PracticeEventIn(
      childId: childId,
      domain: domain,
      exerciseId: exerciseId,
      outcome: success ? 'success' : 'fail',
      score: score,
      meta: meta,
      occurredAt: DateTime.now().toUtc(),
    );

    // SprokiApi.addPracticeEvents expects List<Map<String, dynamic>>
    await _api.addPracticeEvents(childId, [evt.toJson()]);
  }
}
