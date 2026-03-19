import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';

/// A circular icon button with a filled [CircleAvatar] background.
///
/// Responsibilities:
/// - Rendering an [Icon] centered within a filled circle
/// - Scaling the icon to fit within the circle based on [radius] and [padding]
/// - Handling optional tap interactions via [InkWell]
class IconCircle extends StatelessWidget {
  /// Creates an [IconCircle] with the given icon and optional styling and tap behavior.
  ///
  /// The icon is scaled to `radius * 2 - padding` to ensure it fits inside the circle
  /// with consistent visual breathing room on all sides.
  ///
  /// Parameters:
  /// - [icon]: The [IconData] to display inside the circle; required
  /// - [onTap]: Callback invoked when the widget is tapped; pass `null` for a non-interactive circle
  /// - [radius]: The radius of the [CircleAvatar] in logical pixels; defaults to `15`
  /// - [padding]: Reduces the icon size relative to the circle diameter; defaults to `5`
  /// - [color]: Background color of the circle; defaults to the theme's avatar color if `null`
  /// - [iconColor]: Color of the icon; defaults to the theme's icon color if `null`
  const IconCircle(
      {super.key,
        required this.icon,
        this.onTap,
        this.color,
        this.radius = 15,
        this.padding = 5,
        this.iconColor});

  /// The icon to display inside the circle.
  final IconData icon;

  /// Callback invoked when the widget is tapped.
  ///
  /// When `null`, the [InkWell] renders no tap effect and the widget is non-interactive.
  final void Function()? onTap;

  /// The radius of the circular background in logical pixels.
  ///
  /// Also determines the icon size via `radius * 2 - padding`.
  final double radius;

  /// The amount by which the icon is inset from the circle's diameter.
  ///
  /// A larger value produces a smaller icon relative to the circle, increasing
  /// visual padding between the icon and the circle's edge.
  final double padding;

  /// The background color of the circle.
  ///
  /// When `null`, falls back to the theme's default [CircleAvatar] background color.
  final Color? color;

  /// The color of the icon.
  ///
  /// When `null`, falls back to the theme's default icon color.
  final Color? iconColor;

  /// Builds an [InkWell] containing a [CircleAvatar] with a scaled, fitted [Icon].
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: Icon(
          icon,
          // Scales the icon to fill the circle diameter minus padding on each side
          size: radius * 2 - padding,
          color: iconColor,
        ).fit(), // .fit() wraps in FittedBox to prevent overflow if the icon is too large
      ),
    );
  }
}