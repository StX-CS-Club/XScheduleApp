import 'dart:convert';
import 'dart:io';

import 'package:localstorage/localstorage.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/schedule/bell_entry.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/schedule/schedule_entry.dart';

/// Handles all local storage serialisation, compression, and encoding of
/// schedule and bell vanity data.
///
/// Responsibilities:
/// - Compressing and writing schedule JSON to [localStorage]
/// - Reading, decompressing, and parsing schedule JSON from [localStorage]
/// - Encoding and decoding bell vanity maps with compressed keys
/// - Omitting empty fields during encoding to minimise payload size
class ScheduleStorage {
  // Private constructor — this class is not intended to be instantiated
  ScheduleStorage._();

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Reusable [GZipCodec] instance for compressing and decompressing JSON.
  ///
  /// Stateless and safe to reuse across calls — instantiated once to avoid
  /// redundant allocation on every [store] and [restore] call.
  static final GZipCodec _gzip = GZipCodec();

  /// Maps full schedule entry field names to their compressed single-character keys.
  ///
  /// Used during serialisation in [_buildScheduleJson] and [ScheduleEntry.toJsonEntry].
  static const Map<String, String> scheduleEncode = {
    'name': 'n',
    'bells': 'b',
  };

  /// Maps full bell vanity field names to their compressed single-character keys.
  ///
  /// Used during serialisation in [encodeBellVanity] and [encodeAllBellVanity].
  static const Map<String, String> vanityEncode = {
    'name': 'n',
    'teacher': 't',
    'location': 'l',
    'emoji': 'e',
    'decal': 'i',
    'color': 'c',
    'alt_days': 'd',
    'alt': 'a',
  };

  /// Maps compressed single-character keys back to full bell vanity field names.
  ///
  /// Used during deserialisation in [decodeBellVanity] and [decodeAllBellVanity].
  static const Map<String, String> vanityDecode = {
    'n': 'name',
    't': 'teacher',
    'l': 'location',
    'e': 'emoji',
    'i': 'decal',
    'c': 'color',
    'd': 'alt_days',
    'a': 'alt',
  };

  // ---------------------------------------------------------------------------
  // Schedule storage
  // ---------------------------------------------------------------------------

  /// Compresses and persists the current [ScheduleDirectory.schedules] to [localStorage].
  ///
  /// The JSON string is GZip-compressed and Base64-encoded before storage,
  /// typically achieving 60–70% size reduction over raw JSON.
  /// Only stores schedules within the next 100 days from today.
  static void store() {
    final List<int> compressed =
        _gzip.encode(utf8.encode(_buildScheduleJson(100)));
    localStorage.setItem("schedule", base64Encode(compressed));
  }

  /// Reads, decompresses, and restores schedule data from [localStorage] into
  /// [ScheduleDirectory.schedules].
  ///
  /// This method:
  /// - Reads the `'schedule'` key from [localStorage] as a Base64 string
  /// - Base64-decodes → GZip-decompresses → UTF-8 decodes to recover the JSON string
  /// - Parses each entry and calls [ScheduleDirectory.writeSchedule] to populate schedules
  ///
  /// Silently no-ops if the stored value is absent, malformed, or throws during parsing.
  static void restore() {
    try {
      final String? stored = localStorage.getItem("schedule");
      if (stored == null) return;

      // Base64 → GZip decompress → UTF-8 decode to recover the original JSON string
      final String jsonString = utf8.decode(_gzip.decode(base64Decode(stored)));

      final Map<String, dynamic> scheduleJson =
          Map<String, dynamic>.from(jsonDecode(jsonString));

      for (final String key in scheduleJson.keys) {
        final DateTime date = DateTime.parse(key);
        final Map<String, dynamic> scheduleMap =
            Map<String, dynamic>.from(scheduleJson[key] ?? {});

        if (scheduleMap.isNotEmpty) {
          ScheduleDirectory.writeSchedule(date,
              // Uses compressed 'n' key since that's what was stored
              name: scheduleMap[scheduleEncode['name']],
              // Reconstructs BellEntrys from compact list-of-arrays
              bells: BellEntry.listFromList(List<dynamic>.from(
                  scheduleMap[scheduleEncode['bells']] ?? [])));
        }
      }
    } catch (_) {
      // Silently discards stale or malformed data — will be re-fetched and
      // re-stored on the next successful data load
    }
  }

  /// Serialises [ScheduleDirectory.schedules] from today up to [range] days
  /// into the future as a JSON string.
  ///
  /// Uses [scheduleEncode] to shorten field names and stores bells as compact
  /// list-of-arrays to minimise payload size. Only includes entries with
  /// non-empty bell data; past schedules are intentionally excluded.
  ///
  /// Parameters:
  /// - [range]: The number of days forward from today to include;
  ///   e.g. `100` covers ~3 months
  ///
  /// Returns: A JSON string with compressed keys and list-encoded bells
  static String _buildScheduleJson(int range) {
    final Map<String, dynamic> result = {};
    final DateTime today = DateTime.now().dateOnly();

    for (int i = 0; i < range; i++) {
      final DateTime iDate = today.addDay(i);
      final ScheduleEntry schedule = ScheduleDirectory.readSchedule(iDate);
      // Only serialises dates that have an existing entry with bells
      if (schedule.bells.isNotEmpty) {
        result[iDate.toIso8601String()] = schedule.toJsonEntry();
      }
    }

    return jsonEncode(result);
  }

