/// An extension on Dart's [DateTime] class for display formatting and date arithmetic.
///
/// Responsibilities:
/// - Mapping integer month and weekday values to their full name strings
/// - Adding days to a [DateTime] with daylight saving time compensation
/// - Formatting a [DateTime] as human-readable date and weekday strings
/// - Computing the difference in months between two [DateTime] instances
/// - Stripping time components from a [DateTime] to produce a date-only value
extension DateTimeExtension on DateTime {
  /// Maps each integer month value (1–12) to its full English name.
  ///
  /// Follows [DateTime.month] conventions: `1` → `'January'`, ..., `12` → `'December'`
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

  /// Maps each integer weekday value (1–7) to its full English name.
  ///
  /// Follows [DateTime.weekday] conventions: `1` → `'Monday'`, ..., `7` → `'Sunday'`
  static Map<int, String> weekdayString = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday'
  };

  /// Returns a new [DateTime] that is [days] days after this instance,
  /// correcting for any hour shift introduced by daylight saving time transitions.
  ///
  /// This method:
  /// - Adds the requested number of days using [Duration]
  /// - Detects a DST-induced hour offset by checking if the result's hour is non-zero
  /// - Steps the result forward or backward by one hour at a time until midnight is reached
  ///
  /// Parameters:
  /// - [days]: The number of days to add; may be negative to subtract days
  ///
  /// Returns: A [DateTime] at midnight, [days] calendar days from this instance
  DateTime addDay(int days) {
    DateTime result = add(Duration(days: days));

    // DST transitions can shift the result's hour by ±1; correct back to midnight.
    // If the hour is past noon, the clock has sprung forward — advance to next midnight.
    // If the hour is before noon, the clock has fallen back — retreat to midnight.
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

  /// Returns a formatted date string for this [DateTime].
  ///
  /// Returns: A [String] in the format `'{Weekday}, {Month #}/{Day #}'`
  /// (e.g. `'Monday, 3/19'`)
  String dateText() {
    return '${weekdayText()}, $month/$day';
  }

  /// Returns the full English name of this [DateTime]'s month.
  ///
  /// Returns: A [String] such as `'January'` or `'December'`
  String monthText() {
    return monthString[month]!;
  }

  /// Returns the full English name of this [DateTime]'s weekday.
  ///
  /// Returns: A [String] such as `'Monday'` or `'Sunday'`
  String weekdayText() {
    return weekdayString[weekday]!;
  }

  /// Returns the difference in whole months between this [DateTime] and [dateTime].
  ///
  /// This method:
  /// - Converts each date to a total month count (`year * 12 + month`)
  /// - Subtracts to find the signed month difference
  ///
  /// Parameters:
  /// - [dateTime]: The [DateTime] to subtract from this instance
  ///
  /// Returns: A positive [int] if this date is later, negative if earlier, or `0` if same month
  int monthDiff(DateTime dateTime) {
    return (year * 12 + month) - (dateTime.year * 12 + dateTime.month);
  }

  /// Returns a copy of this [DateTime] with all time components set to zero.
  ///
  /// Constructs a new [DateTime] using only [year], [month], and [day],
  /// discarding hour, minute, second, and sub-second values.
  ///
  /// Returns: A [DateTime] at midnight (`00:00:00.000`) on the same calendar date
  DateTime dateOnly() {
    return DateTime(year, month, day);
  }
}