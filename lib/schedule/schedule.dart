/*
  * schedule.dart *
  Intended for the better management of the various variables of each day's Schedule
  (i.e. bell hashmap, firstBell, start and end times, name, etc.)
 */
import 'dart:convert';

import 'package:localstorage/localstorage.dart';
import 'package:xschedule/schedule/clock.dart';

/// class for managing the various variables of each day's Schedule
class Schedule {
  /// Global Map (&lt;Bell, Map&lt;ValueName, value>>) of vanity values (Class name, location, color, etc.) of all bells
  static Map<String, Map<String, dynamic>> bellVanity =
      Map<String, Map<String, dynamic>>.from(
          json.decode(localStorage.getItem("bellVanity") ?? '{}'));

  /// const Map (&lt;Day Title, Order>) of standard day structures.
  static const Map<String, List<String>> sampleDays = {
    "A Day": ["A", "B", "C", "FLEX", "D", "E", "F"],
    "G Day": ["G", "H", "A", "FLEX", "B", "C", "D"],
    "E Day": ["E", "F", "G", "FLEX", "H", "A", "B"],
    "C Day": ["C", "D", "E", "FLEX", "F", "G", "H"],
    "X Day": ["A", "B", "FLEX", "C", "D"],
    "Y Day": ["E", "F", "FLEX", "G", "H"],
    "All Meet": ["A", "B", "C", "D", "FLEX", "E", "F", "G", "H"],
  };

  static const List<String> sampleBells = [
    "A", "B", "C", "D", "E", "F", "G", "H", "HR", "FLEX"
  ];

  void writeBells(Map<String, String>? bells) {
    if(bells != null) {
      this.bells = bells;
      // Assigns firstBell and firstFlex Strings
      for (String bell in bells.keys) {
        if (bell.toLowerCase().contains('flex')) {
          firstFlex ??= bell;
        } else {
          firstBell ??= bell;
        }
      }
    }
  }

  void writeInfo(Map<String, dynamic>? info) {
    if(info != null){
      this.info = info;
    }
  }

  void writeName(String? name){
    if(name != null){
      this.name = name;
    }
  }

  /// Hashmap containing data of schedule (i.e. uniform, lunch, etc.)
  Map<String, dynamic> info = {};

  /// Hashmap (&lt;Bell, Map&lt;ValueName, value>>) of bells of Schedule
  Map<String, String> bells = {};

  /// The String label of the Schedule (i.e. A Day)
  String name = "No Classes";

  /// The String value of the first standard bell, if it exists (i.e. A)
  String? firstBell;

  /// The String value of the first flex bell, it it exists (i.e. Flex, Flex 1)
  String? firstFlex;

  /// Returns the 'start' and 'end' times of the inputted bell
  Map<String, Clock?>? clockMap(String bell) {
    // If bell doesn't exist, return null
    if (bells[bell] != null) {
      // Splits bell into start and end
      List<String> times = bells[bell]?.split('-') ?? [];
      // If bell improperly formatted, return null
      if (times.length == 2) {
        final Clock? startClock = Clock.parse(times[0]);
        // Converts early-PM hours into military time
        startClock?.estimate24hrTime();

        final Clock? endClock = Clock.parse(times[1]);
        //Converts early-PM hours into military time
        endClock?.estimate24hrTime();
        // Returns Clocks in Map form
        return {'start': startClock, 'end': endClock};
      }
    }
    return null;
  }

  Map<String, dynamic> toJsonEntry() {
    return {"name": name, "bells": bells, "info": info};
  }

  bool containsClasses({bool tutorial = false, bool clean = true}){
    if (tutorial) {
      if (firstBell == null || firstFlex == null) {
        return false;
      }
    }
    // Checks if schedule has bells
    if (bells.isEmpty) {
      return false;
    }

    if(clean) {
      // Removes any bells with fault Clocks
      List<String> keys = bells.keys.toList();
      for (String key in keys) {
        if (clockMap(key) == null) {
          bells.remove(key);
        }
      }
    }
    return true;
  }
}
