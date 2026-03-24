import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/schedule/schedule_storage.dart';
import 'package:xschedule/ui/schedule/schedule_display.dart';
import 'package:xschedule/util/stream_signal.dart';

class ScheduleSettings {
  // Private constructor — this class is not intended to be instantiated
  ScheduleSettings._();

  /// Persisted vanity data for each bell, keyed by bell label.
  ///
  /// Each entry maps value names (e.g. `'className'`, `'location'`, `'color'`) to their values.
  /// Loaded from [localStorage] on startup under the key `'bellVanity'`.
  static Map<String, Map<String, dynamic>> bellVanity =
      ScheduleStorage.restoreBellVanity();

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

  // Temporary bell vanity values used during editing, keyed by bell name
  static final Map<String, HSVColor> colors = {};
  static final Map<String, String> emojis = {};
  static final Map<String, String?> decals = {};
  static final Map<String, String> names = {};
  static final Map<String, String> teachers = {};
  static final Map<String, String> locations = {};
  static final Map<String, List<String>> altDays = {};

  /// Clears all temporary bell values from settings
  static void clearSettings() {
    colors.clear();
    emojis.clear();
    decals.clear();
    names.clear();
    teachers.clear();
    locations.clear();
    altDays.clear();
  }

  /// Saves bell vanity data to local storage and refreshes the schedule stream
  static void saveBells() {
    ScheduleStorage.storeBellVanity(bellVanity);
    localStorage.setItem("state", "logged");
    ScheduleDisplay.scheduleStream.updateStream();
  }

  /// Writes a bell's vanity data (and optionally its alternate) from a decoded map
  static void writeBell(String bell, Map<String, dynamic> bellVanity) {
    defineBell(bell);
    _writeVanityFields(bell, bellVanity);

    if (bellVanity['alt_days'] != null) {
      altDays[bell] = bellVanity['alt_days'].cast<String>();
    }

    if (bellVanity['alt'] != null) {
      final String altBell = '${bell}_alt';
      defineBell(bell, alternate: true);
      _writeVanityFields(altBell, bellVanity['alt']);
    }
  }

  /// Writes color, emoji, name, teacher, and location from [vanity] into the
  /// temporary maps for [bell]. Skips any field that is null.
  static void _writeVanityFields(String bell, Map<String, dynamic> vanity) {
    if (vanity['color'] != null) {
      colors[bell] =
          HSVColor.fromColor(ColorExtension.fromHex(vanity['color']));
    }
    if (vanity['emoji'] != null) emojis[bell] = vanity['emoji'];
    if (vanity['decal'] != null) decals[bell] = vanity['decal'];
    if (vanity['name'] != null) names[bell] = vanity['name'];
    if (vanity['teacher'] != null) teachers[bell] = vanity['teacher'];
    if (vanity['location'] != null) locations[bell] = vanity['location'];
  }

  /// Ensures all vanity fields for [bell] are defined with defaults,
  /// and populates the temporary editing maps.
  static void defineBell(String bell, {bool alternate = false}) {
    late Map<String, dynamic> reference;

    if (!alternate) {
      _initBellVanityDefaults(bell);
      reference = bellVanity[bell]!;
      altDays[bell] ??= List<String>.from(reference['alt_days']);
    } else {
      reference = Map<String, dynamic>.from(bellVanity[bell]!['alt']);
      // Fill in any missing alt fields from the primary bell's vanity
      bellVanity[bell]!.forEach((key, value) {
        reference[key] ??= value;
      });
      bell = '${bell}_alt';
    }

    colors[bell] ??=
        HSVColor.fromColor(ColorExtension.fromHex(reference['color']));
    emojis[bell] ??= reference['emoji'].replaceAll('HR', '📚');
    decals[bell] ??= reference['decal'];
    names[bell] ??= reference['name'];
    teachers[bell] ??= reference['teacher'];
    locations[bell] ??= reference['location'];
  }

  /// Applies default vanity values to [bell] in [ScheduleSettings.bellVanity]
  /// if they are not already set.
  static void _initBellVanityDefaults(String bell) {
    final bool isFlex = bell == 'FLEX';
    final bool isFlexOrHr = isFlex || bell == 'HR';

    bellVanity[bell] ??= {};
    bellVanity[bell]!['alt'] ??= {};
    bellVanity[bell]!['alt_days'] ??= [];

    bellVanity[bell]!['color'] ??= isFlex ? '#888888' : '#006aff';
    bellVanity[bell]!['emoji'] ??= isFlexOrHr ? '📚' : bell;
    bellVanity[bell]!['name'] ??= '$bell Bell'
        .replaceAll('HR Bell', 'Homeroom')
        .replaceAll('FLEX Bell', 'FLEX');
    bellVanity[bell]!['teacher'] ??= '';
    bellVanity[bell]!['location'] ??= '';
  }
}
