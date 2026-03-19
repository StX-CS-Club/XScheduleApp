/*
  * welcome_page.dart *
  Initial destination page of app for first-time users.
  Displays logo over background of X, with button leading to ScheduleSettings.
*/
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/materials/styled_button.dart';
import 'package:xschedule/interface/schedule/schedule_settings/schedule_settings.dart';

/// First-time-use destination page. <p>
/// Displays the logo over a background of St. X with a welcome Card with a button leading to ScheduleSettings.
class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Returns a Scaffold with an image background with a translucent overlay, card and logo atop
    return Scaffold(
        // All contents displayed in Stack
        body: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Background image set to cover screen
        SizedBox(
          width: mediaQuery.size.width,
          height: mediaQuery.size.height,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.asset("assets/images/x_building.jpg"),
            ),
          ),
        ),
        // Translucent blue overlay
        Container(color: colorScheme.primary.withValues(alpha: 0.7)),
        // Logo aligned towards the center
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: EdgeInsets.only(top: mediaQuery.size.width / 10),
            height: mediaQuery.size.height * 5 / 16,
            child: Image.asset("assets/images/xschedule_transparent.png"),
          ),
        ),
        // Welcome Card; contains progression button
        Card(
          // Displaces card 30px from bottom
          margin: const EdgeInsets.only(bottom: 30),
          color: colorScheme.surface,
          child: SizedBox(
            width: mediaQuery.size.width * 4 / 5,
            child: Column(
              // Minimum height to fit contents
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome text fitted to card
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Welcome to X-Schedule",
                      style: TextStyle(
                          fontFamily: "SansitaSwashed",
                          fontSize: 30,
                          color: colorScheme.onSurface),
                    ).fit()),
                // Button spaced 10px from vertical edges
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: StyledButton(
                    text: "Get Started",
                    width: mediaQuery.size.width * .6,
                    onTap: () {
                      // Pushes ScheduleSettings to Navigator with animation
                      Navigator.push(context,
                          CupertinoPageRoute(builder: (context) {
                        return const ScheduleSettings();
                      }));
                    },
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    ));
  }
}
