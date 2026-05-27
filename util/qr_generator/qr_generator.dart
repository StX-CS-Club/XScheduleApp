import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

const List<String> clubTitles = [
  "Advocacy Club",
  "AMDG",
  "Anime Club",
  "Aquaponics Club",
  "Asian Pacific Alliance Club",
  "Astronomy Club",
  "Audio Visual Club",
  "Backpacking Club",
  "Bands and Ensembles",
  "Bible Study Club",
  "Black Student Union",
  "Bomb Squad Fall",
  "Bomb Squad Winter",
  "Bomber Pilots",
  "Boxing Club",
  "Build Something Big",
  "Chamber & Blues",
  "Chess Club",
  "Chinese Club",
  "Computer Science Club",
  "Culinary Club",
  "EDM Club",
  "Environmental Action Club",
  "E-Sports",
  "ESPX",
  "Ethics Club",
  "Euchre Club",
  "Expressions",
  "Fair Trade Club",
  "Fe Y Alegria",
  "Fishing Club",
  "French Club",
  "German Club",
  "Guitar Club",
  "H.O.L.A. Club",
  "Hands Across Campus",
  "InterAlliance Chapter",
  "Intramural Basketball",
  "Intramural Golf Fall",
  "Intramural Golf Spring",
  "Investment Club",
  "Latin Club",
  "Lego Club",
  "Liturgical Music",
  "Maker Club",
  "Marine Biology Club",
  "Math Club",
  "Minecraft Club",
  "Mission Collection Club",
  "Mock Trial",
  "Model Railroading Club",
  "Model UN",
  "Muslim Student Association",
  "National Honor Society",
  "Ohio Seal of Biliteracy",
  "Parents Across Cultures",
  "Pickleball Club",
  "Pokémon Club",
  "Quiz Team",
  "Robot-X",
  "Rock Climbing Club",
  "Science Olympiad",
  "Sources of Strength",
  "Spanish Club",
  "Spike Ball Club",
  "St. Xavier United",
  "STEMs Club",
  "Superhero Film Club",
  "The Blueprint",
  "Theatre Xavier",
  "Triathlon Club",
  "Vocal Groups",
  "World Language Honor Society",
  "X-Cell Club",
  "X-Emplify",
  "Xpeditions: RPG Club",
  "X-Plore Healthcare",
  "Young Conservatives",
  "Young Progressives",
  "Young Writers Forum",
  "Zoology Club",
];

void main() {
  runApp(const QrApp());
}

class QrApp extends StatelessWidget {
  const QrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: QrHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QrHomePage extends StatefulWidget {
  const QrHomePage({super.key});

  @override
  State<QrHomePage> createState() => _QrHomePageState();
}

class _QrHomePageState extends State<QrHomePage> {
  final Map<String, GlobalKey> _qrKey = {};

  Future<void> _exportPng(String title) async {
    final bytes = await QrExporter.widgetToPng(_qrKey[title]!);

    // Save location (change this if you want)
    final directory = Directory("C:/Users/johnd/Documents/QRCodes");

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File("${directory.path}/${title.toLowerCase().replaceAll(" ", "_").replaceAll(":", "").replaceAll(".", "")}.png");

    await file.writeAsBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    for(String title in clubTitles){
      _qrKey[title] = GlobalKey();
    }
    return Scaffold(
      appBar: AppBar(title: const Text("QR Generator")),
      body: ListView(
        children: [
          ElevatedButton(
            onPressed: (){
              for(String title in clubTitles){
                _exportPng(title);
              }
            },
            child: const Text("Export as PNGs"),
          ),
          const SizedBox(height: 20),

          /// 🔹 The QR widget we will export
          Stack(children: List<Widget>.generate(clubTitles.length, (i){
            final String title = clubTitles[i];
            return Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 16),
              child: RepaintBoundary(
                key: _qrKey[title],
                child: QrCard(
                  title: title,
                  data: "xschedule_bp:${title.toLowerCase().replaceAll(" ", "_").replaceAll(":", "").replaceAll(".", "")}",
                ),
              ),
            );
          }))
        ],
      ),
    );
  }
}

/// 🔹 Pretty QR Widget (Title + QR + subtitle)
class QrCard extends StatelessWidget {
  final String title;
  final String data;

  const QrCard({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfff4ecdb),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          QrImageView(
            data: data,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            size: 250,
            embeddedImage:
                const AssetImage("assets/images/april_fools_transparent.png"),
            embeddedImageStyle: QrEmbeddedImageStyle(
              size: Size.square(125),
            ),
            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 🔹 Converts any widget (via GlobalKey) → PNG
class QrExporter {
  static Future<Uint8List> widgetToPng(GlobalKey key) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3.0);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}
