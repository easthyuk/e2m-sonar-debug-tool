import 'package:flutter/material.dart';

class AppTheme {
  // 라이트 테마
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueGrey[800],
      foregroundColor: Colors.white,
      elevation: 2,
    ),
  );

  // 다크 테마
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardTheme: CardThemeData(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
  );

  // Sonar 그래프 색상 (라이트)
  static const Color sonarSurfaceLight = Color(0xFFBBDEFB); // 파랑
  static const Color sonarFishLight = Color(0xFFFFEB3B); // 노랑
  static const Color sonarStrongLight = Color(0xFFFF9800); // 주황
  static const Color sonarBottomLight = Color(0xFFFF5722); // 빨강

  // Sonar 그래프 색상 (다크)
  static const Color sonarSurfaceDark = Color(0xFF0D47A1); // 진한 파랑
  static const Color sonarFishDark = Color(0xFFFDD835); // 밝은 노랑
  static const Color sonarStrongDark = Color(0xFFFB8C00); // 밝은 주황
  static const Color sonarBottomDark = Color(0xFFE53935); // 밝은 빨강

  // 연결 상태 색상
  static const Color connectedLight = Color(0xFF4CAF50);
  static const Color disconnectedLight = Color(0xFFF44336);
  static const Color connectedDark = Color(0xFF66BB6A);
  static const Color disconnectedDark = Color(0xFFEF5350);
}
