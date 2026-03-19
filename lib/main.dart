/*
  * main.dart *
  Entry point of XSchedule app. Runs initialization processes and builds the app.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xschedule/startup/splash_page.dart';
import 'package:xschedule/startup/themes.dart';
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/extensions/date_time_extension.dart';
import 'package:xschedule/interface/personal/credits.dart';
import 'package:xschedule/interface/schedule/schedule_display.dart';
import 'package:xschedule/backend/rss/rss.dart';

Future<void> main() async {
  // Initializes several processes in the app
  await init();

  // Creates the Flutter app itself
  runApp(const XScheduleApp());
}

/// App Initialization Process. <p>
/// Interprets json file data, initializes communication with backend
Future<void> init() async {
  // Ensures Flutter is ready-to-go
  WidgetsFlutterBinding.ensureInitialized();

  await configAndroid();
  // Initializes local storage; Runs synchronously since local storage is essential
  await initLocalStorage();
  ScheduleDirectory.readStoredSchedule();

  // Reads the various data from local json files asynchronously
  //GitHub.loadGithubJson();
  Credits.loadCreditsJson();
  await RSS.loadRSSJson();

  RSS.getDailyOrder(refreshStream: true, storeResults: true, overwrite: true).then((_) {
        ScheduleDisplay.scheduleStream.updateStream();
  });

  // Reads supabase.json and then initializes communication with the Supabase database
  /*
  SupaBaseDB.loadSupabaseJson().then((_) => SupaBaseDB.initialize());
  */

  // Fetches information about the build of the app; miniscule run duration
  Credits.packageInfo = await PackageInfo.fromPlatform();

  // Fetches schedule info from X via RSS and database for closest 101 days
  final DateTime now = DateTime.now();
  ScheduleDirectory.addDailyData(now.addDay(-50), now.addDay(50));

  // Fetches co-curricular data from X via RSS
  /*
  ScheduleDirectory.getCoCurriculars().then((result) {
    ScheduleDirectory.coCurriculars = result;
  });
   */
}

Future<void> configAndroid() async {
  // Sets screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
}

/// The base Flutter app <p>
/// Sets the theme, default text style, and default destination
class XScheduleApp extends StatelessWidget {
  const XScheduleApp({super.key});

  static const bool beta = bool.fromEnvironment("BETA", defaultValue: false);

  @override
  Widget build(BuildContext context) {
    // Returns the Flutter App
    return MaterialApp(
      theme: Themes.blueTheme,
      debugShowCheckedModeBanner: false,
      title: 'X-Schedule',
      // Sets the default text styling of the app
      home: const DefaultTextStyle(
        style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            decoration: null,
            // Any overflowing text fades out
            overflow: TextOverflow.fade),
        // Directs to the app's splash page to determine destination
        child: SplashPage(),
      ),
    );
  }
}
