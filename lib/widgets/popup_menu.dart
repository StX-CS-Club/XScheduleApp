import 'package:flutter/material.dart';

/// A centered [Card]-based popup overlay widget with an optional close button.
///
/// Responsibilities:
/// - Centering its [child] content on screen within a [Card] container
/// - Applying a custom or theme-derived background color to the [Card]
/// - Optionally rendering a close [IconButton] in the top-right corner to pop the route
class PopupMenu extends StatelessWidget {
  /// Creates a [PopupMenu] wrapping [child] in a centered [Card].
  ///
  /// When [popButton] is `true`, a close button is rendered at the top-right
  /// of the card that calls [Navigator.pop] when tapped.
  ///
  /// Parameters:
  /// - [backgroundColor]: Background color of the [Card]; defaults to the theme's surface color if `null`
  /// - [child]: The content widget to display inside the popup; required
  /// - [popButton]: When `true`, overlays a close button at the top-right of the card; defaults to `false`
  const PopupMenu({
    super.key,
    this.backgroundColor,
    required this.child,
    this.popButton = false,
  });

  /// Background color of the [Card].
  ///
  /// When `null`, falls back to the theme's [ColorScheme.surface] color.
  final Color? backgroundColor;

  /// The content widget displayed inside the popup card.
  final Widget child;

  /// Whether to show a close [IconButton] in the top-right corner of the card.
  ///
  /// When `true`, an [Icons.close] button is overlaid via [Positioned] inside a [Stack],
  /// and tapping it calls [Navigator.pop] to dismiss the popup.
  final bool popButton;

  /// Builds a centered [Card] containing [child] and an optional close button.
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        // Falls back to theme surface color if no backgroundColor is provided
        color: backgroundColor ?? colorScheme.surface,
        child: Stack(
          children: [
            child,
            // Conditionally overlays a close button at the top-right of the card
            if (popButton)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  // Pops the current route to dismiss the popup
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}