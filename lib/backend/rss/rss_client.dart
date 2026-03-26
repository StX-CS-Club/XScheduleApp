import 'dart:async';
import 'package:http/http.dart' as http;

/// Handles all network communication for RSS feeds.
///
/// Responsibilities:
/// - Perform HTTP GET requests
/// - Retry requests indefinitely until success
/// - Track online/offline state
/// - Notify listeners when connection state changes
class RSSClient {
  // Private constructor — this class is not intended to be instantiated
  RSSClient._();

  /// Whether the app is currently considered offline.
  ///
  /// Set to `true` when:
  /// - request times out
  /// - request throws an error
  /// - response status code is retryable
  ///
  /// Set to `false` when a valid response is received.
  static bool offline = false;

  /// Continuously attempts to fetch [url] until a successful response is received.
  ///
  /// This method:
  /// - never gives up (infinite retry loop)
  /// - only returns when a valid (non-retryable) response is received
  ///
  /// Parameters:
  /// - [retryCodes]: HTTP status codes that should trigger a retry
  /// - [onOfflineChanged]: optional callback triggered when connection state changes
  ///
  /// Returns:
  /// - a successful [http.Response]
  static Future<http.Response> getUntilSuccess(
      String url, {
        required List<int> retryCodes,
        required Duration retryDelay,
        required Duration timeoutDelay,
        void Function(bool offline)? onOfflineChanged,
      }) async {
    // Infinite retry loop: will continue until a valid response is returned
    while (true) {
      // Attempt a single request
      final response = await attemptGet(
        url,
        timeoutDelay: timeoutDelay,
        retryCodes: retryCodes,
        onOfflineChanged: onOfflineChanged,
      );

      // If a valid response was received, return it
      if (response != null) {
        return response;
      }

      // Otherwise, wait before retrying
      await Future.delayed(retryDelay);
    }
  }

  /// Attempts a single HTTP GET request.
  ///
  /// Returns:
  /// - [http.Response] if successful
  /// - `null` if the request should be retried
  ///
  /// A retry is triggered when:
  /// - the request times out
  /// - an exception occurs
  /// - the response status code is in [retryCodes]
  static Future<http.Response?> attemptGet(
      String url, {
        required List<int> retryCodes,
        required Duration timeoutDelay,
        void Function(bool offline)? onOfflineChanged,
      }) async {
    // Track previous offline state to detect changes
    final bool previousOffline = offline;

    try {
      // Perform HTTP GET with timeout
      final http.Response response = await http
          .get(Uri.parse(url))
          .timeout(timeoutDelay);

      // If status code indicates retryable failure
      if (retryCodes.contains(response.statusCode)) {
        offline = true;
        _notifyOfflineChange(previousOffline, onOfflineChanged);
        return null; // signal retry
      }

      // Successful response
      offline = false;
      _notifyOfflineChange(previousOffline, onOfflineChanged);
      return response;
    }

    // Timeout occurred
    on TimeoutException {
      offline = true;
      _notifyOfflineChange(previousOffline, onOfflineChanged);
      return null;
    }

    // Any other error (network failure, DNS, etc.)
    catch (_) {
      offline = true;
      _notifyOfflineChange(previousOffline, onOfflineChanged);
      return null;
    }
  }

  /// Notifies listener if the offline state has changed.
  ///
  /// This prevents redundant updates when state remains the same.
  static void _notifyOfflineChange(
      bool previousOffline,
      void Function(bool offline)? onOfflineChanged,
      ) {
    // Only notify if state actually changed
    if (previousOffline != offline) {
      onOfflineChanged?.call(offline);
    }
  }
}