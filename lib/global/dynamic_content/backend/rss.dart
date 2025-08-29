import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:xschedule/global/dynamic_content/backend/schedule_directory.dart';
import 'package:xschedule/global/dynamic_content/stream_signal.dart';
import 'package:xschedule/global/static_content/extensions/date_time_extension.dart';
import 'package:xschedule/schedule/schedule_display/schedule_display.dart';

import '../../../schedule/schedule.dart';

class RSS {
  // rss.json variables TBD
  static late String dailyOrderUrl;
  static late String coCurricularsUrl;
  static late List<int> retryCodes;

  // Reads and interprets rss.json
  static Future<void> loadRSSJson() async {
    // Reads json as String
    final String jsonString =
        await rootBundle.loadString("assets/data/rss.json");
    // Interprets json String as hashmap
    final Map<String, dynamic> json = jsonDecode(jsonString);

    // Maps comm. variables
    dailyOrderUrl = json['daily_order_url'];
    coCurricularsUrl = json['cocurriculars_url'];
    retryCodes = List<int>.from(json['retry_status_codes']);
  }

  static bool offline = false;

  /// Reads dailyOrder RSS via http. <p>
  /// [bool limitRequests = true]: Limits the number of active http requests to 1. <p>
  /// [bool storeResults = false]: Automatically writes and stores the results locally. <p>
  /// [bool override = false]: Automatically writes the replaces the Schedule Directory with the results.
  static Future<void> getDailyOrder(
      {bool storeResults = false,
        bool refreshStream = true,
      bool overwrite = false}) async {
      try {
        // Read dailyOrder RSS via http
        final Response response = await httpGet(dailyOrderUrl);

        // Formats the response type (ICS) into an object we can work with
        final ICalendar iCalendar = ICalendar.fromString(response.body);

        // RegExp used for decoding schedule
        final RegExp regexp = RegExp(
          r"""(?:""" // Establishes an OR condition
          r"""_\s*([A-Za-z0-9\- *]*?[A-Za-z0-9])\s*_""" // Group 1: allows '*', still ends with alnum
          r"""|\s*""" // Portion of preceding white space.
          r"""([A-Za-z0-9\- *]*?[A-Za-z0-9])""" // Group 2: allows '*', still ends with alnum (i.e. A, HR, Flex 1, *Cafeteria Open)
          r"""[\s\-–—−:]*""" // Portion of white space, dashes, and/or colons.
          r"""(\d{1,2}:\d{2})""" // Group 3: H:MM or HH:MM (i.e. 7:30, 3:05)
          r"""[\s\-–—−:]*""" // Portion of white space, dashes, and/or colons.
          r"""(\d{1,2}:\d{2})?""" // Group 4: Optional H:MM or HH:MM
          r""")""",
          multiLine: true,
        );



        // Gets the calendar data as a list from the iCalendar
        final List<Map<String, dynamic>> calSchedules = iCalendar.data;

        // If override, clear schedules to be re-written. No errors will occur from here
        if (overwrite) {
          ScheduleDirectory.clearBells();
          ScheduleDirectory.clearNames();
        }

        // For each date data, inserts the schedule data Map into our schedule Map under the key of the date
        for (Map<String, dynamic> instance in calSchedules) {
          if (instance['type'] == "VEVENT") {
            // Gets the base String describing the day layout
            final String rawSchedule = instance['description']
                .replaceAll(r'\n', '_')
                .replaceAll("–", "-")
                .replaceAll("—", "-")
                .replaceAll("Bell", "");
            // The return schedule of this for loop
            final Map<String, String> bells = {};
            // Analyzes string to find all instances of regexp matching, and stores as result
            final List<String> titles = [];
            final List<String?> starts = [];
            final List<String?> ends = [];
            for (RegExpMatch match in regexp.allMatches(rawSchedule)) {
              // Title of bell
              String title = match.group(1) ?? match.group(2)!;
              if(!title.contains("*")){
                // If title is int, specify as Flex bell
                if (int.tryParse(title) != null) {
                  title = 'FLEX $title';
                }
                titles.add(title);
                starts.add(match.group(3));
                ends.add(match.group(4));
              }
            }
            if (titles.isNotEmpty) {
              starts[0] ??= "8:00";
              ends[ends.length - 1] ??= "3:05";
              for (int n = 0; n < 10; n++) {
                if (!starts.contains(null) && !ends.contains(null)) {
                  break;
                }
                for (int i = 0; i < titles.length; i++) {
                  if (i > 0) {
                    starts[i] ??= ends[i - 1];
                  }
                  if (i + 1 < titles.length) {
                    ends[i] ??= starts[i + 1];
                  }
                }
              }

              for (int i = 0; i < titles.length; i++) {
                if (starts[i] != null && ends[i] != null) {
                  String upperCaseTitle = titles[i].toUpperCase();
                  if (Schedule.sampleBells.contains(upperCaseTitle) ||
                      upperCaseTitle.contains("FLEX") ||
                      upperCaseTitle.contains("HOMEROOM")) {
                    titles[i] = upperCaseTitle.replaceAll("HOMEROOM", "HR");
                  }
                  bells[titles[i]] = "${starts[i]}-${ends[i]}";
                }
              }

              // Date of the data
              final DateTime date = instance['dtstart'].toDateTime();
              // Adds the forSchedule to our schedule data Map, under the DateTime (ignoring time)
              ScheduleDirectory.writeSchedule(date.dateOnly(),
                  bells: bells, name: instance['summary']);
            }
          }
        }
        if (storeResults) {
          ScheduleDirectory.storeSchedule();
        }
        if(refreshStream){
          ScheduleDisplay.scheduleStream.updateStream();
        }
      } catch (_) {
        rethrow;
      }
  }

