import 'dart:convert';

import 'package:flutter/services.dart';

/// Represents configuration values required for RSS operations.
///
/// Responsibilities:
/// - Store RSS-related configuration (URLs, retry codes)
/// - Load configuration from local JSON asset
class RSSConfig {
  /// URL used to fetch the daily order (ICS calendar feed).
  final String dailyOrderUrl;

  /// HTTP status codes that should trigger a retry.
  ///
  /// These typically represent server-side issues (e.g., 500, 503).
  final List<int> retryCodes;

  /// Creates an immutable RSS configuration object.
  const RSSConfig({
    required this.dailyOrderUrl,
    required this.retryCodes,
  });

  /// Loads RSS configuration from `assets/data/rss.json`.
  ///
  /// This method:
  /// - Reads the JSON file from app assets
  /// - Decodes it into a Dart map
  /// - Extracts required fields
  /// - Returns a fully constructed [RSSConfig]
  ///
  /// Returns:
  /// - A populated [RSSConfig] instance
  static Future<RSSConfig> load() async {
    // Read JSON file as raw string from Flutter asset bundle
    final String jsonString =
    await rootBundle.loadString("assets/data/rss.json");

    // Decode JSON string into a Map<String, dynamic>
    final Map<String, dynamic> json = jsonDecode(jsonString);

    // Extract required configuration values
    final String dailyOrderUrl = json['daily_order_url'];

    // Convert dynamic list into strongly typed List<int>
    final List<int> retryCodes =
    List<int>.from(json['retry_status_codes']);

    // Return immutable config object
    return RSSConfig(
      dailyOrderUrl: dailyOrderUrl,
      retryCodes: retryCodes,
    );
  }
}