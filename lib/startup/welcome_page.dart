import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/widgets/styled_button.dart';
import 'package:xschedule/ui/schedule/schedule_settings/schedule_settings_page.dart';

/// First-time-use destination page shown to users who have not yet set up their schedule.
///
/// Responsibilities:
/// - Displays the X building photo as a full-screen background
/// - Overlays a translucent blue tint and the X-Schedule logo
/// - Presents a welcome card with a "Get Started" button that leads to [ScheduleSettingsPage]
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _buildBackground(screenSize),
          // Translucent blue overlay on top of the background image
          Container(color: colorScheme.primary.withValues(alpha: 0.7)),
          _buildLogo(screenSize),
          _buildWelcomeCard(context, colorScheme, screenSize),
        ],
      ),
    );
  }

  /// Builds the full-screen background image of the X building.
  /// Uses [FittedBox] with [BoxFit.cover] to fill the screen at any aspect ratio.
  ///
  /// Parameters:
  /// - [screenSize]: The device screen dimensions used to size the container.
  Widget _buildBackground(Size screenSize) {
    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: Image.asset("assets/images/x_building.jpg"),
        ),
      ),
    );
  }

  /// Builds the centered X-Schedule logo displayed above the welcome card.
  ///
  /// Parameters:
  /// - [screenSize]: Used to compute the logo height and top margin.
  Widget _buildLogo(Size screenSize) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.only(top: screenSize.width / 10),
        height: screenSize.height * 5 / 16,
        child: Image.asset("assets/images/xschedule_transparent.png"),
      ),
    );
  }

  /// Builds the welcome card anchored 30px above the bottom of the screen.
  /// Contains a welcome title and a "Get Started" button leading to [ScheduleSettingsPage].
  ///
  /// Parameters:
  /// - [context]: Used for navigation.
  /// - [colorScheme]: Provides surface and text colors.
  /// - [screenSize]: Used to size the card and button widths.
  Widget _buildWelcomeCard(BuildContext context, ColorScheme colorScheme, Size screenSize) {
    return Card(
      // Displaces card 30px from bottom
      margin: const EdgeInsets.only(bottom: 30),
      color: colorScheme.surface,
      child: SizedBox(
        width: screenSize.width * 4 / 5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "Welcome to X-Schedule",
                style: TextStyle(
                  fontFamily: "SansitaSwashed",
                  fontSize: 30,
                  color: colorScheme.onSurface,
                ),
              ).fit(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: StyledButton(
                text: "Get Started",
                width: screenSize.width * .6,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const ScheduleSettingsPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}