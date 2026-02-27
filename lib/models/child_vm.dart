class ChildVm {
  final int id;
  final String name;
  final int ageYears;
  final int ageMonths;

  const ChildVm({
    required this.id,
    required this.name,
    required this.ageYears,
    required this.ageMonths,
  });

  String get ageLabel {
    final parts = <String>[];
    if (ageYears > 0) parts.add('$ageYears år');
    if (ageMonths > 0) parts.add('$ageMonths mdr');
    if (parts.isEmpty) return '0 mdr';
    return parts.join(' ');
  }
}
