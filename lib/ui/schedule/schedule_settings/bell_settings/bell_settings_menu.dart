import 'dart:math';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:xschedule/extensions/color_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/schedule_settings.dart';
import 'package:xschedule/util/tutorial_system.dart';
import 'package:xschedule/widgets/icon_circle.dart';
import 'package:xschedule/widgets/styled_button.dart';

/// Popup menu for configuring the vanity of a single bell.
///
/// Responsibilities:
/// - Displays a flippable card with a primary face (standard vanity) and back face (alternate vanity + day selector)
/// - Allows the user to set color, emoji, name, teacher, and location for both the primary and alternate bell
/// - Manages text controllers and focus nodes for all editable fields
/// - Saves the configured vanity back to [ScheduleSettings] on confirmation
/// - Runs a guided tutorial via [tutorialSystem] on first open
class BellSettingsMenu extends StatefulWidget {
  /// Creates the bell settings popup for the given [bell].
  /// Refreshes [tutorialSystem] GlobalKeys on construction so showcase
  /// targets are valid for this new widget instance.
  ///
  /// Parameters:
  /// - [bell]: The bell identifier to configure (e.g. "A", "HR", "FLEX").
  /// - [onStateChange]: The parent's setState, called after saving to refresh the bell list.
  /// - [deleteButton]: If true, shows a red delete button alongside the confirm button.
  BellSettingsMenu({
    super.key,
    required this.bell,
    required this.onStateChange,
    this.deleteButton = false,
  }) {
    tutorialSystem.refreshKeys();
  }

  /// The bell identifier being configured.
  final String bell;

  /// Parent setState callback used to refresh the bell list after saving.
  final StateSetter onStateChange;

  /// Whether to show a delete button that clears all settings and closes the popup.
  /// Shown when the menu is opened from a QR import, allowing the user to discard the import.
  final bool deleteButton;

  /// Tutorial text shown on the standard (front) bell configuration card.
  /// Keys map to showcase widget tutorial IDs.
  static late Map<String, String> bellTutorialData;

  /// Tutorial text shown on the alternate (back) bell configuration card.
  /// Reuses 'tutorial_settings:bell' key to target the same showcase widget.
  static late Map<String, String> bellAltTutorialData;

  /// Tutorial system managing the guided walkthrough for this popup.
  /// Initialized with only the entry and help tutorials; remaining tutorials
  /// are added dynamically when the user triggers them.
  /// Kept static so tutorial completion persists across popup instances.
  static late TutorialSystem tutorialSystem;

  /// Resets [tutorialSystem] to its initial two-tutorial state and refreshes keys.
  /// Called from [PersonalPage._clearAllData] during a full app reset.
  static void resetTutorials() {
    tutorialSystem.set({
      'bell_settings:bell_settings': bellTutorialData['bell_settings:bell_settings']!,
      'bell_settings:help': bellTutorialData['bell_settings:help']!,
    });
    tutorialSystem.refreshKeys();
  }

  @override
  State<BellSettingsMenu> createState() => _BellSettingsMenuState();
}

class _BellSettingsMenuState extends State<BellSettingsMenu> {
  /// Controls the flip animation between the front (standard) and back (alternate) card faces.
  final GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();

  /// Scroll controller for the color swatch row on the primary bell editor.
  final ScrollController _colorScrollController = ScrollController();

  /// Scroll controller for the color swatch row on the alternate bell editor.
  final ScrollController _colorScrollAltController = ScrollController();

  /// Controls which accordion section is expanded on the back card.
  /// - true: Appearance section is collapsed, Program (day selector) is expanded
  /// - false: Appearance section is expanded, Program is collapsed
  bool _appearanceExpanded = true;

  /// Text editing controllers for all editable fields, keyed by "fieldName[suffix]".
  /// Suffix is '' for the primary bell and '_alt' for the alternate bell.
  final Map<String, TextEditingController> _controllers = {};

  /// Focus nodes for all editable fields, keyed by "fieldName[suffix]".
  final Map<String, FocusNode> _focusNodes = {};

  /// Returns a human-readable display name for the bell.
  /// Single-character bells are formatted as "X Bell"; "HR" becomes "Homeroom".
  String get _bellDisplayName {
    if (widget.bell.length == 1) return '${widget.bell} Bell';
    if (widget.bell == 'HR') return 'Homeroom';
    return widget.bell;
  }

