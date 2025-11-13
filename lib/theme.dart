import 'package:flutter/material.dart';

/// Centralized theme and colors for the UI revamp.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E88E5); // blue
  static const Color accent = Color(0xFFFFA726); // orange
  static const Color background = Color(0xFFF6F8FA);
  static const Color card = Colors.white;
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
}

class AppTheme {
  AppTheme._();

  // Centralized animation durations used across the UI revamp.
  static const Duration shortAnimation = Duration(milliseconds: 250);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 450);

  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      elevation: 8,
      backgroundColor: Colors.white,
      showUnselectedLabels: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: false,
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Color(0xFF0F1720),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white70,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFF0B1220),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF111316),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Simple ChangeNotifier to hold ThemeMode so we can toggle later from UI.
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get themeMode => _mode;

  void setThemeMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
  }

  void toggle() {
    if (_mode == ThemeMode.light) {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.light;
    }
    notifyListeners();
  }
}
