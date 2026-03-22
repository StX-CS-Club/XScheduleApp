import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';

/// A popup calendar for quickly navigating to any school day within ±18 months.
///
/// Responsibilities:
/// - Displaying a month-by-month [PageView] of date dot grids
/// - Highlighting the currently viewed date and today's date with distinct colors
/// - Dimming dots for dates outside the page month or without a schedule
/// - Notifying the parent via [onSelect] when a date is tapped
class CalendarNavigation extends StatefulWidget {
  const CalendarNavigation(
      {super.key,
        required this.initialDate,
        required this.currentDate,
        required this.onSelect});

  /// Today's date; used as the anchor for month offset calculations and dot highlighting.
  final DateTime initialDate;

  /// The date currently viewed on the schedule page; highlighted with [ColorScheme.primary].
  final DateTime currentDate;

  /// Called with the selected [DateTime] when the user taps a date dot.
  final void Function(DateTime) onSelect;

  @override
  State<CalendarNavigation> createState() => _CalendarNavigationState();
}

/// Private [State] for [CalendarNavigation].
///
/// Responsibilities:
/// - Owning the [PageController] and [monthIndex] state
/// - Computing dot opacity and color for each rendered date
/// - Building the month header and date dot grid
class _CalendarNavigationState extends State<CalendarNavigation> {
  /// Total number of month pages (18 months back + current month + 18 months forward).
  static const int pageCount = 37;

  /// The page index of the current month; also the clamp bound for [monthIndex].
  static const int pageMidpoint = 18;

  /// Base opacity applied to all date dots regardless of other conditions.
  static const double _opacityBase = 0.05;

  /// Additional opacity for dots whose date falls within the page's month.
  static const double _opacityInMonth = 0.05;

  /// Additional opacity for dots whose date has a schedule with classes.
  static const double _opacityHasSchedule = 0.15;

  /// Opacity boost applied to the selected ([currentDate]) and today ([initialDate]) dots.
  static const double _opacitySelected = 0.60;

  /// The month offset from [initialDate] currently displayed; `0` = current month.
  late int monthIndex;

