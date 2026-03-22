import 'dart:convert';

import 'package:localstorage/localstorage.dart';
import 'package:xschedule/schedule/bell_entry.dart';

/// A model class representing a single day's schedule and its associated bell data.
///
/// Responsibilities:
/// - Storing and providing access to the bell timetable and schedule name
/// - Deriving the first standard and flex bells from the bell list
/// - Providing static reference data for standard day structures and bell labels
/// - Serialising schedule data to a JSON-compatible map
class ScheduleEntry {
  /// Persisted vanity data for each bell, keyed by bell label.
  ///
  /// Each entry maps value names (e.g. `'className'`, `'location'`, `'color'`) to their values.
  /// Loaded from [localStorage] on startup under the key `'bellVanity'`.
  static Map<String, Map<String, dynamic>> bellVanity =
  Map<String, Map<String, dynamic>>.from(
      json.decode(localStorage.getItem("bellVanity") ?? '{}'));

  /// Standard day structures, mapping a day title to its ordered list of bell labels.
  ///
  /// Used as reference templates when constructing or validating a schedule's bell order.
  static const Map<String, List<String>> sampleDays = {
    "A Day": ["A", "B", "C", "FLEX", "D", "E", "F"],
    "G Day": ["G", "H", "A", "FLEX", "B", "C", "D"],
    "E Day": ["E", "F", "G", "FLEX", "H", "A", "B"],
    "C Day": ["C", "D", "E", "FLEX", "F", "G", "H"],
    "X Day": ["A", "B", "FLEX", "C", "D"],
    "Y Day": ["E", "F", "FLEX", "G", "H"],
    "All Meet": ["A", "B", "C", "D", "FLEX", "E", "F", "G", "H"],
  };

  /// The full set of recognised bell labels across all standard day types.
  static const List<String> sampleBells = [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "HR",
    "FLEX"
  ];

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

  /// Serialises this schedule to a JSON-compatible map.
  ///
  /// Returns: A [Map] with `'name'` and `'bells'` keys, suitable for [jsonEncode]
  Map<String, dynamic> toJsonEntry() => {"name": name, "bells": _bellMap()};

  /// Converts [bells] to a `Map<title, timeRange>` for JSON serialisation.
  ///
  /// Only includes [BellEntry]s with valid (non-null) start and end times,
  /// to prevent `'null-null'` time range strings that would fail to parse on restore.
  /// Duplicate bell titles are deduplicated by appending zero-width spaces (`'\u200B'`)
  /// to the key — stripped on deserialisation in [BellEntry.listFromMap].
  ///
  /// Returns: A [Map]<[String], [String]> of bell title to `'HH:MM-HH:MM'` time range
  Map<String, String> _bellMap() {
    final Map<String, String> result = {};
    for (BellEntry bell in bells) {
      // Skips bells with missing times to avoid storing unparseable 'null-null' ranges
      if (bell.start != null && bell.end != null) {
        // Appends zero-width spaces until the key is unique, preserving duplicate-titled bells
        String key = bell.title;
        while (result.containsKey(key)) {
          key += '\u200B';
        }
        result[key] = "${bell.start}-${bell.end}";
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