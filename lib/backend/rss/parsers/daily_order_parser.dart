import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/schedule/schedule.dart';
import 'package:xschedule/schedule/schedule_directory.dart';

/// Parses daily order calendar data (ICS format) into bell schedules.
///
/// Responsibilities:
/// - Convert raw ICS calendar strings into structured data
/// - Extract bell titles and times using regex
/// - Normalize inconsistent formatting in schedule descriptions
/// - Fill missing start/end times between bells
/// - Write parsed schedules to [ScheduleDirectory]
class DailyOrderParser {
  /// Regex used to extract bell titles and times from schedule text.
  ///
  /// Matches patterns like:
  /// - "_A_ 8:00-8:45"
  /// - "HR 9:00 - 9:30"
  /// - "Flex 1 10:15"
  ///
  /// Captures:
  /// - Group 1/2: Bell title (with or without underscores)
  /// - Group 3: Start time (required)
  /// - Group 4: End time (optional)
  static final RegExp _scheduleRegex = RegExp(
    r"""(?:""" // Establishes an OR condition
    r"""_\s*([A-Za-z0-9\- *]*?[A-Za-z0-9])\s*_""" // Group 1: allows '*', still ends with alnum
    r"""|\s*""" // Portion of preceding white space.
    r"""([A-Za-z0-9\- *]*?[A-Za-z0-9])""" // Group 2: allows '*', still ends with alnum (i.e. A, HR, Flex 1, *Cafeteria Open)
    r"""[\s\-–—−:]*""" // Portion of white space, dashes, and/or colons.
    r"""(\d{1,2}:\d{2})""" // Group 3: H:MM or HH:MM (i.e. 7:30, 3:05)
    r"""[\s\-–—−:]*""" // Portion of white space, dashes, and/or colons.
    r"""(\d{1,2}:\d{2})?""" // Group 4: Optional H:MM or HH:MM
    r""")""",
    multiLine: true,
  );

  /// Parses an entire ICS calendar string and writes schedules to storage.
  ///
  /// This method:
  /// - Converts raw ICS string into [ICalendar]
  /// - Iterates through VEVENT entries
  /// - Extracts bell schedules for each event
  /// - Writes results into [ScheduleDirectory]
  ///
  /// Parameters:
  /// - [calendar]: raw ICS string from server
  static void parseCalendar(String calendar) {
    // Convert raw ICS string into structured calendar object
    final ICalendar iCalendar = ICalendar.fromString(calendar);

    // Iterate through all calendar entries
    for (final Map<String, dynamic> instance in iCalendar.data) {
      // Only process event entries (ignore metadata)
      if (instance['type'] != 'VEVENT') {
        continue;
      }

      // Parse bell schedule for this event
      final Map<String, String> bells = DailyOrderParser.parseEvent(instance);

      // Skip if no valid bell data found
      if (bells.isEmpty) {
        continue;
      }

      // Extract date (ignoring time component)
      final DateTime date = instance['dtstart'].toDateTime();

      // Optional schedule name (e.g., "Regular Schedule")
      final String? name = instance['summary'] as String?;

      // Write parsed schedule into directory
      ScheduleDirectory.writeSchedule(
        date.dateOnly(),
        bells: bells,
        name: name,
      );
    }
  }

  /// Parses a single calendar event into a bell schedule map.
  ///
  /// This method:
  /// - Normalizes raw description text
  /// - Extracts bell entries via regex
  /// - Fills missing start/end times
  /// - Converts entries into final bell map format
  ///
  /// Parameters:
  /// - [instance]: raw VEVENT map from ICalendar
  ///
  /// Returns:
  /// - Map of bell title → "start-end" string
  static Map<String, String> parseEvent(Map<String, dynamic> instance) {
    // Extract description safely (may be null)
    final String rawDescription = instance['description'] as String? ?? '';

    // Normalize formatting inconsistencies
    final String normalizedDescription = _normalizeDescription(rawDescription);

    // Extract bell entries from text
    final List<BellEntry> entries = _extractEntries(normalizedDescription);

    // If nothing parsed, return empty map
    if (entries.isEmpty) return {};

    // Fill in missing times between entries
    _fillMissingTimes(entries);

    // Convert structured entries into final output format
    return _toBellMap(entries);
  }