  /// Reads Co-curriculars RSS via http
  static Future<Map<DateTime, List<Map<String, dynamic>>>>
      getCoCurriculars() async {
    // Result map tbd
    final Map<DateTime, List<Map<String, dynamic>>> result = {};

    // Reads calendarData RSS via http
    final Response response = await http.get(Uri.parse(coCurricularsUrl));

    // Formats the response type (ICS) into an object we can work with
    final ICalendar iCalendar = ICalendar.fromString(response.body);

    // Gets the calendar data as a list from the iCalendar
    final List<Map> clubs = iCalendar.data;

    // For each date data, inserts the schedule data Map into out schedule Map under the key of the date
    for (Map instance in clubs) {
      DateTime date = instance['dtstart'].toDateTime();
      result[date.dateOnly()] ??= [];
      result[date.dateOnly()]!.add({
        'summary': instance['summary'],
        'dtStart': instance['dtstart'].toDateTime(),
        'dtEnd': instance['dtend'].toDateTime(),
        'location': instance['location']
      });
    }
    // Returns result
    return result;
  }

  /// Waits for a set amount of time
  static Future<void> wait() async {
    await Future.delayed(const Duration(milliseconds: 5000));
  }

  /// Attempts to get a response through http get. Handles errors and re-attempts.
  static Future<Response> httpGet(String url, {bool refreshStream = false}) async {
    Response? response;
    // If successful contact has been made with server
    bool connected = false;
    bool lastState = offline;

    // Loop until contact made
    while(!connected){
      try {
        // Gets response from given url OR times out after 15 seconds
        response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException("");
        });
        // If status code allows retry
        if(retryCodes.contains(response.statusCode)){
          // Mark as offline and wait before retrying
          offline = true;
          await wait();
        } else {
          // Status as connected, with no server errors
          connected = true;
          offline = false;
        }
      } catch (_){
        // Mark as offline and wait before retrying
        offline = true;
        await wait();
      }
      if(offline != lastState && refreshStream){
        ScheduleDisplay.scheduleStream.updateStream();
      }
      lastState = offline;
    }
    // Return response, which can't be null.
    return response!;
  }
}
