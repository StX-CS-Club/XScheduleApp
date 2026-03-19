import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xschedule/materials/styled_button.dart';

class TutorialSystem {
  // Constructor
  TutorialSystem(this.tutorials) {
    // Generates GlobalKeys for each tutorial key
    generateKeys(tutorials.keys.toSet(), reference: keys);
    // If no tutorial exists, mark as finished
    finished = keys.isEmpty;
  }

  /// Map of tutorials provided (&lt;id, text>)
  final Map<String, String> tutorials;

  /// Map of GlobalKeys per id (&lt;id, GlobalKey>)
  final Map<String, GlobalKey> keys = {};

  /// If the system is marked as finished (tutorial complete)
  bool finished = false;

  /// Re-generates GlobalKeys for each tutorial event
  static Map<String, GlobalKey> generateKeys(Set<String> tutorials,
      {Map<String, GlobalKey>? reference}) {
    // Reference as hashmap to alter
    reference ??= {};
    // Generates new key for each tutorial id
    for (String key in tutorials) {
      reference[key] = GlobalKey();
    }
    // Returns altered hashmap
    return reference;
  }

  /// Creates a Showcase widget to fit within the tutorialSystem
  /// [required BuildContext context]: The BuildContext of the ShowcaseView the widget is created it <p>
  /// [required String tutorial]: The tutorial ID of the Showcase <p>
  /// [required Widget child]: The child widget to highlight during the tutorial <p>
  /// [bool dense = false]: If the tutorial display should be condensed <p>
  /// [bool uniqueNull = false]: If a non-existent id's placeholder should be unique <p>
  /// [bool circular = false]: If the target during the tutorial should have a circular border <p>
  /// [EdgeInsets? targetPadding]: Padding of the target from its border in the tutorial <p>
  /// [voud Function()? onTap]: Method to run on tapped to progress
  Showcase showcase(
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

    // Returns Showcase widget w/ settings matching system
    return Showcase(
        key: key(tutorial, uniqueNull: uniqueNull),
        description: tutorials[tutorial],
        onToolTipClick: simulateTap,
        toolTipSlideEndDistance: dense ? 3 : 7,
        targetPadding: targetPadding ?? EdgeInsets.zero,
        // Simulates tap on shaded region
        onBarrierClick: () async {
          // Brief delay to make tap appear more natural
          await onTap!();
          await Future.delayed(const Duration(milliseconds: 100));
          if (tutorial != tutorials.keys.lastOrNull && context.mounted) {
            ShowCaseWidget.of(context).next();
          }
        },
        // Simulates tap on shaded region
        onTargetClick: () async {
          // Brief delay to make tap appear more natural
          await Future.delayed(const Duration(milliseconds: 100));
          simulateTap();
        },
        disposeOnTap: false,
        // Style condensed if set as dense
        descTextStyle: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: dense ? 15 : 17,
            height: dense ? 1 : null,
            fontFamily: 'Exo2'),
        tooltipBackgroundColor: colorScheme.primary,
        targetShapeBorder: circular
            ? CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
        // Action button set inside bottom right of text bubble
        tooltipActionConfig: TooltipActionConfig(
            alignment: MainAxisAlignment.end, gapBetweenContentAndAction: 0),
        tooltipActions: [
          // Custom ToolTip button; "Done" button which simulates tap on shaded region
          TooltipActionButton.custom(
              button: StyledButton(
                  text: "Next",
                  textStyle: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: dense ? 15 : 17,
                      height: dense ? 1 : null,
                      fontFamily: 'Exo2'),
                  onTap: () async {
                    // Brief delay to feel more natural
                    await Future.delayed(const Duration(milliseconds: 50));
                    simulateTap();
                  }))
        ],
        child: child);
  }

  /// Re-generates keys and resets finished state
  void refreshKeys() {
    generateKeys(tutorials.keys.toSet(), reference: keys);
    finished = keys.isEmpty;
  }

  /// Removes any tutorials marked in local storage as complete
  void removeFinished() {
    // Goes through each tutorial id
    for (String tutorial in tutorials.keys) {
      // If state marked as T (true), remove from keys
      if ((localStorage.getItem(tutorial) ?? '') == 'T') {
        keys.remove(tutorial);
      }
    }
    // If none left, mark as finished
    if (keys.isEmpty) {
      finished = true;
    }
  }

  /// Clears the states of each tutorial id stored in local storage
  void clearStorage() {
    for (String tutorial in tutorials.keys) {
      localStorage.removeItem(tutorial);
    }
  }

  /// Pairs a provided tutorial id with it's GlobalKey
  GlobalKey key(String tutorial, {bool uniqueNull = false}) {
    // If uniqueNull, store GlobalKey w/ undefined key
    if (!uniqueNull) {
      keys[tutorial] ??= GlobalKey();
    }
    return keys[tutorial] ?? GlobalKey();
  }

  /// Begins the tutorial showcase of the system
  void showTutorials(final BuildContext context,
      {final bool storeCompletion = true}) {
    // Set of tutorial ids to display
    final Set<String> showTutorials = {};

    // If storeCompletion, ignore all tutorials with ids marked as complete
    if (storeCompletion) {
      showTutorials.addAll(tutorials.keys
          .where((element) => (localStorage.getItem(element) ?? '').isEmpty));
    } else {
      showTutorials.addAll(tutorials.keys);
    }

    // Marks each tutorial id as complete while converting Set to List.
    final List<GlobalKey> tutorialKeys = [];
    for (String tutorial in showTutorials) {
      localStorage.setItem(tutorial, 'T');
      tutorialKeys.add(key(tutorial));
    }

    // If list of tutorials to display is not empty, begin tutorial
    if (tutorialKeys.isNotEmpty) {
      ShowCaseWidget.of(context).startShowCase(tutorialKeys);
    }
  }

  /// Simulates a tap on the shaded region
  void simulateTap() {
    // Very quickly presses and releases top left corner of screen
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        position: Offset.zero, // Adjust if needed
      ),
    );
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        position: Offset.zero,
      ),
    );
  }

  /// Sets the finished state of the system to true
  void finish() {
    finished = true;
  }

  /// Adds updates the system to include specified tutorials.
  void set(Map<String, String> setTutorials) {
    tutorials.clear();
    tutorials.addAll(setTutorials);
    finished = false;
  }
}
