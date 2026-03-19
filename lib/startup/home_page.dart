/*
  * home_page.dart *
  Base destination page of the app.
  Contains basic navigation bar and PageView of app's pages
*/
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/interface/personal/personal_page.dart';
import 'package:xschedule/interface/schedule/schedule_display.dart';


/// Basic destination page of the app <p>
/// Features a bottom navigation bar with page icons and body of a PageView.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // HomePage stream; allows static calling of HomePage refresh
  static StreamController<StreamSignal> homePageStream = StreamController();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // List of pages displayed in PageView
  static const List<Widget> pages = [
    ScheduleDisplay(),
    Personal(),
  ];

  // Controller of the PageView; allows access to variables and methods
  final PageController controller = PageController(initialPage: 0);

  // int value representing which page the pageView is on
  int pageIndex = 0;

  // On Widget disposed, dispose controller as well
  @override
  void dispose(){
    super.dispose();
    controller.dispose();
  }

  //Builds the HomePage
  @override
  Widget build(BuildContext context) {
    // Refreshes stream on rebuild
    HomePage.homePageStream = StreamController();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // HomePage wrapped in StreamBuilder; updates on stream update
    return StreamBuilder(
        stream: HomePage.homePageStream.stream,
        builder: (context, snapshot) {
          // HomePage
          return Scaffold(
            backgroundColor: colorScheme.primaryContainer,
            // Bottom Navigation Bar containing page icons
            bottomNavigationBar: _buildNavBar(context),
            // Body as PageView; body alternates between pages
            body: PageView(
              controller: controller,
              physics: const PageScrollPhysics(),
              // Once page changes, sets pageIndex to the new index
              onPageChanged: (i) {
                setState(() {
                  pageIndex = i;
                });
              },
              children: pages,
            ),
          );
        });
  }

  // Builds the bottom nav bar
  Widget _buildNavBar(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Color used in navbar gradient
    Color gradient = colorScheme.tertiary;

    // Returns NavBar wrapped in GestureDetector
    return GestureDetector(
      // Horizontal Swiping listener
      onHorizontalDragEnd: (detail) {
        // Changes page based on direction
        controller.animateToPage(
            pageIndex - detail.primaryVelocity!.sign.round(),
            duration: const Duration(milliseconds: 125),
            curve: Curves.easeInOut);
      },
      // NavBar w/ fixed Size
      child: SizedBox(
          height: 65,
          // Stack of NavBar body and gradient
          child: Stack(
            children: [
              // Body aligned to bottom
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 62.5,
                  color: colorScheme.tertiaryContainer,
                  padding: const EdgeInsets.only(bottom: 15),
                  // Row of page icons
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPageIcon(context, Icons.calendar_month, 0),
                      _buildPageIcon(context, Icons.person, 1),
                    ],
                  ),
                ),
              ),
              // Navbar gradient aligned at top
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                    gradient.withValues(alpha: 0),
                    gradient.withValues(alpha: 0.25),
                    gradient.withValues(alpha: 0.125),
                    gradient.withValues(alpha: 0)
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                ),
              ),
            ],
          )),
    );
  }

  // Builds the page icons in the bottom NavBar
  Widget _buildPageIcon(BuildContext context, IconData icon, int index) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return TextButton(
        // When pressed, animates PageView to the selected page
        onPressed: () {
          controller.animateToPage(index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut);
        },
        // DecoratedIcon to feature outline
        child: DecoratedIcon(
          // Outline decoration
            decoration: IconDecoration(
                border: IconBorder(width: 2, color: colorScheme.onSurface)),
            // Provided Icon
            icon: Icon(
              icon,
              //When page selected, icon is fully opaque and white; if not, only at 70% opacity
              color: colorScheme.onPrimary
                  .withValues(alpha: pageIndex == index ? 1 : 0.65),
              size: 30,
            )));
  }
}
