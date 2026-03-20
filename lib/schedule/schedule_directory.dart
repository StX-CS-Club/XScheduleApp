import 'dart:convert';

import 'package:localstorage/localstorage.dart';
import 'package:xschedule/schedule/schedule_entry.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/schedule/bell_entry.dart';

/// A simple immutable date range used to track prior Supabase request windows.
///
/// Responsibilities:
/// - Storing a [start] and [end] [DateTime] pair as a typed, safe alternative to
///   `Map<String, DateTime>` with stringly-typed keys
typedef DateRange = ({DateTime start, DateTime end});

/// A static directory managing all [ScheduleEntry] data across dates.
///
/// Responsibilities:
/// - Storing and retrieving [ScheduleEntry] objects keyed by date-only [DateTime]
/// - Persisting and restoring schedule data to/from [localStorage]
/// - Serialising future schedules to JSON within a given day range
/// - Deduplicating Supabase request ranges to avoid redundant fetches
/// - Clearing bell and name data across all stored schedules
class ScheduleDirectory {
  /// All loaded [ScheduleEntry] objects, keyed by date-only [DateTime] (time stripped via [DateTime.dateOnly]).
  ///
  /// Keys must always be normalised via [dateOnly] before use to prevent duplicate entries
  /// for the same calendar date with different time components.
  static Map<DateTime, ScheduleEntry> schedules = {};

  /// Writes bell and name data to the [ScheduleEntry] for [date], creating one if absent.
  ///
  /// Parameters:
  /// - [date]: The calendar date to write to; normalised to date-only internally
  /// - [name]: Optional schedule name (e.g. `'A Day'`); no-op if `null`
  /// - [bells]: Optional list of [BellEntry]s to assign; no-op if `null`
  static void writeSchedule(DateTime date,
      {String? name, List<BellEntry>? bells}) {
    // Normalises key to date-only to prevent duplicate entries for the same calendar date
    final DateTime key = date.dateOnly();
    schedules[key] ??= ScheduleEntry();
    schedules[key]!.writeBells(bells);
    schedules[key]!.writeName(name);
  }

  /// Returns the [ScheduleEntry] for [date], creating and storing an empty one if absent.
  ///
  /// Parameters:
  /// - [date]: The calendar date to look up; normalised to date-only internally
  ///
  /// Returns: The existing or newly created [ScheduleEntry] for [date]
  static ScheduleEntry readSchedule(DateTime date) {
    final DateTime key = date.dateOnly();
    schedules[key] ??= ScheduleEntry();
    return schedules[key]!;
  }

  /// Clears all bell data across every stored [ScheduleEntry].
  static void clearBells() {
    for (ScheduleEntry schedule in schedules.values) {
      schedule.bells.clear();
    }
  }

  /// Resets the name of every stored [ScheduleEntry] to `'No Classes'`.
  static void clearNames() {
    for (ScheduleEntry schedule in schedules.values) {
      schedule.name = "No Classes";
    }
  }

  /// Clears all bell and name data across every stored [ScheduleEntry].
  ///
  /// Equivalent to calling [clearBells] and [clearNames] in sequence.
  static void clearAll() {
    clearBells();
    clearNames();
  }

  /// Tracks the date ranges of prior Supabase requests to avoid redundant fetches.
  ///
  /// Each [DateRange] record stores the [start] and [end] of a completed request window.
  static List<DateRange> dailyInfoRequests = [];

  /// Restores schedule data from [localStorage] into [schedules].
  ///
  /// This method:
  /// - Reads the `'schedule'` key from [localStorage] as a JSON string
  /// - Decodes the JSON into a map of ISO date strings to schedule data maps
  /// - Calls [writeSchedule] for each valid entry to populate [schedules]
  ///
  /// Silently no-ops if the stored value is absent, malformed, or throws during parsing.
  static void readStoredSchedule() {
    try {
      final String scheduleJsonString = localStorage.getItem("schedule")!;
      final Map<String, Map<String, dynamic>> scheduleJson =
      Map<String, Map<String, dynamic>>.from(
          jsonDecode(scheduleJsonString));

      for (String key in scheduleJson.keys) {
        final DateTime date = DateTime.parse(key);
        final Map<String, dynamic> scheduleMap = scheduleJson[key] ?? {};

        if (scheduleMap.isNotEmpty) {
          writeSchedule(date,
              name: scheduleMap['name'],
              bells: BellEntry.listFromMap(
                  Map<String, String>.from(scheduleMap['bells'])));
        }
      }
    } catch (_) {}
  }

  /// Serialises and persists the current [schedules] to [localStorage].
  ///
  /// Only stores schedules within the next [100] days from today.
  /// See [jsonSchedule] for serialisation details.
  static void storeSchedule() {
    localStorage.setItem("schedule", jsonSchedule(100));
  }

  /// Serialises [ScheduleEntry]s from today up to [range] days into the future as a JSON string.
  ///
  /// Only includes entries with non-empty bell data. Past schedules are intentionally excluded.
  ///
  /// Parameters:
  /// - [range]: The number of days forward from today to include; e.g. `100` covers ~3 months
  ///
  /// Returns: A JSON string of the format `{ "YYYY-MM-DDT...": { name, bells, ... }, ... }`
  static String jsonSchedule(int range) {
    final Map<String, Map<String, dynamic>> result = {};
    final DateTime today = DateTime.now().dateOnly();

    for (int i = 0; i < range; i++) {
      final DateTime iDate = today.addDay(i);
      // Only serialises dates that have an existing entry with bells
      final ScheduleEntry schedule = readSchedule(iDate);
      if (schedule.bells.isNotEmpty) {
        result[iDate.toIso8601String()] = schedule.toJsonEntry();
      }
    }

    return jsonEncode(result);
  }

  /// Registers a Supabase data request for the range [[start], [end]], trimming any overlap
  /// with previously registered ranges to avoid redundant fetches.
  ///
  /// This method:
  /// - Checks [dailyInfoRequests] for any existing range that overlaps [start] or [end]
  /// - Trims [start] forward or [end] backward to exclude already-fetched windows
  /// - No-ops if the trimmed range is impossible (i.e. [start] is after [end]),
  ///   meaning the entire requested range was already covered
  /// - Adds the trimmed range to [dailyInfoRequests] if valid
  ///
  /// Parameters:
  /// - [start]: The beginning of the requested date range
  /// - [end]: The end of the requested date range
  static Future<void> addDailyData(DateTime start, DateTime end) async {
    // Uses local copies to avoid confusion — parameter mutation doesn't affect callers,
    // but reassigning parameters directly reads as if it might
    DateTime trimStart = start;
    DateTime trimEnd = end;

    // Trims the requested range against each prior request to remove overlap
    for (DateRange prior in dailyInfoRequests) {
      // If trimStart falls inside a prior range, advance it to the end of that range
      if (trimStart.isAfter(prior.start) && trimStart.isBefore(prior.end)) {
        trimStart = prior.end;
      }
      // If trimEnd falls inside a prior range, retreat it to the start of that range
      if (trimEnd.isBefore(prior.end) && trimEnd.isAfter(prior.start)) {
        trimEnd = prior.start;
      }
    }

    // If the trimmed range is impossible, the entire window was already fetched
    if (trimStart.isAfter(trimEnd)) return;

    // Registers the trimmed range as a completed request window
    dailyInfoRequests.add((start: trimStart, end: trimEnd));
  }
}