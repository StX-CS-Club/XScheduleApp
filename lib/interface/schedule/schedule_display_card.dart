import 'package:flutter/material.dart';
import 'package:xschedule/extensions/int_extension.dart';
import 'package:xschedule/materials/refresh_widget.dart';
import 'package:xschedule/interface/schedule/schedule_display.dart';
import 'package:xschedule/schedule/bell_entry.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/interface/schedule/bell_display/bell_tile.dart';

/// Displays the schedule card for a single calendar day.
///
/// Responsibilities:
/// - Reading and rendering the [ScheduleEntry] for [date]
/// - Displaying a "No Classes" placeholder when no schedule exists
/// - Laying out an hour timeline alongside a stack of [BellTile]s
/// - Overlaying a current-time indicator refreshed every minute
class ScheduleDisplayCard extends StatelessWidget {
  const ScheduleDisplayCard({super.key, required this.date});

  /// The calendar date this card represents.
  final DateTime date;

  /// Total minutes in the schedule window displayed on screen (8:00AM–3:10PM).
  static const int scheduleMinutes = 430;

  /// Minutes from midnight to the start of the schedule window (8:00AM = 60 × 8).
  static const int scheduleStartMinutes = 480;

  /// Upper bound in minutes past [scheduleStartMinutes] at which the time indicator is shown.
  static const int timeIndicatorMaxMinutes = 425;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Available vertical space for the card after subtracting fixed chrome and safe areas
    final double cardHeight = mediaQuery.size.height -
        200 -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    // Read schedule once and reuse — avoids redundant map lookups below
    final ScheduleEntry schedule = ScheduleDirectory.readSchedule(date);

    if (!schedule.containsClasses()) {
      return _buildEmpty(context, cardHeight);
    }

    final List<BellEntry> bells = schedule.bells;

    /// Pixels per minute, scaled to the device's available card height.
    final double minuteHeight = cardHeight / scheduleMinutes;

    // Wrap in Showcase so the tutorial can highlight this card on the tutorial date
    return ScheduleDisplay.tutorialSystem.showcase(
        context: context,
        uniqueNull: true,
        tutorial: date == ScheduleDisplay.tutorialDate
            ? 'tutorial_schedule'
            : 'no_tutorial',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          // Stack overlays the time indicator on top of the schedule layout
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 5, right: 15),
                height: cardHeight,
                child: Row(
                  children: [
                    // Hour labels along the left edge
                    _buildTimeline(context, minuteHeight),
                    // Bell tiles fill the remaining width
                    Expanded(
                        child: Container(
                          // 6.5px top padding aligns bell tops with their timeline hour labels
                          padding: const EdgeInsets.only(top: 6.5),
                          height: cardHeight,
                          child: _buildBellStack(bells, minuteHeight, cardHeight),
                        )),
                  ],
                ),
              ),
              // Time indicator floats above the schedule, refreshed every minute
              _buildTimeIndicator(context, cardHeight),
            ],
          ),
        ));
  }

  /// Builds the hour label timeline displayed on the left side of the schedule.
  ///
  /// Appearance: A [Stack] of 8 hour labels (8AM–3PM), each offset downward by one hour's
  /// worth of pixels relative to [minuteHeight].
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [minuteHeight]: Pixels per minute, used to compute vertical offsets
  Widget _buildTimeline(BuildContext context, double minuteHeight) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: List<Widget>.generate(8, (hourIndex) {
        // Convert 0-based index to a 12-hour label starting at 8AM
        int hourLabel = (hourIndex + 8) % 12;
        if (hourLabel == 0) hourLabel = 12;

        // Offset each label by one hour's worth of pixels per index step
        return Padding(
          padding: EdgeInsets.only(top: minuteHeight * hourIndex * 60),
          child: Text(
            '${hourLabel.multiDecimal()} - ',
            style: TextStyle(
                fontSize: 15,
                height: 0.9,
                color: colorScheme.onSurface), // Text px height = 18
          ),
        );
      }),
    );
  }

  /// Builds a [Stack] of [BellTile]s positioned at their correct times within the card.
  ///
  /// Parameters:
  /// - [bells]: The ordered list of [BellEntry]s to render
  /// - [minuteHeight]: Pixels per minute, passed through to each [BellTile]
  /// - [cardHeight]: Total card height, passed through to each [BellTile]
  Widget _buildBellStack(
      List<BellEntry> bells, double minuteHeight, double cardHeight) {
    return Stack(
      alignment: Alignment.topCenter,
      children: List<Widget>.generate(bells.length, (bellIndex) {
        final BellEntry bell = bells[bellIndex];
        return BellTile(
            date: date,
            bell: bell,
            minuteHeight: minuteHeight,
            index: bellIndex);
      }),
    );
  }

  /// Builds the current time indicator overlay, refreshed every minute via [RefreshWidget].
  ///
  /// Appearance: A translucent horizontal line with a back-arrow icon on the right,
  /// colored in [ColorScheme.secondary], positioned at the pixel height corresponding to now.
  /// Hidden entirely when outside the schedule window or when [date] is not today.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme] and [MediaQueryData]
  /// - [cardHeight]: Used to scale the time offset to pixel position
  Widget _buildTimeIndicator(BuildContext context, double cardHeight) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return RefreshWidget(
        refreshDuration: const Duration(minutes: 1),
        builder: (context) {
          final DateTime now = DateTime.now();

          // Minutes elapsed since schedule start (8:00AM)
          final double timeOffsetMinutes =
              now.hour * 60.0 + now.minute - scheduleStartMinutes;

          // Only render the indicator when within the visible window and viewing today
          if (timeOffsetMinutes < 0 ||
              timeOffsetMinutes > timeIndicatorMaxMinutes ||
              date != ScheduleDisplay.initialDate) {
            return Container();
          }

          return Opacity(
            opacity: 0.6,
            child: Padding(
              // 25px left padding clears the timeline hour labels
              padding: EdgeInsets.only(
                  left: 25,
                  top: timeOffsetMinutes * cardHeight / timeIndicatorMaxMinutes),
              child: Row(
                children: [
                  // Horizontal line spanning available width (83px accounts for nib + padding)
                  Container(
                    height: 1.5,
                    width: mediaQuery.size.width - 83,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_back_ios,
                    size: 10,
                    color: colorScheme.secondary,
                  )
                ],
              ),
            ),
          );
        });
  }

  /// Builds the placeholder shown when no schedule exists for [date].
  ///
  /// Appearance: Centered "No Classes" text in the full card height.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [cardHeight]: Sets the container height so the text is vertically centered
  Widget _buildEmpty(BuildContext context, double cardHeight) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: cardHeight,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 5, right: 10, top: 10, bottom: 10),
      child: Text(
        'No Classes',
        style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface),
      ),
    );
  }
}