import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/backend/rss/rss.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/widgets/popup_menu.dart';

/// A popup displaying the daily info for a given [date].
///
/// Responsibilities:
/// - Reading and displaying the [ScheduleEntry] name for [date]
/// - Formatting and displaying the date string in the header
/// - Showing an offline error banner when [RSS.offline] is true
/// - Mapping dress code strings to representative emoji via [_dressCodeEmoji]
class ScheduleInfoDisplay extends StatelessWidget {
  const ScheduleInfoDisplay({super.key, required this.date});

  /// The date whose daily info this popup displays.
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final ScheduleEntry schedule = ScheduleDirectory.readSchedule(date);

    return PopupMenu(
        child: SizedBox(
          // Cap width at 500px on large screens
          width: min(mediaQuery.size.width * .9, 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, schedule),
              // Only shown when the RSS server is unreachable
              if (RSS.offline) _buildOfflineBanner(context),
            ],
          ),
        ));
  }

  /// Builds the header section containing the formatted date and schedule name.
  ///
  /// Appearance: A centered column with the date in bold above the schedule name with
  /// a clock emoji prefix; the name is italicised when the day has no classes.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [schedule]: Provides the [ScheduleEntry.name] to display
  Widget _buildHeader(BuildContext context, ScheduleEntry schedule) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full date string (e.g. "Monday, 3/19")
          Text(
            date.dateText(),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
          ),
          // Schedule name with clock emoji prefix; fitted to available width
          RichText(
            // Single line of mixed-style text via nested TextSpans
            text: TextSpan(children: [
              TextSpan(
                  text: "⏰ ",
                  style:
                  TextStyle(fontSize: 20, color: colorScheme.onSurface)),
              TextSpan(
                  text: schedule.name,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                      // Italicise when day has no classes
                      fontStyle: schedule.containsClasses(includeEvents: false)
                          ? FontStyle.italic
                          : FontStyle.normal))
            ]),
          ).fit(),
        ],
      ),
    );
  }

  /// Builds the offline error banner shown at the bottom of the popup.
  ///
  /// Appearance: A full-width error-colored bar with rounded bottom corners,
  /// containing an info icon and an offline message in a fitted [Row].
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme] and [MediaQueryData]
  Widget _buildOfflineBanner(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return Container(
      width: mediaQuery.size.width * .9,
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
          color: colorScheme.error,
          // Rounds only the bottom corners to align with the popup card shape
          borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(12))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outlined,
            color: colorScheme.onError,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            "Failed to connect to server. You are offline!",
            style: TextStyle(
                color: colorScheme.onError,
                fontSize: 16,
                fontFamily: "Exo_2"),
          )
        ],
      ).fit(),
    );
  }
}