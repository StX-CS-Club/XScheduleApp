import 'package:xschedule/schedule/bell_entry.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/schedule/schedule_settings.dart';

/// A resolved vanity map paired with its display suffix string.
typedef BellData = ({Map<String, dynamic> vanity, String bellSuffix});

/// A resolved vanity map paired with a flag indicating whether the alternate block is active.
typedef BellVanityData = ({Map<String, dynamic> vanity, bool isAlt});

/// Resolves the vanity map for [bell] within [schedule].
///
/// This function:
/// - Looks up [bell.title] in [ScheduleSettings.bellVanity]
/// - Overrides with the `'HR'` or `'FLEX'` vanity entry if the title contains either keyword
/// - Switches to the alternate vanity block if the schedule name matches an `'alt_days'` entry
///
/// Parameters:
/// - [bell]: The bell to resolve vanity for
/// - [schedule]: Used for alternate day condition matching
///
/// Returns: A [BellVanityData] record with the resolved [vanity] map and [isAlt] indicating
/// whether the alternate block was activated
BellVanityData resolveBellVanity(BellEntry bell, ScheduleEntry schedule) {
  Map<String, dynamic> bellVanity =
      ScheduleSettings.bellVanity[bell.title] ?? {};
  if (bell.title.contains("HR")) {
    bellVanity = ScheduleSettings.bellVanity["HR"] ?? {};
  }
  if (bell.title.contains("FLEX")) {
    bellVanity = ScheduleSettings.bellVanity["FLEX"] ?? {};
  }
  for (String altDay in bellVanity['alt_days'] ?? []) {
    if (schedule.name
        .toLowerCase()
        .replaceAll('-', ' ')
        .contains(altDay.toLowerCase())) {
      return (
        vanity: Map<String, dynamic>.from(bellVanity['alt'] ?? {}),
        isAlt: true
      );
    }
  }
  return (vanity: bellVanity, isAlt: false);
}
