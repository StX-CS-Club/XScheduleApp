/*
  * clock.dart *
  Manages time variables beyond what a standard DateTime would
 */

import 'package:xschedule/extensions/int_extension.dart';

/// Intended for managing time variables beyond what DateTime offers
class Clock {
  // Constructor
  Clock({this.hours = 0, this.minutes = 0}) {
    // Formats values on creation
    format();
  }

  /// The current hour value of the Clock (0-23)
  int hours;
  /// The current minute value of the Clock (0-59)
  int minutes;

  /// Ensures hour and minute values are within logical range
  void format(){
    hours = (hours + (minutes/60).floor()) % 24;
    minutes = minutes % 60;
  }

  /// Adds minutes and/or hours to a clock; input negative to subtract
  /// [int deltaHours = 0]: The int number of hours to add to the clock <p>
  /// [int deltaMinutes = 0]: The int number of minutes to add to the clock <p>
  void add({int deltaHours = 0, int deltaMinutes = 0}) {
    minutes += deltaMinutes;
    hours += deltaHours;
    format();
  }

  /// Sets the time of the Clock to be 12hr time
  void hr12Time(){
    hours = hours % 12;
    if(hours == 0){
      hours = 12;
    }
  }

  /// Outputs temporary clock with time added to it optionally.
  /// [int deltaHours = 0]: The int number of hours to add to the displayed Clock <p>
  /// [int deltaMinutes = 0]: The int number of minutes to add to the displayed Clock <p>
  /// [bool amPm = true]: Whether or not to display the Clock within 12hr time
  String display({int deltaHours = 0, int deltaMinutes = 0, bool amPm = true}) {
    // The Clock being displayed; by default this Clock
    Clock displayClock = this;
    // If change in time, clone clock and add to that clock instead
    if(deltaHours != 0 || deltaMinutes != 0){
      displayClock = clone();
      displayClock.add(deltaHours: deltaHours, deltaMinutes: deltaMinutes);
    }
    // If amPm, set Clock to 12hr time
    if(amPm){
      displayClock.hr12Time();
    }
    // Returns a String of the displayed Clock
    return '${displayClock.hours}:${displayClock.minutes.multiDecimal()}';
  }

  /// Finds the time interval between one clock and another
  int difference(Clock otherClock) {
    return (minutes - otherClock.minutes + (hours - otherClock.hours) * 60);
  }

  /// Provides a clone of the clock
  Clock clone() {
    return Clock(hours: hours, minutes: minutes);
  }

  /// Provides the total minutes of this Clock from 0:00
  int totalMinutes() {
    return minutes + hours * 60;
  }

  /// Returns a Clock from a given String
  static Clock? parse(String clockText) {
    // The inputted String's components
    final List<String> parts = clockText.split(':');
    // If improperly formated, returns null
    if (parts.length == 2) {
      // Attempts to parse integers from the components
      int? tryHours = int.tryParse(parts[0]);
      int? tryMinutes = int.tryParse(parts[1]);
      // If exists, return parsed Clock
      if (tryHours != null && tryMinutes != null) {
        return Clock(hours: tryHours, minutes: tryMinutes);
      }
    }
    return null;
  }

  /// Returns a Clock from a given DateTime
  static Clock fromDateTime(DateTime date) {
    return Clock(hours: date.hour, minutes: date.minute);
  }

  /// Creates a DateTime, with given year, month, and day, with the current time values
  DateTime toDateTime(DateTime reference) {
    return DateTime(
        reference.year, reference.month, reference.day, hours, minutes);
  }

  /// Converts a 12hr time Clock into 24hr based off estimation
  void estimate24hrTime(){
    // If hour value less than 3, likely PM time
    if(hours <= 3){
      add(deltaHours: 12);
    }
  }
}