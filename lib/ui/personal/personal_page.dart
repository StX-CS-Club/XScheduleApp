import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xschedule/april_fools/2026_battle_pass/battle_pass.dart';
import 'package:xschedule/startup/splash_page.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/widgets/styled_button.dart';
import 'package:xschedule/main.dart';
import 'package:xschedule/ui/personal/credits.dart';
import 'package:xschedule/ui/schedule/schedule_display.dart';
import 'package:xschedule/schedule/schedule_settings.dart';
import 'package:xschedule/ui/schedule/schedule_settings/bell_settings/bell_settings_menu.dart';

import '../schedule/schedule_settings/schedule_settings_page.dart';

/// The main settings page of the app.
///
/// Responsibilities:
/// - Presents a scrollable column of settings options as tappable tiles
/// - Provides access to bell customization, schedule cache clearing, credits, and beta tools
/// - Handles confirmation dialogs before performing destructive operations
/// - Conditionally shows beta-only options based on [XScheduleApp.beta]
class PersonalPage extends StatelessWidget {
  const PersonalPage({super.key});

  /// Google Form URL for submitting beta feedback reports.
  static const String _betaReportUrl =
      "https://forms.office.com/Pages/ResponsePage.aspx?id=udgb07DszU6VE6pe_6S_QEKQcshWKqpCj4E9J0VU-BRUN1o3SlRJMzk1SkZMMklLWFc3UEVFVkIzOC4u";

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorScheme.secondaryContainer,
      appBar: _buildAppBar(colorScheme, screenWidth),
      body: Column(
        children: [
          _buildOptionTile(context, Icons.palette_outlined, "Customize Bell Appearances", () {
            context.pushSwipePage(const ScheduleSettingsPage(showBackArrow: true));
          }),
          if (XScheduleApp.beta)
            _buildOptionTile(context, Icons.playlist_remove_outlined, "Clear Local Storage",
                    () => _clearLocalStorageDialog(context))
          else
            _buildOptionTile(context, Icons.refresh_rounded, "Reset Bell Appearances",
                    () => _clearBellSettingsDialog(context)),
          _buildOptionTile(context, Icons.folder_delete_outlined, "Clear Schedule Cache",
                  () => _clearCacheDialog(context)),
          _buildOptionTile(context, Icons.info_outlined, "Credits and Copyright", () {
            context.pushPopup(Credits(), begin: const Offset(1, 0));
          }),
          if (XScheduleApp.beta)
            _buildOptionTile(context, Icons.feedback_outlined, "Submit Beta Report", () {
              launchUrl(Uri.parse(_betaReportUrl));
            }),
        ],
      ),
    );
  }

  /// Builds a custom AppBar with a centered title and a shadow divider at the bottom.
  ///
  /// Parameters:
  /// - [colorScheme]: Provides text and shadow colors.
  /// - [screenWidth]: Used to size the divider.
  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme, double screenWidth) {
    return PreferredSize(
      preferredSize: Size(screenWidth, 55),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Settings",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                fontFamily: "Georama",
                color: colorScheme.onSurface,
              ),
            ).fit(),
            Container(
              color: colorScheme.shadow,
              height: 2.5,
              width: screenWidth - 10,
              margin: const EdgeInsets.only(top: 5),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single settings option tile.
  /// Displays an icon, label text, and a right-pointing arrow.
  /// Responds to both tap and left horizontal swipe gestures.
  ///
  /// Parameters:
  /// - [context]: Used to read the color scheme.
  /// - [icon]: Leading icon displayed on the left.
  /// - [text]: Label describing the option.
  /// - [action]: Callback invoked on tap or left swipe.
  Widget _buildOptionTile(
      BuildContext context, IconData icon, String text, void Function() action) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: action,
      // Left swipe triggers the same action as tapping
      onHorizontalDragEnd: (detail) {
        if (detail.primaryVelocity! < 0) action();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: colorScheme.secondaryContainer,
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: colorScheme.onSurface, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ).expandedFit(alignment: Alignment.centerLeft),
                  Icon(Icons.arrow_forward_ios, size: 20, color: colorScheme.onSurface),
                ],
              ),
            ),
            Divider(color: colorScheme.shadow),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before clearing all bell vanity settings.
  /// On confirmation, clears bell data and navigates to [ScheduleSettingsPage].
  ///
  /// Parameters:
  /// - [context]: Used to show the dialog and navigate.
  static Future<void> _clearBellSettingsDialog(BuildContext context) async {
    final bool clear = await _showPermissionDialog(
      context,
      title: "Clear Bell Settings?",
      description:
      "This will erase everything you have inputted for schedule settings. This action cannot be undone.",
      confirmText: "Clear",
    ) ??
        false;

    if (clear) {
      _clearBellVanity();
      if (context.mounted) {
        context.pushSwipePage(const ScheduleSettingsPage(showBackArrow: true));
      }
    }
  }

  /// Shows a confirmation dialog before clearing the cached schedule data.
  /// On confirmation, resets the schedule cache in local storage.
  ///
  /// Parameters:
  /// - [context]: Used to show the dialog.
  static Future<void> _clearCacheDialog(BuildContext context) async {
    final bool clear = await _showPermissionDialog(
      context,
      title: "Clear Schedule Cache?",
      description:
      "This will remove the schedule data you have cached on your device. Offline functionality will be reset.",
      confirmText: "Clear",
    ) ??
        false;

    if (clear) _clearCache();
  }

  /// Shows a confirmation dialog before performing a full app reset (beta only).
  /// On confirmation, clears all data and navigates to [SplashPage].
  ///
  /// Parameters:
  /// - [context]: Used to show the dialog and navigate.
  static Future<void> _clearLocalStorageDialog(BuildContext context) async {
    final bool clear = await _showPermissionDialog(
      context,
      title: "Clear Local Storage?",
      description:
      "This will fully reset the app. All progress, inputted settings, cached data, and more will be lost. This action cannot be undone.",
      confirmText: "Clear",
    ) ??
        false;

    if (clear && context.mounted) _clearAllData(context);
  }

  /// Displays a styled confirmation [AlertDialog] and returns the user's choice.
  ///
  /// Parameters:
  /// - [context]: Used to show the dialog.
  /// - [title]: Bold heading text of the dialog.
  /// - [description]: Optional body text providing additional context.
  /// - [cancelText]: Label for the cancel button. Pass null to hide the cancel button entirely.
  /// - [confirmText]: Label for the confirm button.
  ///
  /// Returns:
  /// - true if the user confirmed, false if cancelled, null if dismissed.
  static Future<bool?> _showPermissionDialog(
      BuildContext context, {
        required String title,
        String? description,
        String? cancelText = "Cancel",
        String confirmText = "Got it",
      }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double buttonWidth = MediaQuery.of(context).size.width * .2;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            fontFamily: "Georama",
          ),
        ),
        content: description != null
            ? Text(
          description,
          style: TextStyle(fontSize: 16, fontFamily: "Georama", color: colorScheme.onSurface),
        )
            : null,
        actions: [
          if (cancelText != null)
            StyledButton(
              text: cancelText,
              backgroundColor: colorScheme.secondary,
              contentColor: colorScheme.onSecondary,
              width: buttonWidth,
              onTap: () => Navigator.pop(context, false),
            ),
          StyledButton(
            text: confirmText,
            width: buttonWidth,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  /// Resets the cached schedule to an empty object in local storage.
  static void _clearCache() {
    localStorage.setItem("schedule:dailyOrder", "{}");
  }

  /// Clears all in-memory bell vanity maps and resets the bellVanity entry in local storage.
  /// Note: when called from [_clearAllData], the subsequent localStorage.clear() makes
  /// the setItem here redundant for storage, but the in-memory clearing is still required.
  static void _clearBellVanity() {
    ScheduleSettings.clearSettings();
    ScheduleSettings.bellVanity.clear();
    localStorage.setItem("vanity:bellVanity", "{}");
  }

  /// Performs a full app reset: clears all in-memory state, wipes local storage,
  /// resets all tutorial systems, and navigates to [SplashPage].
  ///
  /// Parameters:
  /// - [context]: Used for navigation.
  static void _clearAllData(BuildContext context) {
    _clearBellVanity();
    localStorage.clear();
    ScheduleSettingsPage.resetTutorials();
    BellSettingsMenu.resetTutorials();
    ScheduleDisplay.tutorialSystem.refreshKeys();
    ScheduleDisplay.tutorialDate = null;
    BattlePass.reset();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SplashPage()),
          (_) => false,
    );
  }
}