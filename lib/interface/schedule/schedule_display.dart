/*
  * schedule_display.dart *
  Main page which displays the schedule.
  Consists of multiple Widgets which come together to form Schedule page.
  References other files under schedule_display for Widgets.
*/
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xschedule/backend/rss/rss.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/materials/icon_circle.dart';
import 'package:xschedule/materials/styled_button.dart';
import 'package:xschedule/schedule/schedule.dart';
import 'package:xschedule/interface/schedule/calendar_navigation.dart';
import 'package:xschedule/interface/schedule/schedule_display_card.dart';
import 'package:xschedule/interface/schedule/schedule_info_display.dart';
import 'package:xschedule/interface/schedule/schedule_settings/schedule_settings.dart';
import 'package:xschedule/util/tutorial_system.dart';

/// Main page which displays the schedules. <p>
/// Features an AppBar with navigation and info and a PageView for all different schedules.
class ScheduleDisplay extends StatefulWidget {
  const ScheduleDisplay({super.key});

  // The current date, ignoring time
  static DateTime initialDate = DateTime.now().dateOnly();

  // A date verified to have a schedule for the tutorial; TBD
  static DateTime? tutorialDate;

  // pageIndex of Schedule PageView
  static int pageIndex = 0;

  // ScheduleDisplay Stream
  static StreamController<StreamSignal> scheduleStream =
      StreamController<StreamSignal>();

  // TutorialSystem used in ScheduleDisplay
  static final TutorialSystem tutorialSystem = TutorialSystem({
    'tutorial_schedule':
        "In this menu, you'll be able to see the schedule of any school day out of the year.",
    'tutorial_schedule_bell':
        'Each individual bell is set to match the information you provided about your class schedule, and clicking on any bell will display more information about it.',
    'tutorial_schedule_flex':
        'Additionally, you can tap the Flex bell to view information about lunch, clubs, and more!',
    'tutorial_schedule_date':
        "Up top, you'll find the date you're currently viewing. You can use the buttons or simple swiping gestures to flip between days.",
    'tutorial_schedule_calendar':
        "... or click this button to quickly navigate through the school days of the year.",
    'tutorial_schedule_info':
        "Tap this button to view important information about a school day, if available.",
    'tutorial_schedule_settings':
        'Lastly, if you ever want to edit your class information, you can do so by clicking this button.'
  });

  @override
  State<ScheduleDisplay> createState() => _ScheduleDisplayState();
}

class _ScheduleDisplayState extends State<ScheduleDisplay> {
  // Page uses PageController system with set amount of pages, starting in the middle to provide a "negative index" scroll effect
  // # of pages to display on PageView (3 years)
  static const int maxPages = 1095;

  // Starting page (middle of PageView; 1.5 years in)
  static const int initialPage = 547;

  // PageView controller; initial page with set index from "0"
  final PageController _controller =
      PageController(initialPage: initialPage + ScheduleDisplay.pageIndex);

