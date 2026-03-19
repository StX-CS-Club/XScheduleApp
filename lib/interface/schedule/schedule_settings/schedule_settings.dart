/*
  * schedule_settings.dart *
  Settings page which allows the user to configure their bell vanity.
  Contains maps for temporary settings values
*/

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xschedule/startup/home_page.dart';
import 'package:xschedule/util/tutorial_system.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/materials/styled_button.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_button.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_settings_menu.dart';
import 'package:xschedule/interface/schedule/schedule_settings/schedule_settings_qr.dart';

import '../../../schedule/schedule.dart';
import 'bell_settings/bell_settings.dart';

/// Settings page which allows the user to configure bell vanity. <p>
/// Contains Appbar with title and AI option, ScrollView of bell tiles, and submission button. <p>
/// [bool backArrow]: Boolean for whether or not the option to leave the menu should appear in the top left.
class ScheduleSettings extends StatefulWidget {
  const ScheduleSettings({super.key, this.backArrow = false});

  // Parameter which specifies if an arrow should appear to back out of the page
  final bool backArrow;

  // Tutorial systems used on ScheduleSettings page
  static final TutorialSystem tutorialSystem = TutorialSystem({
    'tutorial_settings':
        "In this menu, you'll be able to customize your schedule to match the classes you have.",
    'tutorial_settings_button':
        "Click on any individual bell to change its name, information, and appearance.",
    'tutorial_settings_qr':
        "... or try sharing your schedules through QR codes!",
    'tutorial_settings_complete':
        "Once you're satisfied with your schedule, tap the button down here to move on."
  });

  /// Refreshes the keys and tutorial text of Setting's tutorial systems.
  static void resetTutorials() {
    tutorialSystem.refreshKeys();
  }

  @override
  State<ScheduleSettings> createState() => _ScheduleSettingsState();
}

class _ScheduleSettingsState extends State<ScheduleSettings> {
  // Default color of color wheels.
  final Color pickerColor = Colors.blue;

  void _onBellTap(String bell) {
    // Pushes the bell configuration popup
    context.pushPopup(BellSettingsMenu(bell: bell, setState: setState));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Refreshes the global keys of each tutorial element
    ScheduleSettings.tutorialSystem.refreshKeys();
    ScheduleSettings.tutorialSystem.removeFinished();

    // Showcase View which returns page Scaffold
    return ShowCaseWidget(builder: (context) {
      // Schedules tutorial start after widget has been built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Wait .25 seconds for page animation
        await Future.delayed(const Duration(milliseconds: 250));
        // If tutorial has not been run, run tutorial system
        if (!ScheduleSettings.tutorialSystem.finished && context.mounted) {
          ScheduleSettings.tutorialSystem.showTutorials(context);
          ScheduleSettings.tutorialSystem.finish();
        }
      });

      // Returns page scaffold with top bar and body containing scroll view of bells
      return Scaffold(
          backgroundColor: colorScheme.primaryContainer,
          appBar: AppBar(
            // If back arrow is selected to be displayed, return null (allows default button to be displayed)
            leading: widget.backArrow ? null : Container(),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            // List of Widgets to be displayed in top right
            actions: [
              // IconButton leading to OpenAI popup padded 10px from right
              Padding(
                padding: const EdgeInsets.only(right: 10),
                // Showcase target for OpenAI button
                child: ScheduleSettings.tutorialSystem.showcase(
                    context: context,
                    circular: true,
                    tutorial: 'tutorial_settings_qr',
                    // OpenAI button
                    child: IconButton(
                      icon: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 35,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () {
                        // Pushes the OpenAI popup to the Navigator
                        context.pushPopup(ScheduleSettingsQr(setSourceState: setState));
                      },
                    )),
              )
            ],
            // Showcase target for title
            title: ScheduleSettings.tutorialSystem.showcase(
              context: context,
              tutorial: 'tutorial_settings',
              // Title fitted to width
              child: Text(
                "Customize Bell Appearance",
                style: TextStyle(
                    //Custom font Goerama
                    fontFamily: "Georama",
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
              ).fit(),
            ),
          ),
          // Extends the body behind the bottom bar
          extendBody: true,
          // "Done" button on the bottom of the page
          bottomNavigationBar: Container(
            height: 40,
            // Offset from bottom corresponding to device "safety zone"
            margin: EdgeInsets.symmetric(
                vertical: 20, horizontal: mediaQuery.size.width * .325),
            // Showcase target for "Done" button
            child: ScheduleSettings.tutorialSystem.showcase(
                context: context,
                tutorial: 'tutorial_settings_complete',
                // "Done" button
                child: StyledButton(
                  icon: Icons.check,
                  borderRadius: null,
                  onTap: () {
                    BellSettings.saveBells();
                    // Returns to HomePage
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => HomePage()),
                        (_) => false);
                  },
                )),
          ),
          // ScrollView of individual bell tiles
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...List<Widget>.generate(Schedule.sampleBells.length, (i) {
                  String bell = Schedule.sampleBells[i];
                  if (i == 0) {
                    return ScheduleSettings.tutorialSystem.showcase(
                        context: context,
                        tutorial: 'tutorial_settings_button',
                        child: BellButton(
                            bell: bell, onTap: () => _onBellTap(bell)));
                  }
                  return BellButton(bell: bell, onTap: () => _onBellTap(bell));
                }),
                // Bottom padding og 60px to add blank space for button to rest
                SizedBox(height: 60, width: mediaQuery.size.width)
              ],
            ),
          ));
    });
  }
}