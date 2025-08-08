// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Define common colors
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color lightSilver = Color(0xFFE0E0E0);
  static const Color darkBackground = Color(0xFF121212);
  static const Color white = Colors.white;

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: darkBlue,
    scaffoldBackgroundColor: white,
    colorScheme: ColorScheme.light(
      primary: darkBlue,
      secondary: silver,
      surface: white,
      onPrimary: white,
      onSecondary: darkBlue,
      onSurface: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBlue,
      foregroundColor: white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkBlue,
        foregroundColor: white,
        textStyle: TextStyle(fontSize: 16),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkBlue,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: darkBlue,
      secondary: silver,
      surface: darkBackground,
      onPrimary: white,
      onSecondary: darkBlue,
      onSurface: white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBlue,
      foregroundColor: white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkBlue,
        foregroundColor: white,
        textStyle: TextStyle(fontSize: 16),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: white),
      bodyLarge: TextStyle(fontSize: 16, color: white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
    ),
  );
}
