import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';


/// Purpose: To provide a PDF link to the lunch menu for a given week
class MenuService {
  static final String _baseMenuUrl = "https://www.aviserves.com/stxavier/menus";

  /// Returns: Link to lunch menu PDF for given week
  ///
  /// Parameters:
  /// - [week]: The current numbered [Week] of ISO 8601
  static String _buildMenuUrl(int week) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "$_baseMenuUrl/wk$week/bistro_menu_wk$week.pdf?cb=$timestamp";
  }

  static Future<File> fetchDiningMenu(int week) async {
    final url = _buildMenuUrl(week);
    final response = await http.get(Uri.parse(url));
    //print(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to load menu: ${response.statusCode}');
    }

    // Troubleshooting the pdf link
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/pdf')) {
      throw Exception('Expected PDF, got: $contentType');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dining_menu.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }


}