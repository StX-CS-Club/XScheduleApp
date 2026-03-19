import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An extension on Flutter's [BuildContext] class.
///
/// Responsibilities:
/// - Displaying SnackBar notifications via the ScaffoldMessenger
/// - Pushing swipe-dismissible pages onto the Navigator
/// - Pushing animated overlay popups onto the Navigator
extension BuildContextExtension on BuildContext {
  /// Pushes a [SnackBar] with [message] text to this context's [ScaffoldMessenger].
  ///
  /// Parameters:
  /// - [message]: The text content to display inside the SnackBar
  /// - [isError]: When `true`, styles the SnackBar using the theme's error color scheme;
  ///   defaults to `false`
  /// - [floating]: When `true`, renders the SnackBar floating above the UI;
  ///   defaults to `true`
  void showSnackBar(String message,
      {bool isError = false, bool floating = true}) {
    // Pushes SnackBar to ScaffoldMessenger
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message,
            overflow: TextOverflow.fade,
            style: TextStyle(
              // Uses error foreground color when isError is true, otherwise uses theme default
                color: isError
                    ? Theme.of(this).colorScheme.onError
                    : Theme.of(this).snackBarTheme.actionTextColor)),
        // SnackBarBehavior.floating renders in front of UI elements (e.g. above bottom nav bar)
        behavior: floating ? SnackBarBehavior.floating : null,
        // Uses error background color when isError is true, otherwise uses theme default
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }

  /// Pushes a horizontally swipe-dismissible [page] onto this context's [Navigator].
  ///
  /// Uses a [CupertinoPageRoute] to wrap [page] in a [GestureDetector] that
  /// listens for rightward horizontal swipes to pop the route.
  ///
  /// Parameters:
  /// - [page]: The [Widget] to display as the pushed page
  Future<void> pushSwipePage(Widget page) async {
    // Pushes page with horizontal swipe dismissal to Navigator
    await Navigator.of(this).push(CupertinoPageRoute(builder: (context) {
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          // A positive primaryVelocity indicates a rightward (back) swipe
          if (details.primaryVelocity! > 0) {
            Navigator.pop(context);
          }
        },
        child: page,
      );
    }));
  }

  /// Pushes an animated overlay popup [widget] onto this context's [Navigator].
  ///
  /// This method:
  /// - Renders the route as transparent so the underlying page remains visible
  /// - Slides [widget] onto the screen from the [begin] offset
  /// - Fades a 50% opacity black backdrop behind the popup
  /// - Dismisses the popup on backdrop tap or a drag in the direction of [begin]
  ///
  /// Parameters:
  /// - [widget]: The popup [Widget] to display
  /// - [begin]: The [Offset] from which the popup slides in; defaults to `Offset(-1.0, 0.0)`
  ///   (one full page to the left). Provide a custom offset to animate from other directions,
  ///   e.g. `Offset(0.0, 1.0)` for bottom-up
  Future<void> pushPopup(Widget widget, {Offset? begin}) async {
    // Pushes the popup to the app navigator
    await Navigator.of(this).push(PageRouteBuilder(
      // Transparent route so the page beneath remains visible through the backdrop
      opaque: false,
      // Builds the popup widget in its own BuildContext scope
      pageBuilder: (context, _, __) {
        return widget;
      },
      // Manages the slide-in and fade-in animations for the popup and its backdrop
      transitionsBuilder: (context, a1, a2, child) {
        // Defaults to sliding in from the left if no begin offset is provided
        begin ??= Offset(-1.0, 0.0);
        const Offset end = Offset.zero;
        const Curve curve = Curves.easeInOut;

        // Tween that moves the popup from [begin] to [Offset.zero] along the given curve
        final Animatable<Offset> slideTween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        // Tween that fades the backdrop from fully transparent to fully opaque
        final Tween<double> fadeTween = Tween(begin: 0.0, end: 1.0);

        // Stacks the fading backdrop behind the sliding popup
        return Stack(
          children: [
            // Backdrop: fades in as a 50% opacity black overlay behind the popup
            FadeTransition(
              opacity: a1.drive(fadeTween),
              child: GestureDetector(
                // Tapping the backdrop dismisses the popup
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                // Dismisses on a horizontal drag whose direction matches the begin offset's
                // horizontal component (i.e. dragging back toward where the popup came from)
                onHorizontalDragEnd: (detail) {
                  if (detail.primaryVelocity!.sign == begin!.dx.sign &&
                      Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                // Dismisses on a vertical drag whose direction matches the begin offset's
                // vertical component (i.e. dragging back toward where the popup came from)
                onVerticalDragEnd: (detail) {
                  if (detail.primaryVelocity!.sign == begin!.dy.sign &&
                      Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Popup: slides in from [begin] offset on top of the backdrop
            SlideTransition(
              position: a1.drive(slideTween),
              child: child,
            ),
          ],
        );
      },
    ));
  }
}