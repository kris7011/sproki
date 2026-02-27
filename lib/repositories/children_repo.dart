import 'package:sproki/models/child_vm.dart';

class ChildrenRepo {
  static final ChildrenRepo current = ChildrenRepo._();

  ChildrenRepo._();

  Future<List<ChildVm>> listChildren() async {
    // TODO: Replace with API call later.
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      ChildVm(id: 1, name: 'Emma', ageYears: 5, ageMonths: 2),
      ChildVm(id: 2, name: 'Noah', ageYears: 4, ageMonths: 8),
    ];
  }
}
