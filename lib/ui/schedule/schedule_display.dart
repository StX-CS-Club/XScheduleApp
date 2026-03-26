import 'dart:async';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/schedule/schedule_storage.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/widgets/icon_circle.dart';
import 'package:xschedule/widgets/styled_button.dart';
import 'package:xschedule/ui/schedule/calendar_navigation.dart';
import 'package:xschedule/ui/schedule/schedule_display_card.dart';
import 'package:xschedule/ui/schedule/schedule_info_button.dart';
import 'package:xschedule/ui/schedule/schedule_settings/schedule_settings_page.dart';
import 'package:xschedule/util/tutorial_system.dart';

/// The main schedule page, displaying a swipeable [PageView] of daily schedules.
///
/// Responsibilities:
/// - Holding shared static state (current date, page index, stream, tutorial system)
/// - Rendering a [PageView] of [ScheduleDisplayCard]s, one per calendar day
/// - Providing a top bar with date navigation, calendar popup, and info button
/// - Managing and sequencing the first-launch tutorial flow
class ScheduleDisplay extends StatefulWidget {
  const ScheduleDisplay({super.key});

  /// Today's date with time stripped; serves as the anchor for all page index calculations.
  static DateTime initialDate = DateTime.now().dateOnly();

  /// A date confirmed to have tutorial-valid classes; determined lazily on first tutorial run.
  static DateTime? tutorialDate;

  /// The currently visible page offset from [initialDate]; negative values are in the past.
  static int pageIndex = 0;

  /// Stream used to trigger rebuilds of [ScheduleDisplay] from external sources.
  static StreamController<StreamSignal> scheduleStream =
  StreamController<StreamSignal>();

  /// The [TutorialSystem] managing all showcase steps on the schedule page.
  ///
  /// Keys map tutorial IDs to their display strings shown during the walkthrough.
  static late TutorialSystem tutorialSystem;

  @override
  State<ScheduleDisplay> createState() => _ScheduleDisplayState();
}

/// The private [State] for [ScheduleDisplay].
///
/// Responsibilities:
/// - Owning and disposing the [PageController]
/// - Initialising the [scheduleStream] once on mount
/// - Running the tutorial sequence after schedule data is available
/// - Building the top bar, page view, and settings button
class _ScheduleDisplayState extends State<ScheduleDisplay> {
  // Uses a large fixed page count centered at [pageMidpoint] to simulate
  // endless scrolling in both directions without a true infinite list

  /// Total number of pages in the [PageView] (~3 years of days).
  static const int pageCount = 1095;

  /// The page index representing today; pages before/after map to negative/positive offsets.
  static const int pageMidpoint = 547;

  /// Controls the [PageView]; initialized at [pageMidpoint] plus any previously saved [pageIndex].
  final PageController _pageController =
  PageController(initialPage: pageMidpoint + ScheduleDisplay.pageIndex);

