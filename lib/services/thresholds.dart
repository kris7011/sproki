// lib/services/thresholds.dart
import 'dart:math' as math;

/// Domænenavne som backend bruger i planen.
/// Brug præcis samme nøgler som i planens `priorityAreas[].domain`.
class Domains {
  static const sprogforstaelse = 'sprogforståelse';
  static const ordforrad = 'ordforråd';
  static const kommunikativeStrategier = 'kommunikativeStrategier';
  static const rim = 'rim';
  static const opmaerksomhedPaSkrift = 'opmærksomhedPåSkrift';

  static const all = <String>{
    sprogforstaelse,
    ordforrad,
    kommunikativeStrategier,
    rim,
    opmaerksomhedPaSkrift,
  };
}

/// En alders-bandet tærskel: [minMonth, maxMonth] (inkl.) og grænser til farver.
class AgeBand {
  final int minMonth;
  final int maxMonth;
  final double greenMin; // score >= grøn
  final double yellowMin; // score >= gul, < grøn (ellers rød)
  const AgeBand({
    required this.minMonth,
    required this.maxMonth,
    required this.greenMin,
    required this.yellowMin,
  });

  bool contains(int ageMonths) =>
      ageMonths >= minMonth && ageMonths <= maxMonth;
}

/// Tærskler pr. domæne.
/// OBS: Tallene her er *eksempelværdier* – ret dem til efter jeres faglige skabelon.
final Map<String, List<AgeBand>> kThresholds = {
  Domains.sprogforstaelse: const [
    AgeBand(minMonth: 36, maxMonth: 47, greenMin: 60, yellowMin: 45),
    AgeBand(minMonth: 48, maxMonth: 59, greenMin: 65, yellowMin: 50),
    AgeBand(minMonth: 60, maxMonth: 72, greenMin: 70, yellowMin: 55),
  ],
  Domains.ordforrad: const [
    AgeBand(minMonth: 36, maxMonth: 47, greenMin: 55, yellowMin: 40),
    AgeBand(minMonth: 48, maxMonth: 59, greenMin: 60, yellowMin: 45),
    AgeBand(minMonth: 60, maxMonth: 72, greenMin: 68, yellowMin: 52),
  ],
  Domains.kommunikativeStrategier: const [
    AgeBand(minMonth: 36, maxMonth: 47, greenMin: 58, yellowMin: 42),
    AgeBand(minMonth: 48, maxMonth: 59, greenMin: 63, yellowMin: 48),
    AgeBand(minMonth: 60, maxMonth: 72, greenMin: 70, yellowMin: 55),
  ],
  Domains.rim: const [
    AgeBand(minMonth: 36, maxMonth: 47, greenMin: 50, yellowMin: 35),
    AgeBand(minMonth: 48, maxMonth: 59, greenMin: 60, yellowMin: 45),
    AgeBand(minMonth: 60, maxMonth: 72, greenMin: 70, yellowMin: 55),
  ],
  Domains.opmaerksomhedPaSkrift: const [
    AgeBand(minMonth: 36, maxMonth: 47, greenMin: 45, yellowMin: 30),
    AgeBand(minMonth: 48, maxMonth: 59, greenMin: 55, yellowMin: 40),
    AgeBand(minMonth: 60, maxMonth: 72, greenMin: 65, yellowMin: 50),
  ],
};

enum Zone { groen, gul, roed }

class ZoneResult {
  final Zone zone;
  final double pointsToGreen; // 0 hvis allerede grøn
  final double greenThreshold; // reference (for UI)
  final double yellowThreshold; // reference (for UI)
  const ZoneResult({
    required this.zone,
    required this.pointsToGreen,
    required this.greenThreshold,
    required this.yellowThreshold,
  });
}

/// Udregn zone + “point til grøn” for et domæne givet alder (måneder) og score.
ZoneResult evaluateZone({
  required String domain,
  required int ageMonths,
  required double score,
}) {
  final bands = kThresholds[domain];

  // Hvis vi ikke har data, antag generisk skala
  if (bands == null || bands.isEmpty) {
    final z =
        score >= 60.0 ? Zone.groen : (score >= 45.0 ? Zone.gul : Zone.roed);
    final pts = z == Zone.groen ? 0.0 : math.max(0.0, 60.0 - score);
    return ZoneResult(
      zone: z,
      pointsToGreen: pts,
      greenThreshold: 60.0,
      yellowThreshold: 45.0,
    );
  }

  final band = bands.firstWhere(
    (b) => b.contains(ageMonths),
    orElse: () => bands.last,
  );

  final isGreen = score >= band.greenMin;
  final isYellow = !isGreen && score >= band.yellowMin;
  final zone = isGreen ? Zone.groen : (isYellow ? Zone.gul : Zone.roed);
  final pts = isGreen ? 0.0 : math.max(0.0, band.greenMin - score);

  return ZoneResult(
    zone: zone,
    pointsToGreen: pts,
    greenThreshold: band.greenMin,
    yellowThreshold: band.yellowMin,
  );
}

/// Hjælpere til tekst/ikonfarver i UI
String zoneLabel(Zone z) =>
    z == Zone.groen ? 'grøn' : (z == Zone.gul ? 'gul' : 'rød');
