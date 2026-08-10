import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/backend/menu_service.dart';

/// Purpose: Builds lunch menu page to display PDF
class LunchMenuPage extends StatefulWidget {
  const LunchMenuPage({super.key, required this.week});

  final int week;

  @override
  State<LunchMenuPage> createState() => _LunchMenuPageState();
}

class _LunchMenuPageState extends State<LunchMenuPage> {
  final ValueNotifier<File?> _menuFile = ValueNotifier(null);
  final ValueNotifier<String?> _error = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final file = await MenuService.fetchDiningMenu(widget.week -
          1); // week-1 because the website has all their weeks one week behind
      _menuFile.value = file;
    } catch (e) {
      _error.value = "Failed to Load Lunch Menu";
      //_error.value = e.toString();
    }
  }

  @override
  void dispose() {
    _menuFile.dispose();
    _error.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
          title: Text('Lunch Menu',
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: "Georama",
                  fontSize: 28,
                  fontWeight: FontWeight.w500)),
          centerTitle: true),
      body: Column(
        children: [
          Container(
            color: colorScheme.primary,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.onPrimary, size: 32),
                const SizedBox(width: 8),
                Text(
                    "Lunch Information may be inaccurate.\nPlease check the date shown in the image.",
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w500,
                    fontSize: 16
                  ),
                ).expandedFit(alignment: Alignment.centerLeft),
              ],
            )
          ),
          Expanded(
              child: ValueListenableBuilder<String?>(
            valueListenable: _error,
            builder: (context, error, _) {
              if (error != null) {
                return Center(child: Text(error));
              }
              return ValueListenableBuilder<File?>(
                valueListenable: _menuFile,
                builder: (context, file, _) {
                  if (file == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SfPdfViewer.file(file);
                },
              );
            },
          ))
        ],
      ),
    );
  }
}
