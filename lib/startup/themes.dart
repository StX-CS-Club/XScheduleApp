import 'package:flutter/material.dart';

/// Defines the color themes used throughout the XSchedule app.
///
/// Responsibilities:
/// - Provides static [ThemeData] instances consumed by [XScheduleApp]
/// - Centralizes all color scheme definitions so changes propagate app-wide
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
}
