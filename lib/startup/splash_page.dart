import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:xschedule/startup/home_page.dart';
import 'package:xschedule/widgets/static_load.dart';
import 'package:xschedule/startup/welcome_page.dart';

/// Transient splash page shown while the app determines where to send the user.
///
/// Responsibilities:
/// - Displays [StaticLoad] (logo on beige background) during the brief routing decision
/// - Reads the "state" key from local storage to decide the destination
/// - Navigates to [HomePage] if the user has previously logged in, or [WelcomePage] otherwise
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  /// Reads local storage state and immediately navigates to the correct destination.
  /// Replaces the entire navigation stack so the user cannot back-navigate to the splash.
  ///
  /// Parameters:
  /// - [context]: The current build context used for navigation.
  static void _navigateFromSplash(BuildContext context) {
    // Route to HomePage if previously logged in, otherwise to WelcomePage
    final Widget destination = localStorage.getItem("state") == "logged"
        ? const HomePage()
        : const WelcomePage();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Navigation must be deferred until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateFromSplash(context);
    });
    return const StaticLoad();
  }
}