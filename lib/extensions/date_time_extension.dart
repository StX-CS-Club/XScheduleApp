/*
  * date_time_extension.dart *
  Provided basic methods and static variables for displaying DateTime instances
 */

/// DateTime extension <p>
/// Provides basic instance methods and static variables for displaying DateTime objects.
extension DateTimeExtension on DateTime {
  /// DateTime extension <p>
  /// Map of String value for each int month value
  static Map<int, String> monthString = {
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December'
  };

  /// DateTime extension <p>
  /// Map of String value for each int weekday value
  static Map<int, String> weekdayString = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday'
  };

  /// DateTime extension <p>
  /// Returns a DateTime a given amount of days from the parent DateTime, accounting for daylight savings
  DateTime addDay(int days){
    DateTime result = add(Duration(days: days));
    // Adjusts for automatic daylight savings adjustment
    if (result.hour > 12) {
      while (result.hour != 0) {
        result = result.add(const Duration(hours: 1));
      }
    } else {
      while (result.hour != 0) {
        result = result.subtract(const Duration(hours: 1));
      }
    }
    return result;
  }

  /// DateTime extension <p>
  /// Provides a String in the format "{Weekday} {Month #}/{Date #}"
  String dateText() {
    return '${weekdayText()}, $month/$day';
  }

  /// DateTime extension <p>
  /// Provides the String value of the DateTime's month
  String monthText(){
    return monthString[month]!;
  }

  /// DateTime extension <p>
  /// Provides a String value of the DateTime's weekday
  String weekdayText(){
    return weekdayString[weekday]!;
  }

  /// DateTime extension <p>
  /// Finds the difference, in months, between this and a given DateTime
  int monthDiff(DateTime dateTime) {
    return (year * 12 + month) - (dateTime.year * 12 + dateTime.month);
  }

  /// DateTime extension <p>
  /// Returns a DateTime instance with time variables set to 0
  DateTime dateOnly(){
    return DateTime(year, month, day);
  }
}