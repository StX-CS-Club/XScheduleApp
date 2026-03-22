import 'dart:convert';

import 'package:xschedule/schedule/bell_entry.dart';
import 'package:xschedule/schedule/schedule_storage.dart';

/// A model class representing a single day's schedule and its associated bell data.
///
/// Responsibilities:
/// - Storing and providing access to the bell timetable and schedule name
/// - Deriving the first standard and flex bells from the bell list
/// - Providing static reference data for standard day structures and bell labels
/// - Serialising schedule data to a JSON-compatible map
class ScheduleEntry {

  /// The ordered list of [BellEntry]s for this schedule.
  ///
  /// Defaults to empty; populated via [writeBells].
  List<BellEntry> bells = [];

  /// The display name of this schedule (e.g. `'A Day'`).
  ///
  /// Defaults to `'No Classes'` when no name has been written.
  String name = "No Classes";

  /// The first non-flex [BellEntry] in [bells], or `null` if none exists.
  ///
  /// Derived lazily from [bells] via [BellEntry.isFlex]; always reflects the
  /// current state of [bells] without requiring manual cache updates.
  BellEntry? get firstBell => bells
      .cast<BellEntry?>()
      .firstWhere((b) => !b!.isFlex, orElse: () => null);

  /// The first flex [BellEntry] in [bells], or `null` if none exists.
  ///
  /// Derived lazily from [bells] via [BellEntry.isFlex]; always reflects the
  /// current state of [bells] without requiring manual cache updates.
  BellEntry? get firstFlex =>
      bells.cast<BellEntry?>().firstWhere((b) => b!.isFlex, orElse: () => null);

  /// Assigns [bells] to this schedule if non-null.
  ///
  /// Parameters:
  /// - [bells]: The list of [BellEntry]s to assign; no-ops if `null`
  void writeBells(List<BellEntry>? bells) {
    if (bells != null) {
      this.bells = bells;
    }
  }

  /// Assigns [name] to this schedule if non-null.
  ///
  /// Parameters:
  /// - [name]: The display name to assign (e.g. `'A Day'`); no-ops if `null`
  void writeName(String? name) {
    if (name != null) {
      this.name = name;
    }
  }

  /// Serialises this schedule to a compressed JSON-compatible map.
  ///
  /// Uses [ScheduleKeys.encode] to shorten field names for storage efficiency.
  /// Omits [name] if it is the default `'No Classes'` to reduce payload size.
  ///
  /// Returns: A [Map] with compressed keys, suitable for [jsonEncode]
  Map<String, dynamic> toJsonEntry() => {
    if (name != "No Classes") ScheduleStorage.scheduleEncode['name']!: name,
    ScheduleStorage.scheduleEncode['bells']!: _bellList(),
  };

  /// Converts [bells] to a compact list-of-arrays for JSON serialisation.
  ///
  /// Each bell is stored as a three-element list `[title, start, end]` rather
  /// than a map, eliminating per-bell key strings and reducing payload size.
  /// Only includes [BellEntry]s with valid (non-null) start and end times.
  /// Duplicate bell titles are deduplicated by appending zero-width spaces
  /// (`'\u200B'`) to the title — stripped on deserialisation in [BellEntry.listFromList].
  ///
  /// Returns: A [List] of `[title, start, end]` arrays
  List<List<String>> _bellList() {
    final List<List<String>> result = [];
    final Set<String> seenTitles = {};
    for (BellEntry bell in bells) {
      // Skips bells with missing times to avoid storing unparseable entries
      if (bell.start != null && bell.end != null) {
        // Appends zero-width spaces to deduplicate titles with identical labels
        String title = bell.title;
        while (seenTitles.contains(title)) {
          title += '\u200B';
        }
        seenTitles.add(title);
        result.add([title, bell.start!, bell.end!]);
      }
    }
    return result;
  }

  /// Removes any [BellEntry]s from [bells] whose [Clock]s are invalid via [BellEntry.isValid].
  ///
  /// This method mutates [bells] in place. Call before [containsClasses] if
  /// invalid bells need to be purged prior to the check.
  void removeInvalid() {
    bells.removeWhere((bell) => !bell.isValid);
  }

  /// Returns whether this schedule contains valid class data.
  ///
  /// This method:
  /// - Returns `false` immediately if [bells] is empty (fast path; also guards when no cleaning has occurred)
  /// - When [tutorial] is `true`, also requires both [firstBell] and [firstFlex] to be non-null
  ///
  /// Parameters:
  /// - [tutorial]: When `true`, requires both a standard bell and a flex bell to be present;
  ///   defaults to `false`
  /// - [includeEvents]: When `true`, a schedule containing only flex/event bells still returns `true`;
  ///   defaults to `true`
  ///
  /// Returns: `true` if the schedule has at least one valid bell (and passes tutorial checks)
  bool containsClasses({bool tutorial = false, bool includeEvents = true}) {
    // Fast path before any cleaning; also guards when removeInvalid has not been called
    if (bells.isEmpty) return false;

    if (tutorial && (firstBell == null || firstFlex == null)) return false;

    return firstBell != null || includeEvents;
  }
}