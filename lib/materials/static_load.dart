/*
  * static_load.dart *
  Simple class of a Stateless, Static loading screen
 */
import 'package:flutter/material.dart';

/// Simple class of a Stateless, Static loading screen. <p>
/// Currently the widget used in the SplashPage.
class StaticLoad extends StatelessWidget {
  const StaticLoad({super.key});

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Returns simple Scaffold w/ logo on colored backgriund
    return Scaffold(
      // Background color of logo
      backgroundColor: const Color(0xfff4ecdb),
      body: Align(
        alignment: Alignment.center,
        // Image sized up to fit 50% of width
        child: SizedBox(
          width: mediaQuery.size.width/2,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            // Logo w/ transparent background
            child: Image.asset('assets/images/xschedule_transparent.png'),
          ),
        ),
      )
    );
  }
}