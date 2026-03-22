import 'dart:async';

import 'package:flutter/material.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/ui/schedule/schedule_display.dart';
import 'package:xschedule/ui/personal/personal_page.dart';

/// Main destination page of the app after login.
///
/// Responsibilities:
/// - Hosts a [PageView] that switches between [ScheduleDisplay] and [PersonalPage]
/// - Renders a custom bottom navigation bar with swipe and tap support
/// - Exposes a static [homePageStream] that external classes can signal to trigger a rebuild
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// Stream used to trigger a full rebuild of [HomePage] from anywhere in the app.
  /// Recreated on each build so listeners always receive fresh events.
  static StreamController<StreamSignal> homePageStream = StreamController();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// The ordered list of pages displayed in the [PageView].
  /// Index corresponds directly to the nav bar icon positions.
  static const List<Widget> _pages = [
    ScheduleDisplay(),
    PersonalPage(),
  ];

  /// Controls programmatic navigation between pages.
  final PageController _pageController = PageController(initialPage: 0);

  /// Tracks which page index is currently visible.
  /// Used to highlight the active nav bar icon and compute swipe targets.
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recreated on every rebuild so the stream is always fresh for new listeners
    HomePage.homePageStream = StreamController();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder(
      stream: HomePage.homePageStream.stream,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: colorScheme.primaryContainer,
          bottomNavigationBar: _buildNavBar(context),
          body: PageView(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPageIndex = i),
            children: _pages,
          ),
        );
      },
    );
  }

  /// Builds the bottom navigation bar.
  /// Wraps the bar in a [GestureDetector] to support horizontal swipe navigation
  /// in addition to icon taps.
  ///
  /// Parameters:
  /// - [context]: Used to read the current [ColorScheme].
  Widget _buildNavBar(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      // sign() gives -1, 0, or 1 based on swipe direction to select adjacent page
      onHorizontalDragEnd: (detail) {
        _pageController.animateToPage(
          _currentPageIndex - detail.primaryVelocity!.sign.round(),
          duration: const Duration(milliseconds: 125),
          curve: Curves.easeInOut,
        );
      },
      child: SizedBox(
        height: 65,
        child: Stack(
          children: [
            _buildNavBarBody(colorScheme),
            _buildNavBarGradient(colorScheme),
          ],
        ),
      ),
    );
  }

  /// Builds the tab icon row and background container, aligned to the bottom of the nav bar.
  ///
  /// Parameters:
  /// - [colorScheme]: Provides the [tertiaryContainer] background color.
  Widget _buildNavBarBody(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 62.5,
        color: colorScheme.tertiaryContainer,
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPageIcon(Icons.calendar_month, 0),
            _buildPageIcon(Icons.person, 1),
          ],
        ),
      ),
    );
  }

  /// Builds a soft shadow gradient at the top of the nav bar to visually blend with the page body.
  /// Uses four alpha stops to create a subtle fade effect.
  ///
  /// Parameters:
  /// - [colorScheme]: Provides the base [tertiary] color used in the gradient.
  Widget _buildNavBarGradient(ColorScheme colorScheme) {
    final Color base = colorScheme.tertiary;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              base.withValues(alpha: 0),
              base.withValues(alpha: 0.25),
              base.withValues(alpha: 0.125),
              base.withValues(alpha: 0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  /// Builds a single tappable nav bar icon.
  /// The icon is fully opaque when its page is active and 65% opaque otherwise.
  ///
  /// Parameters:
  /// - [icon]: The icon to display.
  /// - [index]: The page index this icon corresponds to.
  Widget _buildPageIcon(IconData icon, int index) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      },
      child: DecoratedIcon(
        decoration: IconDecoration(
          border: IconBorder(width: 2, color: colorScheme.onSurface),
        ),
        icon: Icon(
          icon,
          // Fully opaque when selected, 65% when not
          color: colorScheme.onPrimary.withValues(alpha: _currentPageIndex == index ? 1 : 0.65),
          size: 30,
        ),
      ),
    );
  }
}