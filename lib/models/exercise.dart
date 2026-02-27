class ExerciseItem {
  ExerciseItem({
    required this.id,
    required this.title,
    required this.domainCode,
    required this.domainName,
    required this.minAgeMonths,
    required this.maxAgeMonths,
  });

  final int id;
  final String title;
  final String domainCode;
  final String domainName;
  final int minAgeMonths;
  final int maxAgeMonths;

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      domainCode: (json['domain_code'] as String?) ?? '',
      domainName: (json['domain_name'] as String?) ?? '',
      minAgeMonths: (json['min_age_months'] as num?)?.toInt() ?? 0,
      maxAgeMonths: (json['max_age_months'] as num?)?.toInt() ?? 9999,
    );
  }
}
