import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_settings.dart';

class BellButton extends StatelessWidget {
  const BellButton({super.key, required this.bell, this.icon = Icons.settings, required this.onTap, this.buttonWidth});

  final String bell;
  final IconData icon;
  final FutureOr<void> Function()? onTap;
  final double? buttonWidth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double width = buttonWidth ?? mediaQuery.size.width * .95;

    // Ensures no null values
    BellSettings.defineBell(bell);

    // Vanity map of provided bell
    final Map<String, dynamic> vanity = ScheduleEntry.bellVanity[bell] ?? {};

    // Returns "Settings Tile", which displays current bell info and ability to edit bell
    return Container(
      margin: const EdgeInsets.all(8),
      width: width,
      height: 100,
      // Tap-able card leading to bell config menu
      child: Card(
        color: colorScheme.surface,
        child: InkWell(
          highlightColor: colorScheme.onPrimary,
          onTap: onTap,
          child: Row(
            children: [
              // Left color nib w/ rounded edges; selected color of bell
              Container(
                decoration: BoxDecoration(
                  // Rounds the left edges to match the Card
                  borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(10)),
                  color: ColorExtension.fromHex(vanity['color']!),
                ),
                width: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                // Column w/ two rows
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Stacks the emoji on top of a shadowed circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainer,
                          radius: 35,
                        ),
                        Text(
                          vanity['emoji'],
                          style: TextStyle(
                              fontSize: 40, color: colorScheme.onSurface),
                        )
                      ],
                    ),
                    // Container including all text widgets
                    const SizedBox(width: 4),
                    Container(
                      width: width - 184,
                      height: 70,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 5),
                      // Column of Text Widgets w/ height divided equally among them, and wrapped in individual FittedBoxes to prevent overflow.
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text set to fit Expanded container
                          if (vanity['name'].isNotEmpty)
                            Text(
                              vanity['name'],
                              style: TextStyle(
                                  height: 1,
                                  fontSize: 25,
                                  overflow: TextOverflow.ellipsis,
                                  //bold
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface),
                            ).expandedFit(alignment: Alignment.centerLeft),
                          if (vanity['teacher'].isNotEmpty)
                            Text(
                              vanity['teacher'],
                              style: TextStyle(
                                  fontSize: 18,
                                  height: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface),
                            ).expandedFit(alignment: Alignment.centerLeft),
                          if (vanity['location'].isNotEmpty)
                            Text(
                              vanity['location'],
                              style: TextStyle(
                                  fontSize: 18,
                                  height: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface),
                            ).expandedFit(alignment: Alignment.centerLeft)
                        ],
                      ),
                    ),
                    // Settings icon to indicate the ability to configure by tapping tile
                    Container(
                      alignment: Alignment.center,
                      width: 70,
                      child: Icon(icon, size: 45, color: colorScheme.onSurface),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}