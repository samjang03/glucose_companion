// lib/core/utils/glucose_converter.dart
class GlucoseConverter {
  static const double conversionFactor = 18.0;

  // з mmol/L в mg/dL
  static double mmolToMgdl(double mmolValue) {
    return mmolValue * conversionFactor;
  }

  // з mg/dL в mmol/L
  static double mgdlToMmol(double mgdlValue) {
    return mgdlValue / conversionFactor;
  }

  // Форматоване значення відповідно до обраних одиниць
  static String formatValue(double mmolValue, bool useMMOL) {
    if (useMMOL) {
      return mmolValue.toStringAsFixed(1);
    } else {
      // Конвертуємо значення в mg/dL перед форматуванням
      double mgdlValue = mmolToMgdl(mmolValue);
      return mgdlValue.round().toString();
    }
  }

  // Одиниця вимірювання як стрічка
  static String unitString(bool useMMOL) {
    return useMMOL ? 'mmol/L' : 'mg/dL';
  }
}