  // ---------------------------------------------------------------------------
  // Bell vanity storage
  // ---------------------------------------------------------------------------

  /// Compresses and persists [vanity] to [localStorage] under the key `'bellVanity'`.
  ///
  /// Encodes all vanity maps via [encodeAllBellVanity] before compression,
  /// omitting empty fields to minimise payload size.
  ///
  /// Parameters:
  /// - [vanity]: The full `Map<bellLabel, vanityMap>` to store
  static void storeBellVanity(Map<String, Map<String, dynamic>> vanity) {
    final String json = jsonEncode(encodeAllBellVanity(vanity));
    final List<int> compressed = _gzip.encode(utf8.encode(json));
    localStorage.setItem("bellVanity", base64Encode(compressed));
  }

  /// Reads, decompresses, and returns all bell vanity data from [localStorage].
  ///
  /// Returns an empty map if the stored value is absent, malformed, or throws.
  ///
  /// Returns: A fully restored `Map<bellLabel, vanityMap>` or `{}` on failure
  static Map<String, Map<String, dynamic>> restoreBellVanity() {
    try {
      final String? stored = localStorage.getItem("bellVanity");
      if (stored == null) return {};

      // Base64 → GZip decompress → UTF-8 decode to recover the original JSON string
      final String jsonString = utf8.decode(_gzip.decode(base64Decode(stored)));

      return decodeAllBellVanity(
          Map<String, dynamic>.from(jsonDecode(jsonString)));
    } catch (_) {
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Bell vanity encoding
  // ---------------------------------------------------------------------------

  /// Encodes a single bell vanity map using compressed keys.
  ///
  /// Omits empty strings, empty lists, and empty maps to reduce payload size.
  /// Recursively compresses the `alt` sub-map if present and non-empty.
  ///
  /// Parameters:
  /// - [vanity]: The full bell vanity map
  ///   (e.g. `{'name': 'A Bell', 'color': '#ff0000', 'alt': {...}, ...}`)
  ///
  /// Returns: A compressed map with single-character keys and omitted empty values
  static Map<String, dynamic> encodeBellVanity(Map<String, dynamic> vanity) {
    final Map<String, dynamic> result = {};
    for (final MapEntry<String, dynamic> entry in vanity.entries) {
      final String? key = vanityEncode[entry.key];
      // Skips unrecognised keys not present in vanityEncode
      if (key == null) continue;
      final dynamic value = entry.value;
      // Omits empty strings, lists, and maps to reduce payload size
      if (value is String && value.isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      if (value is Map && value.isEmpty) continue;
      // Recursively encodes the alt sub-map using the same key compression
      if (entry.key == 'alt' && value is Map) {
        result[key] = encodeBellVanity(Map<String, dynamic>.from(value));
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  /// Decodes a single compressed bell vanity map back to full key names.
  ///
  /// Restores any omitted fields to their default empty values
  /// (`''` for strings, `[]` for lists, `{}` for maps).
  /// Recursively decodes the `alt` sub-map if present.
  ///
  /// Parameters:
  /// - [compressed]: A compressed vanity map with single-character keys
  ///
  /// Returns: A full bell vanity map with restored keys and default empty values
  static Map<String, dynamic> decodeBellVanity(
      Map<String, dynamic> compressed) {
    // Initialises all fields to defaults so missing keys are always present
    final Map<String, dynamic> result = {
      'name': '',
      'teacher': '',
      'location': '',
      'emoji': '',
      'color': '',
      'alt_days': <String>[],
      'alt': <String, dynamic>{},
    };
    for (final MapEntry<String, dynamic> entry in compressed.entries) {
      final String? key = vanityDecode[entry.key];
      // Skips unrecognised compressed keys
      if (key == null) continue;
      // Recursively decodes the alt sub-map
      if (key == 'alt' && entry.value is Map) {
        result[key] = decodeBellVanity(Map<String, dynamic>.from(entry.value));
      } else {
        result[key] = entry.value;
      }
    }
    return result;
  }

  /// Encodes all bell vanity entries using compressed keys via [encodeBellVanity].
  ///
  /// Parameters:
  /// - [vanity]: The full `Map<bellLabel, vanityMap>` to compress
  ///
  /// Returns: A new map with the same bell label keys and compressed vanity values
  static Map<String, dynamic> encodeAllBellVanity(
      Map<String, Map<String, dynamic>> vanity) {
    return vanity.map((bell, data) => MapEntry(bell, encodeBellVanity(data)));
  }

  /// Decodes all compressed bell vanity entries back to full key names via
  /// [decodeBellVanity].
  ///
  /// Parameters:
  /// - [compressed]: A `Map<bellLabel, compressedVanityMap>` from storage
  ///
  /// Returns: A fully restored `Map<bellLabel, vanityMap>`
  static Map<String, Map<String, dynamic>> decodeAllBellVanity(
      Map<String, dynamic> compressed) {
    return compressed.map((bell, data) =>
        MapEntry(bell, decodeBellVanity(Map<String, dynamic>.from(data))));
  }
}
