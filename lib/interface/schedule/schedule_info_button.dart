import 'package:flutter/material.dart';
import 'package:xschedule/backend/rss/rss.dart';
import 'package:xschedule/materials/icon_circle.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/interface/schedule/schedule_info_display.dart';

/// A self-contained info button for the [ScheduleDisplay] top bar.
///
/// Responsibilities:
/// - Reflecting RSS connectivity state through icon and background color
/// - Pushing a [ScheduleInfoDisplay] popup for the current [date] on tap
class ScheduleInfoButton extends StatelessWidget {
  const ScheduleInfoButton({super.key, required this.date});

  /// The currently viewed date; passed to [ScheduleInfoDisplay] on tap.
  final DateTime date;

  /// Returns the icon and background colors for the button based on [RSS.offline].
  ///
  /// - When offline: error colors to signal the connectivity problem
  /// - When online: dimmed surface colors to indicate info is available but not prominent
  ///
  /// Parameters:
  /// - [colorScheme]: The active [ColorScheme] used to derive colors
  ///
  /// Returns: A record with [icon] and [background] [Color] values
  ({Color icon, Color background}) _infoButtonColors(ColorScheme colorScheme) {
    if (RSS.offline) {
      return (
      icon: colorScheme.onError,
      background: colorScheme.error.withAlpha(194),
      );
    }
    return (
    icon: colorScheme.onSurface.withAlpha(128),
    background: colorScheme.tertiary.withAlpha(128),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final colors = _infoButtonColors(colorScheme);

    // Circular icon button; color reflects RSS state
    return IconCircle(
        icon: Icons.info_outline,
        iconColor: colors.icon,
        color: colors.background,
        radius: 20,
        padding: 5,
        onTap: () {
          context.pushPopup(ScheduleInfoDisplay(date: date));
        });
  }
}