import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import "package:xschedule/schedule/bell_entry.dart";
import 'package:xschedule/schedule/clock.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/schedule/schedule_settings.dart';
import 'package:xschedule/ui/schedule/bell_display/bell_info.dart';
import 'package:xschedule/ui/schedule/schedule_display.dart';

typedef _BellData = ({Map<String, dynamic> vanity, String bellSuffix});

/// A single bell tile rendered within the schedule card's bell stack.
///
/// Responsibilities:
/// - Positioning itself at the correct vertical offset based on [bell] start time
/// - Sizing itself to span the bell's duration via [minuteHeight]
/// - Resolving and applying the bell's vanity color, emoji, name, and suffix
/// - Switching to compact or tiny layout when the tile is too short for full display
/// - Opening a [BellInfo] popup on tap
class BellTile extends StatelessWidget {
  const BellTile(
      {super.key,
        required this.scContext,
      required this.date,
      required this.bell,
      required this.minuteHeight,
      this.index});

  /// The calendar date this tile belongs to; used for tutorial ID resolution and popup context.
  final DateTime date;

  final BuildContext scContext;

  /// The bell entry this tile represents.
  final BellEntry bell;

  /// Pixels per minute, derived from the card height and total schedule minutes.
  final double minuteHeight;

  /// The zero-based position of this tile in the bell list; used for alternating background opacity.
  final int? index;

  /// Height in pixels below which the time range is merged into the name line.
  static const double _compactThreshold = 50;

  /// Height in pixels below which the emoji avatar is hidden entirely.
  static const double _tinyThreshold = 25;

  /// Returns the tutorial showcase ID for a bell on a given date.
  ///
  /// NOTE: Compares [bellTitle] to [ScheduleEntry.firstBell] and [ScheduleEntry.firstFlex]
  /// via string conversion — relies on [BellEntry.toString] returning the bell title.
  ///
  /// Parameters:
  /// - [date]: The date to check against [ScheduleDisplay.tutorialDate]
  /// - [bellTitle]: The title of the bell being checked
  ///
  /// Returns: A tutorial ID string, or `'no_tutorial'` if no match
  static String _tutorialId(final DateTime date, final String bellTitle) {
    if (date == ScheduleDisplay.tutorialDate) {
      final ScheduleEntry schedule = ScheduleDirectory.readSchedule(date);
      if (bellTitle == schedule.firstBell?.title) {
        return 'schedule:bell';
      }
      if (bellTitle == schedule.firstFlex?.title) {
        return 'schedule:flex';
      }
    }
    return 'no_tutorial';
  }

  /// Resolves the vanity data map and display suffix for [bell] within [schedule].
  ///
  /// This method:
  /// - Looks up [bell.title] in [ScheduleSettings.bellVanity]
  /// - Overrides with the `'HR'` or `'FLEX'` entry and strips the keyword from the suffix
  /// - Switches to the alternate vanity map if the schedule name matches an `'alt_days'` entry
  ///
  /// NOTE: Duplicated from [BellInfo._resolveVanity] — consider consolidating into
  /// a method on [BellEntry] (e.g. `bell.resolveVanity(schedule)`)
  ///
  /// Parameters:
  /// - [schedule]: The [ScheduleEntry] used for alternate day condition matching
  ///
  /// Returns: A record with the resolved [vanity] map and the display [bellSuffix]
  _BellData _resolveVanity(ScheduleEntry schedule) {
    Map<String, dynamic> bellVanity =
        ScheduleSettings.bellVanity[bell.title] ?? {};
    String bellSuffix = "";

    // HR and FLEX bells use their own fixed vanity entries; keyword is stripped into the suffix
    if (bell.title.contains("HR")) {
      bellVanity = ScheduleSettings.bellVanity["HR"] ?? {};
      bellSuffix = "${bell.title.replaceAll("HR", "")}$bellSuffix";
    }
    if (bell.title.contains("FLEX")) {
      bellVanity = ScheduleSettings.bellVanity["FLEX"] ?? {};
      bellSuffix = "${bell.title.replaceAll("FLEX", "")}$bellSuffix";
    }

    // Switch to alternate vanity map if the schedule name matches an alt_days entry
    for (String altDay in bellVanity['alt_days'] ?? []) {
      if (schedule.name.toLowerCase().contains(altDay.toLowerCase())) {
        bellVanity = bellVanity['alt'];
        break;
      }
    }

    return (vanity: bellVanity, bellSuffix: bellSuffix);
  }

  /// Builds the left color nib strip for the tile.
  ///
  /// Appearance: A 10px-wide vertical bar in [bellColor].
  ///
  /// Parameters:
  /// - [bellColor]: The resolved vanity color for this bell
  Widget _buildColorNib(Color bellColor) {
    return Container(
      width: 10,
      color: bellColor,
    );
  }

