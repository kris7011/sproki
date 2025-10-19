// Keep UI source of truth in one place.
class Domains {
  static const sprogforstaelse = "sprogforståelse";
  static const ordforrad = "ordforråd";
  static const kommunikativeStrategier = "kommunikativeStrategier";
  static const rim = "rim";
  static const opmaerksomhedPaSkrift = "opmærksomhedPåSkrift";

  static const all = <String>{
    sprogforstaelse,
    ordforrad,
    kommunikativeStrategier,
    rim,
    opmaerksomhedPaSkrift,
  };

  // UI labels if needed
  static const labels = <String, String>{
    sprogforstaelse: "Sprogforståelse",
    ordforrad: "Ordforråd",
    kommunikativeStrategier: "Kommunikative strategier",
    rim: "Rim",
    opmaerksomhedPaSkrift: "Opmærksomhed på skrift",
  };
}
