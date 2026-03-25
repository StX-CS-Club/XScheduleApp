import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/schedule_settings.dart';

/// A tappable tile displaying a single bell's current vanity configuration.
///
/// Responsibilities:
/// - Reads vanity data for the given [bell] from [ScheduleSettings]
/// - Renders a color nib, emoji avatar, name/teacher/location text, and an action icon
/// - Invokes [onTap] when the tile is pressed
class BellButton extends StatelessWidget {
  /// Creates a [BellButton] for the given [bell].
  ///
  /// Parameters:
  /// - [bell]: The bell identifier used to look up vanity data.
  /// - [icon]: The action icon shown on the right. Defaults to [Icons.settings].
  /// - [onTap]: Callback invoked when the tile is tapped.
  /// - [buttonWidth]: Optional explicit width. Defaults to 95% of screen width.
  const BellButton({
    super.key,
    required this.bell,
    this.icon = Icons.settings,
    required this.onTap,
    this.buttonWidth,
  });

  /// The bell identifier (e.g. "A", "HR", "FLEX") used to read vanity from [ScheduleSettings].
  final String bell;

  /// Icon displayed on the right side of the tile to indicate the available action.
  final IconData icon;

  /// Callback invoked when the tile is tapped or triggered.
  final FutureOr<void> Function()? onTap;

  /// Optional explicit width for the tile.
  /// If null, defaults to 95% of the current screen width.
  final double? buttonWidth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double width = buttonWidth ?? MediaQuery.of(context).size.width * .95;

    // Ensure vanity defaults are set before reading them
    ScheduleSettings.defineBell(bell);
    final Map<String, dynamic> vanity = ScheduleSettings.bellVanity[bell] ?? {};

    return Container(
      margin: const EdgeInsets.all(8),
      width: width,
      height: 100,
      child: Card(
        color: colorScheme.surface,
        child: Stack(
          children: [
            if ((vanity['decal'] ?? "Blank") != "Blank")
              Positioned.fill(
                  child: Image.asset(
                          'assets/images/decals/${vanity['decal']}.png',
                          fit: BoxFit.cover)
                      .withOpacity(0.25)),
            InkWell(
              highlightColor: colorScheme.onPrimary,
              onTap: onTap,
              child: Row(
                children: [
                  _buildColorNib(vanity),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildEmojiAvatar(vanity, colorScheme),
                        const SizedBox(width: 4),
                        _buildTextColumn(vanity, colorScheme, width),
                        _buildIconButton(colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Builds the 10px wide color strip on the left edge of the tile.
  /// Rounded on the left to match the card border radius.
  /// Color is derived from the bell's hex color string in [vanity].
  ///
  /// Parameters:
  /// - [vanity]: The bell's vanity map, must contain a non-null 'color' field.
  Widget _buildColorNib(Map<String, dynamic> vanity) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
        color: ColorExtension.fromHex(vanity['color']!),
      ),
      width: 10,
    );
  }

  /// Builds the emoji displayed centered over a circular avatar background.
  ///
  /// Parameters:
  /// - [vanity]: The bell's vanity map, must contain an 'emoji' field.
  /// - [colorScheme]: Provides the avatar background color.
  Widget _buildEmojiAvatar(
      Map<String, dynamic> vanity, ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.surfaceContainer,
          radius: 35,
        ),
        Text(
          vanity['emoji'],
          style: TextStyle(fontSize: 40, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  /// Builds the text column showing name, teacher, and location.
  /// Each field is only rendered if its value is non-empty.
  ///
  /// Parameters:
  /// - [vanity]: The bell's vanity map containing 'name', 'teacher', and 'location'.
  /// - [colorScheme]: Provides text color.
  /// - [width]: The full tile width, used to compute the text column's constrained width.
  Widget _buildTextColumn(
    Map<String, dynamic> vanity,
    ColorScheme colorScheme,
    double width,
  ) {
    return Container(
      // 184px accounts for: color nib (10) + padding (20) + avatar (70) + spacer (4) + icon (70) + padding (10)
      width: width - 184,
      height: 70,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vanity['name'].isNotEmpty)
            _buildInfoText(vanity['name'], 25, FontWeight.w600, colorScheme),
          if (vanity['teacher'].isNotEmpty)
            _buildInfoText(vanity['teacher'], 18, FontWeight.w500, colorScheme),
          if (vanity['location'].isNotEmpty)
            _buildInfoText(
                vanity['location'], 18, FontWeight.w500, colorScheme),
        ],
      ),
    );
  }

  /// Builds a single line of info text that expands to fill available width and scales to fit.
  ///
  /// Parameters:
  /// - [text]: The string to display.
  /// - [fontSize]: Font size in logical pixels.
  /// - [fontWeight]: Weight of the text.
  /// - [colorScheme]: Provides text color.
  Widget _buildInfoText(
    String text,
    double fontSize,
    FontWeight fontWeight,
    ColorScheme colorScheme,
  ) {
    return Text(
      text,
      style: TextStyle(
        height: 1,
        fontSize: fontSize,
        overflow: TextOverflow.ellipsis,
        fontWeight: fontWeight,
        color: colorScheme.onSurface,
      ),
    ).expandedFit(alignment: Alignment.centerLeft);
  }

  /// Builds the action icon container on the right side of the tile.
  ///
  /// Parameters:
  /// - [colorScheme]: Provides the icon color.
  Widget _buildIconButton(ColorScheme colorScheme) {
    return Container(
      alignment: Alignment.center,
      width: 70,
      child: Icon(icon, size: 45, color: colorScheme.onSurface),
    );
  }
}
