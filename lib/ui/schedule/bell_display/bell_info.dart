import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/bell_entry.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/widgets/popup_menu.dart';
import 'package:xschedule/schedule/schedule_settings.dart';

/// A popup displaying detailed vanity information for a single [BellEntry].
///
/// Responsibilities:
/// - Resolving the correct vanity map for the bell, including HR/FLEX overrides and alternate days
/// - Displaying the bell's emoji, name, teacher, location, and time range
/// - Rendering a colored left nib matching the bell's vanity color
class BellInfo extends StatelessWidget {
  const BellInfo({super.key, required this.schedule, required this.bell});

  /// The schedule the bell belongs to; used for alternate day condition matching.
  final ScheduleEntry schedule;

  /// The bell whose info this popup displays.
  final BellEntry bell;

  /// Resolves the vanity data map and display suffix for [bell].
  ///
  /// This method:
  /// - Looks up [bell] in [ScheduleSettings.bellVanity] by title string
  /// - Overrides with the `'HR'` or `'FLEX'` vanity entry if the title contains either
  /// - Switches to the alternate vanity map if the schedule name matches any `'alt_days'` entry
  ///
  /// NOTE: [ScheduleSettings.bellVanity] is keyed by [String] — relies on [BellEntry.toString]
  /// returning the correct key for the initial lookup.
  ///
  /// Returns: A record with the resolved [vanity] map and the display [bellSuffix]
  ({Map<String, dynamic> vanity, String bellSuffix}) _resolveVanity() {
    Map<String, dynamic> bellVanity = ScheduleSettings.bellVanity[bell.title] ?? {};

    /// Suffix appended after the bell title in display strings; single-char bells get ' Bell'.
    String bellSuffix = bell.title.length <= 1 ? ' Bell' : '';

    // HR and FLEX bells use their own fixed vanity entries regardless of the full title
    if (bell.title.contains("HR")) {
      bellVanity = ScheduleSettings.bellVanity["HR"] ?? {};
    }
    if (bell.title.contains("FLEX")) {
      bellVanity = ScheduleSettings.bellVanity["FLEX"] ?? {};
    }

    // Switch to the alternate vanity map if the schedule name matches an alt_days entry
    for (String altDay in bellVanity['alt_days'] ?? []) {
      if (schedule.name
          .toLowerCase()
          .replaceAll('-', ' ')
          .contains(altDay.toLowerCase())) {
        bellVanity = bellVanity['alt'];
        bellSuffix = '$bellSuffix - Alt';
        break;
      }
    }

    return (vanity: bellVanity, bellSuffix: bellSuffix);
  }

  /// Builds the left color nib with rounded left corners matching the [PopupMenu] card border.
  ///
  /// Appearance: A 10px-wide vertical strip in the bell's vanity color, rounded on the left.
  ///
  /// Parameters:
  /// - [bellVanity]: Provides the `'color'` hex string; defaults to `'#999999'`
  Widget _buildColorNib(Map<String, dynamic> bellVanity) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
        const BorderRadius.horizontal(left: Radius.circular(10)),
        color: ColorExtension.fromHex(bellVanity['color'] ?? '#999999'),
      ),
      width: 10,
    );
  }

  /// Builds the emoji avatar — a large [CircleAvatar] with the bell emoji centered on it.
  ///
  /// Appearance: A 90px-diameter circle in [ColorScheme.surfaceContainer] with a 50px emoji.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [bellVanity]: Provides the `'emoji'` string; defaults to `'📚'`
  Widget _buildEmojiAvatar(
      BuildContext context, Map<String, dynamic> bellVanity) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.surfaceContainer,
          radius: 45,
        ),
        Text(
          bellVanity['emoji'] ?? '📚',
          style: TextStyle(fontSize: 50, color: colorScheme.onSurface),
        )
      ],
    );
  }

  /// Builds the info column displaying the bell name, teacher, and location.
  ///
  /// Appearance: A left-aligned column of up to three fitted text rows.
  /// Teacher and location rows are omitted when not present in [bellVanity].
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [bellVanity]: Source of `'name'`, `'teacher'`, and `'location'` values
  /// - [bellSuffix]: Appended to the title fallback when no vanity name is set
  /// - [popupWidth]: Used to constrain column width relative to popup size
  Widget _buildInfoColumn(BuildContext context, Map<String, dynamic> bellVanity,
      String bellSuffix, double popupWidth) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: popupWidth * 4 / 5 - 130,
      height: 90,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bell name; falls back to title + suffix when no vanity name is set
          Text(
            bellVanity['name'] ?? '${bell.title}$bellSuffix',
            style: TextStyle(
                height: 0.9,
                fontSize: 25,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600),
          ).expandedFit(alignment: Alignment.centerLeft),
          if (bellVanity['teacher'] != null)
            Text(
              bellVanity['teacher'],
              style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500),
            ).expandedFit(alignment: Alignment.centerLeft),
          if (bellVanity['location'] != null)
            Text(
              bellVanity['location'],
              style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500),
            ).expandedFit(alignment: Alignment.centerLeft),
        ],
      ),
    );
  }

  /// Builds the bottom row displaying the bell title and start–end time range.
  ///
  /// Appearance: A single fitted text line in the format `'{title}{suffix}:   HH:MM - HH:MM'`.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [bellVanity]: Unused directly; passed for consistency with other build methods
  /// - [bellSuffix]: Appended to the bell title display string
  /// - [popupWidth]: Used to constrain row width relative to popup size
  Widget _buildTimeRow(BuildContext context, Map<String, dynamic> bellVanity,
      String bellSuffix, double popupWidth) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      width: popupWidth * 4 / 5 - 40,
      padding: const EdgeInsets.only(left: 12.5),
      alignment: Alignment.centerLeft,
      child: Text(
        '${bell.title}$bellSuffix:   ${bell.startClock?.displayString} - ${bell.endClock?.displayString}',
        style: TextStyle(
            height: 0.9,
            fontSize: 25,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500),
      ).fit(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Cap popup width at 500px on large screens
    final double popupWidth = min(mediaQuery.size.width, 500);
    final resolved = _resolveVanity();

    return PopupMenu(
        child: SizedBox(
          width: popupWidth * 4 / 5,
          height: 160,
          child: Row(
            children: [
              // Left color nib
              _buildColorNib(resolved.vanity),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upper row: emoji avatar alongside name/teacher/location
                    Row(
                      children: [
                        _buildEmojiAvatar(context, resolved.vanity),
                        _buildInfoColumn(context, resolved.vanity,
                            resolved.bellSuffix, popupWidth),
                      ],
                    ),
                    // Bottom row: bell title and time range
                    _buildTimeRow(context, resolved.vanity, resolved.bellSuffix,
                        popupWidth),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}