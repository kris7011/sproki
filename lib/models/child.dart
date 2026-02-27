class Child {
  Child({
    required this.id,
    required this.name,
    required this.ageYears,
    required this.ageMonths,
  });

  final int id;
  final String name;
  final int ageYears;
  final int ageMonths;

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      ageYears: (json['age_years'] as num?)?.toInt() ?? 0,
      ageMonths: (json['age_months'] as num?)?.toInt() ?? 0,
    );
  }

  String get ageText => '$ageYears år $ageMonths mdr';
}
