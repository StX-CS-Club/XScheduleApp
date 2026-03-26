import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/widgets/popup_menu.dart';

/// Popup widget displaying app contributors, copyright info, and build version.
///
/// Responsibilities:
/// - Loads and parses contributor data from credits.json at startup
/// - Renders contributors in categorized, 2-column grid sections
/// - Displays app version and build number from [packageInfo]
class Credits extends StatelessWidget {
  const Credits({super.key});

  /// Contributor data loaded from assets/data/credits.json.
  /// Keys are section titles (e.g. "Developer"); values are lists of names.
  static final Map<String, List<dynamic>> credits = {};

  /// Build and version info populated at startup via [PackageInfo.fromPlatform].
  static late PackageInfo packageInfo;

  /// The one section title that is exempt from pluralization, as it is already plural.
  static const String _alumniKey = "Development Alumni";

  /// Reads assets/data/credits.json and populates [credits].
  /// Must be called during app initialization before this widget is shown.
  static Future<void> loadJson() async {
    final String jsonString = await rootBundle.loadString("assets/data/credits.json");
    final Map<String, dynamic> json = jsonDecode(jsonString);
    credits.addAll(Map<String, List<dynamic>>.from(json));
  }

  /// Builds a labeled section for a single contributor category.
  /// Renders a bold section title followed by contributor names in a 2-column grid.
  /// Returns an empty [Container] if the section has no entries.
  ///
  /// Parameters:
  /// - [context]: Used to read the [ColorScheme].
  /// - [sectionTitle]: The key from [credits] used as the section heading.
  ///   Automatically pluralized if the list has more than one entry (except [_alumniKey]).
  static Widget _buildContributorSection(BuildContext context, String sectionTitle) {
    final List<dynamic> names = credits[sectionTitle] ?? [];

    if (names.isEmpty) return Container();

    // Pluralize the section title unless the key is already plural
    if (names.length > 1 && sectionTitle != _alumniKey) {
      sectionTitle = '${sectionTitle}s';
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sectionTitle,
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Georama",
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          // Names displayed in a 2-column grid
          Column(
            children: List<Widget>.generate(
              (names.length + 1) ~/ 2,
                  (row) => _buildNameRow(context, names, row, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single row of up to 2 contributor names for the grid layout.
  /// If [row] * 2 + col exceeds the list length, an empty [Container] fills that cell.
  ///
  /// Parameters:
  /// - [context]: Used to read the [ColorScheme].
  /// - [names]: The full list of names for this section.
  /// - [row]: The zero-based row index within the grid.
  /// - [colorScheme]: Provides text color.
  static Widget _buildNameRow(
      BuildContext context,
      List<dynamic> names,
      int row,
      ColorScheme colorScheme,
      ) {
    return Row(
      children: List<Widget>.generate(2, (col) {
        final int index = 2 * row + col;
        if (index >= names.length) return Container();
        return Text(
          names[index],
          style: TextStyle(fontSize: 20, fontFamily: "Georama", color: colorScheme.onSurface),
        ).expandedFit(padding: const EdgeInsets.symmetric(horizontal: 4));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Size screenSize = MediaQuery.of(context).size;

    return PopupMenu(
      backgroundColor: colorScheme.secondaryContainer,
      popButton: true,
      child: SizedBox(
        width: screenSize.width * 4 / 5,
        height: screenSize.height * 2 / 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 125,
              margin: const EdgeInsets.all(8),
              child: Image.asset("assets/images/xschedule.png")
                  .clip(borderRadius: BorderRadius.circular(20)),
            ),
            Text(
              "X-Schedule",
              style: TextStyle(
                fontSize: 25,
                fontFamily: "Georama",
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              "Contributors",
              style: TextStyle(
                fontSize: 22.5,
                height: 1,
                fontFamily: "Georama",
                color: colorScheme.onSurface,
                decoration: TextDecoration.underline,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                color: colorScheme.surface,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(credits.length, (i) {
                      return _buildContributorSection(context, credits.keys.elementAt(i));
                    }),
                  ),
                ),
              ),
            ),
            Text(
              "© 2025 St. Xavier HS, Cincinnati OH\nAvailable under MIT license.",
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 0.975,
                fontSize: 17.5,
                fontFamily: "Georama",
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "v${packageInfo.version} Build ${packageInfo.buildNumber}",
              style: TextStyle(
                fontSize: 14,
                height: 0.9,
                fontFamily: "Georama",
                color: colorScheme.onSurface,
              ),
            ).fit(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}