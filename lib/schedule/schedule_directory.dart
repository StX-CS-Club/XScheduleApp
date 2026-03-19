/*
  * schedule_directory.dart *
  In charge of managing schedule data from various sources.
  See supabase_db.dart for more db comm. methods.
 */
import 'dart:convert';

import 'package:localstorage/localstorage.dart';
import 'package:xschedule/schedule/schedule.dart';
import 'package:xschedule/extensions/date_time_extension.dart';

class ScheduleDirectory {
  /// Schedule objects of each date
  static Map<DateTime, Schedule> schedules = {};

  static void writeSchedule(DateTime date,
      {String? name, Map<String, String>? bells, Map<String, dynamic>? info}) {
    schedules[date] ??= Schedule();
    schedules[date]!.writeInfo(info);
    schedules[date]!.writeBells(bells);
    schedules[date]!.writeName(name);
  }

  static Schedule readSchedule(DateTime date) {
    schedules[date] ??= Schedule();
    return schedules[date]!;
  }

  /// Clears all bell data across schedules
  static void clearBells(){
    for(Schedule schedule in schedules.values){
      schedule.bells.clear();
    }
  }

  /// Clears all name data across schedules
  static void clearNames(){
    for(Schedule schedule in schedules.values){
      schedule.name = "No Classes";
    }
  }

  /// List of ranges of prior supabase requests to remove overlap
  static List<Map<String, DateTime>> dailyInfoRequests = [];

  static void readStoredSchedule() {
    try {
      String scheduleJsonString = localStorage.getItem("schedule")!;
      Map<String, Map<String, dynamic>> scheduleJson =
          Map<String, Map<String, dynamic>>.from(
              jsonDecode(scheduleJsonString));

      for (String key in scheduleJson.keys) {
        DateTime date = DateTime.parse(key);
        Map<String, dynamic> scheduleMap = scheduleJson[key] ?? {};

        if (scheduleMap.isNotEmpty) {
          writeSchedule(date,
              name: scheduleMap['name'],
              bells: Map<String, String>.from(scheduleMap['bells']));
        }
      }
    } catch (_) {}
  }

  /// Stores the schedule as a json object.
  static void storeSchedule() {
    localStorage.setItem("schedule", jsonSchedule(100));
  }

  /// Converts schedules within a given range of the current date into a json map.
  static String jsonSchedule(int range) {
    Map<String, Map<String, dynamic>> result = {};

    DateTime date = DateTime.now().dateOnly();
    for (int i = 0; i < range; i++) {
      DateTime iDate = date.addDay(i);
      Schedule schedule = readSchedule(iDate);
      if (schedule.bells.isNotEmpty) {
        result[iDate.toIso8601String()] = {
          'name': schedule.name,
          'bells': schedule.bells
        };
      }
    }

    return jsonEncode(result);
  }

  /// Fetches and stores supabase data in efficient manner
  static Future<void> addDailyData(DateTime start, DateTime end) async {
    // Checks prior supabase requests, and removes overlap in times
    for (Map<String, DateTime> day in dailyInfoRequests) {
      if (start.isAfter(day["start"]!) && start.isBefore(day["end"]!)) {
        start = day["end"]!;
      }
      if (end.isBefore(day["end"]!) && end.isAfter(day["start"]!)) {
        end = day["start"]!;
      }
    }
    // If range is impossible (AKA after for loop, completely inside another range), ends the method
    if (start.isAfter(end)) {
      return;
    }
    // Adds current request to map
    dailyInfoRequests.add({"start": start, "end": end});
  }
}
