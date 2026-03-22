import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xschedule/schedule/schedule_storage.dart';
import 'package:xschedule/startup/splash_page.dart';
import 'package:xschedule/startup/themes.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/ui/personal/credits.dart';
import 'package:xschedule/ui/schedule/schedule_display.dart';
import 'package:xschedule/backend/rss/rss.dart';

/// Entry point of the application.
/// Runs initialization then launches the Flutter app.
Future<void> main() async {
  await init();
  runApp(const XScheduleApp());
}

/// Runs all startup processes required before the app is usable.
///
/// This method:
/// - Ensures Flutter bindings are ready
/// - Locks screen orientation to portrait
/// - Initializes local storage and reads any cached schedule
/// - Loads local JSON assets (credits, RSS config)
/// - Fetches the daily bell order from RSS and updates the schedule stream
/// - Reads app build info (version, build number)
/// - Fetches schedule data for a 101-day window centered on today
Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _lockPortrait();
  await initLocalStorage();
  ScheduleStorage.restore();

  // Load data from local json files
  Credits.loadCreditsJson();
  await RSS.loadRSSJson();

  RSS.getDailyOrder(refreshStream: true, storeResults: true, overwrite: true)
      .then((_) {
    ScheduleDisplay.scheduleStream.updateStream();
  });

  Credits.packageInfo = await PackageInfo.fromPlatform();

  // Fetch schedule info from X via RSS for the closest 101 days
  final DateTime now = DateTime.now();
  ScheduleDirectory.addDailyData(now.addDay(-50), now.addDay(50));
}

/// Locks the device to portrait-up orientation.
Future<void> _lockPortrait() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

/// Root widget of the XSchedule application.
///
/// Responsibilities:
/// - Applies the global [Themes.blueTheme]
/// - Sets a default [TextStyle] used across all descendant widgets
/// - Directs to [SplashPage] as the initial route
class XScheduleApp extends StatelessWidget {
  const XScheduleApp({super.key});

  /// Whether the app is running as a beta build.
  /// Set at compile time via the --dart-define=BETA=true flag.
  static const bool beta = bool.fromEnvironment("BETA", defaultValue: false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Themes.blueTheme,
      debugShowCheckedModeBanner: false,
      title: 'X-Schedule',
      // Sets the default text styling across the entire app
      home: const DefaultTextStyle(
        style: TextStyle(
          color: Colors.black,
          fontSize: 25,
          decoration: null,
          // Any overflowing text fades out
          overflow: TextOverflow.fade,
        ),
        // Directs to the splash page to determine the user's destination
        child: SplashPage(),
      ),
    );
  }
}