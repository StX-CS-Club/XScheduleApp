import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:xschedule/lunch_menu/menu_service.dart';

/// Purpose: Builds lunch menu page
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
      final file = await MenuService.fetchDiningMenu(widget.week-1); // week-1 because the website has all their weeks one week behind
      _menuFile.value = file;
    } catch (e) {
      _error.value = "Cannot load lunch menu";
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
    return Scaffold(
      appBar: AppBar(title: const Text('Lunch Menu')),
      body: ValueListenableBuilder<String?>(
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
      ),
    );
  }
}