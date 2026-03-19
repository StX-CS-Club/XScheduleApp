/*
  * color_extension.dart *
  Extension on the Flutter Color class to handle hex codes and storing values.
 */
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Color extension <p>
/// Handles Colors involving hex values and storing color components.
extension ColorExtension on Color {
  /// Color extension <p>
  /// Returns a Flutter color object from a given hex code (RGB)
  static Color fromHex(String hex) {
    // Parses hexadecimal int of color
    final int parsedInt = int.parse('0xff${hex.replaceAll('#', '')}');
    // Returns Color created from int value.
    return Color(parsedInt);
  }

  /// Color extension <p>
  /// Returns a hex String for the given color
  String toHex() {
    // Breaks color into RGB components
    final List<String> components = [
      red().toRadixString(16),
      green().toRadixString(16),
      blue().toRadixString(16)
    ];
    // Converts all components into hex format
    final List<String> hexComponents = [];
    for (String component in components) {
      while (component.length < 2) {
        component = '0$component';
      }
      hexComponents.add(component);
    }
    // Returns hex string from merged components
    return '#${hexComponents[0]}${hexComponents[1]}${hexComponents[2]}';
  }

  /// Color extension <p>
  /// Provides the 8-bit int value of the color's red component
  int red() {
    // Converts r proportion to 8-bit int
    return (r * 255).floor();
  }

  /// Color extension <p>
  /// Provides the 8-bit int value of the color's green component
  int green() {
    // Converts g proportion to 8-bit int
    return (g * 255).floor();
  }

  /// Color extension <p>
  /// Provides the 8-bit int value of the color's blue component
  int blue() {
    // Converts b proportion to 8-bit int
    return (b * 255).floor();
  }
}