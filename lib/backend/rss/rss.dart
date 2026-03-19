import 'package:http/http.dart' as http;
import 'package:xschedule/schedule/schedule_directory.dart';
import 'package:xschedule/backend/rss/parsers/daily_order_parser.dart';
import 'package:xschedule/backend/rss/rss_client.dart';
import 'package:xschedule/backend/rss/rss_config.dart';
import 'package:xschedule/util/stream_signal.dart';
import 'package:xschedule/interface/schedule/schedule_display.dart';

/// Public facing API for RSS functionality
///
/// Responsibilities:
/// - Loading RSS configuration
/// - Fetching calendar data from the server
/// - Delegating parsing to [DailyOrderParser]
/// - Writing results to [ScheduleDirectory]
class RSS {
  /// Loaded configuration (URLs, retry codes, etc.)
  static late RSSConfig _config;

  /// Whether the app is currently considered offline.
  static bool get offline => RSSClient.offline;

  /// Whether [loadRSSJson] has been called.
  static bool get initialized => _initialized;

  static bool _initialized = false;

  /// Loads RSS configuration from `assets/data/rss.json`.
  ///
  /// Must be called before any network operations.
  static Future<void> loadRSSJson() async {
    _config = await RSSConfig.load();
    _initialized = true;
  }

  /// Ensures the class has been initialized before use.
  ///
  /// Throws a [StateError] if [loadRSSJson] has not been called.
  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'RSS has not been initialized. Call RSS.loadRSSJson() first.',
      );
    }
  }

  /// Fetches the daily order calendar, parses it, and updates stored schedules.
  ///
  /// Flow:
  /// 1. Fetch ICS data from server (with retry logic)
  /// 2. Optionally clear existing schedules
  /// 3. Parse ICS into schedules via [DailyOrderParser]
  /// 4. Optionally persist results
  /// 5. Optionally refresh UI
  ///
  /// Parameters:
  /// - [storeResults]: saves parsed schedules to local storage
  /// - [refreshStream]: updates UI when data or connection state changes
  /// - [overwrite]: clears existing schedule data before writing new data
  static Future<void> getDailyOrder({
    bool storeResults = false,
    bool refreshStream = true,
    bool overwrite = false,
  }) async {
    _ensureInitialized();

    // Fetch data from server.
    // This will retry indefinitely until a successful response is received.
    final http.Response response = await RSSClient.getUntilSuccess(
      _config.dailyOrderUrl,
      retryCodes: _config.retryCodes,

      // Trigger UI updates when online/offline state changes
      onOfflineChanged: (_) {
        if (refreshStream) {
          ScheduleDisplay.scheduleStream.updateStream();
        }
      },
    );

    // If requested, clear existing stored schedules before writing new ones
    if (overwrite) {
      ScheduleDirectory.clearBells();
      ScheduleDirectory.clearNames();
    }

    // Delegate parsing + writing logic to parser
    // (Parser is responsible for interpreting events and writing schedules)
    DailyOrderParser.parseCalendar(response.body);

    // Persist schedules to local storage if requested
    if (storeResults) {
      ScheduleDirectory.storeSchedule();
    }

    // Final UI refresh after all updates are complete
    if (refreshStream) {
      ScheduleDisplay.scheduleStream.updateStream();
    }
  }
}