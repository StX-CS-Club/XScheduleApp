import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An extension on Flutter's [Color] class for hex string conversion and 8-bit component access.
///
/// Responsibilities:
/// - Constructing [Color] objects from RGB hex strings
/// - Converting [Color] objects back to RGB hex strings
/// - Exposing red, green, and blue channel values as 8-bit integers
extension ColorExtension on Color {
  /// Returns a [Color] constructed from an RGB hex string.
  ///
  /// Parameters:
  /// - [hex]: A hex color string in the format `'RRGGBB'` or `'#RRGGBB'`
  ///
  /// Returns: A [Color] corresponding to the given hex value
  static Color fromHex(String hex) {
    // Strips any leading '#' and prepends '0xff' to form a valid Dart hex integer literal
    final int parsedInt = int.parse('0xff${hex.replaceAll('#', '')}');
    return Color(parsedInt);
  }

  /// Returns the RGB hex string representation of this [Color].
  ///
  /// This method:
  /// - Retrieves the red, green, and blue components as 8-bit integers
  /// - Converts each component to a two-character hex string, zero-padding if needed
  /// - Joins the components into a `'#RRGGBB'` formatted string
  ///
  /// Returns: A hex color string in the format `'#RRGGBB'`
  String toHex() {
    // Retrieves each color channel as a raw hex string (e.g. 'f', 'a3', 'ff')
    final List<String> components = [
      red().toRadixString(16),
      green().toRadixString(16),
      blue().toRadixString(16)
    ];

    // Ensures each component is exactly 2 characters, padding with a leading '0' if needed
    // (e.g. 'f' → '0f', 'a3' → 'a3')
    final List<String> hexComponents = [];
    for (String component in components) {
      while (component.length < 2) {
        component = '0$component';
      }
      hexComponents.add(component);
    }

    // Concatenates components into a '#RRGGBB' hex string
    return '#${hexComponents[0]}${hexComponents[1]}${hexComponents[2]}';
  }

  /// Returns the red channel of this [Color] as an 8-bit integer (0–255).
  ///
  /// Note: [Color.r] is a linear proportion in the range `[0.0, 1.0]`;
  /// multiplying by 255 and flooring converts it to a standard 8-bit value.
  ///
  /// Returns: An [int] in the range `0–255`
  int red() {
    return (r * 255).floor();
  }

  /// Returns the green channel of this [Color] as an 8-bit integer (0–255).
  ///
  /// Note: [Color.g] is a linear proportion in the range `[0.0, 1.0]`;
  /// multiplying by 255 and flooring converts it to a standard 8-bit value.
  ///
  /// Returns: An [int] in the range `0–255`
  int green() {
    return (g * 255).floor();
  }

  /// Returns the blue channel of this [Color] as an 8-bit integer (0–255).
  ///
  /// Note: [Color.b] is a linear proportion in the range `[0.0, 1.0]`;
  /// multiplying by 255 and flooring converts it to a standard 8-bit value.
  ///
  /// Returns: An [int] in the range `0–255`
  int blue() {
    return (b * 255).floor();
  }
}