  /// Initializes focus nodes and text controllers for the bell identified by [suffix].
  /// Controllers are pre-populated from the current [ScheduleSettings] editing maps.
  ///
  /// Parameters:
  /// - [suffix]: '' for the primary bell, '_alt' for the alternate bell.
  void _loadBell(String suffix) {
    final bellKey = widget.bell + suffix;
    _focusNodes['emoji$suffix'] = FocusNode();
    _focusNodes['name$suffix'] = FocusNode();
    _focusNodes['teacher$suffix'] = FocusNode();
    _focusNodes['location$suffix'] = FocusNode();
    _controllers['emoji$suffix'] =
        TextEditingController(text: ScheduleSettings.emojis[bellKey]);
    _controllers['name$suffix'] =
        TextEditingController(text: ScheduleSettings.names[bellKey]);
    _controllers['teacher$suffix'] =
        TextEditingController(text: ScheduleSettings.teachers[bellKey]);
    _controllers['location$suffix'] =
        TextEditingController(text: ScheduleSettings.locations[bellKey]);
  }

  /// Writes the current text controller values back into [ScheduleSettings] editing maps
  /// for the bell identified by [suffix].
  ///
  /// Parameters:
  /// - [suffix]: '' for the primary bell, '_alt' for the alternate bell.
  void _writeBell(String suffix) {
    final bellKey = widget.bell + suffix;
    ScheduleSettings.emojis[bellKey] = _controllers['emoji$suffix']?.text ?? '';
    ScheduleSettings.names[bellKey] = _controllers['name$suffix']?.text ?? '';
    ScheduleSettings.teachers[bellKey] =
        _controllers['teacher$suffix']?.text ?? '';
    ScheduleSettings.locations[bellKey] =
        _controllers['location$suffix']?.text ?? '';
  }

  /// Writes all controller values to [ScheduleSettings] and assembles the final
  /// [ScheduleSettings.bellVanity] map for this bell, including the alt block.
  ///
  /// This method:
  /// - Flushes both primary and alternate text controllers via [_writeBell]
  /// - Constructs and sets the complete vanity map including color, emoji,
  ///   name, teacher, location, alt_days, and the nested alt block
  void _saveBell() {
    final String altBell = '${widget.bell}_alt';
    _writeBell('');
    _writeBell('_alt');

    ScheduleSettings.bellVanity[widget.bell] = {
      'name': ScheduleSettings.names[widget.bell],
      'teacher': ScheduleSettings.teachers[widget.bell],
      'location': ScheduleSettings.locations[widget.bell],
      'emoji': ScheduleSettings.emojis[widget.bell],
      'decal': ScheduleSettings.decals[widget.bell],
      'color': ScheduleSettings.colors[widget.bell]!.toColor().toHex(),
      'alt_days': ScheduleSettings.altDays[widget.bell],
      'alt': {
        'name': ScheduleSettings.names[altBell],
        'teacher': ScheduleSettings.teachers[altBell],
        'location': ScheduleSettings.locations[altBell],
        'emoji': ScheduleSettings.emojis[altBell],
        'decal': ScheduleSettings.decals[altBell],
        'color': ScheduleSettings.colors[altBell]!.toColor().toHex(),
      },
    };
  }

  @override
  void initState() {
    super.initState();
    // Ensure both primary and alternate bells have defaults before loading controllers
    ScheduleSettings.defineBell(widget.bell);
    ScheduleSettings.defineBell(widget.bell, alternate: true);
    _loadBell('');
    _loadBell('_alt');

    BellSettingsMenu.tutorialSystem.register();
  }

  @override
  void dispose() {
    for (final key in _focusNodes.keys) {
      _focusNodes[key]?.dispose();
      _controllers[key]?.dispose();
    }
    _colorScrollController.dispose();
    _colorScrollAltController.dispose();


    BellSettingsMenu.tutorialSystem.unregister();

    super.dispose();
  }

  /// Loads and starts either the standard or alternate tutorial set.
  ///
  /// Parameters:
  /// - [context]: Used to run the showcase.
  /// - [alt]: If true, loads [bellAltTutorials]; otherwise loads [bellTutorials].
  /// - [storeCompletion]: If true, marks the tutorial as permanently complete after running.
  void _startBellTutorial(BuildContext context, bool alt,
      {bool storeCompletion = false}) {
    BellSettingsMenu.tutorialSystem.set(
      alt
          ? BellSettingsMenu.bellAltTutorialData
          : BellSettingsMenu.bellTutorialData,
    );
    BellSettingsMenu.tutorialSystem
        .showTutorials(context, storeCompletion: storeCompletion);
  }

