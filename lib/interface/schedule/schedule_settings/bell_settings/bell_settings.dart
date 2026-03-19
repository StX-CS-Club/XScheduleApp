import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/schedule/schedule.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/interface/schedule/schedule_display.dart';

class BellSettings {
  // Maps of temporary values used in editing bell vanity (<Bell, Value>)
  static final Map<String, HSVColor> colors = {};
  static final Map<String, String> emojis = {};
  static final Map<String, String> names = {};
  static final Map<String, String> teachers = {};
  static final Map<String, String> locations = {};
  static final Map<String, List<String>> altDays = {};

  /// Clears all temporary bell values from settings
  static void clearSettings() {
    colors.clear();
    emojis.clear();
    names.clear();
    teachers.clear();
    locations.clear();
    altDays.clear();
  }

  static void saveBells() {
    // Saves the schedule vanity data to local storage
    localStorage.setItem("bellVanity", json.encode(Schedule.bellVanity));
    // Confirms that the user's progress is marked as "logged"
    localStorage.setItem("state", "logged");
    // Refreshed HomePage stream
    ScheduleDisplay.scheduleStream.updateStream();
  }

  static void writeBell(String bell, Map<String, dynamic> bellVanity) {
    defineBell(bell);
    if (bellVanity['color'] != null) {
      colors[bell] =
          HSVColor.fromColor(ColorExtension.fromHex(bellVanity['color']));
    }
    if(bellVanity['emoji'] != null) {
      emojis[bell] = bellVanity['emoji'];
    }
    if(bellVanity['name'] != null) {
      names[bell] = bellVanity['name'];
    }
    if(bellVanity['teacher'] != null) {
      teachers[bell] = bellVanity['teacher'];
    }
    if(bellVanity['location'] != null) {
      locations[bell] = bellVanity['location'];
    }
    if(bellVanity['alt_days'] != null) {
      altDays[bell] = bellVanity['alt_days'].cast<String>();
    }
    if(bellVanity['alt'] != null){
      String altBell = "${bell}_alt";
      Map<String, dynamic> altBellVanity = bellVanity['alt'];
      defineBell(bell, alternate: true);


      if (altBellVanity['color'] != null) {
        colors[altBell] =
            HSVColor.fromColor(ColorExtension.fromHex(altBellVanity['color']));
      }
      if(altBellVanity['emoji'] != null) {
        emojis[altBell] = altBellVanity['emoji'];
      }
      if(altBellVanity['name'] != null) {
        names[altBell] = altBellVanity['name'];
      }
      if(altBellVanity['teacher'] != null) {
        teachers[altBell] = altBellVanity['teacher'];
      }
      if(altBellVanity['location'] != null) {
        locations[altBell] = altBellVanity['location'];
      }
    }
  }

  // Method which ensures no bell variables are undefined
  static void defineBell(String bell, {bool alternate = false}) {
    late Map<String, dynamic> reference;

    // If not alternate bell, define vanity defaults
    if (!alternate) {
      // Defines bellVanity map
      Schedule.bellVanity[bell] ??= {};
      Schedule.bellVanity[bell]!['alt'] ??= {};
      Schedule.bellVanity[bell]!['alt_days'] ??= [];
      // Defines color values
      if (bell == "FLEX") {
        Schedule.bellVanity[bell]!['color'] ??= "#888888";
      } else {
        Schedule.bellVanity[bell]!['color'] ??= "#006aff";
      }
      // Defines emoji values
      if (bell == "FLEX" || bell == "HR") {
        Schedule.bellVanity[bell]!['emoji'] ??= '📚';
      } else {
        Schedule.bellVanity[bell]!['emoji'] ??= bell;
      }
      // Defines name values
      Schedule.bellVanity[bell]!['name'] ??= '$bell Bell'
          .replaceAll('HR Bell', 'Homeroom')
          .replaceAll('FLEX Bell', 'FLEX');
      // Defines teacher values
      Schedule.bellVanity[bell]!['teacher'] ??= '';
      // Defines location values
      Schedule.bellVanity[bell]!['location'] ??= '';

      reference = Schedule.bellVanity[bell]!;

      altDays[bell] ??= List<String>.from(reference['alt_days']);
    } else {
      // ...else set as any existing alt vanity values
      reference = Map<String, dynamic>.from(Schedule.bellVanity[bell]!['alt']);
      Schedule.bellVanity[bell]!.forEach((key, value) {
        reference[key] ??= value;
      });
      // set bell id as alt id
      bell = "${bell}_alt";
    }

    // Null-aware assignments of bell variables
    colors[bell] ??=
        HSVColor.fromColor(ColorExtension.fromHex(reference['color']));
    emojis[bell] ??= reference['emoji'].replaceAll('HR', '📚');
    names[bell] ??= reference['name'];
    teachers[bell] ??= reference['teacher'];
    locations[bell] ??= reference['location'];
  }
}
