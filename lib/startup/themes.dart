/*
  * themes.dart *
  Class in charge of managing teh app's themes.
 */
import 'package:flutter/material.dart';

/// Manages the themes, including colorSchemes, of the app.
/// Contains blueTheme.
class Themes {
  // St. X Blue theme
  static final ThemeData blueTheme = ThemeData(
      colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2979FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF31ADFD),
    onSecondary: Color(0xFFE1E1E1),
    secondaryContainer: Color(0xFFF1F1F1),
    tertiary: Color(0xFF013089),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF6E707C),
    surface: Color(0xFFE1E1E1),
    shadow: Color(0xFF3B3B3B),
    onSurface: Color(0xFF000000),
    surfaceContainer: Color(0xFFC9C9C9),
    error: Color(0xFF910515),
    onError: Color(0xFFFFBD2E),
  ));
}