  @override
  Widget build(BuildContext context) {
    final double width = min(MediaQuery.of(context).size.width, 500);

    BellSettingsMenu.tutorialSystem.schedule(context);

    return KeyboardAvoider(
      autoScroll: true,
      child: Center(
        child: BellSettingsMenu.tutorialSystem.showcase(
          context: context,
          tutorial: 'bell_settings:bell_settings',
          // When the tutorial taps this target, reset the back card to show Appearance
          onTap: () async {
            setState(() => _appearanceExpanded = true);
            await Future.delayed(const Duration(milliseconds: 150));
          },
          child: FlipCard(
            key: _cardKey,
            flipOnTouch: false,
            direction: FlipDirection.HORIZONTAL,
            front: _buildFrontCard(context, width),
            back: _buildBackCard(context, width),
          ),
        ),
      ),
    );
  }

  /// Builds the front card face containing the standard bell vanity editor.
  /// Includes the top action row, the vanity editor, and the confirm/delete buttons.
  ///
  /// Parameters:
  /// - [context]: Used for navigation and showcase.
  /// - [width]: The constrained popup width.
  Widget _buildFrontCard(BuildContext context, double width) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        width: width * .95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTopActionRow(
              context: context,
              colorScheme: colorScheme,
              width: width,
              label: _bellDisplayName,
              helpTutorial: 'bell_settings:help',
              onHelpTap: () => _startBellTutorial(context, false),
              actionTutorial: 'bell_settings:alternate',
              // Only show the flip button if this bell appears on "All Meet" days
              action: ScheduleSettings.sampleSchedules['All Meet']!
                      .contains(widget.bell)
                  ? IconButton(
                      onPressed: () async {
                        _cardKey.currentState?.toggleCard();
                        // Wait for the flip animation before starting the alt tutorial
                        await Future.delayed(
                            const Duration(milliseconds: 1000));
                        if (context.mounted) {
                          _startBellTutorial(context, true,
                              storeCompletion: true);
                        }
                      },
                      icon: Icon(Icons.autorenew,
                          size: 30, color: colorScheme.onSurface),
                    )
                  // Transparent placeholder to maintain row layout for non-alternating bells
                  : const CircleAvatar(
                      radius: 20, backgroundColor: Colors.transparent),
            ),
            _buildVanityEditor(context, false),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: BellSettingsMenu.tutorialSystem.showcase(
                context: context,
                tutorial: 'bell_settings:complete',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.deleteButton) ...[
                      StyledButton(
                        icon: Icons.delete_forever_rounded,
                        backgroundColor: Colors.red,
                        width: width * .3,
                        onTap: () {
                          ScheduleSettings.clearSettings();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    StyledButton(
                      icon: Icons.check,
                      backgroundColor: Colors.green,
                      width: width * (widget.deleteButton ? .3 : .6),
                      onTap: () {
                        widget.onStateChange(() {
                          _saveBell();
                          ScheduleSettings.saveBells();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the back card face containing the alternate bell vanity editor and day selector.
  /// Uses two accordion sections: Appearance (alternate vanity) and Program (day selector).
  ///
  /// Parameters:
  /// - [context]: Used for navigation and showcase.
  /// - [width]: The constrained popup width.
  Widget _buildBackCard(BuildContext context, double width) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        width: width * .95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTopActionRow(
              context: context,
              colorScheme: colorScheme,
              width: width,
              label: '$_bellDisplayName - Alternate',
              helpTutorial: 'bell_alt_settings:help',
              onHelpTap: () => _startBellTutorial(context, true),
              actionTutorial: 'bell_alt_settings:alternate',
              action: IconButton(
                onPressed: () => _cardKey.currentState?.toggleCard(),
                icon: Icon(Icons.autorenew,
                    size: 30, color: colorScheme.onSurface),
              ),
            ),
            BellSettingsMenu.tutorialSystem.showcase(
              context: context,
              tutorial: 'bell_alt_settings:vanity',
              child: _buildAccordionSection(
                context: context,
                colorScheme: colorScheme,
                title: 'Appearance',
                // Appearance expands when _appearanceExpanded is false
                expanded: !_appearanceExpanded,
                tutorial: 'bell_alt_settings:vanity',
                onTutorialTap: () async {
                  setState(() => _appearanceExpanded = false);
                  await Future.delayed(const Duration(milliseconds: 150));
                },
                content: _buildVanityEditor(context, true),
              ),
            ),
            Divider(color: colorScheme.onSurface, height: 8),
            BellSettingsMenu.tutorialSystem.showcase(
              context: context,
              tutorial: 'bell_alt_settings:day',
              onTap: () async {
                setState(() => _appearanceExpanded = false);
                await Future.delayed(const Duration(milliseconds: 150));
              },
              child: _buildAccordionSection(
                context: context,
                colorScheme: colorScheme,
                title: 'Program',
                // Program expands when _appearanceExpanded is true
                expanded: _appearanceExpanded,
                tutorial: 'bell_alt_settings:day',
                content: _buildDaySelector(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the shared top action row used on both card faces.
  /// Contains a help icon button, a centered label, and a right-side action widget,
  /// all spread evenly across the row width.
  ///
  /// Parameters:
  /// - [context]: Used for showcase targeting.
  /// - [colorScheme]: Provides icon and text colors.
  /// - [width]: The card width; row is sized to 90% of this.
  /// - [label]: The dimmed hint text displayed in the center.
  /// - [helpTutorial]: Tutorial key for the help icon showcase target.
  /// - [onHelpTap]: Callback for the help icon button.
  /// - [actionTutorial]: Tutorial key for the right action widget showcase target.
  /// - [action]: The right-side widget (flip button or transparent placeholder).
  Widget _buildTopActionRow({
    required BuildContext context,
    required ColorScheme colorScheme,
    required double width,
    required String label,
    required String helpTutorial,
    required VoidCallback onHelpTap,
    required String actionTutorial,
    required Widget action,
  }) {
    return SizedBox(
      width: width * .9,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BellSettingsMenu.tutorialSystem.showcase(
            context: context,
            tutorial: helpTutorial,
            circular: true,
            child: IconButton(
              onPressed: onHelpTap,
              icon: Icon(Icons.help_outline_rounded,
                  size: 30, color: colorScheme.onSurface),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 25,
              height: 1,
              fontFamily: 'Exo2',
              // Dimmed to distinguish from editable content
              color: colorScheme.onSurface.withAlpha(128),
            ),
          ),
          BellSettingsMenu.tutorialSystem.showcase(
            context: context,
            tutorial: actionTutorial,
            circular: true,
            child: action,
          ),
        ],
      ),
    );
  }

  /// Builds an animated accordion section with a tappable header and collapsible content.
  /// Used on the back card for both the Appearance and Program sections.
  /// Only one section is expanded at a time, controlled by [_appearanceExpanded].
  ///
  /// Parameters:
  /// - [context]: Used for layout measurements.
  /// - [colorScheme]: Provides header text and chevron colors.
  /// - [title]: The section header label.
  /// - [expanded]: Whether this section is currently expanded.
  /// - [tutorial]: Tutorial key associated with this section (unused internally, passed for context).
  /// - [content]: The widget shown when the section is expanded.
  /// - [onTutorialTap]: Optional async callback triggered by the showcase on this section.
  Widget _buildAccordionSection({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String title,
    required bool expanded,
    required String tutorial,
    required Widget content,
    Future<void> Function()? onTutorialTap,
  }) {
    final double maxHeight = MediaQuery.of(context).size.height * .75;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      // Collapsed sections are clamped to 50px (header height only)
      constraints: BoxConstraints(maxHeight: expanded ? maxHeight : 50),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () =>
                  setState(() => _appearanceExpanded = !_appearanceExpanded),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 25,
                        color: colorScheme.onSurface,
                        fontFamily: 'Georama',
                        fontWeight: FontWeight.w600,
                      ),
                    ).expandedFit(),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: colorScheme.onSurface,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  /// Builds the vanity editor column for either the primary or alternate bell.
  ///
  /// Contains, in order:
  /// - A color wheel with an overlaid emoji text field and a decal picker icon
  /// - A horizontally scrollable color swatch row
  /// - Text fields for bell name, teacher, and location
  ///
  /// Each section is wrapped in a [TutorialSystem.showcase] target.
  ///
  /// Parameters:
  /// - [alternate]: If true, builds for the alternate bell (suffix `'_alt'`);
  ///   if false, builds for the primary bell (no suffix)
  Widget _buildVanityEditor(BuildContext context, bool alternate) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final String suffix = alternate ? '_alt' : '';
    final String bell = '${widget.bell}$suffix';

    return Column(
      children: [
        SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                BellSettingsMenu.tutorialSystem.showcase(
                  context: context,
                  tutorial: 'bell${suffix}_settings:color_wheel',
                  child: _buildColorWheel(context, alternate),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16, right: 24),
                  alignment: Alignment.bottomRight,
                  child: BellSettingsMenu.tutorialSystem.showcase(
                      context: context,
                      tutorial: "bell${suffix}_settings:decal",
                      circular: true,
                      child: IconCircle(
                          onTap: () => _showDecalPopup(context, bell),
                          color: colorScheme.surfaceContainer,
                          iconColor: colorScheme.onSurface,
                          radius: 20,
                          padding: 8,
                          icon: Icons.brush)),
                )
              ],
            )),
        BellSettingsMenu.tutorialSystem.showcase(
          context: context,
          tutorial: 'bell${suffix}_settings:color_row',
          child: _buildColorScroll(bell, alternate),
        ),
        const SizedBox(height: 16),
        BellSettingsMenu.tutorialSystem.showcase(
          context: context,
          tutorial: 'bell${suffix}_settings:info',
          targetPadding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _buildTextForm(_controllers['name$suffix']!, 'Bell Name', 40,
                  focusNode: _focusNodes['name$suffix']!),
              _buildTextForm(_controllers['teacher$suffix']!, 'Teacher', 25,
                  focusNode: _focusNodes['teacher$suffix']!),
              _buildTextForm(_controllers['location$suffix']!, 'Location', 20,
                  focusNode: _focusNodes['location$suffix']!),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the circular color wheel with an overlaid emoji text field.
  /// A solid color circle behind the wheel previews the currently selected color.
  /// The color is stored at full value and saturation to match what appears on the wheel.
  ///
  /// Parameters:
  /// - [alternate]: If true, targets the alternate bell's color and emoji fields.
  Widget _buildColorWheel(BuildContext context, bool alternate) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String suffix = alternate ? '_alt' : '';
    final String bell = '${widget.bell}$suffix';

    return SizedBox(
      width: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Solid color circle previewing the currently selected color
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: CircleAvatar(
              backgroundColor: ScheduleSettings.colors[bell]!.toColor(),
              radius: 95,
              child: (ScheduleSettings.decals[bell] ?? "Blank") != "Blank"
                  ? ClipOval(
                      child: Image.asset(
                        "assets/images/decals/${ScheduleSettings.decals[bell]}.png",
                        width: 190,
                        height: 190,
                        fit: BoxFit.cover,
                      ).withOpacity(0.25),
                    )
                  : null,
            ),
          ),
          WheelPicker(
            showPalette: false,
            color: ScheduleSettings.colors[bell]!,
            onChanged: (HSVColor value) {
              setState(() {
                // Lock to full value and saturation so color matches wheel position
                ScheduleSettings.colors[bell] =
                    value.withValue(1).withSaturation(1);
              });
            },
          ),
          // Emoji picker centered over the wheel
          BellSettingsMenu.tutorialSystem.showcase(
            context: context,
            tutorial: 'bell${suffix}_settings:icon',
            circular: true,
            child: Container(
              width: 125,
              height: 125,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 50),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 80, maxWidth: 240),
                  child: TextField(
                    controller: _controllers['emoji$suffix']!,
                    focusNode: _focusNodes['emoji$suffix']!,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 120,
                      height: 1.2,
                      color: colorScheme.onSurface,
                      overflow: TextOverflow.visible,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTapOutside: (_) => _focusNodes['emoji$suffix']?.unfocus(),
                    onChanged: (String text) {
                      // Enforce a single character; fall back to '_' if empty
                      if (text.isEmpty) text = '_';
                      if (text.characters.length > 1) {
                        text = text.characters.last;
                      }
                      setState(() => _controllers['emoji$suffix']!.text = text);
                    },
                  ).intrinsicFit(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontally scrollable color swatch row with left/right arrow buttons
  /// and fading edge overlays. Selecting a swatch updates the bell's color immediately.
  ///
  /// Parameters:
  /// - [bell]: The map key used to update [ScheduleSettings.colors].
  /// - [alternate]: If true, uses [_colorScrollAltController]; otherwise [_colorScrollController].
  Widget _buildColorScroll(String bell, bool alternate) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double width = min(MediaQuery.of(context).size.width, 500);
    final ScrollController controller =
        alternate ? _colorScrollAltController : _colorScrollController;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => controller.animateTo(
            controller.offset - 46 * 3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          icon: Icon(Icons.arrow_back_ios,
              color: colorScheme.onSurface.withAlpha(128), size: 12),
        ).expandedFit(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          width: width * .7,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: controller,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(
                      ScheduleSettings.colorOptions.length, (i) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          ScheduleSettings.colors[bell] = HSVColor.fromColor(
                              ColorExtension.fromHex(
                                  ScheduleSettings.colorOptions[i]));
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: ColorExtension.fromHex(
                              ScheduleSettings.colorOptions[i]),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(color: colorScheme.shadow, blurRadius: 1)
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              _buildScrollFade(colorScheme, fromLeft: true),
              Align(
                alignment: Alignment.centerRight,
                child: _buildScrollFade(colorScheme, fromLeft: false),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => controller.animateTo(
            controller.offset + 46 * 3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          icon: Icon(Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withAlpha(128), size: 12),
        ).expandedFit(),
      ],
    );
  }

  /// Builds a short gradient overlay that fades the color scroll edge into the background.
  /// Used on both the left and right edges of the color scroll and day selector.
  ///
  /// Parameters:
  /// - [colorScheme]: Provides the surface color used for the fade.
  /// - [fromLeft]: If true, fades left-to-right; if false, fades right-to-left.
  Widget _buildScrollFade(ColorScheme colorScheme, {required bool fromLeft}) {
    return IgnorePointer(
      child: Container(
        width: 12,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surface.withAlpha(0)],
            begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
          ),
        ),
      ),
    );
  }

  /// Builds a single labeled text field for bell info entry (name, teacher, or location).
  ///
  /// Parameters:
  /// - [controller]: Pre-populated text controller for this field.
  /// - [label]: The floating label shown inside the field.
  /// - [maxLength]: Maximum number of characters allowed.
  /// - [focusNode]: Optional focus node for keyboard management.
  Widget _buildTextForm(
    TextEditingController controller,
    String label,
    int maxLength, {
    FocusNode? focusNode,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double size = min(MediaQuery.of(context).size.width, 500) * 5 / 6;

    return Container(
      margin: const EdgeInsets.only(top: 5),
      height: size * 2 / 15,
      width: size,
      child: TextFormField(
        keyboardType: TextInputType.text,
        focusNode: focusNode,
        controller: controller,
        maxLength: maxLength,
        maxLines: 1,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          // Hide the character counter shown below the field by default
          counterText: '',
          labelStyle: TextStyle(
              color: colorScheme.onSurface, overflow: TextOverflow.ellipsis),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.shadow, width: 1),
          ),
        ),
      ),
    );
  }

  /// Builds the horizontal day selector shown in the Program accordion section.
  /// Displays a scrollable list of schedule day columns, each showing a visual
  /// representation of the bell order for that day and a checkbox to mark it as
  /// an alternate day for this bell.
  ///
  /// This method:
  /// - Filters [ScheduleSettings.sampleDays] to only days containing this bell
  /// - Renders each day as a column of colored segments proportional to bell count
  /// - Highlights this bell's segment in primary color; FLEX is shown at fixed 25px height
  /// - Toggling a day adds or removes it from [ScheduleSettings.altDays]
  Widget _buildDaySelector() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Only show days that include this bell
    final List<String> meetDays = ScheduleSettings.sampleSchedules.keys
        .where((key) =>
            ScheduleSettings.sampleSchedules[key]!.contains(widget.bell))
        .toList();

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(meetDays.length, (i) {
              final String dayTitle = meetDays[i];
              final List<String> day =
                  ScheduleSettings.sampleSchedules[dayTitle] ?? [];
              // Distribute 150px total height evenly across non-FLEX bells
              final double bellHeight = 150 / (day.length - 1);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 90,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (ScheduleSettings.altDays[widget.bell]!
                          .contains(dayTitle)) {
                        ScheduleSettings.altDays[widget.bell]!.remove(dayTitle);
                      } else {
                        ScheduleSettings.altDays[widget.bell]!.add(dayTitle);
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayTitle,
                        style: TextStyle(
                            fontSize: 24,
                            color: colorScheme.onSurface,
                            fontFamily: 'Exo_2'),
                      ).fit(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List<Widget>.generate(day.length, (e) {
                            final String dayBell = day[e];
                            return Container(
                              // FLEX is always 25px; other bells share the remaining height
                              height: dayBell == 'FLEX' ? 25 : bellHeight,
                              // This bell is highlighted in primary; others use muted onSurface
                              color: dayBell == widget.bell
                                  ? colorScheme.primary
                                  : colorScheme.onSurface
                                      .withAlpha(dayBell == 'FLEX' ? 64 : 96),
                            );
                          }),
                        ),
                      ),
                      // Read-only checkbox; interaction handled by the parent InkWell
                      Checkbox(
                        activeColor: colorScheme.primary,
                        value: ScheduleSettings.altDays[widget.bell]!
                            .contains(dayTitle),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        _buildScrollFade(colorScheme, fromLeft: true),
        Align(
          alignment: Alignment.centerRight,
          child: _buildScrollFade(colorScheme, fromLeft: false),
        ),
      ],
    );
  }

  /// Opens a dialog for selecting a decal to apply to [bell].
  ///
  /// Appearance: A modal card containing a scrollable list of [_buildDecalPreview] tiles,
  /// each showing the decal image overlaid on the bell's current color.
  /// The currently selected decal is highlighted with a checkmark.
  /// Selecting a decal updates [ScheduleSettings.decals] and closes the dialog.
  ///
  /// Parameters:
  /// - [context]: Used to show the dialog and read [ColorScheme]
  /// - [bell]: The bell key (e.g. `'A'` or `'A_alt'`) whose decal is being set
  void _showDecalPopup(BuildContext context, String bell) {
    showDialog<String>(
      context: context,
      builder: (context) {
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final Size screen = MediaQuery.of(context).size;

        final String selected = ScheduleSettings.decals[bell] ?? "Blank";

        return Center(
          child: Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: screen.width * 0.85,
              height: screen.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select Decal',
                      style: TextStyle(
                        fontFamily: "Georama",
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Divider(
                      color: colorScheme.onSurface.withAlpha(64), height: 1),
                  Expanded(
                    child: ListView(
                      children:
                          ScheduleSettings.decalOptions.map((String decal) {
                        return InkWell(
                          onTap: () => Navigator.pop(context, decal),
                          child: _buildDecalPreview(
                              decal,
                              ScheduleSettings.colors[bell]!.toColor(),
                              decal == selected),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((selected) {
      if (selected != null) {
        setState(() {
          ScheduleSettings.decals[bell] = selected;
        });
      }
    });
  }

  /// Builds a single decal preview tile for the decal picker dialog.
  ///
  /// Appearance: A rounded rectangle with the decal image at 50% opacity over a
  /// colored background. Shows the decal name centered and a checkmark on the
  /// right when [selected] is `true`. A [Divider] is prepended for decals listed
  /// in [ScheduleSettings.decalOptionDividers].
  ///
  /// Parameters:
  /// - [decal]: The decal name to display and preview
  /// - [color]: The bell's current color, used as the background tint
  /// - [selected]: Whether this decal is currently applied to the bell
  Widget _buildDecalPreview(String decal, Color color, bool selected) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ScheduleSettings.decalOptionDividers.contains(decal))
          Divider(height: 4, thickness: 1.5, color: colorScheme.onSurface),
        Container(
          constraints: BoxConstraints(maxHeight: 64),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (decal != "Blank")
                Image.asset(
                  'assets/images/decals/$decal.png',
                  fit: BoxFit.cover,
                ).withOpacity(0.5),
              Container(color: color.withAlpha(selected ? 112 : 64)),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      ' $decal ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Exo_2',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        shadows: [
                          Shadow(
                            color: colorScheme.surface.withAlpha(180),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ).expandedFit(),
                    selected
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.check,
                                size: 32, color: colorScheme.onSurface))
                        : const SizedBox(width: 40),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
