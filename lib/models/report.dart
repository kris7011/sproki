class ReportDomain {
  ReportDomain({
    required this.domainCode,
    required this.domainName,
    required this.rawScore,
    required this.zone,
    required this.pointsToGreen,
  });

  final String domainCode;
  final String domainName;
  final int rawScore;
  final String zone;
  final int? pointsToGreen;

  factory ReportDomain.fromJson(Map<String, dynamic> json) {
    return ReportDomain(
      domainCode: (json['domain_code'] as String?) ?? '',
      domainName: (json['domain_name'] as String?) ?? '',
      rawScore: (json['raw_score'] as num?)?.toInt() ?? 0,
      zone: (json['zone'] as String?) ?? '',
      pointsToGreen: (json['points_to_green'] as num?)?.toInt(),
    );
  }
}

class ChildReportAnalysis {
  ChildReportAnalysis({
    required this.reportId,
    required this.childId,
    required this.ageMonths,
    required this.domains,
  });

  final int reportId;
  final int childId;
  final int ageMonths;
  final List<ReportDomain> domains;

  factory ChildReportAnalysis.fromJson(Map<String, dynamic> json) {
    final domainsJson = (json['domains'] as List<dynamic>? ?? []);
    return ChildReportAnalysis(
      reportId: (json['report_id'] as num).toInt(),
      childId: (json['child_id'] as num).toInt(),
      ageMonths: (json['age_months'] as num).toInt(),
      domains: domainsJson
          .whereType<Map<String, dynamic>>()
          .map(ReportDomain.fromJson)
          .toList(),
    );
  }
}
