/// An extension on Dart's [DateTime] class for display formatting and date arithmetic.
///
/// Responsibilities:
/// - Mapping integer month and weekday values to their full name strings
/// - Adding days to a [DateTime] without daylight saving time interference
/// - Formatting a [DateTime] as human-readable date and weekday strings
/// - Computing the difference in calendar days or months between two [DateTime] instances
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

  /// Returns a new [DateTime] that is [days] days after this instance.
  ///
  /// Uses direct [DateTime] construction rather than [Duration] arithmetic,
  /// which sidesteps DST transitions entirely and always returns a midnight value.
  /// Dart's [DateTime] constructor normalises out-of-range day values automatically
  /// (e.g. day 32 of March becomes April 1).
  ///
  /// Parameters:
  /// - [days]: The number of days to add; may be negative to subtract days
  ///
  /// Returns: A [DateTime] at midnight, [days] calendar days from this instance
  DateTime addDay(int days) {
    return DateTime(year, month, day + days);
  }

  /// Returns the difference in whole calendar days between this [DateTime] and [dateTime].
  ///
  /// Uses Julian Day Numbers to perform pure integer arithmetic, avoiding
  /// [Duration]-based subtraction which is susceptible to DST off-by-one errors.
  ///
  /// Parameters:
  /// - [dateTime]: The [DateTime] to subtract from this instance
  ///
  /// Returns: A positive [int] if this date is later, negative if earlier, or `0` if the same day
  int dayDiff(DateTime dateTime) {
    return _toJulianDay(dateOnly()) -
        _toJulianDay(dateTime.dateOnly());
  }

  /// Converts a [DateTime] to a Julian Day Number — an integer count of days since
  /// the Julian epoch (January 1, 4713 BC). Used internally by [dayDiff].
  ///
  /// Parameters:
  /// - [d]: The [DateTime] to convert; only [DateTime.year], [DateTime.month],
  ///   and [DateTime.day] are used
  ///
  /// Returns: An [int] Julian Day Number for the given date
  static int _toJulianDay(DateTime d) {
    final int m = d.month;
    final int y = d.year + (m < 3 ? -1 : 0);
    return d.day +
        ((153 * (m + (m < 3 ? 9 : -3)) + 2) ~/ 5) +
        (365 * y) +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
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