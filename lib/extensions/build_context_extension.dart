/*
  * build_context_extension.dart *
  Extension to the Flutter BuildContext class featuring navigation methods and more.
 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// BuildContext extension <p>
/// Features methods for managing Navigators and ScaffoldMessengers of a given BuildContext.
extension BuildContextExtension on BuildContext {
  /// BuildContext extension <p>
  /// Pushes a SnackBar of given text to the ScaffoldMessenger of the BuildContext
  void showSnackBar(String message,
      {bool isError = false, bool floating = true}) {
    // Pushes SnackBar to ScaffoldMessenger
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message,
            overflow: TextOverflow.fade,
            style: TextStyle(
              // Changes color based on error
                color: isError
                    ? Theme.of(this).colorScheme.onError
                    : Theme.of(this).snackBarTheme.actionTextColor)),
        // Floating pushes to front of UI
        behavior: floating ? SnackBarBehavior.floating : null,
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }

  /// BuildContext extension <p>
  /// Pushes a gesture-dismissible page to the NavigatorState of the BuildContext
  Future<void> pushSwipePage(Widget page) async {
    // Pushes page w/ horizontal swipe dismissing to Navigator
    await Navigator.of(this).push(CupertinoPageRoute(builder: (context) {
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          // If swipe right, dismiss.
          if (details.primaryVelocity! > 0) {
            Navigator.pop(context);
          }
        },
        child: page,
      );
    }));
  }

  /// BuildContext extension <p>
  /// Pushes an animated popup to the NavigatorState of the BuildContext
  Future<void> pushPopup(Widget widget, {Offset? begin}) async {
    // Pushes the popup to the app navigator
    await Navigator.of(this).push(PageRouteBuilder(
      // See-through 'page'
      opaque: false,
      // Builds the popup; creates separate instance of BuildContext
      pageBuilder: (context, _, __) {
        return widget;
      },
      // Manages animation
      transitionsBuilder: (context, a1, a2, child) {
        // Page begins 1 page to the left of the visible screen; slides onto screen
        begin ??= Offset(-1.0, 0.0);
        const Offset end = Offset.zero;
        const Curve curve = Curves.easeInOut;

        // Animation 'Tween' which manages popup movement
        final Animatable<Offset> slideTween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        // Tween which handles the background fading to 50% opacity black
        final Tween<double> fadeTween = Tween(begin: 0.0, end: 1.0);

        // Stacks the sliding animation on top of the fading animation
        return Stack(
          children: [
            // Container (50% opacity black) follows fade in animation
            FadeTransition(
              opacity: a1.drive(fadeTween),
              child: GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                // Listens for swipe in opposite direction of animation to dismiss popup
                onHorizontalDragEnd: (detail){
                  if(detail.primaryVelocity!.sign == begin!.dx.sign && Navigator.canPop(context)){
                    Navigator.of(context).pop();
                  }
                },
                onVerticalDragEnd: (detail){
                  if(detail.primaryVelocity!.sign == begin!.dy.sign && Navigator.canPop(context)){
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Popup follows sliding animation
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