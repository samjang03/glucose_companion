import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF4A5CFF),
      secondaryHeaderColor: const Color(0xFF7B61FF),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF4A5CFF),
        secondary: const Color(0xFF7B61FF),
        tertiary: const Color(0xFFFF61DC),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4A5CFF),
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: const Color(0xFF4A5CFF),
      secondaryHeaderColor: const Color(0xFF7B61FF),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF4A5CFF),
        secondary: const Color(0xFF7B61FF),
        tertiary: const Color(0xFFFF61DC),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
      ),
    );
  }
}
