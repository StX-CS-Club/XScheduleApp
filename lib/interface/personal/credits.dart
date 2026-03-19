import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/materials/popup_menu.dart';

class Credits extends StatelessWidget {
  const Credits({super.key});

  // Map of credits info derived from json file interpreted on startup
  static final Map<String, List<dynamic>> credits = {};

  // App build info determined on startup
  static late PackageInfo packageInfo;

  // Interprets the credits.json file on startup
  static Future<void> loadCreditsJson() async {
    // Loads json file contents as String
    final String jsonString =
        await rootBundle.loadString("assets/data/credits.json");
    // Interprets String as hashmap
    final Map<String, dynamic> json = jsonDecode(jsonString);
    // Adds all instances which fit typing (should be all)
    credits.addAll(Map<String, List<dynamic>>.from(json));
  }

  // Builds a list of Text Widgets containing values from json file
  static Widget _buildTextList(BuildContext context, String key) {
    // List of Strings from given key
    final List<dynamic> list = credits[key] ?? [];

    // If no names found; don't bother building list
    if (list.isEmpty) {
      return Container();
    }

    // Makes the title plural if list >1
    if (list.length > 1 && key != "Development Alumni") {
      key = '${key}s';
    }
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Returns Container featuring title and generated list of names
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title list
          Text(
            key,
            style: TextStyle(
                fontSize: 20,
                fontFamily: "Georama",
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
          ),
          // Generated Column of pairs of names
          Column(
            children: List<Widget>.generate((list.length / 2).round(), (r) {
              return Row(
                children: List<Widget>.generate(2, (c) {
                  // Index of name being generated
                  final int index = 2 * r + c;
                  // If index passes surpasses list length, return empty Container
                  if (index >= list.length) {
                    return Container();
                  }
                  // Returns expandedFit Text of name
                  return Text(
                    list[index],
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Georama",
                        color: colorScheme.onSurface),
                  ).expandedFit(
                      padding: const EdgeInsets.symmetric(horizontal: 4));
                }),
              );
            }),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Returns credits popup
    return PopupMenu(
        backgroundColor: colorScheme.secondaryContainer,
        popButton: true,
        child: SizedBox(
          width: mediaQuery.size.width * 4 / 5,
          height: mediaQuery.size.height * 2 / 3,
          // Contents displayed in Column
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // X-Schedule Logo
              Container(
                height: 125,
                margin: const EdgeInsets.all(8),
                child: Image.asset("assets/images/xschedule.png")
                    .clip(borderRadius: BorderRadius.circular(20)),
              ),
              // X-Schedule title
              Text(
                "X-Schedule",
                style: TextStyle(
                    fontSize: 25,
                    fontFamily: "Georama",
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
              ),
              // Credits title
              Text(
                "Contributors",
                style: TextStyle(
                    fontSize: 22.5,
                    height: 1,
                    fontFamily: "Georama",
                    color: colorScheme.onSurface,
                    decoration: TextDecoration.underline),
              ),
              // ScrollView of Credits set to fill rest of popup
              Expanded(
                  child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                color: colorScheme.surface,
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // Builds list of contributors
                      children: List<Widget>.generate(credits.length, (i) {
                        final String key = credits.keys.elementAt(i);
                        return _buildTextList(context, key);
                      })),
                ),
              )),
              // Copyright info text
              Text(
                "© 2025 St. Xavier HS, Cincinnati OH\nAvailable under MIT license.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    height: 0.975,
                    fontSize: 17.5,
                    fontFamily: "Georama",
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              // Build and Version info
              Text(
                "v${packageInfo.version} Build ${packageInfo.buildNumber}",
                style: TextStyle(
                    fontSize: 14,
                    height: 0.9,
                    fontFamily: "Georama",
                    color: colorScheme.onSurface),
              ).fit(),
              const SizedBox(height: 8),
            ],
          ),
        ));
  }
}
