import 'package:flutter/cupertino.dart';

/// A convenience widget that animates changes to its [constraints] and [padding].
///
/// Responsibilities:
/// - Smoothly tweening layout changes (size, margin) via [AnimatedContainer]
/// - Clipping overflow content during contraction via a non-scrollable
///   [SingleChildScrollView], so content collapses cleanly without scrolling
class AnimatedBox extends StatelessWidget {
  /// Creates an [AnimatedBox] that animates to the given [constraints] and [padding].
  ///
  /// [duration] and [curve] control the animation timing; both have sensible defaults.
  const AnimatedBox(
      {super.key,
      this.constraints,
      this.padding,
      required this.child,
      this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 250)});

  /// Duration of the constraint and margin animation.
  ///
  /// Defaults to 250ms.
  final Duration duration;

  /// The animated size constraints applied to the container.
  ///
  /// Set [BoxConstraints.maxHeight] to `0` to collapse the box to nothing;
  /// animate it to a positive value to reveal the content.
  final BoxConstraints? constraints;

  /// Applied as the [AnimatedContainer]'s outer margin, animating spacing changes.
  ///
  /// Note: despite the field name, this maps to [AnimatedContainer.margin] (not
  /// [AnimatedContainer.padding]) so the child's layout origin does not shift.
  final EdgeInsets? padding;

  /// The easing curve applied to the animation.
  ///
  /// Defaults to [Curves.linear].
  final Curve curve;

  /// The widget displayed inside the animated box.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: duration,
        margin: padding,
        constraints: constraints,
        curve: curve,
        // SingleChildScrollView with NeverScrollableScrollPhysics clips overflow
        // content while the container is contracting without allowing any scroll.
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: child,
        ));
  }
}