  // On Widget disposed, also dispose of timer and PageController
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  // Method which begins the ScheduleDisplay tutorial
  Future<void> _showTutorial(BuildContext context) async {
    // awaits the fetching of schedule data before starting
    while (ScheduleDirectory.schedules.isEmpty) {
      // wait .1 seconds before checking again for Thread resting
      await Future.delayed(Duration(milliseconds: 100));
    }
    // Verify that >= .25 seconds have been waited for any page animation to finish
    await Future.delayed(const Duration(milliseconds: 250));
    if (!ScheduleDisplay.tutorialSystem.finished) {
      if (ScheduleDisplay.tutorialDate == null) {
        // Temporary counting int for determining tutorialDate
        int index = 0;
        while (index <= 25 && ScheduleDisplay.tutorialDate == null) {
          // Checks dates of both positive and negative count index from starting date for schedule
          if (ScheduleDirectory.readSchedule(
                  ScheduleDisplay.initialDate.addDay(index))
              .containsClasses(tutorial: true)) {
            break;
          }
          if (ScheduleDirectory.readSchedule(
                  ScheduleDisplay.initialDate.addDay(-index))
              .containsClasses(tutorial: true)) {
            index = -index;
            break;
          }
          // Increment index
          index++;
        }
        // If index != 26, schedule was found
        if (index != 26) {
          setState(() {
            ScheduleDisplay.tutorialDate =
                ScheduleDisplay.initialDate.addDay(index);
          });
        }
      } else {
        int index =
            ScheduleDisplay.tutorialDate!.day - ScheduleDisplay.initialDate.day;
        // if animation needs to occur, run it and end
        if (index != ScheduleDisplay.pageIndex) {
          // Set pageIndex to determined index, then animate page
          ScheduleDisplay.pageIndex = index;
          _controller.animateToPage(initialPage + index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut);
        } else if (context.mounted) {
          // ...else begin tutorial
          ScheduleDisplay.tutorialSystem.showTutorials(context);
          ScheduleDisplay.tutorialSystem.finish();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Refreshes tutorialSystem GlobalKeys
    ScheduleDisplay.tutorialSystem.refreshKeys();
    ScheduleDisplay.tutorialSystem.removeFinished();

    // Runs addDailyData asynchronously on page moved; may do nothing at all if ranges overlap
    ScheduleDirectory.addDailyData(
        ScheduleDisplay.initialDate.addDay(ScheduleDisplay.pageIndex - 25),
        ScheduleDisplay.initialDate.addDay(ScheduleDisplay.pageIndex + 25));
    // Refreshes stream
    ScheduleDisplay.scheduleStream = StreamController();
    // ScheduleDisplay wrapped in StreamBuilder
    return StreamBuilder(
        stream: ScheduleDisplay.scheduleStream.stream,
        builder: (context, snapshot) {
          // ScheduleDisplay wrapped in Showcase View
          return ShowCaseWidget(onComplete: (_, __) {
            ScheduleDisplay.tutorialSystem.finish();
          }, builder: (context) {
            // Schedule tutorial to begin after widget finished building
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _showTutorial(context);
            });
            // ScheduleDisplay
            return Scaffold(
                backgroundColor: colorScheme.primaryContainer,
                // Body as Column w/ TopBar, PageView, and settings button
                body: Column(
                  children: [
                    // The TopBar containing calendar button, current viewing date, and info button
                    Container(
                      // Row w/ margin set to compensate for device safeZone
                      margin: EdgeInsets.only(
                          top: 8 + mediaQuery.padding.top, bottom: 8),
                      height: 50,
                      alignment: Alignment.center,
                      // TopBar
                      child: _buildTopBar(context),
                    ),
                    // Schedule PageView set to take up remaining column space
                    Expanded(child: _buildPageView(context)),
                    // ScheduleSettings Button
                    Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: mediaQuery.size.width * .3),
                      height: 30,
                      // Button wrapped in ShowCase
                      child: ScheduleDisplay.tutorialSystem.showcase(
                          context: context,
                          tutorial: 'tutorial_schedule_settings',
                          child: StyledButton(
                            width: mediaQuery.size.width * .6,
                            icon: Icons.settings,
                            backgroundColor: colorScheme.secondary,
                            contentColor: colorScheme.onSecondary,
                            onTap: () {
                              ScheduleDirectory.readStoredSchedule();
                              // Push animated page of ScheduleSettings
                              context.pushSwipePage(const ScheduleSettings(
                                backArrow: true,
                              ));
                            },
                          )),
                    ),
                    // Bottom padding of 8px
                    const SizedBox(height: 8)
                  ],
                ));
          });
        });
  }

  // Builds the TopBar containing the calendar button, date title, and info button
  Widget _buildTopBar(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Simple row of buttons and title
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Calendar button w/ padding
        Padding(
          padding: const EdgeInsets.only(left: 16),
          // Calendar button wrapped in Showcase
          child: ScheduleDisplay.tutorialSystem.showcase(
              context: context,
              circular: true,
              tutorial: 'tutorial_schedule_calendar',
              // Calendar IconCircle (serves as button)
              child: IconCircle(
                  icon: Icons.calendar_month,
                  iconColor: colorScheme.onSurface,
                  color: colorScheme.tertiary.withValues(alpha: 0.4),
                  radius: 20,
                  padding: 10,
                  onTap: () {
                    // Pushes the calendar navigation popup
                    _pushCalendarNav();
                  })),
        ),
        // Current Date Navigator wrapped in Showcase
        ScheduleDisplay.tutorialSystem.showcase(
            context: context,
            tutorial: 'tutorial_schedule_date',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left Arrow IconButton
                _buildNavButton(context, -1),
                // Date Title is SizedBox
                SizedBox(
                  width: mediaQuery.size.width - 220,
                  child: Text(
                    ScheduleDisplay.initialDate
                        .addDay(ScheduleDisplay.pageIndex)
                        .dateText(),
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 32.5,
                        color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ).fit(),
                ),
                // Right Arrow IconButton
                _buildNavButton(context, 1),
              ],
            )),
        // Info button w/ padding
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ScheduleDisplay.tutorialSystem.showcase(
              context: context,
              circular: true,
              tutorial: 'tutorial_schedule_info',
              // Info Button
              child: _buildInfoButton(context)),
        ),
      ],
    );
  }

  // Loading wheel which appears while fetching data
  Widget _buildLoading(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Remaining height on page for card
    final double cardHeight = mediaQuery.size.height -
        200 -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    // Returns Loading Wheel of set size aligned at center of space
    return Container(
      height: cardHeight,
      alignment: Alignment.center,
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  // Pseudo-PageView which displays all schedule cards
  Widget _buildPageView(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Returns PageView which builds schedule cards by index
    return PageView.builder(
        controller: _controller,
        physics: const PageScrollPhysics(),
        // When page index changes, updates pageIndex variable
        onPageChanged: (i) {
          setState(() {
            ScheduleDisplay.pageIndex = i - initialPage;
          });
        },
        // # of pages to ~1000, creating pseudo-endless scrolling effect in both directions
        itemCount: maxPages,
        // Builds the schedules based on given index (i)
        itemBuilder: (_, i) {
          // The date of the schedule by index (currentDate+index)
          final DateTime date =
              ScheduleDisplay.initialDate.addDay(i - initialPage);

          // Schedule card wrapped in GestureDetector
          return GestureDetector(
            // On long tap, animate to current date schedule
            onLongPress: () {
              _controller.animateToPage(
                  (_controller.page! - ScheduleDisplay.pageIndex).floor(),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut);
              ScheduleDisplay.pageIndex = 0;
            },
            // Vertical swipe listener
            onVerticalDragEnd: (detail) {
              // If swipe up, animate to next page (to correct people who try and do that fsr)
              if (detail.primaryVelocity! < 0) {
                _controller.animateToPage((_controller.page! + 1).floor(),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
                ScheduleDisplay.pageIndex++;
              } else {
                // If swipe down, bring up calendar navigation popup
                _pushCalendarNav();
              }
            },
            // Schedule Builder wrapped in Decoration Container
            child: Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
              // Decoration with simple offset shadow
              decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: colorScheme.surfaceContainer,
                        blurRadius: 3,
                        spreadRadius: 1),
                    BoxShadow(
                        color: colorScheme.surfaceContainer,
                        offset: const Offset(2.25, 2.25))
                  ]),
              // If schedule data is empty, return FutureBuilder for schedule, else simply display schedule
              child: ScheduleDirectory.schedules.isEmpty
                  // FutureBuilder, which displays placeholder (loading wheel) while data is fetched asynchronously, then replaced by schedule
                  ? _buildLoading(context)
                  // ...else simply display schedule
                  : ScheduleDisplayCard(date: date),
            ),
          );
        });
  }

  // Builds the arrow buttons for swapping between pages
  Widget _buildNavButton(BuildContext context, int direction) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Returns Arrow Icon Button
    return IconButton(
      // When pressed, animates to new page
      onPressed: () {
        // If forwards == true, animates to next page, if not, animates backwards
        _controller.animateToPage(_controller.page!.round() + direction,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut);
      },
      // If forwards == true, displays forward arrow, if not, backwards arrow
      icon:
          Icon(direction > 0 ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
      color: colorScheme.onSurface,
    );
  }

  // Builds the info popup button
  Widget _buildInfoButton(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Schedule schedule = ScheduleDirectory.readSchedule(
        ScheduleDisplay.initialDate.addDay(ScheduleDisplay.pageIndex));

    Color iconColor = colorScheme.onSurface;
    Color backgroundColor = colorScheme.tertiary.withAlpha(128);

    if (RSS.offline) {
      iconColor = colorScheme.onError;
      backgroundColor = colorScheme.error.withAlpha(194);
    } else if (schedule.info.isEmpty) {
      iconColor = iconColor.withAlpha(128);
    }

    // Returns IconCircle of info button
    return IconCircle(
        // Simple info icon
        icon: Icons.info_outline,
        // Icon opacity changes w/ info available
        iconColor: iconColor,
        color: backgroundColor,
        radius: 20,
        padding: 5,
        // OnTap, pushes info popup
        onTap: () {
          context.pushPopup(ScheduleInfoDisplay(
              date: ScheduleDisplay.initialDate
                  .addDay(ScheduleDisplay.pageIndex)));
        });
  }

  void _pushCalendarNav() {
    context.pushPopup(
        CalendarNavigation(
            initialDate: ScheduleDisplay.initialDate,
            currentDate:
                ScheduleDisplay.initialDate.addDay(ScheduleDisplay.pageIndex),
            onSelect: (date) {
              final int change = ScheduleDisplay.initialDate
                  .addDay(ScheduleDisplay.pageIndex)
                  .difference(date)
                  .inDays;
              ScheduleDisplay.pageIndex -= change;

              _controller.animateToPage(_controller.page!.round() - change,
                  duration:
                      Duration(milliseconds: change.abs() < 10 ? 250 : 1000),
                  curve: Curves.easeInOut);
            }),
        begin: Offset(0, -1));
  }
}
