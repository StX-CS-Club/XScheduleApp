import 'package:flutter/material.dart';

/// A static, stateless loading screen displaying the app logo on a branded background.
///
/// Responsibilities:
/// - Rendering a full-screen [Scaffold] with the app's brand background color
/// - Displaying the app logo centered on screen, scaled to 50% of the screen width
class StaticLoad extends StatelessWidget {
  /// Creates a [StaticLoad] splash screen.
  const StaticLoad({super.key});

  /// Builds a centered logo on a branded background color.
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return Scaffold(
      // Brand cream background color (#F4ECDB)
      backgroundColor: const Color(0xfff4ecdb),
      body: Align(
        alignment: Alignment.center,
        child: SizedBox(
          // Constrains the logo to half the screen width
          width: mediaQuery.size.width / 2,
          child: FittedBox(
            // Scales the image to fill the SizedBox width, maintaining aspect ratio
            fit: BoxFit.fitWidth,
            // Transparent-background logo asset to blend with the background color
            child: Image.asset('assets/images/xschedule_transparent.png'),
          ),
        ),
      ),
    );
  }
}