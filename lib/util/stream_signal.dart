import 'dart:async';

import 'package:flutter/cupertino.dart';

/// A signal object transmitted through a [StreamController] to communicate state changes across the app.
///
/// Responsibilities:
/// - Carrying an arbitrary data payload across a [StreamController]
/// - Maintaining a persistent history of data sent through each [StreamController] via [streamData]
/// - Merging new data into the existing history for a given controller on each construction
class StreamSignal {
  /// Persistent history of data sent through each [StreamController].
  ///
  /// Keyed by [StreamController] instance; each value is the cumulative merged data map
  /// for all [StreamSignal]s sent through that controller.
  static Map<StreamController, Map<String, dynamic>> streamData = {};

  /// Creates a [StreamSignal] for [streamController], merging [data] into its history.
  ///
  /// This constructor:
  /// - Initialises [streamData] for [streamController] with [data] if no history exists yet
  /// - Merges [data] into the existing history entry via [Map.addAll], so new keys are added
  ///   and existing keys are overwritten
  /// - Assigns the resulting cumulative data map to this signal's [data] field
  ///
  /// Parameters:
  /// - [streamController]: The [StreamController] this signal will be sent through; required
  /// - [data]: Optional payload to transmit and merge into the controller's history;
  ///   defaults to an empty map if `null`
  StreamSignal({required this.streamController, Map<String, dynamic>? data}) {
    // Falls back to an empty map if no data is provided
    Map<String, dynamic> dataMap = data ?? <String, dynamic>{};

    // Initialises the history entry for this controller if it doesn't exist yet
    streamData[streamController] ??= dataMap;
    // Merges new data into the existing history, overwriting duplicate keys
    streamData[streamController]?.addAll(dataMap);

    // Assigns the full cumulative history as this signal's data payload
    data = streamData[streamController] ?? {};
  }

  /// The [StreamController] this signal is sent through.
  ///
  /// Used as the key in [streamData] to associate history with a specific stream.
  final StreamController<StreamSignal> streamController;

  /// The cumulative data payload of this signal.
  ///
  /// Contains the merged result of all data sent through [streamController] up to
  /// and including this signal's construction.
  late final Map<String, dynamic> data;
}

/// An extension on [StreamController]<[StreamSignal]> for conveniently emitting signals.
///
/// Responsibilities:
/// - Wrapping signal emission in a single method call with optional data
/// - Injecting a unique [GlobalKey] into each signal's data to distinguish successive signals
extension StreamSignalExtension on StreamController<StreamSignal> {
  /// Emits a [StreamSignal] through this controller with optional [newData].
  ///
  /// This method:
  /// - Defaults [newData] to an empty map if `null`
  /// - Injects a fresh [GlobalKey] under the key `'key'` to ensure each emitted signal
  ///   is unique, even if the rest of the data is unchanged
  /// - Constructs and adds a [StreamSignal] to this controller
  ///
  /// Parameters:
  /// - [newData]: Optional map of data to include in the signal payload;
  ///   merged into this controller's cumulative [StreamSignal.streamData] history
  void updateStream({Map<String, dynamic>? newData}) {
    newData ??= {};
    // Injects a unique GlobalKey so listeners can distinguish successive signals
    // even when the rest of the payload is identical
    newData['key'] = GlobalKey();
    add(StreamSignal(streamController: this, data: newData));
  }
}