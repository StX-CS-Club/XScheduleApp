import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/schedule/schedule_storage.dart';
import 'package:xschedule/ui/schedule/schedule_display.dart';
import 'package:xschedule/util/stream_signal.dart';

/// Manages all bell vanity configuration and schedule reference data for the app.
///
/// Responsibilities:
/// - Loading bell and schedule reference data from the local JSON asset
/// - Storing and providing persisted bell vanity maps (color, emoji, name, teacher, location)
/// - Holding in-memory editing state for the bell settings UI
/// - Providing methods to read, write, and save bell vanity to [localStorage]
/// - Managing the set of unlocked special decals
class ScheduleSettings {
  // Private constructor — this class is not intended to be instantiated
  ScheduleSettings._();

  /// Persisted vanity data for each bell, keyed by bell label.
  ///
  /// Each entry maps value names (e.g. `'className'`, `'location'`, `'color'`) to their values.
  /// Loaded from [localStorage] on startup under the key `'vanity:bellVanity'`.
  static Map<String, Map<String, dynamic>> bellVanity =
      ScheduleStorage.restoreBellVanity();

  /// Standard day structures, mapping a day title to its ordered list of bell labels.
  ///
  /// Used as reference templates when constructing or validating a schedule's bell order.
  /// Imported from `assets/data/schedule_settings.json`.
  static late Map<String, List<String>> sampleSchedules;

  /// The full set of recognised bell labels across all standard day types.
  ///
  /// Imported from `assets/data/schedule_settings.json`.
  static late List<String> sampleBells;

  /// Preset hex color options shown in the horizontal color scroll in the bell settings UI.
  ///
  /// Imported from `assets/data/schedule_settings.json`.
  static late List<String> colorOptions;

  /// Names of all available decals that can be applied to bell tiles.
  ///
  /// Includes both standard decals and any unlocked [specialDecals].
  /// Imported from `assets/data/schedule_settings.json`.
  static late List<String> decalOptions;

  /// Names of decals that require special unlocking (e.g. via the Battle Pass).
  ///
  /// Only added to [decalOptions] when the corresponding `specialDecal:<name>` key
  /// in [localStorage] equals `'T'`.
  /// Imported from `assets/data/schedule_settings.json`.
  static late List<String> specialDecals;

  /// Decal names that act as visual section dividers in the decal picker list.
  ///
  /// When a decal's name appears in this list, a [Divider] is rendered above it.
  /// Imported from `assets/data/schedule_settings.json`.
  static late List<String> decalOptionDividers;

  /// Loads all reference data from `assets/data/schedule_settings.json`.
  ///
  /// This method:
  /// - Reads and decodes the JSON asset file
  /// - Populates [sampleBells], [sampleSchedules], [colorOptions], [decalOptions],
  ///   [specialDecals], and [decalOptionDividers]
  /// - Calls [addSpecialDecals] to append any previously unlocked special decals
  ///
  /// Must be called during app initialisation before any schedule settings UI is displayed.
  static Future<void> loadJson() async {
    // Read JSON file as raw string from Flutter asset bundle
    final String jsonString =
        await rootBundle.loadString("assets/data/schedule_settings.json");

    // Decode JSON string into a Map<String, dynamic>
    final Map<String, dynamic> json = jsonDecode(jsonString);

    sampleBells = List<String>.from(json['sample_bells']);
    sampleSchedules = _mapFromJson(json['sample_schedules']);
    colorOptions = List<String>.from(json['color_options']);
    decalOptions = List<String>.from(json['decal_options']);
    specialDecals = List<String>.from(json['special_decals']);
    decalOptionDividers = List<String>.from(json['decal_option_dividers']);

    addSpecialDecals();
  }

  /// Converts a raw JSON [map] of `{dayTitle: [bellLabel, ...]}` into a typed Dart map.
  ///
  /// Parameters:
  /// - [map]: The raw decoded JSON map from the schedule_settings asset
  ///
  /// Returns: A `Map<String, List<String>>` with typed values
  static Map<String, List<String>> _mapFromJson(Map map) {
    return map.map((key, value) => MapEntry(
          key,
          List<String>.from(value),
        ));
  }

  // ---------------------------------------------------------------------------
  // Temporary editing state
  // ---------------------------------------------------------------------------

  /// Temporary bell color values used during editing in [BellSettingsMenu], keyed by bell key.
  ///
  /// The map key is the bell label (e.g. `'A'`) or `'A_alt'` for alternate configuration.
  static final Map<String, HSVColor> colors = {};

