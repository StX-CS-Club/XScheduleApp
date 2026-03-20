import 'package:xschedule/extensions/int_extension.dart';

/// A lightweight time representation offering arithmetic and formatting beyond [DateTime].
///
/// Responsibilities:
/// - Storing and normalising hour and minute values
/// - Performing time arithmetic (add, difference, total minutes)
/// - Converting between 12hr, 24hr, and [DateTime] representations
/// - Lazily caching a default display string for efficient repeated rendering
class Clock {
  /// Creates a [Clock] with the given [hours] and [minutes], normalising values on construction.
  ///
  /// Values outside the standard range are automatically wrapped via [format]
  /// (e.g. `minutes: 90` becomes `hours + 1, minutes: 30`).
  Clock({this.hours = 0, this.minutes = 0}) {
    format();
  }

  /// Private constructor that skips [format] for already-normalised values.
  ///
  /// Used internally by [clone] to avoid redundant normalisation of values
  /// that are guaranteed to already be in range.
  Clock._raw(this.hours, this.minutes);

  /// The current hour value of this clock (0–23 after [format]).
  int hours;

  /// The current minute value of this clock (0–59 after [format]).
  int minutes;

  /// Cached default display string, lazily initialised on first access of [displayString].
  ///
  /// Invalidated to `null` whenever [hours] or [minutes] are mutated via [format].
  String? _displayString;

  /// The default display string for this clock in 12hr format (e.g. `'9:05'`).
  ///
  /// Lazily computed on first access and cached. The cache is cleared on any mutation
  /// to [hours] or [minutes] via [format], ensuring the value stays accurate.
  String get displayString {
    _displayString ??= display();
    return _displayString!;
  }

  /// The total number of minutes elapsed since `0:00`.
  ///
  /// A getter rather than a method since it is a pure derived value with no parameters.
  int get totalMinutes => minutes + hours * 60;

  /// Normalises [hours] and [minutes] to their valid ranges and clears the display cache.
  ///
  /// This method:
  /// - Carries overflow minutes into hours (e.g. 90 minutes → 1 hour, 30 minutes)
  /// - Wraps hours within 0–23 using modulo 24
  /// - Clears [_displayString] so [displayString] is recomputed on next access
  void format() {
    hours = (hours + (minutes / 60).floor()) % 24;
    minutes = minutes % 60;
    // Invalidates the display cache since time values have changed
    _displayString = null;
  }

  /// Adds [deltaHours] and/or [deltaMinutes] to this clock, then normalises via [format].
  ///
  /// Pass negative values to subtract time.
  ///
  /// Parameters:
  /// - [deltaHours]: Hours to add; defaults to `0`
  /// - [deltaMinutes]: Minutes to add; defaults to `0`
  void add({int deltaHours = 0, int deltaMinutes = 0}) {
    minutes += deltaMinutes;
    hours += deltaHours;
    format();
  }

  /// Returns a formatted time string for this clock, optionally offset and in 12hr format.
  ///
  /// When [deltaHours] or [deltaMinutes] are non-zero, operates on a [clone] to avoid
  /// mutating this clock. The default (no delta, amPm true) result is cached via
  /// [displayString] for repeated access.
  ///
  /// Parameters:
  /// - [deltaHours]: Hours to add to the displayed time; defaults to `0`
  /// - [deltaMinutes]: Minutes to add to the displayed time; defaults to `0`
  /// - [amPm]: When `true`, converts the displayed time to 12hr format; defaults to `true`
  ///
  /// Returns: A time string in the format `'H:MM'` (e.g. `'9:05'`, `'12:30'`)
  String display({int deltaHours = 0, int deltaMinutes = 0, bool amPm = true}) {
    // Operates on a clone if a time delta is requested, to avoid mutating this clock
    Clock displayClock = this;
    if (deltaHours != 0 || deltaMinutes != 0) {
      displayClock = clone();
      displayClock.add(deltaHours: deltaHours, deltaMinutes: deltaMinutes);
    }
    if (amPm) {
      // _to12hr returns a display-only int without mutating this clock
      final int displayHours = _to12hr(displayClock.hours);
      // multiDecimal() zero-pads minutes to 2 digits (e.g. 5 → '05')
      return '$displayHours:${displayClock.minutes.multiDecimal()}';
    }
    return '${displayClock.hours}:${displayClock.minutes.multiDecimal()}';
  }