  /// Cleans and standardizes raw description text.
  ///
  /// This method:
  /// - Replaces escaped newlines with separators
  /// - Normalizes dash characters
  /// - Removes redundant "Bell" text
  ///
  /// Returns:
  /// - Cleaned string ready for regex parsing
  static String _normalizeDescription(String description) {
    return description
        .replaceAll(r'\n', '_')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('Bell', '');
  }

  /// Extracts bell entries (title + times) from schedule text.
  ///
  /// This method:
  /// - Applies regex to find matches
  /// - Filters out unwanted entries (e.g., starred notes)
  /// - Normalizes titles
  /// - Builds [BellEntry] objects
  ///
  /// Returns:
  /// - List of parsed [BellEntry] objects
  static List<BellEntry> _extractEntries(String rawSchedule) {
    final List<BellEntry> entries = [];

    // Iterate through all regex matches
    for (final match in _scheduleRegex.allMatches(rawSchedule)) {
      // Title may come from either capture group
      String title = match.group(1) ?? match.group(2)!;

      // Skip special entries (e.g., "*Cafeteria Open")
      if (title.contains('*')) continue;

      // Normalize title formatting
      title = _normalizeTitle(title);

      // Create structured entry
      entries.add(
        BellEntry(
          title: title,
          start: match.group(3),
          end: match.group(4),
        ),
      );
    }

    return entries;
  }

  /// Fills missing start/end times using neighboring entries.
  ///
  /// This method:
  /// - Sets default start/end bounds
  /// - Iteratively propagates known times across entries
  /// - Stops early if no further changes occur
  ///
  /// Parameters:
  /// - [entries]: list of bell entries to modify
  static void _fillMissingTimes(List<BellEntry> entries) {
    // Default bounds if missing
    entries.first.start ??= '8:00';
    entries.last.end ??= '3:05';

    // Perform multiple passes to propagate values
    for (int pass = 0; pass < 10; pass++) {
      bool changed = false;

      for (int i = 0; i < entries.length; i++) {
        // Fill missing start from previous end
        if (i > 0 && entries[i].start == null && entries[i - 1].end != null) {
          entries[i].start = entries[i - 1].end;
          changed = true;
        }

        // Fill missing end from next start
        if (i + 1 < entries.length &&
            entries[i].end == null &&
            entries[i + 1].start != null) {
          entries[i].end = entries[i + 1].start;
          changed = true;
        }
      }

      // Stop early if no changes occurred
      if (!changed) break;
    }
  }

  /// Normalizes bell titles for consistency across schedules.
  ///
  /// This method:
  /// - Converts numeric titles into FLEX blocks
  /// - Uppercases known bell types
  /// - Standardizes "HOMEROOM" → "HR"
  ///
  /// Returns:
  /// - Normalized title string
  static String _normalizeTitle(String title) {
    // Convert numeric-only titles into FLEX blocks
    if (int.tryParse(title) != null) {
      title = 'FLEX $title';
    }

    final String upper = title.toUpperCase();

    // Normalize known bell names
    if (Schedule.sampleBells.contains(upper) ||
        upper.contains('FLEX') ||
        upper.contains('HOMEROOM')) {
      return upper.replaceAll('HOMEROOM', 'HR');
    }

    return title;
  }

  /// Converts structured bell entries into final map format.
  ///
  /// Returns:
  /// - Map of title → "start-end" string
  static Map<String, String> _toBellMap(List<BellEntry> entries) {
    final Map<String, String> bells = {};

    for (final entry in entries) {
      // Skip incomplete entries
      if (entry.start == null || entry.end == null) continue;

      bells[entry.title] = '${entry.start}-${entry.end}';
    }

    return bells;
  }
}

/// Represents a single bell period with title and optional times.
///
/// Responsibilities:
/// - Store parsed bell data before final formatting
/// - Allow mutation during time-filling process
class BellEntry {
  /// Name of the bell (e.g., "A", "HR", "FLEX 1")
  String title;

  /// Start time (nullable until inferred)
  String? start;

  /// End time (nullable until inferred)
  String? end;

  BellEntry({
    required this.title,
    this.start,
    this.end,
  });
}
