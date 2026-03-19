/*
  * widget_extension *
  Extension on Widget which provides static Widgets and better fitting methods.
 */
import 'package:flutter/material.dart';

/// Widget extension <p>
/// Provided static Widgets and fit methods for existing widgets.
extension WidgetExtension on Widget {

  /// Widget extension <p>
  /// Returns a FittedBox set to scaleDown wrapping this widget.
  Widget fit() {
    // Returns child wrapped in FittedBox
    return FittedBox(fit: BoxFit.scaleDown, child: this);
  }

  /// Widget extension <p>
  /// Returns a FittedBox set to scaleDown wrapping this widget wrapped in an Expanded box and at a specified alignment.
  /// [Alignment alignment = Alignment.center]: Alignment of widget in Expanded <p>
  /// [EdgeInsets padding = EdgeInsets.zero]: Padding from edges of Expanded <p>
  Widget expandedFit(
      {Alignment alignment = Alignment.center,
      EdgeInsets padding = EdgeInsets.zero}) {
    // Returns child wrapped in FittedBox w/ padding wrapped in Expanded
    return Expanded(
        child: Container(
            margin: padding,
            alignment: alignment,
            child: FittedBox(fit: BoxFit.scaleDown, child: this)));
  }

  /// Widget extension <p>
  /// Returns this widget wrapped in an IntrinsicWidth widget. IntrinsicWidth matches teh size of its child.
  Widget intrinsicFit() {
    return IntrinsicWidth(child: this);
  }

  /// Widget extension <p>
  /// Returns this widget wrapped in a ClipRRECT Widget.
  Widget clip({BorderRadius borderRadius = BorderRadius.zero}){
    return ClipRRect(borderRadius: borderRadius, clipBehavior: Clip.hardEdge, child: this);
  }

  /// Widget extension <p>
  /// Returns this widget wrapped in an Opacity Widget of given opacity. <p>
  /// [double opacity]: % opacity of widget <p>
  Widget withOpacity(double opacity){
    return Opacity(opacity: opacity, child: this);
  }
}
