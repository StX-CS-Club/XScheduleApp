import 'package:flutter/material.dart';

/// An extension on Flutter's [Widget] class for common layout and visual wrapping operations.
///
/// Responsibilities:
/// - Wrapping widgets in [FittedBox] to scale content down to fit available space
/// - Wrapping widgets in [Expanded] for flex-layout compatibility with fit and alignment control
/// - Wrapping widgets in [IntrinsicWidth] to size to child content width
/// - Wrapping widgets in [ClipRRect] to apply rounded-rectangle clipping
/// - Wrapping widgets in [Opacity] to control widget transparency
extension WidgetExtension on Widget {
  /// Returns this widget wrapped in a [FittedBox] set to [BoxFit.scaleDown].
  ///
  /// Scales the widget down to fit its parent's constraints, but never scales it up.
  ///
  /// Returns: A [FittedBox] wrapping this widget
  Widget fit() {
    return FittedBox(fit: BoxFit.scaleDown, child: this);
  }

  /// Returns this widget wrapped in a [FittedBox] inside an [Expanded], with optional
  /// alignment and padding.
  ///
  /// Intended for use inside [Row] or [Column] layouts where the widget should claim
  /// all remaining space and scale its content down to fit within it.
  ///
  /// Parameters:
  /// - [alignment]: Alignment of this widget within the [Expanded]; defaults to [Alignment.center]
  /// - [padding]: Margin between this widget and the edges of the [Expanded]; defaults to [EdgeInsets.zero]
  ///
  /// Returns: An [Expanded] containing a [Container] containing a [FittedBox] wrapping this widget
  Widget expandedFit(
      {Alignment alignment = Alignment.center,
        EdgeInsets padding = EdgeInsets.zero}) {
    // Container handles alignment and margin; FittedBox handles scale-down within that space
    return Expanded(
        child: Container(
            margin: padding,
            alignment: alignment,
            child: FittedBox(fit: BoxFit.scaleDown, child: this)));
  }

  /// Returns this widget wrapped in an [IntrinsicWidth] widget.
  ///
  /// [IntrinsicWidth] sizes itself to match the intrinsic (natural/preferred) width of its
  /// child, useful when a widget would otherwise stretch to fill available horizontal space.
  ///
  /// Returns: An [IntrinsicWidth] wrapping this widget
  Widget intrinsicFit() {
    return IntrinsicWidth(child: this);
  }

  /// Returns this widget clipped to a rounded rectangle with the given [borderRadius].
  ///
  /// Uses [Clip.hardEdge] for performance — pixels outside the rounded bounds are
  /// clipped without anti-aliasing.
  ///
  /// Parameters:
  /// - [borderRadius]: The corner radii applied to the clip; defaults to [BorderRadius.zero]
  ///   (no rounding, equivalent to a plain rectangular clip)
  ///
  /// Returns: A [ClipRRect] wrapping this widget
  Widget clip({BorderRadius borderRadius = BorderRadius.zero}) {
    return ClipRRect(
        borderRadius: borderRadius, clipBehavior: Clip.hardEdge, child: this);
  }

  /// Returns this widget wrapped in an [Opacity] widget.
  ///
  /// Parameters:
  /// - [opacity]: A value between `0.0` (fully transparent) and `1.0` (fully opaque)
  ///
  /// Returns: An [Opacity] wrapping this widget
  Widget withOpacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }
}