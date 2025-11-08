import 'package:sproki/api/api_client.dart';

class ReportService {
  ReportService._();
  static final instance = ReportService._();

  Future<Map<String, dynamic>> uploadReport({
    required String childId,
    required int ageYears,
    required int ageMonths,
    required List<Map<String, dynamic>> items,
  }) {
    return api.postReport(
      childId: childId,
      ageYears: ageYears,
      ageMonths: ageMonths,
      items: items,
    );
  }

  Future<Map<String, dynamic>> fetchLatestSummary(String childId) {
    return api.getLatestSummary(childId);
  }

  Future<bool> health() => api.health();
  Future<Map<String, dynamic>> pprPing() => api.pprPing();
}