  /// Temporary bell emoji values used during editing in [BellSettingsMenu], keyed by bell key.
  static final Map<String, String> emojis = {};

  /// Temporary bell decal values used during editing in [BellSettingsMenu], keyed by bell key.
  ///
  /// `null` indicates no decal is selected; `'Blank'` is the explicit "no decal" option.
  static final Map<String, String?> decals = {};

  /// Temporary bell name values used during editing in [BellSettingsMenu], keyed by bell key.
  static final Map<String, String> names = {};

  /// Temporary bell teacher values used during editing in [BellSettingsMenu], keyed by bell key.
  static final Map<String, String> teachers = {};

  /// Temporary bell location values used during editing in [BellSettingsMenu], keyed by bell key.
  static final Map<String, String> locations = {};

  /// Temporary alternate-day selections used during editing, keyed by bell label.
  ///
  /// Each value is the list of day titles (from [sampleSchedules]) on which this bell
  /// should display using its alternate vanity configuration.
  static final Map<String, List<String>> altDays = {};

  /// Clears all temporary editing state from the in-memory editing maps.
  ///
  /// Called when discarding unsaved changes or resetting the app.
  static void clearSettings() {
    colors.clear();
    emojis.clear();
    decals.clear();
    names.clear();
    teachers.clear();
    locations.clear();
    altDays.clear();
  }

  /// Saves the current [bellVanity] map to [localStorage] and refreshes the schedule stream.
  ///
  /// Also writes `'T'` to the `'state:welcome'` key to mark that the user has completed setup.
  static void saveBells() {
    ScheduleStorage.storeBellVanity(bellVanity);
    localStorage.setItem("state:welcome", "T");
    ScheduleDisplay.scheduleStream.updateStream();
  }

  /// Writes vanity data for [bell] (and optionally its alternate) from a decoded map.
  ///
  /// This method:
  /// - Ensures [bell] has defaults via [defineBell]
  /// - Writes the primary vanity fields via [_writeVanityFields]
  /// - If [bellVanity] contains `'alt_days'`, stores them in [altDays]
  /// - If [bellVanity] contains `'alt'`, writes the alternate vanity block for `'${bell}_alt'`
  ///
  /// Parameters:
  /// - [bell]: The bell label to write (e.g. `'A'`, `'HR'`)
  /// - [bellVanity]: The decoded vanity map containing field values to write
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

  /// Writes color, emoji, decal, name, teacher, and location from [vanity] into the
  /// temporary editing maps for [bell]. Skips any field that is null.
  ///
  /// Parameters:
  /// - [bell]: The map key to write into (e.g. `'A'` or `'A_alt'`)
  /// - [vanity]: The source vanity map; only non-null fields are applied
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

  /// Ensures all vanity fields for [bell] are defined with defaults
  /// and populates the temporary editing maps from [bellVanity].
  ///
  /// When [alternate] is true, targets the `'${bell}_alt'` editing map key
  /// and fills any missing alternate fields from the primary bell's vanity.
  ///
  /// Parameters:
  /// - [bell]: The bell label to initialise (e.g. `'A'`, `'HR'`)
  /// - [alternate]: When `true`, initialises the alternate vanity instead; defaults to `false`
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

  /// Appends any previously unlocked [specialDecals] to [decalOptions].
  ///
  /// Only adds a special decal if it is not already in [decalOptions] and its
  /// corresponding `specialDecal:<name>` key in [localStorage] equals `'T'`.
  static void addSpecialDecals() {
    decalOptions.addAll(specialDecals.where((element) =>
        !decalOptions.contains(element) &&
        localStorage.getItem("specialDecal:$element") == "T"));
  }

  /// Applies default vanity values to [bell] in [bellVanity] if they are not already set.
  ///
  /// Defaults:
  /// - `'color'`: `'#888888'` for FLEX, `'#006aff'` for all others
  /// - `'emoji'`: `'📚'` for HR and FLEX, otherwise the raw bell label
  /// - `'name'`: `'${bell} Bell'` normalised to `'Homeroom'` for HR and `'FLEX'` for FLEX
  /// - `'teacher'` and `'location'`: empty strings
  /// - `'alt'` and `'alt_days'`: empty map and list respectively
  ///
  /// Parameters:
  /// - [bell]: The bell label to initialise in [bellVanity]
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
