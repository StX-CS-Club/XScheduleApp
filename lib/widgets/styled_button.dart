import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';

/// A themed [ElevatedButton] supporting an icon, a text label, or both, in horizontal or vertical layouts.
///
/// Responsibilities:
/// - Rendering an [ElevatedButton] with customisable colors, size, and corner radius
/// - Displaying an optional [icon] and/or [text] label arranged horizontally or vertically
/// - Adding a leading space before [text] when displayed inline beside an icon
/// - Delegating tap handling to an async-compatible [onTap] callback
class StyledButton extends StatelessWidget {
  /// Creates a [StyledButton] with optional icon, text, and styling.
  ///
  /// At least one of [icon] or [text] should be provided; supplying neither
  /// will render an empty button.
  ///
  /// Parameters:
  /// - [text]: Label text displayed on the button; omitted from layout if `null`
  /// - [icon]: Icon displayed on the button; omitted from layout if `null`
  /// - [iconSize]: Size of the icon in logical pixels; defaults to `24`
  /// - [textStyle]: Custom [TextStyle] for the label; defaults to 24pt Georama in [contentColor]
  /// - [onTap]: Callback invoked when the button is pressed; supports both sync and async functions;
  ///   pass `null` to render the button as disabled
  /// - [backgroundColor]: Fill color of the button; defaults to the theme's primary color
  /// - [contentColor]: Color applied to both the icon and text label;
  ///   defaults to the theme's onPrimary color
  /// - [vertical]: When `true`, stacks icon above text in a [Column];
  ///   when `false`, places icon left of text in a [Row]; defaults to `false`
  /// - [height]: Fixed height of the button's inner [Container]; defaults to unconstrained
  /// - [width]: Fixed width of the button's inner [Container]; defaults to unconstrained
  /// - [borderRadius]: Corner radius of the button in logical pixels; defaults to `16`;
  ///   pass `null` for the default [ElevatedButton] shape
  const StyledButton(
      {super.key,
        this.text,
        this.icon,
        this.iconSize = 24,
        this.textStyle,
        this.onTap,
        this.backgroundColor,
        this.contentColor,
        this.vertical = false,
        this.height,
        this.width,
        this.borderRadius = 16});

  /// The text label displayed on the button.
  ///
  /// When `null`, no [Text] widget is added to the layout.
  /// When displayed alongside an [icon] in horizontal mode, a leading space is prepended.
  final String? text;

  /// The icon displayed on the button.
  ///
  /// When `null`, no [Icon] widget is added to the layout.
  final IconData? icon;

  /// The size of the [icon] in logical pixels.
  ///
  /// Has no effect when [icon] is `null`. Defaults to `24`.
  final double? iconSize;

  /// Custom [TextStyle] for the [text] label.
  ///
  /// When `null`, defaults to 24pt Georama font in [contentColor] (or the theme's onPrimary color).
  final TextStyle? textStyle;

  /// Callback invoked when the button is pressed.
  ///
  /// Accepts both synchronous (`void`) and asynchronous (`Future<void>`) functions
  /// via [FutureOr]. When `null`, the [ElevatedButton] renders in its disabled state.
  final FutureOr<void> Function()? onTap;

  /// Background fill color of the button.
  ///
  /// When `null`, falls back to the theme's [ColorScheme.primary] color.
  final Color? backgroundColor;

  /// Color applied to both the [icon] and [text] label.
  ///
  /// Also used as the button's overlay (ripple) color.
  /// When `null`, falls back to the theme's [ColorScheme.onPrimary] color.
  final Color? contentColor;

  /// Whether to arrange [icon] and [text] vertically.
  ///
  /// When `true`, [icon] is stacked above [text] in a [Column].
  /// When `false`, [icon] is placed to the left of [text] in a [Row].
  /// Defaults to `false`.
  final bool vertical;

  /// Fixed height of the button's inner [Container].
  ///
  /// When `null`, the container sizes to its content height.
  final double? height;

  /// Fixed width of the button's inner [Container].
  ///
  /// When `null`, the container sizes to its content width.
  final double? width;

  /// Corner radius of the button's [RoundedRectangleBorder] in logical pixels.
  ///
  /// When `null`, no custom shape is applied and the [ElevatedButton] uses its default shape.
  /// Defaults to `16`.
  final double? borderRadius;

  /// Builds a themed [ElevatedButton] with the configured icon, text, and layout.
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Builds the list of content widgets; each is conditionally included based on nullability
    final List<Widget> children = [
      if (icon != null)
        Icon(
          icon,
          size: iconSize,
          color: contentColor ?? colorScheme.onPrimary,
        ),
      if (text != null)
        Text(
          // Prepends two spaces when icon is present in horizontal layout to visually
          // separate icon and text — vertical layout handles spacing via Column naturally
          "${icon != null && !vertical ? '  ' : ''}$text",
          style: textStyle ??
              TextStyle(
                  fontSize: 24,
                  fontFamily: "Georama",
                  color: contentColor ?? colorScheme.onPrimary),
        )
    ];

    return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
            overlayColor: contentColor ?? colorScheme.onPrimary,
            backgroundColor: backgroundColor ?? colorScheme.primary,
            // Only applies a custom shape when borderRadius is non-null
            shape: borderRadius != null
                ? RoundedRectangleBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(borderRadius ?? 16)))
                : null),
        child: Container(
            alignment: Alignment.center,
            height: height,
            width: width,
            // Switches between vertical (Column) and horizontal (Row) content layout
            child: vertical
                ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ).fit()
                : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ).fit()));
  }
}