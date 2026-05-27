import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xschedule/startup/home_page.dart';
import 'package:xschedule/util/tutorial_system.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/widgets/styled_button.dart';
import 'package:xschedule/ui/schedule/schedule_settings/bell_settings/bell_button.dart';
import 'package:xschedule/ui/schedule/schedule_settings/bell_settings/bell_settings_menu.dart';
import 'package:xschedule/ui/schedule/schedule_settings/schedule_settings_qr.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/schedule/schedule_settings.dart';

/// Full-page settings screen where the user configures the appearance of all bells.
///
/// Responsibilities:
/// - Displays a scrollable list of [BellButton] tiles, one per bell in [ScheduleEntry.sampleBells]
/// - Opens [BellSettingsMenu] when a bell tile is tapped
/// - Provides a QR code manager via [ScheduleSettingsPageQr] in the app bar
/// - Runs a first-use tutorial via [tutorialSystem]
/// - Saves all bell vanity on "Done" and returns to [HomePage]
class ScheduleSettingsPage extends StatefulWidget {
  /// Creates the settings page.
  ///
  /// Parameters:
  /// - [showBackArrow]: If true, the default back arrow appears in the app bar,
  ///   allowing the user to navigate back without saving. If false, no back option is shown.
  const ScheduleSettingsPage({super.key, this.showBackArrow = false});

  /// Whether to show the default back arrow in the app bar.
  /// - true: user can navigate back (e.g. when opened from [PersonalPage])
  /// - false: no back option; user must tap "Done" to proceed (e.g. on first launch)
  final bool showBackArrow;

  /// Tutorial system managing the guided walkthrough of the settings page.
  /// Kept static so tutorial completion persists across page instances.
  static late TutorialSystem tutorialSystem;

  /// Resets [tutorialSystem] so the tutorial will run again on next page load.
  /// Called from [PersonalPage._clearAllData] during a full app reset.
  static void resetTutorials() {
    tutorialSystem.refreshKeys();
  }

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  /// Opens the [BellSettingsMenu] popup for the given [bell].
  ///
  /// Parameters:
  /// - [bell]: The bell identifier to configure.
  void _openBellSettings(String bell) {
    context.pushPopup(BellSettingsMenu(bell: bell, onStateChange: setState));
  }

  /// Builds a [BellButton] for the given [bell].
  /// If [isFirst] is true, wraps the button in a tutorial showcase target.
  ///
  /// Parameters:
  /// - [bell]: The bell identifier to display.
  /// - [isFirst]: Whether this is the first bell in the list (used for tutorial targeting).
  Widget _buildBellButton(BuildContext context, String bell, {required bool isFirst}) {
    final button = BellButton(bell: bell, onTap: () => _openBellSettings(bell));
    if (!isFirst) return button;
    return ScheduleSettingsPage.tutorialSystem.showcase(
      context: context,
      tutorial: 'schedule_settings:button',
      child: button,
    );
  }

  /// Builds the scrollable list of [BellButton] tiles.
  /// Adds 60px of bottom padding so the last tile is not obscured by the "Done" button.
  ///
  /// Parameters:
  /// - [screenWidth]: Used to size the trailing spacer.
  Widget _buildBellList(BuildContext context, double screenWidth) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...List<Widget>.generate(
            ScheduleSettings.sampleBells.length,
                (i) => _buildBellButton(context, ScheduleSettings.sampleBells[i], isFirst: i == 0),
          ),
          // Blank space so the bottom button doesn't overlap the last bell
          SizedBox(height: 60, width: screenWidth),
        ],
      ),
    );
  }

  /// Builds the "Done" button pinned to the bottom of the screen.
  /// On tap, saves all bells and navigates to [HomePage], clearing the navigation stack.
  ///
  /// Parameters:
  /// - [context]: Used for navigation.
  /// - [screenWidth]: Used to horizontally center the button.
  Widget _buildDoneButton(BuildContext context, double screenWidth) {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(vertical: 20, horizontal: screenWidth * .325),
      child: ScheduleSettingsPage.tutorialSystem.showcase(
        context: context,
        tutorial: 'schedule_settings:complete',
        child: StyledButton(
          icon: Icons.check,
          borderRadius: null,
          onTap: () {
            ScheduleSettings.saveBells();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
                  (_) => false,
            );
          },
        ),
      ),
    );
  }

  /// Builds the app bar containing the page title and QR code manager button.
  ///
  /// Parameters:
  /// - [context]: Used to push the QR popup.
  /// - [colorScheme]: Provides surface and icon colors.
  AppBar _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      // null allows Flutter's default back button; Container() hides it entirely
      leading: widget.showBackArrow ? null : Container(),
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ScheduleSettingsPage.tutorialSystem.showcase(
            context: context,
            circular: true,
            tutorial: 'schedule_settings:qr',
            child: IconButton(
              icon: Icon(
                Icons.qr_code_scanner_rounded,
                size: 35,
                color: colorScheme.onSurface,
              ),
              onPressed: () {
                context.pushPopup(ScheduleSettingsQr(onStateChange: setState));
              },
            ),
          ),
        ),
      ],
      title: ScheduleSettingsPage.tutorialSystem.showcase(
        context: context,
        tutorial: 'schedule_settings:schedule_settings',
        child: Text(
          "Customize Bell Appearance",
          style: TextStyle(
            fontFamily: "Georama",
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ).fit(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    ScheduleSettingsPage.tutorialSystem.register();
    // Generate stable GlobalKeys here so Showcase widgets keep their identity
    // across rebuilds and always mount with the correct currentScope.
    ScheduleSettingsPage.tutorialSystem.refreshKeys();
    ScheduleSettingsPage.tutorialSystem.removeFinished();
  }

  @override
  void dispose() {
    ScheduleSettingsPage.tutorialSystem.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    ScheduleSettingsPage.tutorialSystem.schedule(context);

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      appBar: _buildAppBar(context, colorScheme),
      extendBody: true,
      bottomNavigationBar: _buildDoneButton(context, screenWidth),
      body: _buildBellList(context, screenWidth),
    );
  }
}