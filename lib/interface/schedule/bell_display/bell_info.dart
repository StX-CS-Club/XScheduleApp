import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/clock.dart';
import 'package:xschedule/schedule/schedule.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/materials/popup_menu.dart';

class BellInfo extends StatelessWidget {
  const BellInfo({super.key, required this.schedule, required this.bell});

  final Schedule schedule;
  final String bell;

  @override
  Widget build(BuildContext context) {

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double width = min(mediaQuery.size.width, 500);

    // Gets vanity data of bell
    Map<String, dynamic> vanity = Schedule.bellVanity[bell] ?? {};

    // Suffix after base bell String
    String suffix = bell.length <= 1 ? ' Bell' : '';

    if (bell.contains("HR")) {
      vanity = Schedule.bellVanity["HR"] ?? {};
    }
    if (bell.contains("FLEX")) {
      vanity = Schedule.bellVanity["FLEX"] ?? {};
    }

    // If schedule fits alternate bell conditions, set vanity map as alternate
    for (String day in vanity['alt_days'] ?? []) {
      if (schedule.name
          .toLowerCase()
          .replaceAll('-', ' ')
          .contains(day.toLowerCase())) {
        vanity = vanity['alt'];
        // Adds alt suffix
        suffix = '$suffix - Alt';
        break;
      }
    }

    // Clock Map of bell ('start' and 'end')
    final Map<String, Clock?> times = schedule.clockMap(bell) ?? {};
    // Aligns on center of screen w/ shadowed background
    return PopupMenu(
        child: SizedBox(
          width: width * 4 / 5,
          height: 160,
          child: Row(
            children: [
              // Left color nib w/ rounded edges
              Container(
                decoration: BoxDecoration(
                  // rounds the left edges to match the Card
                  borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(10)),
                  // Converts hex color string to flutter color object
                  color: ColorExtension.fromHex(vanity['color'] ?? '#999999'),
                ),
                width: 10,
              ),
              Padding(
                  padding: const EdgeInsets.all(10),
                  // Column w/ two rows containing vanity components
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Uppermost row; emoji and title components
                      Row(
                        children: [
                          // Stacks the emoji on top of a shadowed circle
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: colorScheme.surfaceContainer,
                                radius: 45,
                              ),
                              Text(
                                vanity['emoji'] ?? '📚',
                                style: TextStyle(
                                    fontSize: 50, color: colorScheme.onSurface),
                              )
                            ],
                          ),
                          // Information Vanity Container
                          Container(
                            width: width * 4 / 5 - 130,
                            height: 90,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vanity['name'] ?? '$bell$suffix',
                                  style: TextStyle(
                                      height: 0.9,
                                      fontSize: 25,
                                      color: colorScheme.onSurface,
                                      //bold
                                      fontWeight: FontWeight.w600),
                                ).expandedFit(alignment: Alignment.centerLeft),
                                if (vanity['teacher'] != null)
                                  Text(
                                    vanity['teacher'],
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w500),
                                  ).expandedFit(
                                      alignment: Alignment.centerLeft),
                                if (vanity['location'] != null)
                                  Text(
                                    vanity['location'],
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w500),
                                  ).expandedFit(alignment: Alignment.centerLeft)
                              ],
                            ),
                          )
                        ],
                      ),
                      //Bottom 'Row'; Displays bell name and time range
                      Container(
                          height: 40,
                          width: width * 4 / 5 - 40,
                          padding: const EdgeInsets.only(left: 12.5),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$bell$suffix:   ${times['start']?.display()} - ${times['end']?.display()}',
                            style: TextStyle(
                                height: 0.9,
                                fontSize: 25,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500),
                          ).fit())
                    ],
                  )),
            ],
          ),
        ));
  }
}