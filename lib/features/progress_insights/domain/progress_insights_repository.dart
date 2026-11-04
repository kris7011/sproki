import 'progress_insights.dart';

abstract interface class ProgressInsightsRepository {
  Future<ProgressInsights> load();
}
