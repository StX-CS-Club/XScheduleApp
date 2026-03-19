/*
  * schedule_info_display.dart *
  StatelessWidget of a popup which displays the daily information of a given date from the database.
*/
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/backend/rss/rss.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/schedule.dart';
import 'package:xschedule/materials/popup_menu.dart';

/// StatelessWidget which displays the popup containing the dailyInfo of a given date. <p>
/// Displays all values which exist, with the popup divided into general info, lunch, and announcements.
class ScheduleInfoDisplay extends StatelessWidget {
  const ScheduleInfoDisplay({super.key, required this.date});

  // Dynamic interpretation of dressCode String as emoji
  static String dressEmoji(String dressCode) {
    if (dressCode.toLowerCase().contains("formal")) {
      return '👔';
    } else if (dressCode.toLowerCase().contains("spirit")) {
      return '🏱';
    }
    return '👕';
  }

  // The Date of the info popup
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Gets the schedules and dailyInfo based on the given date
    final Schedule schedule = ScheduleDirectory.readSchedule(date);
    final Map<String, dynamic> dailyInfo = schedule.info;

    // Returns dailyInfo popup
    return PopupMenu(
        child: SizedBox(
      width: min(mediaQuery.size.width * .9, 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date Text
                  Text(
                    date.dateText(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface),
                  ),
                  // Day Schedule Name Text fitted to width
                  RichText(
                    // TextSpan serving as Row of Text; single line of text with different styles
                    text: TextSpan(children: [
                      TextSpan(
                          text: "⏰ ",
                          style: TextStyle(
                              fontSize: 20, color: colorScheme.onSurface)),
                      TextSpan(
                          text: schedule.name,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                              // If day has no classes, make text italic
                              fontStyle: schedule.name.contains("No Classes")
                                  ? FontStyle.italic
                                  : FontStyle.normal))
                    ]),
                  ).fit(),
                  // Row of quarter and dress code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // If variable is null, do not display
                      if (dailyInfo['quarter'] != null)
                        // expandedFit Text for quarter
                        Text(
                          '🗓️ Quarter ${dailyInfo['quarter']}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface),
                        ).expandedFit(),
                      // If variable is null, then replace with empty string, and checks if string is empty; detects both null and empty values
                      if ((dailyInfo['dressCode'] ?? '').isNotEmpty)
                        // expandedFit Text for dressCode
                        Text(
                          '${dressEmoji(dailyInfo['dressCode'])} ${dailyInfo['dressCode']}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface),
                        ).expandedFit()
                    ],
                  ),
                  // Checks to display lunch divider and header
                  if ((dailyInfo['lunchPasta'] ?? '').isNotEmpty ||
                      (dailyInfo['lunchBox'] ?? '').isNotEmpty ||
                      (dailyInfo['lunchMain'] ?? '').isNotEmpty)
                    Column(
                      children: [
                        // Divider between lunch info; only displayed if lunch data exists
                        Divider(
                          color: colorScheme.shadow,
                        ),
                        // Lunch Title
                        Text(
                          "Lunch",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface),
                        ),
                        // If lunchMain exists, display
                        if ((dailyInfo['lunchMain'] ?? '').isNotEmpty)
                          // fitted Text for lunchMain
                          Text(
                            '🥘 ${dailyInfo['lunchMain']}',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface),
                          ).fit(),
                        // Row containing lunchPasta and lunchBox Texts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // If lunchPasta value exists, display
                            if ((dailyInfo['lunchPasta'] ?? '').isNotEmpty)
                              // expandedFit Text for lunchPasta
                              Text(
                                '🍝 ${dailyInfo['lunchPasta']}',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface),
                              ).expandedFit(),
                            if ((dailyInfo['lunchBox'] ?? '').isNotEmpty)
                              Text(
                                '🍱 ${dailyInfo['lunchBox']}',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface),
                              ).expandedFit(),
                          ],
                        )
                      ],
                    ),
                  // Checks to display event Text and Divider
                  if ((dailyInfo['event'] ?? '').isNotEmpty)
                    Column(
                      children: [
                        // Divider which only displays if event exists
                        Divider(
                          color: colorScheme.shadow,
                        ),
                        // Event Title
                        Text(
                          '📢 Announcement',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: colorScheme.onSurface),
                        ),
                        // Event Text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            dailyInfo['event'],
                            maxLines: 10,
                            style: TextStyle(
                                fontSize: 15,
                                overflow: TextOverflow.ellipsis,
                                color: colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                ],
              )),
          if (RSS.offline)
            Container(
              width: mediaQuery.size.width * .9,
              height: 50,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                  color: colorScheme.error,
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
                  Text("Failed to connect to server. You are offline!",
                      style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 16,
                          fontFamily: "Exo_2"))
                ],
              ).fit(),
            )
        ],
      ),
    ));
  }
}