  @override
  void initState() {
    super.initState();
    // Initialise stream once here rather than recreating it on every build
    ScheduleDisplay.scheduleStream = StreamController<StreamSignal>();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  /// Searches up to 25 days forward and backward from [initialDate] for a date
  /// with tutorial-valid classes (i.e. at least one standard bell and one flex bell).
  ///
  /// Returns: The nearest such [DateTime], or `null` if none found within range
  DateTime? _findNearestTutorialDate() {
    for (int dayOffset = 0; dayOffset <= 25; dayOffset++) {
      if (ScheduleDirectory.readSchedule(
          ScheduleDisplay.initialDate.addDay(dayOffset))
          .containsClasses(tutorial: true)) {
        return ScheduleDisplay.initialDate.addDay(dayOffset);
      }
      // Skip the negative check on the first iteration (addDay(0) == addDay(-0))
      if (dayOffset > 0 &&
          ScheduleDirectory.readSchedule(
              ScheduleDisplay.initialDate.addDay(-dayOffset))
              .containsClasses(tutorial: true)) {
        return ScheduleDisplay.initialDate.addDay(-dayOffset);
      }
    }
    return null;
  }

  /// Orchestrates the tutorial sequence after the widget is built and data is loaded.
  ///
  /// This method:
  /// - Polls until [ScheduleDirectory.schedules] is populated
  /// - Waits an additional 250ms for any in-progress page animation to settle
  /// - On first run, finds and sets [tutorialDate] via [_findNearestTutorialDate]
  /// - On subsequent runs, animates to [tutorialDate] if not already there, then starts the tutorial
  ///
  /// Parameters:
  /// - [context]: The [BuildContext] used to trigger the showcase; must be [mounted] before use
  Future<void> _showTutorial(BuildContext context) async {
    // Poll until schedule data is available; 100ms delay avoids busy-spinning the thread
    while (ScheduleDirectory.schedules.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // Ensure any page animation has finished before proceeding
    await Future.delayed(const Duration(milliseconds: 250));

    if (ScheduleDisplay.tutorialSystem.finished) return;

    if (ScheduleDisplay.tutorialDate == null) {
      // First run: find and persist the nearest tutorial-valid date
      final DateTime? found = _findNearestTutorialDate();
      if (found != null) {
        setState(() {
          ScheduleDisplay.tutorialDate = found;
        });
      }
    } else {
      final int dayOffset =
          ScheduleDisplay.tutorialDate!.day - ScheduleDisplay.initialDate.day;
      if (dayOffset != ScheduleDisplay.pageIndex) {
        // Animate to the tutorial date; _showTutorial will re-run after the animation settles
        ScheduleDisplay.pageIndex = dayOffset;
        _pageController.animateToPage(pageMidpoint + dayOffset,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut);
      } else if (context.mounted) {
        // Already on the correct date — begin the tutorial
        ScheduleDisplay.tutorialSystem.showTutorials(context);
        ScheduleDisplay.tutorialSystem.finish();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Refresh showcase GlobalKeys and remove any already-completed steps
    ScheduleDisplay.tutorialSystem.refreshKeys();
    ScheduleDisplay.tutorialSystem.removeFinished();

    // Wrap in StreamBuilder so external signals can trigger a full rebuild
    return StreamBuilder(
        stream: ScheduleDisplay.scheduleStream.stream,
        builder: (context, snapshot) {
          // Wrap in ShowCaseWidget to enable showcase step rendering
          return ShowCaseWidget(onComplete: (_, __) {
            ScheduleDisplay.tutorialSystem.finish();
          }, builder: (context) {
            // Queue tutorial to start after this frame's layout is complete
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _showTutorial(context);
            });
            return Scaffold(
                backgroundColor: colorScheme.primaryContainer,
                body: Column(
                  children: [
                    // Top bar: calendar button, date navigator, info button
                    Container(
                      // Top margin compensates for device safe zone
                      margin: EdgeInsets.only(
                          top: 8 + mediaQuery.padding.top, bottom: 8),
                      height: 50,
                      alignment: Alignment.center,
                      child: _buildTopBar(context),
                    ),
                    // Schedule PageView fills remaining vertical space
                    Expanded(child: _buildPageView(context)),
                    // Settings button centered at the bottom
                    Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: mediaQuery.size.width * .3),
                      height: 30,
                      child: ScheduleDisplay.tutorialSystem.showcase(
                          context: context,
                          tutorial: 'schedule:settings',
                          child: StyledButton(
                            width: mediaQuery.size.width * .6,
                            icon: Icons.settings,
                            backgroundColor: colorScheme.secondary,
                            contentColor: colorScheme.onSecondary,
                            onTap: () {
                              ScheduleStorage.restore();
                              context.pushSwipePage(const ScheduleSettingsPage(
                                showBackArrow: true,
                              ));
                            },
                          )),
                    ),
                    const SizedBox(height: 8)
                  ],
                ));
          });
        });
  }

