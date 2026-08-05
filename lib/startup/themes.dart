import 'package:flutter/material.dart';

/// All theme options
enum ThemeToggle {light, dark, auto}

/// Defines the color themes used throughout the XSchedule app.
///
/// Responsibilities:
/// - Provides static [ThemeData] instances consumed by [XScheduleApp]
/// - Centralizes all color scheme definitions so changes propagate app-wide
///
/// To change themes: themeNotifier.value = ThemeToggle.light (or .dark, .auto...)
class Themes {
  // Private constructor — this class is not intended to be instantiated
  Themes._();

  /// The primary St. Xavier blue theme applied to the entire app.
  ///
  /// Color roles:
  /// - [primary]: St. X bright blue — used for buttons, active indicators, and highlights
  /// - [onPrimary]: White — text/icons on primary-colored surfaces
  /// - [primaryContainer]: White — main page background
  /// - [secondary]: Light blue — secondary buttons and accents
  /// - [onSecondary]: Light grey — text/icons on secondary surfaces
  /// - [secondaryContainer]: Near-white grey — settings page background
  /// - [tertiary]: Deep St. X navy — nav bar and strong accent elements
  /// - [onTertiary]: White — text/icons on tertiary surfaces
  /// - [tertiaryContainer]: Muted blue-grey — nav bar background
  /// - [surface]: Light grey — card and popup backgrounds
  /// - [onSurface]: Black — primary text and icon color
  /// - [surfaceContainer]: Medium grey — avatar and container backgrounds
  /// - [shadow]: Dark grey — dividers, borders, and drop shadows
  /// - [error]: Dark red — error states
  /// - [onError]: Amber — text/icons on error surfaces
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

  static final ThemeData darkTheme = ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF5B9BFF),
        onPrimary: Color(0xFF00204D),
        primaryContainer: Color(0xFF121212),
        secondary: Color(0xFF31ADFD),
        onSecondary: Color(0xFF0A0A0A),
        secondaryContainer: Color(0xFF1E1E1E),
        tertiary: Color(0xFF3D5AFE),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFF0D1B3E),
        surface: Color(0xFF1E1E1E),
        shadow: Color(0xFF000000),
        onSurface: Color(0xFFECECEC),
        surfaceContainer: Color(0xFF2C2C2C),
        error: Color(0xFFCF6679),
        onError: Color(0xFF1B0000),
      ));
}
