import 'package:xschedule/schedule/clock.dart';

/// Represents a single bell period within a [ScheduleEntry].
///
/// Responsibilities:
/// - Storing a bell's title and optional start/end time strings
/// - Lazily parsing and caching start/end times as [Clock] objects
/// - Identifying flex periods by title
/// - Constructing [BellEntry] instances from raw time range strings and bell maps
class BellEntry {
  /// Creates a [BellEntry] with the given [title] and optional [start] and [end] time strings.
  ///
  /// Parameters:
  /// - [title]: The bell label (e.g. `'A'`, `'HR'`, `'FLEX 1'`); required
  /// - [start]: The start time string in `'H:MM'` format; nullable until inferred
  /// - [end]: The end time string in `'H:MM'` format; nullable until inferred
  BellEntry({
    required this.title,
    this.start,
    this.end,
  });

  /// The label of this bell period (e.g. `'A'`, `'HR'`, `'FLEX 1'`).
  final String title;

  /// The raw start time string (e.g. `'9:05'`).
  ///
  /// Nullable until inferred during the time-filling process.
  /// Normalised to [Clock.displayString] format on first successful [startClock] access.
  String? start;

  /// The raw end time string (e.g. `'10:00'`).
  ///
  /// Nullable until inferred during the time-filling process.
  /// Normalised to [Clock.displayString] format on first successful [endClock] access.
  String? end;

  /// Whether this bell period is a flex/advisory period.
  ///
  /// Determined by whether [title] contains `'flex'` (case-insensitive).
  bool get isFlex => title.toLowerCase().contains('flex');

  /// Whether this bell has valid, parseable start and end times.
  ///
  /// Returns `true` only if both [startClock] and [endClock] resolve to non-null [Clock]s.
  bool get isValid => startClock != null && endClock != null;

  /// Cached parsed [Clock] for [start].
  Clock? _startClock;

  /// Cached parsed [Clock] for [end].
  Clock? _endClock;

  /// The parsed [Clock] for this bell's start time, lazily initialised and cached.
  ///
  /// Returns `null` if [start] is `null` or cannot be parsed.
  /// Normalises [start] to the clock's display string on first successful parse,
  /// ensuring consistent comparisons on subsequent accesses.
  /// The cache is invalidated if [start] is changed externally.
  Clock? get startClock {
    if (start == null) return null;
    if (_startClock == null || _startClock?.displayString != start) {
      _startClock = Clock.parse(start!);
      // Normalises start to the parsed display string only on successful parse;
      // leaves start unchanged if parse fails so it can be retried after correction
      if (_startClock != null) start = _startClock?.displayString;
    }
    return _startClock;
  }

  /// The parsed [Clock] for this bell's end time, lazily initialised and cached.
  ///
  /// Returns `null` if [end] is `null` or cannot be parsed.
  /// Normalises [end] to the clock's display string on first successful parse,
  /// ensuring consistent comparisons on subsequent accesses.
  /// The cache is invalidated if [end] is changed externally.
  Clock? get endClock {
    if (end == null) return null;
    if (_endClock == null || _endClock?.displayString != end) {
      _endClock = Clock.parse(end!);
      // Normalises end to the parsed display string only on successful parse;
      // leaves end unchanged if parse fails so it can be retried after correction
      if (_endClock != null) end = _endClock?.displayString;
    }
    return _endClock;
  }

  /// Creates a [BellEntry] from a [title] and a `'HH:MM-HH:MM'` time range string.
  ///
  /// Splits [timeRange] on `'-'` and assigns the two components to [start] and [end].
  /// Returns a [BellEntry] with null times if [timeRange] is not in the expected format.
  ///
  /// Parameters:
  /// - [title]: The bell label; required
  /// - [timeRange]: A time range string in the format `'H:MM-H:MM'` (e.g. `'9:00-10:00'`)
  ///
  /// Returns: A [BellEntry] with [start] and [end] populated, or null times if malformed
  static BellEntry fromTimeRange(String title, String timeRange) {
    final List<String> parts = timeRange.split('-');
    // If not exactly two components, return a BellEntry with no times
    if (parts.length != 2) return BellEntry(title: title);
    return BellEntry(title: title, start: parts[0], end: parts[1]);
  }

  /// Converts a `Map<bell title, time range>` into an ordered [List] of [BellEntry]s.
  ///
  /// Each entry is constructed via [fromTimeRange], preserving the map's insertion order.
  /// Zero-width spaces (`'\u200B'`) appended to keys during serialisation by [ScheduleEntry]
  /// are stripped from titles before construction.
  ///
  /// Parameters:
  /// - [map]: A map of bell label to time range string (e.g. `{'A': '9:00-10:00'}`)
  ///
  /// Returns: A [List]<[BellEntry]> in the same order as [map]
  static List<BellEntry> listFromMap(Map<String, String> map) {
    return map.entries
        .map((entry) => fromTimeRange(
      // Strips zero-width spaces added during serialisation for key deduplication
      entry.key.replaceAll('\u200B', ''),
      entry.value,
    ))
        .toList();
  }

  /// Converts a list of `[title, start, end]` arrays into an ordered [List] of [BellEntry]s.
  ///
  /// This is the deserialisation counterpart to [ScheduleEntry._bellList].
  /// Zero-width spaces (`'\u200B'`) appended to titles during serialisation for
  /// deduplication are stripped before construction.
  ///
  /// Parameters:
  /// - [list]: A list of three-element string arrays `[title, start, end]`
  ///
  /// Returns: A [List]<[BellEntry]> in the same order as [list]
  static List<BellEntry> listFromList(List<dynamic> list) {
    return list.map((entry) {
      // Strips zero-width spaces added during serialisation for title deduplication
      final String title = (entry[0] as String).replaceAll('\u200B', '');
      return BellEntry(title: title, start: entry[1], end: entry[2]);
    }).toList();
  }
}