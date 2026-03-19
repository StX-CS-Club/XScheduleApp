import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_button.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_settings.dart';
import 'package:xschedule/interface/schedule/schedule_settings/bell_settings/bell_settings_menu.dart';
import 'package:xschedule/schedule/schedule.dart';
import 'package:xschedule/materials/popup_menu.dart';
import 'package:xschedule/materials/styled_button.dart';

class ScheduleSettingsQr extends StatefulWidget {
  const ScheduleSettingsQr({super.key, required this.setSourceState});

  final StateSetter setSourceState;

  @override
  State<StatefulWidget> createState() => _ScheduleSettingsQrState();
}

class _ScheduleSettingsQrState extends State<ScheduleSettingsQr> {
  final MobileScannerController _controller = MobileScannerController(
      facing: CameraFacing.back, formats: [BarcodeFormat.qrCode]);
  bool _scanning = false;

  // Builds the popup for selecting and uploading an image
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final double width = min(mediaQuery.size.width * .95, 500);
    final double scannerSize = width * .6;

    // Returns popup
    return PopupMenu(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: width),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            "QR Code Manager",
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFamily: "Exo2",
                color: colorScheme.onSurface),
          ).fit(),
        ),
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Divider(),
        ),
        AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _scanning ? scannerSize : 0,
            width: scannerSize,
            child: _scanning
                ? Container(
                    height: scannerSize,
                    width: scannerSize,
                    decoration: BoxDecoration(
                        border:
                            Border.all(color: colorScheme.primary, width: 7.5)),
                    child: MobileScanner(
                      controller: _controller,
                      errorBuilder: (context, error, _){
                        return _buildCameraError();
                      },
                      onDetect: (capture) {
                        for (Barcode barcode in capture.barcodes) {
                          try {
                            String data = barcode.displayValue!;
                            Map<String, dynamic> map = jsonDecode(data);
                            String bell = map.keys.first;

                            BellSettings.writeBell(bell, map[bell]);

                            Navigator.pop(context);
                            context.pushPopup(BellSettingsMenu(
                                bell: bell,
                                setState: widget.setSourceState,
                                deleteButton: true));
                            break;
                          } catch (e) {
                            BellSettings.clearSettings();
                            context.showSnackBar("Failed to scan QR Code.");
                          }
                        }
                      },
                    ),
                  ).clip()
                : null),
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Divider(),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    width: width * 2 / 5,
                    height: 100,
                    child: StyledButton(
                      vertical: true,
                      iconSize: 40,
                      text: "Scan",
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () {
                        setState(() {
                          _scanning = !_scanning;
                        });
                      },
                    )),
                Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    width: width * 2 / 5,
                    height: 100,
                    child: StyledButton(
                      vertical: true,
                      iconSize: 40,
                      text: "Share",
                      icon: Icons.share_outlined,
                      onTap: () {
                        if (_scanning) {
                          setState(() {
                            _scanning = false;
                          });
                        }
                        context.pushPopup(_buildQrSelect());
                      },
                    )),
              ],
            ))
      ],
    ));
  }

  Widget _buildQrSelect() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return PopupMenu(
        child: Container(
            height: mediaQuery.size.height * .75,
            width: mediaQuery.size.width * .8,
            color: colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Export Bell as QR Code",
                      style: TextStyle(
                          fontSize: 30,
                          fontFamily: "Exo2",
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface),
                    ).fit()),
                Expanded(
                    child: SingleChildScrollView(
                        child: Column(
                            children: List<Widget>.generate(
                                Schedule.sampleBells.length, (i) {
                  String bell = Schedule.sampleBells[i];
                  return BellButton(
                      bell: bell,
                      buttonWidth: mediaQuery.size.width * .8 - 16,
                      icon: Icons.qr_code_2_outlined,
                      onTap: () {
                        context.pushPopup(_displayQr(bell),
                            begin: Offset(0, 1));
                      });
                })))),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: StyledButton(
                    text: "Done",
                    width: mediaQuery.size.width * .7,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            )).clip(borderRadius: BorderRadius.circular(16)));
  }

  Widget _displayQr(String bell) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final Map<String, dynamic> bellVanity = Schedule.bellVanity[bell] ?? {};
    final Map<String, Map<String, dynamic>> bellMap = {bell: bellVanity};
    final String encodedBell = jsonEncode(bellMap);

    final String emoji = bellVanity['emoji'];

    return PopupMenu(
        backgroundColor: const Color(0xfff4ecdb),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (emoji != bell)
                    Text('$emoji ', style: TextStyle(fontSize: 30)),
                  Container(
                    constraints:
                        BoxConstraints(maxWidth: mediaQuery.size.width * .5),
                    child: Text(bellVanity['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 30,
                                fontFamily: "Exo2",
                                fontWeight: FontWeight.w600,
                                color: Colors.black))
                        .fit(),
                  ),
                  if (emoji != bell)
                    Text(' $emoji', style: TextStyle(fontSize: 30)),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: QrImageView(
                  data: encodedBell,
                  semanticsLabel: "X-Schedule",
                  size: mediaQuery.size.width * .75,
                  embeddedImage:
                      AssetImage("assets/images/xschedule_transparent.png"),
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: Size.square(mediaQuery.size.width * .25),
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(8),
              child: StyledButton(
                text: "Done",
                width: mediaQuery.size.width * .7,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            )
          ],
        ));
  }
  
  Widget _buildCameraError(){
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.tertiary,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.onTertiary, size: 64),
          const SizedBox(height: 8),
          Text("Failed to access camera", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: colorScheme.onTertiary)),
        ],
      ).fit(),
    );
  }
}