  /// Builds the top bar containing the calendar button, date navigator, and info button.
  ///
  /// Appearance: A horizontal [Row] spanning the full width with items spaced apart;
  /// calendar icon on the left, date title with arrows in the center, info icon on the right.
  Widget _buildTopBar(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Calendar button — opens [CalendarNavigation] popup
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: ScheduleDisplay.tutorialSystem.showcase(
              context: context,
              circular: true,
              tutorial: 'schedule:calendar',
              child: IconCircle(
                  icon: Icons.calendar_month,
                  iconColor: colorScheme.onSurface,
                  color: colorScheme.tertiary.withValues(alpha: 0.4),
                  radius: 20,
                  padding: 10,
                  onTap: () {
                    _pushCalendarNav();
                  })),
        ),
        // Date navigator: left arrow, current date text, right arrow
        ScheduleDisplay.tutorialSystem.showcase(
            context: context,
            tutorial: 'schedule:date',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavButton(context, -1),
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
                _buildNavButton(context, 1),
              ],
            )),
        // Info button — opens [ScheduleInfoDisplay] popup for the current date
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ScheduleDisplay.tutorialSystem.showcase(
              context: context,
              circular: true,
              tutorial: 'schedule:info',
              child: ScheduleInfoButton(
                date: ScheduleDisplay.initialDate
                    .addDay(ScheduleDisplay.pageIndex),
              )),
        ),
      ],
    );
  }

  /// Builds a centered loading spinner shown while schedule data is being fetched.
  ///
  /// Appearance: A 20×20 [CircularProgressIndicator] centered in the full card height.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme] and [MediaQueryData]
  Widget _buildLoadingIndicator(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Match the card height so the spinner is vertically centered in the same space
    final double cardHeight = mediaQuery.size.height -
        200 -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

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

  /// Returns the [BoxDecoration] applied to each schedule card container in the [PageView].
  ///
  /// Parameters:
  /// - [colorScheme]: Used to derive surface and shadow colors
  BoxDecoration _cardDecoration(ColorScheme colorScheme) => BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
          color: colorScheme.surfaceContainer,
          blurRadius: 3,
          spreadRadius: 1),
      BoxShadow(
          color: colorScheme.surfaceContainer,
          offset: const Offset(2.25, 2.25)),
    ],
  );

  /// Builds the [PageView] that displays one [ScheduleDisplayCard] per calendar day.
  ///
  /// Appearance: Full-height swipeable cards with rounded corners and a drop shadow.
  /// Long press returns to today; swipe up advances one page; swipe down opens [CalendarNavigation].
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  Widget _buildPageView(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PageView.builder(
        controller: _pageController,
        physics: const PageScrollPhysics(),
        onPageChanged: (pageIndex) {
          setState(() {
            ScheduleDisplay.pageIndex = pageIndex - pageMidpoint;
          });
          // Extend the loaded schedule data window around the new position
          ScheduleDirectory.addDailyData(
              ScheduleDisplay.initialDate
                  .addDay(ScheduleDisplay.pageIndex - 25),
              ScheduleDisplay.initialDate
                  .addDay(ScheduleDisplay.pageIndex + 25));
        },
        // ~1000 pages simulates an endless scroll in both directions
        itemCount: pageCount,
        itemBuilder: (_, pageIndex) {
          // Derive the calendar date for this page from its offset to initialDate
          final DateTime date =
          ScheduleDisplay.initialDate.addDay(pageIndex - pageMidpoint);

          return GestureDetector(
            // Long press: return to today's page
            onLongPress: () {
              _pageController.animateToPage(
                  (_pageController.page! - ScheduleDisplay.pageIndex).floor(),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut);
              ScheduleDisplay.pageIndex = 0;
            },
            onVerticalDragEnd: (drag) {
              if (drag.primaryVelocity! < 0) {
                // Swipe up: advance to next page (catches users who swipe vertically by habit)
                _pageController.animateToPage(
                    (_pageController.page! + 1).floor(),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
                ScheduleDisplay.pageIndex++;
              } else {
                // Swipe down: open calendar navigation popup
                _pushCalendarNav();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
              decoration: _cardDecoration(colorScheme),
              // Show spinner while data loads, then swap to the schedule card
              child: ScheduleDirectory.schedules.isEmpty
                  ? _buildLoadingIndicator(context)
                  : ScheduleDisplayCard(scContext: context, date: date),
            ),
          );
        });
  }

  /// Builds a single directional navigation arrow button for the date navigator.
  ///
  /// Appearance: An [IconButton] showing a forward or back iOS-style arrow.
  ///
  /// Parameters:
  /// - [context]: Used to resolve [ColorScheme]
  /// - [direction]: `1` for forward (right arrow), `-1` for backward (left arrow)
  Widget _buildNavButton(BuildContext context, int direction) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () {
        _pageController.animateToPage(
            _pageController.page!.round() + direction,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut);
      },
      icon:
      Icon(direction > 0 ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
      color: colorScheme.onSurface,
    );
  }

  /// Pushes the [CalendarNavigation] popup, sliding in from the top.
  ///
  /// On date selection, animates the [PageView] to the chosen date.
  /// Animation duration scales with distance: fast for nearby dates, slow for distant ones.
  void _pushCalendarNav() {
    context.pushPopup(
        CalendarNavigation(
            initialDate: ScheduleDisplay.initialDate,
            currentDate:
            ScheduleDisplay.initialDate.addDay(ScheduleDisplay.pageIndex),
            onSelect: (date) {
              final int newIndex = date.dayDiff(ScheduleDisplay.initialDate);
              ScheduleDisplay.pageIndex = newIndex;
              _pageController.animateToPage(
                  pageMidpoint + newIndex,
                  duration: Duration(
                      milliseconds: (newIndex - ScheduleDisplay.pageIndex).abs() < 10 ? 250 : 1000),
                  curve: Curves.easeInOut);
            }),
        begin: Offset(0, -1));
  }
}