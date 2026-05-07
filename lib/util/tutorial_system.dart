import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xschedule/ui/schedule/schedule_display.dart';
import 'package:xschedule/ui/schedule/schedule_settings/bell_settings/bell_settings_menu.dart';
import 'package:xschedule/ui/schedule/schedule_settings/schedule_settings_page.dart';
import 'package:xschedule/widgets/styled_button.dart';

/// Manages a set of sequential [Showcase] tutorial steps for a given screen or feature.
///
/// Responsibilities:
/// - Generating and managing [GlobalKey]s for each tutorial step
/// - Building [Showcase] widgets with consistent styling and tap-progression behaviour
/// - Persisting and querying tutorial completion state via [localStorage]
/// - Starting, refreshing, and resetting the tutorial sequence
/// - Simulating screen taps to advance the showcase programmatically
class TutorialSystem {
  /// Loads all tutorial content from `assets/data/tutorials.json` and
  /// initialises the [TutorialSystem] instances for each screen.
  ///
  /// This method:
  /// - Reads and decodes the tutorials JSON asset
  /// - Constructs [TutorialSystem] instances for [ScheduleDisplay] and [ScheduleSettingsPage]
  /// - Populates [BellSettingsMenu.bellTutorialData] and [BellSettingsMenu.bellAltTutorialData]
  /// - Initialises [BellSettingsMenu.tutorialSystem] with only the entry and help steps
  ///   (remaining steps are added dynamically when triggered)
  ///
  /// Must be called during app initialisation before any tutorial-enabled page is shown.
  static Future<void> loadJson() async {
    // Read JSON file as raw string from Flutter asset bundle
    final String jsonString =
        await rootBundle.loadString("assets/data/tutorials.json");

    // Decode JSON string into a Map<String, dynamic>
    final Map<String, dynamic> json = jsonDecode(jsonString);

    ScheduleDisplay.tutorialSystem =
        TutorialSystem._(_mapFromJson("schedule", json["schedule"]));
    ScheduleSettingsPage.tutorialSystem = TutorialSystem._(
        _mapFromJson("schedule_settings", json["schedule_settings"]));

    BellSettingsMenu.bellTutorialData =
        _mapFromJson("bell_settings", json["bell_settings"]);
    BellSettingsMenu.bellAltTutorialData =
        _mapFromJson("bell_alt_settings", json["bell_alt_settings"]);
    BellSettingsMenu.tutorialSystem = TutorialSystem._({
      'bell_settings:bell_settings':
          BellSettingsMenu.bellTutorialData['bell_settings:bell_settings']!,
      'bell_settings:help':
          BellSettingsMenu.bellTutorialData['bell_settings:help']!,
    });
  }

  /// Converts a raw tutorial JSON [map] into a typed `Map<String, String>` keyed by tutorial ID.
  ///
  /// Keys prefixed with `'!'` are used as-is (allowing cross-screen IDs); all other keys are
  /// namespaced as `'$title:$key'` (e.g. `'schedule:bell'`).
  ///
  /// Parameters:
  /// - [title]: The scope prefix applied to non-prefixed keys (e.g. `'schedule'`)
  /// - [map]: The raw decoded JSON map of `{key: description}` pairs
  ///
  /// Returns: A `Map<String, String>` of scoped tutorial IDs to description strings
  static Map<String, String> _mapFromJson(String title, Map map) {
    return map.map((key, value) => MapEntry(
          key.startsWith('!') ? key.substring(1) : '$title:$key',
          value,
        ));
  }

  /// Creates a [TutorialSystem] for the given [tutorials] map.
  /// Private constructor; not intended for use outside of class.
  ///
  /// Generates a [GlobalKey] for each tutorial ID on construction.
  /// Sets [finished] to `true` immediately if [tutorials] is empty.
  ///
  /// Parameters:
  /// - [tutorials]: A map of tutorial ID to description text; required
  TutorialSystem._(this.tutorials) {
    // Generates a GlobalKey for each tutorial ID into the [keys] map
    generateKeys(tutorials.keys.toSet(), reference: keys);
    // If no tutorials were provided, mark the system as already finished
    finished = keys.isEmpty;
  }