  /// Builds the emoji avatar circle shown in the tile.
  ///
  /// Appearance: A [CircleAvatar] of radius [emojiRadius] with a semi-transparent dark
  /// background and the bell's emoji centered inside.
  /// Hidden entirely when the tile is too short ([isTiny]).
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [bellVanity]: Provides the `'emoji'` string; defaults to `'📚'`
  /// - [emojiRadius]: The avatar radius, proportional to tile height
  Widget _buildEmojiAvatar(BuildContext context,
      Map<String, dynamic> bellVanity, double emojiRadius) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      backgroundColor: Colors.black.withValues(alpha: .25),
      radius: emojiRadius,
      child: Text(
        bellVanity['emoji'] ?? '📚',
        style:
            TextStyle(fontSize: emojiRadius + 10, color: colorScheme.onSurface),
      ).fit(),
    );
  }

  /// Builds the text column showing the bell name and time range.
  ///
  /// Appearance: A two-row column (name + time range) when [isCompact] is false;
  /// a single row with the time range appended inline when [isCompact] is true.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme] and [MediaQueryData]
  /// - [bellVanity]: Provides `'name'`; falls back to [bell.title]
  /// - [bellSuffix]: Appended to the bell name or title
  /// - [timeRange]: Pre-formatted `'HH:MM - HH:MM'` string
  /// - [isCompact]: When `true`, merges the time range into the name line
  /// - [isTiny]: When `true`, excludes the emoji avatar diameter from width calculation
  /// - [emojiRadius]: Used to compute available text width (excluded when [isTiny])
  Widget _buildTextColumn(
      BuildContext context,
      Map<String, dynamic> bellVanity,
      String bellSuffix,
      String timeRange,
      bool isCompact,
      bool isTiny,
      double emojiRadius) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // 136px accounts for the color nib (10), spacers (8+8), and surrounding padding;
    // emoji avatar diameter excluded when tile is too short to show it
    final double textWidth =
        mediaQuery.size.width - 136 - (isTiny ? 0 : emojiRadius * 2);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      width: textWidth,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name line; includes time range inline when isCompact
          Expanded(
            child: Container(
              alignment:
                  isCompact ? Alignment.centerLeft : Alignment.bottomLeft,
              child: Text(
                '${(bellVanity['name'] ?? bell.title) ?? ''}$bellSuffix'
                '${isCompact ? ':     $timeRange' : ''}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Inter",
                    color: colorScheme.onSurface),
              ).fit(),
            ),
          ),
          // Separate time range line when there is enough vertical space
          if (!isCompact)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                alignment: Alignment.topLeft,
                child: Text(
                  timeRange,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: "Inter",
                      color: colorScheme.onSurface),
                ).fit(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final ScheduleEntry schedule = ScheduleDirectory.readSchedule(date);
    final _BellData resolved = _resolveVanity(schedule);

    final Color bellColor =
        ColorExtension.fromHex(resolved.vanity['color'] ?? '#909090');

    final String bellDecal = resolved.vanity['decal'] ?? "Blank";

    // Tile height spans the bell's full duration in pixels
    final double height =
        minuteHeight * bell.endClock!.difference(bell.startClock!).abs();

    // Emoji radius proportional to tile height; capped to prevent overflow on wide screens.
    // The 3/7 ratio keeps the avatar visually balanced within the tile.
    final double emojiRadius =
        min(height * 3 / 7 - 5, mediaQuery.size.width / 6);

    // Top margin positions the tile at the correct time relative to 8:00AM
    final double topMargin =
        bell.startClock!.difference(Clock(hours: 8)).abs() * minuteHeight;

    final String timeRange =
        '${bell.startClock!.display()} - ${bell.endClock!.display()}';

    final bool isCompact = height <= _compactThreshold;
    final bool isTiny = height <= _tinyThreshold;

    return Container(
        height: height,
        margin: EdgeInsets.only(top: topMargin),
        child: Stack(
          children: [
            if (bellDecal != "Blank")
              Positioned.fill(
                child: Opacity(
                    opacity: 0.25,
                    child: ClipRect(
                        child: Image.asset(
                      "assets/images/decals/$bellDecal.png",
                      fit: BoxFit.cover,
                    ))),
              ),
            Positioned.fill(
                child: ColoredBox(
              // Alternating alpha between even/odd tiles for subtle visual separation
              color: (index ?? 1) % 2 == 0
                  ? bellColor.withAlpha(64)
                  : bellColor.withAlpha(40),
            )),
            Positioned.fill(
                child: InkWell(
              // Tap opens the BellInfo popup for this bell
              onTap: () {
                context.pushPopup(BellInfo(schedule: schedule, bell: bell));
              },
              child: ScheduleDisplay.tutorialSystem.showcase(
                context: scContext,
                tutorial: _tutorialId(date, bell.title),
                uniqueNull: true,
                child: Row(
                  children: [
                    _buildColorNib(bellColor),
                    const SizedBox(width: 8),
                    // Emoji avatar hidden when tile is too short
                    if (!isTiny)
                      _buildEmojiAvatar(context, resolved.vanity, emojiRadius),
                    // Name and time range text
                    _buildTextColumn(
                        context,
                        resolved.vanity,
                        resolved.bellSuffix,
                        timeRange,
                        isCompact,
                        isTiny,
                        emojiRadius),
                  ],
                ),
              ),
            ))
          ],
        ));
  }
}
