// lib/services/age_gate.dart
import 'package:sproki/constants/domains.dart';

class AgeGate {
  /// Minimum-aldre (i måneder) for domæner. Justér efter fagligt niveau.
  static const Map<String, int> _minAge = {
    Domains.rim: 42, // ca. 3,5 år
    Domains.opmaerksomhedPaSkrift: 48,
    Domains.kommunikativeStrategier: 36,
    Domains.sprogforstaelse: 36,
    Domains.ordforrad: 36,
  };

  static bool isDomainEnabled(String domain, int ageMonths) {
    final minM = _minAge[domain] ?? 0;
    return ageMonths >= minM;
  }
}
