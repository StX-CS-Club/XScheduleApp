import 'dart:async';

import 'package:flutter/cupertino.dart';

/// A [StatefulWidget] that periodically rebuilds its child and reacts to app lifecycle changes.
///
/// Responsibilities:
/// - Rebuilding the widget tree on a fixed [refreshDuration] interval via a [Timer]
/// - Triggering an optional [onRefresh] callback on each interval and on app resume
/// - Cancelling the [Timer] and removing lifecycle observers on disposal
class RefreshWidget extends StatefulWidget {
  /// Creates a [RefreshWidget] that rebuilds on [refreshDuration] intervals.
  ///
  /// Also triggers a rebuild immediately when the app returns to the foreground
  /// via [WidgetsBindingObserver].
  ///
  /// Parameters:
  /// - [builder]: A function that returns the [Widget] to display; called on every rebuild; required
  /// - [refreshDuration]: The interval between periodic rebuilds; required
  /// - [onRefresh]: An optional callback invoked on each rebuild tick and on app resume
  const RefreshWidget(
      {super.key,
        required this.builder,
        required this.refreshDuration,
        this.onRefresh});

  /// A builder function that produces the widget to display.
  ///
  /// Called on every periodic rebuild and on app resume, receiving the current [BuildContext].
  final Widget Function(BuildContext) builder;

  /// Optional callback invoked alongside each [setState] call.
  ///
  /// Useful for updating external state or fetching fresh data before the rebuild.
  /// When `null`, only [setState] is called to trigger the rebuild.
  final void Function()? onRefresh;

  /// The interval between periodic rebuilds.
  ///
  /// Passed directly to [Timer.periodic]; shorter durations produce more frequent rebuilds.
  final Duration refreshDuration;

  @override
  State<RefreshWidget> createState() => _RefreshWidgetState();
}

/// Private state class for [RefreshWidget].
///
/// Responsibilities:
/// - Starting and managing the periodic [Timer]
/// - Observing app lifecycle state changes via [WidgetsBindingObserver]
/// - Cleaning up the [Timer] and observer on disposal
class _RefreshWidgetState extends State<RefreshWidget>
    with WidgetsBindingObserver {
  /// The periodic timer that drives timed rebuilds.
  ///
  /// Initialised in [initState] and cancelled in [dispose].
  late Timer _timer;

  /// Registers this state as a lifecycle observer and starts the refresh timer.
  @override
  void initState() {
    super.initState();
    // Registers for app lifecycle events (e.g. resume) via WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  /// Starts a periodic [Timer] that calls [setState] and [onRefresh] on each tick.
  ///
  /// This method:
  /// - Creates a [Timer.periodic] using [refreshDuration] as the interval
  /// - On each tick, calls [setState] to trigger a rebuild and invokes [onRefresh] if provided
  void _startTimer() {
    _timer = Timer.periodic(widget.refreshDuration, (_) {
      setState(() => widget.onRefresh?.call());
    });
  }

  /// Responds to app lifecycle state changes.
  ///
  /// Triggers a rebuild and calls [onRefresh] when the app returns to the foreground,
  /// ensuring the UI reflects any data changes that occurred while the app was inactive.
  ///
  /// Parameters:
  /// - [state]: The new [AppLifecycleState]; only [AppLifecycleState.resumed] is acted upon
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Triggers an immediate refresh when the app returns to the foreground
      setState(() => widget.onRefresh?.call());
    }
  }

  /// Cancels the periodic timer and removes this state as a lifecycle observer.
  ///
  /// Both cleanup steps are required to prevent memory leaks and stale callbacks
  /// after the widget is removed from the tree.
  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Builds the widget by delegating to [RefreshWidget.builder].
  @override
  Widget build(BuildContext context) => widget.builder(context);
}