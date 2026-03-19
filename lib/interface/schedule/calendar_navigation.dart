import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';

class CalendarNavigation extends StatefulWidget {
  const CalendarNavigation(
      {super.key,
      required this.initialDate,
      required this.currentDate,
      required this.onSelect});

  final DateTime initialDate;
  final DateTime currentDate;
  final void Function(DateTime) onSelect;

  @override
  State<CalendarNavigation> createState() => _CalendarNavigationState();
}

class _CalendarNavigationState extends State<CalendarNavigation> {
  late int monthIndex;

  late PageController _controller;

  @override
  void initState() {
    super.initState();
    monthIndex = widget.currentDate.monthDiff(widget.initialDate);
    _controller = PageController(initialPage: 18+monthIndex);
  }

  void _setPage(int page) {
    int pageIndex = page.clamp(-18, 18);

    setState(() {
      monthIndex = pageIndex;
    });

    _controller.animateToPage(18+pageIndex,
        duration: Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Sizing of popup
    final double height = mediaQuery.size.width * 24 / 35;
    final double width = mediaQuery.size.width * 4 / 5;

    print(monthIndex);
    DateTime newMonth = DateTime(
        widget.initialDate.year, widget.initialDate.month + monthIndex);
    // Popup of fixed size card aligned at center
    return Center(
      child: SizedBox(
        width: width,
        height: 69 + height,
        child: Card(
            color: colorScheme.surface,
            // Forces contents to match Card border shape
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title row consisting of month text amd navigator buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left Arrow IconButton
                    IconButton(
                        iconSize: 25,
                        onPressed: () => _setPage(monthIndex - 1),
                        // Simple left arrow icon
                        icon: Icon(Icons.arrow_back_ios,
                            color: colorScheme.onSurface)),
                    // Month text fitted to set size
                    SizedBox(
                      width: min(125, width - 150),
                      height: 50,
                      child: Text(
                        // Text in Month Year format
                        "${newMonth.monthText()} ${newMonth.year}",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ).fit(),
                    ),
                    // Right Arrow IconButton
                    IconButton(
                        iconSize: 25,
                        onPressed: () => _setPage(monthIndex + 1),
                        // Simple right arrow icon
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: colorScheme.onSurface,
                        )),
                  ],
                ),
                // Calendar view wrapped in GestureDetector
                GestureDetector(
                  // On long tap, return to starting month (similar to schedule PageView)
                  onLongPress: () => _setPage(0),
                  // On horizontal swipe, animate to next/last month
                  onHorizontalDragEnd: (details) => _setPage(
                      monthIndex - details.primaryVelocity!.sign.round()),
                  // Calendar view (generative PageView of set dimensions)
                  child: Container(
                    color: colorScheme.surfaceContainer,
                    height: height,
                    width: width,
                    child: PageView(
                      controller: _controller,
                      // Ignore standard scrolling; use GestureDetector for snappier physics
                      physics: const NeverScrollableScrollPhysics(),
                      // Generates pages of columns and rows of date dots
                      children: List<Widget>.generate(37, (i) => _buildMonth(i-18)),
                    ),
                  ),
                )
              ],
            ).clip(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildMonth(int index){
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Radius of date dot
    final double radius = (mediaQuery.size.width * 4 / 5 - 10) / 28;

    // DT month of page
    final DateTime iMonth =
    DateTime(widget.initialDate.year, widget.initialDate.month + index);

    // Returns column of generated rows
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      // Generated rows within column
      children: List<Widget>.generate(6, (e) {
        // DT month of row start
        final eMonth = DateTime(iMonth.year, iMonth.month,
            e * 7 - iMonth.weekday + 1);
        // Checks if week row being generated contains >= 1 date within the page's month
        if (eMonth.month != iMonth.month &&
            eMonth.addDay(6).month != iMonth.month) {
          return Container();
        }
        return Row(
          children: List<Widget>.generate(7, (n) {
            // DT of date dot
            DateTime dotDate = eMonth.addDay(n);

            // Determines opacity of date dot
            double opacity = 0;
            // If date in main month, add 5%
            if (dotDate.month == iMonth.month) {
              opacity += 0.05;
            }
            // If date has schedule, add 15%
            if (ScheduleDirectory.readSchedule(dotDate)
                .containsClasses()) {
              opacity += 0.15;
            }

            // Determines color of date dot
            Color dotColor = Colors.black
                .withValues(alpha: 0.05 + opacity);
            Color textColor = Colors.black;
            // Primary for selected date
            if (dotDate == widget.currentDate) {
              dotColor = colorScheme.primary
                  .withValues(alpha: 0.60 + opacity);
              textColor = colorScheme.onPrimary;
              // Secondary for current date
            } else if (dotDate == widget.initialDate) {
              dotColor = colorScheme.secondary
                  .withValues(alpha: 0.60 + opacity);
              textColor = colorScheme.onSecondary;
            }
            // Returns Date Dot
            return InkWell(
              // Pops popup and animates schedule to selected date
                onTap: () {
                  Navigator.pop(context);
                  print(dotDate.toString());
                  widget.onSelect(dotDate);
                },
                // Date Dot
                child: Padding(
                  padding: EdgeInsets.all(radius),
                  // Stack of background dot and date text
                  child: CircleAvatar(
                    backgroundColor: dotColor,
                    radius: radius,
                    child: Text(dotDate.day.toString(),
                        style:
                        TextStyle(color: textColor, fontFamily: "Georama")).fit(),
                  ),
                ));
          }),
        );
      }),
    );
  }
}