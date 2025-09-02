import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/global/static_content/extensions/build_context_extension.dart';
import 'package:xschedule/global/static_content/extensions/widget_extension.dart';

import '../../../global/dynamic_content/backend/schedule_directory.dart';
import '../../../global/dynamic_content/clock.dart';
import '../../../global/static_content/extensions/color_extension.dart';
import '../../schedule.dart';
import '../schedule_display.dart';
import 'bell_info.dart';

class BellTile extends StatelessWidget {
  const BellTile(
      {super.key,
      required this.date,
      required this.bell,
      required this.minuteHeight,
      this.index});

  final DateTime date;
  final String bell;
  final double minuteHeight;
  final int? index;

  // Provides the tutorial ID of a given bell of a given date
  static String _tutorial(final DateTime date, final String bell) {
    // Checks if date matches selected tutorialDate
    if (date == ScheduleDisplay.tutorialDate) {
      // The Schedule of the date
      final Schedule schedule = ScheduleDirectory.readSchedule(date);
      // Checks if bell matches first bell or flex bell
      if (bell == schedule.firstBell) {
        return 'tutorial_schedule_bell';
      }
      if (bell == schedule.firstFlex) {
        return 'tutorial_schedule_flex';
      }
    }
    // ...else return error ID
    return 'no_tutorial';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // The Schedule the bell is in
    final Schedule schedule = ScheduleDirectory.readSchedule(date);

    // Vanity info of bell
    Map<String, dynamic> vanity = Schedule.bellVanity[bell] ?? {};
    String suffix = "";

    if (bell.contains("HR")) {
      vanity = Schedule.bellVanity["HR"] ?? {};
      suffix = "${bell.replaceAll("HR", "")}$suffix";
    }
    if (bell.contains("FLEX")) {
      vanity = Schedule.bellVanity["FLEX"] ?? {};
      suffix = "${bell.replaceAll("FLEX", "")}$suffix";
    }

    // If schedule fits alternate bell conditions, set vanity map as alternate
    for (String day in vanity['alt_days'] ?? []) {
      if (schedule.name.toLowerCase().contains(day.toLowerCase())) {
        vanity = vanity['alt'];
        break;
      }
    }

    final Color color = ColorExtension.fromHex(vanity['color'] ?? '#909090');

    // Clock values of bell ('start' and 'end' primarily)
    final Map<String, Clock?> times = schedule.clockMap(bell) ?? {};

    // Height of bell base don start and end times
    final double height =
        minuteHeight * times['end']!.difference(times['start']!).abs();
    final double radius = min(height * 3 / 7 - 5, mediaQuery.size.width / 6);
    // Margin from top of schedule based on start time
    final double margin =
        times['start']!.difference(Clock(hours: 8)).abs() * minuteHeight;

    // Time range text to be displayed
    final String timeRange =
        '${times['start']!.display()} - ${times['end']!.display()}';

    final bool dense = height <= 50;
    final bool veryDense = height <= 25;

    //Returns Tile w/ margin
    return Container(
        height: height,
        margin: EdgeInsets.only(top: margin),
        // Transparent background matching vanity color
        color:
            (index ?? 1) % 2 == 0 ? color.withAlpha(64) : color.withAlpha(40),
        // Tile contents wrapped in Showcase
        child: InkWell(
          // When Tile is tapped, will display popup with more info
          onTap: () {
            context.pushPopup(BellInfo(schedule: schedule, bell: bell));
          },
          child: ScheduleDisplay.tutorialSystem.showcase(
            context: context,
            tutorial: _tutorial(date, bell),
            uniqueNull: true,
            child: Row(
              children: [
                // Left color nib; if no setting set, displays as grey
                Container(
                  width: 10,
                  color: color,
                ),
                const SizedBox(width: 8),
                // If tile is not too short, displays emoji circle as Stack
                if (!veryDense)
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: .2),
                    radius: radius,
                    child: Text(
                      // If no emoji set in settings, displays default book emoji
                      vanity['emoji'] ?? '📚',
                      style: TextStyle(
                          fontSize: radius + 10, color: colorScheme.onSurface),
                    ).fit(),
                  ),
                // Text (with line skips) wrapped in FittedBox
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: mediaQuery.size.width - 136 - radius * 2,
                  alignment: Alignment.centerLeft,
                  // Column of expanded components (name and time range)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Text Widget fitted to Expanded box
                      Expanded(
                          child: Container(
                        // Forces close to second row
                        alignment:
                            dense ? Alignment.centerLeft : Alignment.bottomLeft,
                        child: Text(
                          // If there won't be room for time range line, include it in this line
                          '${(vanity['name'] ?? bell) ?? ''}$suffix${dense ? ':     $timeRange' : ''}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Inter",
                              color: colorScheme.onSurface),
                        ).fit(),
                      )),
                      // If there is space, display time range as separate line
                      if (!dense)
                        Expanded(
                            child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          // Forces close to top row
                          alignment: Alignment.topLeft,
                          child: Text(
                            timeRange,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: "Inter",
                                color: colorScheme.onSurface),
                          ).fit(),
                        ))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