  /// Converts a 24hr [hours] value to its 12hr equivalent as a pure function.
  ///
  /// Returns `12` for both `0` (midnight) and `12` (noon), and `hours % 12` otherwise.
  /// Does not mutate any state — used exclusively by [display].
  ///
  /// Parameters:
  /// - [hours]: A 24hr hour value (0–23)
  ///
  /// Returns: The equivalent 12hr hour value (1–12)
  static int _to12hr(int hours) {
    final int result = hours % 12;
    // 0 in 12hr time is displayed as 12 (e.g. midnight → 12:00, noon → 12:00)
    return result == 0 ? 12 : result;
  }

  /// Returns the signed difference in total minutes between this clock and [otherClock].
  ///
  /// A positive result means this clock is later than [otherClock].
  ///
  /// Parameters:
  /// - [otherClock]: The [Clock] to subtract from this one
  ///
  /// Returns: The difference in minutes as a signed [int]
  int difference(Clock otherClock) {
    return totalMinutes - otherClock.totalMinutes;
  }

  /// Returns a new [Clock] with the same [hours] and [minutes] as this one.
  ///
  /// Uses [Clock._raw] to skip redundant normalisation, since the source values
  /// are already guaranteed to be in range.
  Clock clone() => Clock._raw(hours, minutes);

  /// Parses a [Clock] from a time string, automatically converting early-PM hours to 24hr.
  ///
  /// Accepts `'H:MM'` or `'HH:MM'` format. Leading/trailing whitespace is trimmed.
  /// Calls [_estimate24hrTime] on the parsed result to correct AM/PM ambiguity for
  /// schedule times — see [_estimate24hrTime] for the heuristic details.
  ///
  /// Returns `null` if [clockText] is not in the expected format or contains
  /// non-integer components.
  ///
  /// Parameters:
  /// - [clockText]: A time string to parse (e.g. `'9:05'`, `' 13:30 '`)
  ///
  /// Returns: A normalised [Clock] with 24hr time applied, or `null` if parsing fails
  static Clock? parse(String clockText) {
    // Trims whitespace to handle incidental spaces from string splitting (e.g. '8:00 - 9:00')
    final List<String> parts = clockText.trim().split(':');
    // Expects exactly two components: hours and minutes
    if (parts.length == 2) {
      int? tryHours = int.tryParse(parts[0]);
      int? tryMinutes = int.tryParse(parts[1]);
      // Returns null if either component is non-integer
      if (tryHours != null && tryMinutes != null) {
        final Clock clock = Clock(hours: tryHours, minutes: tryMinutes);
        // Applies 24hr estimation at parse time so callers receive a fully resolved Clock
        clock.estimate24hrTime();
        return clock;
      }
    }
    return null;
  }

  /// Creates a [Clock] from the time components of a [DateTime].
  ///
  /// Parameters:
  /// - [date]: The [DateTime] whose [DateTime.hour] and [DateTime.minute] are used
  ///
  /// Returns: A [Clock] matching the time of [date]
  static Clock fromDateTime(DateTime date) {
    return Clock(hours: date.hour, minutes: date.minute);
  }

  /// Creates a [DateTime] using [reference]'s date and this clock's time.
  ///
  /// Parameters:
  /// - [reference]: The [DateTime] whose year, month, and day are used
  ///
  /// Returns: A [DateTime] on [reference]'s date at this clock's time
  DateTime toDateTime(DateTime reference) {
    return DateTime(
        reference.year, reference.month, reference.day, hours, minutes);
  }

  /// Converts this clock from 12hr to 24hr time by estimation.
  ///
  /// If [hours] is 3 or below, the time is assumed to be a PM hour that was
  /// parsed without a suffix (e.g. `1:00` → `13:00`, `3:30` → `15:30`).
  /// Hours above 3 are left unchanged on the assumption they are already correct.
  ///
  /// This is a heuristic tuned for typical school schedule hours
  /// (roughly 8:00 AM to 3:30 PM) — it is not a general 12hr→24hr converter.
  /// Called automatically by [parse] so callers always receive a 24hr [Clock].
  void estimate24hrTime() {
    // Hours of 3 or below are treated as early-afternoon PM times
    if (hours <= 3) {
      add(deltaHours: 12);
    }
  }
}