  /// The tutorial steps managed by this system, keyed by tutorial ID.
  ///
  /// Each value is the description text displayed in the [Showcase] tooltip.
  /// The value type is `Map<id, description text>`.
  final Map<String, String> tutorials;

  /// The [GlobalKey] assigned to each tutorial step, keyed by tutorial ID.
  ///
  /// Keys are generated in [generateKeys] and consumed by [Showcase] widgets
  /// to identify their target widgets in the tree.
  /// The value type is `Map<id, GlobalKey>`.
  final Map<String, GlobalKey> keys = {};

  /// Whether this tutorial system has been marked as complete.
  ///
  /// Set to `true` when [keys] is empty (no remaining steps) or when [finish] is called.
  /// Set back to `false` when [set] is called with new tutorials.
  bool finished = false;

  /// Generates a fresh [GlobalKey] for each tutorial ID in [tutorials], storing results
  /// in [reference].
  ///
  /// Parameters:
  /// - [tutorials]: The set of tutorial IDs to generate keys for
  /// - [reference]: An optional existing map to write keys into;
  ///   a new map is created and returned if `null`
  ///
  /// Returns: The [reference] map populated with a new [GlobalKey] per tutorial ID
  static Map<String, GlobalKey> generateKeys(Set<String> tutorials,
      {Map<String, GlobalKey>? reference}) {
    reference ??= {};
    // Assigns a fresh GlobalKey to each tutorial ID, replacing any existing key
    for (String key in tutorials) {
      reference[key] = GlobalKey();
    }
    return reference;
  }

