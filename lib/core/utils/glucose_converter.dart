class GlucoseConverter {
  static const double conversionFactor = 18.0;

  // Convert from mmol/L to mg/dL
  static double mmolToMgdl(double mmolValue) {
    return mmolValue * conversionFactor;
  }

  // Convert from mg/dL to mmol/L
  static double mgdlToMmol(double mgdlValue) {
    return mgdlValue / conversionFactor;
  }

  // Format value according to selected units
  static String formatValue(double mmolValue, bool useMMOL) {
    if (useMMOL) {
      return mmolValue.toStringAsFixed(1);
    } else {
      return mmolToMgdl(mmolValue).round().toString();
    }
  }

  // Unit string
  static String unitString(bool useMMOL) {
    return useMMOL ? 'mmol/L' : 'mg/dL';
  }
}
