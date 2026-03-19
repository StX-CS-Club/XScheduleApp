/*
  * splash_page.dart *
  Temporary destination page of the app which appears while it determines where to send the user.
  Displays static load featuring logo while loading.
  Currently useless, considering destination is determined synchronously.
*/
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:xschedule/startup/home_page.dart';
import 'package:xschedule/materials/static_load.dart';
import 'package:xschedule/startup/welcome_page.dart';

/// Splash page which appears while determining destination <p>
/// Displays the logo on a beige background while the destination is determined.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  // Determines where to send the user based on app history status
  static void determineDestination(BuildContext context) {
    // Sends user to Welcome if not logged, else sends them to home page
    if (localStorage.getItem("state") != "logged") {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Welcome()), (_) => false);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Schedules reroute post build
    WidgetsBinding.instance.addPostFrameCallback((_){
      determineDestination(context);
    });
    // Basic scaffold displaying logo while app loads (as of right now, practically unused)
    return StaticLoad();
  }
}
