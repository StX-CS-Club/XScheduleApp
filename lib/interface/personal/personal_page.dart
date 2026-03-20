/*
  * personal_page.dart *
  Currently a sort of Settings page to provide additional options in the app.
  Simple Scaffold with a title AppBar and body Column of options.
*/
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xschedule/startup/splash_page.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/materials/styled_button.dart';
import 'package:xschedule/main.dart';
import 'package:xschedule/interface/personal/credits.dart';
import 'package:xschedule/interface/schedule/schedule_display.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_settings.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_settings_menu.dart';

import '../schedule/schedule_settings/schedule_settings.dart';

/// Current Settings page of the app. <p>
/// Contains title AppBar and body of Column consisting of various options (ScheduleSettings, Credits, Feedback, etc.)
class Personal extends StatelessWidget {
  const Personal({super.key});

  static const String betaReport =
      "https://forms.office.com/Pages/ResponsePage.aspx?id=udgb07DszU6VE6pe_6S_QEKQcshWKqpCj4E9J0VU-BRUN1o3SlRJMzk1SkZMMklLWFc3UEVFVkIzOC4u";

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Simple Scaffold with title AppBar and Column body
    return Scaffold(
        backgroundColor: colorScheme.secondaryContainer,
        // Custom AppBar; features title
        appBar: PreferredSize(
            // Auto-adapts to fit device safe zone
            preferredSize: Size(mediaQuery.size.width, 55),
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Settings title
                  Text(
                    "Settings",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Georama",
                        color: colorScheme.onSurface),
                  ).fit(),
                  // Shadow divider
                  Container(
                    color: colorScheme.shadow,
                    height: 2.5,
                    width: mediaQuery.size.width - 10,
                    margin: const EdgeInsets.only(top: 5),
                  )
                ],
              ),
            )),
        // Simple Column containing list of options
        body: Column(children: [
          // ScheduleSettings button
          _buildOption(context, Icons.palette_outlined, "Customize Bell Appearances", () {
            context.pushSwipePage(const ScheduleSettings(backArrow: true));
          }),
          // Clear localData button
          if (XScheduleApp.beta)
            _buildOption(context, Icons.playlist_remove_outlined, "Clear Local Storage",
                () => _clearLocalStorageDialog(context))
          else
            _buildOption(context, Icons.refresh_rounded, "Reset Bell Appearances",
                () => _clearBellSettingsDialog(context)),
          // Clear cache button
          _buildOption(context, Icons.folder_delete_outlined, "Clear Schedule Cache",
              () => _clearCacheDialog(context)),
          // Credits popup button
          _buildOption(context, Icons.info_outlined, "Credits and Copyright", () {
            context.pushPopup(Credits(), begin: Offset(1, 0));
          }),
          // Beta Report Google Form button
          if (XScheduleApp.beta)
            _buildOption(context, Icons.feedback_outlined, "Submit Beta Report", () {
              launchUrl(Uri.parse(betaReport));
            }),
        ]));
  }

  // builds the options which appear in the body column
  Widget _buildOption(
      BuildContext context, IconData icon, String text, void Function() action) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // GestureDetector to listen for tap and horizontal swipe
    return GestureDetector(
      // Runs provided action on tap or left swipe
      onTap: action,
      onHorizontalDragEnd: (detail) {
        if (detail.primaryVelocity! < 0) {
          action();
        }
      },
      // Returns Container w/ row consisting of title and icon
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
                  Icon(icon, color: colorScheme.onSurface, size: 32,),
                  const SizedBox(width: 12),
                  // Option title
                  Text(
                    text,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface),
                  ).expandedFit(alignment: Alignment.centerLeft),
                  // Simple arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: colorScheme.onSurface,
                  )
                ],
              ),
            ),
            // Divider to separate from next option
            Divider(color: colorScheme.shadow)
          ],
        ),
      ),
    );
  }

  static Future<void> _clearBellSettingsDialog(BuildContext context) async {
    final bool clear = await _showPermissionDialog(context,
            title: "Clear Bell Settings?",
            description:
                "This will erase everything you have inputted for schedule settings. This action cannot be done.",
            confirmText: "Clear") ??
        false;

    if (clear) {
      _clearBellVanity();
      if (context.mounted) {
        context.pushSwipePage(const ScheduleSettings(backArrow: true));
      }
    }
  }

  static Future<void> _clearCacheDialog(BuildContext context) async {
    final bool clear = await _showPermissionDialog(context,
            title: "Clear Schedule Cache?",
            description:
                "This will remove the schedule data you have cached on your device. Offline functionality will be reset.",
            confirmText: "Clear") ??
        false;

    if (clear) {
      _clearCache();
    }
  }

  static Future<void> _clearLocalStorageDialog(BuildContext context) async {
    final bool clear = await _showPermissionDialog(context,
            title: "Clear Local Storage?",
            description:
                "This will fully reset the app. All progress, inputted settings, cached data, and more will be lost. This action cannot be undone.",
            confirmText: "Clear") ??
        false;

    if (clear && context.mounted) _clearAllData(context);
  }

  static Future<bool?> _showPermissionDialog(BuildContext context,
      {required String title,
      String? description,
      String? cancelText = "Cancel",
      String confirmText = "Got it"}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double buttonWidth = mediaQuery.size.width * .2;

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
                    fontFamily: "Georama"),
              ),
              content: description != null
                  ? Text(description,
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Georama",
                          color: colorScheme.onSurface))
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
                    onTap: () => Navigator.pop(context, true))
              ],
            ));
  }

  static void _clearCache() {
    localStorage.setItem("schedule", "{}");
  }

  static void _clearBellVanity() {
    BellSettings.clearSettings();
    ScheduleEntry.bellVanity.clear();
    localStorage.setItem("bellVanity", "{}");
  }

  // Clears all variables and localStorage
  static void _clearAllData(BuildContext context) {
    // Clears bell vanity settings
    _clearBellVanity();
    // Clears localStorage
    localStorage.clear();
    // Resets storage variables
    ScheduleSettings.resetTutorials();
    BellSettingsMenu.resetTutorials();
    ScheduleDisplay.tutorialSystem.refreshKeys();
    ScheduleDisplay.tutorialDate = null;
    // Forward to SplashPage
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => SplashPage()), (_) => false);
  }
}
