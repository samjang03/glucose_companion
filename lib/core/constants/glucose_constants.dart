// lib/core/constants/glucose_constants.dart
class GlucoseConstants {
  // Стандартні пороги в mmol/L (базові значення для зберігання в БД)
  static const double LOW_THRESHOLD_MMOL = 3.9;
  static const double HIGH_THRESHOLD_MMOL = 10.0;
  static const double URGENT_LOW_THRESHOLD_MMOL = 3.0;
  static const double URGENT_HIGH_THRESHOLD_MMOL = 13.9;

  // Відповідні пороги в mg/dL для відображення
  static const double LOW_THRESHOLD_MGDL = 70;
  static const double HIGH_THRESHOLD_MGDL = 180;
  static const double URGENT_LOW_THRESHOLD_MGDL = 54;
  static const double URGENT_HIGH_THRESHOLD_MGDL = 250;

  // Діапазони для слайдерів в settings
  static const double MIN_LOW_THRESHOLD_MMOL = 3.0;
  static const double MAX_LOW_THRESHOLD_MMOL = 5.0;
  static const double MIN_HIGH_THRESHOLD_MMOL = 8.0;
  static const double MAX_HIGH_THRESHOLD_MMOL = 15.0;
  static const double MIN_URGENT_LOW_THRESHOLD_MMOL = 2.0;
  static const double MAX_URGENT_LOW_THRESHOLD_MMOL = 4.0;
  static const double MIN_URGENT_HIGH_THRESHOLD_MMOL = 12.0;
  static const double MAX_URGENT_HIGH_THRESHOLD_MMOL = 20.0;

  // Відповідні діапазони в mg/dL
  static const double MIN_LOW_THRESHOLD_MGDL = 54;
  static const double MAX_LOW_THRESHOLD_MGDL = 90;
  static const double MIN_HIGH_THRESHOLD_MGDL = 144;
  static const double MAX_HIGH_THRESHOLD_MGDL = 270;
  static const double MIN_URGENT_LOW_THRESHOLD_MGDL = 36;
  static const double MAX_URGENT_LOW_THRESHOLD_MGDL = 72;
  static const double MIN_URGENT_HIGH_THRESHOLD_MGDL = 216;
  static const double MAX_URGENT_HIGH_THRESHOLD_MGDL = 360;

  // Фізіологічні межі для валідації
  static const double MIN_PHYSIOLOGICAL_MMOL = 1.0;
  static const double MAX_PHYSIOLOGICAL_MMOL = 30.0;
  static const double MIN_PHYSIOLOGICAL_MGDL = 18;
  static const double MAX_PHYSIOLOGICAL_MGDL = 540;

  // Максимальна швидкість зміни глюкози (ммоль/л за 5 хвилин)
  static const double MAX_GLUCOSE_CHANGE_RATE_MMOL = 2.0;

  // Конвертація
  static const double MMOL_TO_MGDL_FACTOR = 18.0182;

  // Методи для отримання правильних порогів
  static double getDefaultLowThreshold(bool useMMOL) {
    return useMMOL ? LOW_THRESHOLD_MMOL : LOW_THRESHOLD_MGDL;
  }

  static double getDefaultHighThreshold(bool useMMOL) {
    return useMMOL ? HIGH_THRESHOLD_MMOL : HIGH_THRESHOLD_MGDL;
  }

  static double getDefaultUrgentLowThreshold(bool useMMOL) {
    return useMMOL ? URGENT_LOW_THRESHOLD_MMOL : URGENT_LOW_THRESHOLD_MGDL;
  }

  static double getDefaultUrgentHighThreshold(bool useMMOL) {
    return useMMOL ? URGENT_HIGH_THRESHOLD_MMOL : URGENT_HIGH_THRESHOLD_MGDL;
  }

  // Методи для отримання діапазонів слайдерів
  static double getMinLowThreshold(bool useMMOL) {
    return useMMOL ? MIN_LOW_THRESHOLD_MMOL : MIN_LOW_THRESHOLD_MGDL;
  }

  static double getMaxLowThreshold(bool useMMOL) {
    return useMMOL ? MAX_LOW_THRESHOLD_MMOL : MAX_LOW_THRESHOLD_MGDL;
  }

  static double getMinHighThreshold(bool useMMOL) {
    return useMMOL ? MIN_HIGH_THRESHOLD_MMOL : MIN_HIGH_THRESHOLD_MGDL;
  }

  static double getMaxHighThreshold(bool useMMOL) {
    return useMMOL ? MAX_HIGH_THRESHOLD_MMOL : MAX_HIGH_THRESHOLD_MGDL;
  }

  static double getMinUrgentLowThreshold(bool useMMOL) {
    return useMMOL
        ? MIN_URGENT_LOW_THRESHOLD_MMOL
        : MIN_URGENT_LOW_THRESHOLD_MGDL;
  }

  static double getMaxUrgentLowThreshold(bool useMMOL) {
    return useMMOL
        ? MAX_URGENT_LOW_THRESHOLD_MMOL
        : MAX_URGENT_LOW_THRESHOLD_MGDL;
  }

  static double getMinUrgentHighThreshold(bool useMMOL) {
    return useMMOL
        ? MIN_URGENT_HIGH_THRESHOLD_MMOL
        : MIN_URGENT_HIGH_THRESHOLD_MGDL;
  }

  static double getMaxUrgentHighThreshold(bool useMMOL) {
    return useMMOL
        ? MAX_URGENT_HIGH_THRESHOLD_MMOL
        : MAX_URGENT_HIGH_THRESHOLD_MGDL;
  }
}