  /// Builds a [Showcase] widget for the given [tutorial] ID, styled to match this system.
  ///
  /// This method:
  /// - Resolves the [GlobalKey] for [tutorial] via [key]
  /// - Attaches barrier and target tap handlers that optionally invoke [onTap],
  ///   then advance to the next showcase step after a brief delay
  /// - Renders a "Next" [StyledButton] in the tooltip action area
  /// - Applies dense or standard sizing based on [dense]
  /// - Applies circular or rounded-rectangle target border based on [circular]
  ///
  /// Parameters:
  /// - [context]: The [BuildContext] of the enclosing [ShowCaseWidget]; required
  /// - [tutorial]: The ID of the tutorial step to build; required
  /// - [child]: The widget to highlight during this tutorial step; required
  /// - [dense]: When `true`, reduces font size and tooltip slide distance for compact layouts;
  ///   defaults to `false`
  /// - [uniqueNull]: When `true`, returns a one-off [GlobalKey] for unrecognised IDs
  ///   rather than storing it; defaults to `false`
  /// - [circular]: When `true`, applies a [CircleBorder] to the target highlight;
  ///   defaults to `false` (rounded rectangle)
  /// - [targetPadding]: Padding between the target widget and its highlight border;
  ///   defaults to [EdgeInsets.zero]
  /// - [onTap]: Optional async callback invoked before advancing on barrier tap;
  ///   defaults to a no-op
  Widget showcase(
      {required BuildContext context,
      required String tutorial,
      required Widget child,
      bool dense = false,
      bool uniqueNull = false,
      bool circular = false,
      EdgeInsets? targetPadding,
      Future<void> Function()? onTap}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    onTap ??= () async {};

    final String? description = tutorials[tutorial];

    if (description == null) return child;

    return Showcase(
        key: key(tutorial, uniqueNull: uniqueNull),
        description: description,
        onToolTipClick: simulateTap,
        // Dense mode reduces the tooltip slide distance for compact layouts
        toolTipSlideEndDistance: dense ? 3 : 7,
        targetPadding: targetPadding ?? EdgeInsets.zero,
        // Barrier tap: runs onTap callback, waits briefly, then advances to the next step
        onBarrierClick: () async {
          // Brief delay to make the tap feel more natural before advancing
          await onTap!();
          await Future.delayed(const Duration(milliseconds: 100));
          // Only advances if this is not the last tutorial step and the context is still mounted
          if (tutorial != tutorials.keys.lastOrNull && context.mounted) {
            ShowcaseView.get().next();
          }
        },
        // Target tap: waits briefly then simulates a barrier tap to advance
        onTargetClick: () async {
          await Future.delayed(const Duration(milliseconds: 100));
          simulateTap();
        },
        // disposeOnTap false keeps the Showcase alive after the target is tapped
        disposeOnTap: false,
        // Applies dense or standard font size and line height to the tooltip description
        descTextStyle: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: dense ? 15 : 17,
            height: dense ? 1 : null,
            fontFamily: 'Exo2'),
        tooltipBackgroundColor: colorScheme.primary,
        // Circular mode highlights a round target; default is a rounded rectangle
        targetShapeBorder: circular
            ? CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
        // "Next" button is right-aligned with no gap between the description and the action
        tooltipActionConfig: TooltipActionConfig(
            alignment: MainAxisAlignment.end, gapBetweenContentAndAction: 0),
        tooltipActions: [
          // Custom "Next" button that simulates a barrier tap after a brief delay
          TooltipActionButton.custom(
              button: StyledButton(
                  text: "Next",
                  textStyle: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: dense ? 15 : 17,
                      height: dense ? 1 : null,
                      fontFamily: 'Exo2'),
                  onTap: () async {
                    // Brief delay to make the progression feel more natural
                    await Future.delayed(const Duration(milliseconds: 50));
                    simulateTap();
                  }))
        ],
        child: child);
  }

  /// Regenerates [GlobalKey]s for all tutorial IDs and resets [finished] to `false`
  /// (or `true` if [tutorials] is empty).
  void refreshKeys() {
    generateKeys(tutorials.keys.toSet(), reference: keys);
    finished = keys.isEmpty;
  }

  /// Removes tutorial steps that have been marked complete in [localStorage] from [keys].
  ///
  /// This method:
  /// - Iterates all tutorial IDs and removes any whose [localStorage] value is `'T'`
  /// - Sets [finished] to `true` if no tutorial steps remain in [keys]
  ///
  /// Completion is stored as the string `'T'` under each tutorial ID as the key.
  void removeFinished() {
    for (String tutorial in tutorials.keys) {
      // A stored value of 'T' indicates this step was previously completed
      if ((localStorage.getItem('tutorial:$tutorial') ?? '') == 'T') {
        keys.remove(tutorial);
      }
    }
    // If all steps have been completed and removed, mark the system as finished
    if (keys.isEmpty) {
      finished = true;
    }
  }

  /// Clears the [localStorage] completion record for every tutorial ID in this system.
  ///
  /// After calling this, [removeFinished] will treat all steps as incomplete.
  void clearStorage() {
    for (String tutorial in tutorials.keys) {
      localStorage.removeItem('tutorial:$tutorial');
    }
  }

  /// Returns the [GlobalKey] associated with [tutorial], creating one if absent.
  ///
  /// Parameters:
  /// - [tutorial]: The tutorial ID to look up
  /// - [uniqueNull]: When `true`, returns a new one-off [GlobalKey] for unrecognised IDs
  ///   without storing it in [keys]; defaults to `false`
  ///
  /// Returns: The stored [GlobalKey] for [tutorial], or a new [GlobalKey] if not found
  GlobalKey key(String tutorial, {bool uniqueNull = false}) {
    if (!uniqueNull) {
      // Stores a new GlobalKey for this ID if one doesn't already exist
      keys[tutorial] ??= GlobalKey();
    }
    // Returns the stored key, or a throwaway GlobalKey if uniqueNull and ID is unrecognised
    return keys[tutorial] ?? GlobalKey();
  }

  /// Starts the [Showcase] sequence for all incomplete tutorial steps.
  ///
  /// This method:
  /// - Collects tutorial IDs that have not been marked complete in [localStorage]
  ///   (when [storeCompletion] is `true`) or all IDs (when `false`)
  /// - Marks each collected ID as complete in [localStorage] under the value `'T'`
  /// - Starts the [ShowCaseWidget] sequence with the resolved [GlobalKey]s
  ///
  /// Parameters:
  /// - [context]: The [BuildContext] of the enclosing [ShowCaseWidget]; required
  /// - [storeCompletion]: When `true`, skips IDs already stored as complete and
  ///   persists new completions; defaults to `true`
  void showTutorials(final BuildContext context,
      {final bool storeCompletion = true}) {
    final Set<String> showTutorials = {};

    if (storeCompletion) {
      // Only includes tutorial IDs with no existing completion record in localStorage
      showTutorials.addAll(tutorials.keys.where((element) =>
          (localStorage.getItem('tutorial:$element') ?? '').isEmpty));
    } else {
      showTutorials.addAll(tutorials.keys);
    }

    // Marks each tutorial as complete and collects its GlobalKey for the showcase sequence
    final List<GlobalKey> tutorialKeys = [];
    for (String tutorial in showTutorials) {
      // Persists completion as 'T' so this step is skipped on future launches
      localStorage.setItem('tutorial:$tutorial', 'T');
      tutorialKeys.add(key(tutorial));
    }

    // Starts the showcase only if there are steps to display
    if (tutorialKeys.isNotEmpty) {
      ShowcaseView.get().startShowCase(tutorialKeys);
    }
  }

  /// Simulates a quick tap at the top-left corner of the screen (`Offset.zero`).
  ///
  /// This method:
  /// - Fires a [PointerDownEvent] followed immediately by a [PointerUpEvent] at [Offset.zero]
  /// - This is used to advance the [Showcase] by triggering the barrier tap handler,
  ///   since [ShowCaseWidget] does not expose a direct programmatic "advance" API at this time
  void simulateTap() {
    // Fires a pointer down then pointer up at the top-left corner to simulate a screen tap
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        position: Offset.zero,
      ),
    );
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        position: Offset.zero,
      ),
    );
  }

  /// Sets [finished] to `true`, marking this tutorial system as complete.
  void finish() {
    finished = true;
  }

  /// Replaces the current tutorials with [setTutorials] and resets [finished] to `false`.
  ///
  /// Parameters:
  /// - [setTutorials]: The new map of tutorial ID to description text to display
  void set(Map<String, String> setTutorials) {
    tutorials.clear();
    tutorials.addAll(setTutorials);
    finished = false;
  }

  /// Schedules [showTutorials] to run after the current frame and an optional [delay].
  ///
  /// This method:
  /// - Defers execution via [WidgetsBinding.addPostFrameCallback] so the widget tree
  ///   is fully built before the tutorial sequence starts
  /// - Waits [delay] (default 250ms) to let any page slide animations settle
  /// - Calls [showTutorials] and [finish] if [finished] is still `false`
  ///
  /// Parameters:
  /// - [context]: The [BuildContext] of the enclosing [ShowCaseWidget]; required
  /// - [delay]: Time to wait after the frame before starting; defaults to 250ms
  void schedule(BuildContext context,
      {Duration delay = const Duration(milliseconds: 250)}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for the page slide animation to finish before starting the tutorial
      await Future.delayed(delay);
      if (!finished && context.mounted) {
        showTutorials(context);
        finish();
      }
    });
  }

  /// The shared scope name used to register and look up this system's [ShowcaseView].
  ///
  /// Derived from the prefix of the first tutorial key (e.g. `'schedule'` from
  /// `'schedule:bell'`). All [Showcase] widgets in this system must share this scope.
  String get scope => tutorials.keys.first.split(".").first;

  /// Registers this tutorial system with [ShowcaseView] under [scope].
  ///
  /// Marks [finished] as `true` when the showcase sequence completes.
  /// Must be called in [State.initState] of the widget that hosts this system.
  void register() {
    ShowcaseView.register(
        scope: scope,
        onComplete: (_, __) {
          finish();
        });
  }

  /// Unregisters this tutorial system from [ShowcaseView].
  ///
  /// Must be called in [State.dispose] of the widget that hosts this system
  /// to prevent memory leaks and stale showcase references.
  void unregister() => ShowcaseView.getNamed(scope).unregister();
}