  /// Controls the month [PageView]; uses [NeverScrollableScrollPhysics] — gestures are custom.
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    monthIndex = widget.currentDate.monthDiff(widget.initialDate);
    _pageController = PageController(initialPage: pageMidpoint + monthIndex);
  }

  /// Clamps [page] to the valid range and animates the [PageView] to it.
  ///
  /// Parameters:
  /// - [page]: The desired month offset; clamped to `[-pageMidpoint, pageMidpoint]`
  void _setPage(int page) {
    final int clamped = page.clamp(-pageMidpoint, pageMidpoint);
    setState(() => monthIndex = clamped);
    _pageController.animateToPage(pageMidpoint + clamped,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  /// Returns the additional opacity for a date dot based on month membership and schedule presence.
  ///
  /// Parameters:
  /// - [date]: The date the dot represents
  /// - [pageMonth]: The month this page displays; dots outside this month receive less opacity
  ///
  /// Returns: A [double] opacity increment to add on top of [_opacityBase]
  double _dotOpacity(DateTime date, DateTime pageMonth) {
    double dotOpacity = 0;
    if (date.month == pageMonth.month) dotOpacity += _opacityInMonth;
    if (ScheduleDirectory.readSchedule(date).containsClasses()) {
      dotOpacity += _opacityHasSchedule;
    }
    return dotOpacity;
  }

  /// Returns the dot background and text colors for a date based on its role.
  ///
  /// - [currentDate]: Primary color at high opacity (selected day)
  /// - [initialDate]: Secondary color at high opacity (today)
  /// - All others: Neutral dark dot at base opacity
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [date]: The date being rendered
  /// - [dotOpacity]: The additional opacity from [_dotOpacity], added to [_opacitySelected] or [_opacityBase]
  ///
  /// Returns: A record with [dot] and [text] [Color] values
  ({Color dot, Color text}) _dotColors(
      BuildContext context, DateTime date, double dotOpacity) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (date == widget.currentDate) {
      return (
      dot: colorScheme.primary
          .withValues(alpha: _opacitySelected + dotOpacity),
      text: colorScheme.onPrimary,
      );
    }
    if (date == widget.initialDate) {
      return (
      dot: colorScheme.secondary
          .withValues(alpha: _opacitySelected + dotOpacity),
      text: colorScheme.onSecondary,
      );
    }
    return (
    dot: Colors.black.withValues(alpha: _opacityBase + dotOpacity),
    text: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Popup dimensions proportional to screen width
    final double height = mediaQuery.size.width * 24 / 35;
    final double width = mediaQuery.size.width * 4 / 5;

    // The month currently displayed in the header
    final DateTime viewingMonth = DateTime(
        widget.initialDate.year, widget.initialDate.month + monthIndex);

    return Center(
      child: SizedBox(
        width: width,
        // 69px accounts for the header row height
        height: 69 + height,
        child: Card(
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header: left arrow, month/year title, right arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        iconSize: 25,
                        onPressed: () => _setPage(monthIndex - 1),
                        icon: Icon(Icons.arrow_back_ios,
                            color: colorScheme.onSurface)),
                    // Month and year text, fitted to available width
                    SizedBox(
                      width: min(125, width - 150),
                      height: 50,
                      child: Text(
                        "${viewingMonth.monthText()} ${viewingMonth.year}",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ).fit(),
                    ),
                    IconButton(
                        iconSize: 25,
                        onPressed: () => _setPage(monthIndex + 1),
                        icon: Icon(Icons.arrow_forward_ios,
                            color: colorScheme.onSurface)),
                  ],
                ),
                // Calendar grid wrapped in GestureDetector for swipe and long-press
                GestureDetector(
                  // Long press: return to the current month
                  onLongPress: () => _setPage(0),
                  // Horizontal swipe: navigate forward or backward one month
                  onHorizontalDragEnd: (details) => _setPage(
                      monthIndex - details.primaryVelocity!.sign.round()),
                  // PageView.builder ensures only visible pages are built
                  child: Container(
                    color: colorScheme.surfaceContainer,
                    height: height,
                    width: width,
                    child: PageView.builder(
                      controller: _pageController,
                      // Standard scroll is disabled; GestureDetector provides snappier physics
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pageCount,
                      itemBuilder: (_, monthOffset) =>
                          _buildMonth(monthOffset - pageMidpoint),
                    ),
                  ),
                )
              ],
            ).clip(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  /// Builds a single month page as a column of up to 6 week rows.
  ///
  /// Appearance: A centered [Column] of [Row]s, each containing 7 tappable [CircleAvatar]
  /// date dots. Rows with no dates in [pageMonth] are skipped entirely.
  ///
  /// Parameters:
  /// - [monthOffset]: The signed month offset from [initialDate] this page represents
  Widget _buildMonth(int monthOffset) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Dot radius derived from popup width so dots fill the grid evenly (28 = 7 dots × 4 units each)
    final double radius = (mediaQuery.size.width * 4 / 5 - 10) / 28;

    /// The month this page represents.
    final DateTime pageMonth = DateTime(
        widget.initialDate.year, widget.initialDate.month + monthOffset);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(6, (weekIndex) {
        // The Sunday-anchored start date of this week row
        final DateTime weekStart = DateTime(pageMonth.year, pageMonth.month,
            weekIndex * 7 - pageMonth.weekday + 1);

        // Skip rows entirely outside the page's month
        if (weekStart.month != pageMonth.month &&
            weekStart.addDay(6).month != pageMonth.month) {
          return Container();
        }

        // Build 7 date dots for the week
        return Row(
          children: List<Widget>.generate(7, (dayIndex) {
            final DateTime date = weekStart.addDay(dayIndex);
            final double dotOpacity = _dotOpacity(date, pageMonth);
            final colors = _dotColors(context, date, dotOpacity);

            // Tappable date dot: dismisses popup and notifies parent
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onSelect(date);
              },
              child: Padding(
                padding: EdgeInsets.all(radius),
                child: CircleAvatar(
                  backgroundColor: colors.dot,
                  radius: radius,
                  child: Text(date.day.toString(),
                      style: TextStyle(
                          color: colors.text, fontFamily: "Georama"))
                      .fit(),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}