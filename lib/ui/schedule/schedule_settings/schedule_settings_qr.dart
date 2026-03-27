import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/schedule_settings.dart';
import 'package:xschedule/schedule/schedule_storage.dart';
import 'package:xschedule/ui/schedule/schedule_settings/bell_settings/bell_button.dart';
import 'package:xschedule/ui/schedule/schedule_settings/bell_settings/bell_settings_menu.dart';
import 'package:xschedule/widgets/popup_menu.dart';
import 'package:xschedule/widgets/styled_button.dart';

/// Popup widget for importing and exporting bell vanity via QR codes.
///
/// Responsibilities:
/// - Toggles a live camera scanner to read bell QR codes
/// - On successful scan, writes the decoded bell data and opens [BellSettingsMenu]
/// - Provides a bell selection list for generating and displaying shareable QR codes
class ScheduleSettingsQr extends StatefulWidget {
  /// Creates the QR manager popup.
  ///
  /// Parameters:
  /// - [onStateChange]: The [setState] of the parent [ScheduleSettings] widget,
  ///   used to refresh the bell list after a QR import.
  const ScheduleSettingsQr({super.key, required this.onStateChange});

  /// Parent setState callback used to rebuild [ScheduleSettings] after importing a bell.
  final StateSetter onStateChange;

  @override
  State<StatefulWidget> createState() => _ScheduleSettingsQrState();
}

class _ScheduleSettingsQrState extends State<ScheduleSettingsQr> {
  /// Controls the camera scanner; configured for back-facing camera and QR format only.
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  /// Whether the camera scanner is currently visible and active.
  /// - true: scanner is expanded and scanning
  /// - false: scanner is collapsed and inactive
  bool _scanning = false;

  /// Handles a detected barcode from the scanner.
  /// Attempts to decode the QR data as a bell vanity JSON map.
  /// On success, writes the bell and opens [BellSettingsMenu] with a delete option.
  /// On failure, clears settings and shows a snackbar error.
  ///
  /// Parameters:
  /// - [capture]: The barcode capture event from [MobileScanner].
  void _onBarcodeDetected(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      try {
        final String data = barcode.displayValue!;
        final Map<String, dynamic> map = jsonDecode(data);
        final String bell = map.keys.first;
        ScheduleSettings.writeBell(
            bell,
            ScheduleStorage.decodeBellVanity(
                Map<String, dynamic>.from(map[bell])));

        Navigator.pop(context);
        context.pushPopup(BellSettingsMenu(
          bell: bell,
          onStateChange: widget.onStateChange,
          deleteButton: true,
        ));
        // Stop processing after the first valid barcode
        break;
      } catch (e) {
        ScheduleSettings.clearSettings();
        context.showSnackBar("Failed to scan QR Code.");
      }
    }
  }

  /// Toggles the scanner open or closed.
  void _onScanTap() {
    setState(() {
      if (_scanning) {
        _scanning = false;
        _scannerController.stop();
      } else {
        _scanning = true;
        _scannerController.start();
      }
    });
  }

  /// Closes the scanner if open, then pushes the bell selection popup.
  void _onShareTap() {
    if (_scanning) {
      setState(() {
        _scanning = false;
        _scannerController.stop();
      });
    }
    context.pushPopup(_buildQrSelectPopup());
  }

  @override
  Widget build(BuildContext context) {
    final double width = min(MediaQuery.of(context).size.width * .95, 500);
    final double scannerSize = width * .6;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PopupMenu(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(width, colorScheme),
          _buildDivider(width),
          _buildScanner(scannerSize, colorScheme),
          _buildDivider(width),
          _buildActionButtons(width),
        ],
      ),
    );
  }

  /// Builds the "QR Code Manager" title fitted to the popup width.
  ///
  /// Parameters:
  /// - [width]: Maximum width of the title container.
  /// - [colorScheme]: Provides text color.
  Widget _buildTitle(double width, ColorScheme colorScheme) {
    return Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        "QR Code Manager",
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          fontFamily: "Exo2",
          color: colorScheme.onSurface,
        ),
      ).fit(),
    );
  }

  /// Builds a full-width divider padded to the popup content width.
  ///
  /// Parameters:
  /// - [width]: The width of the surrounding popup content area.
  Widget _buildDivider(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: const Divider(),
    );
  }

  /// Builds the animated camera scanner panel.
  /// Collapses to height 0 when [_scanning] is false; expands to [scannerSize] when true.
  /// Displays [_buildCameraError] if camera access fails.
  ///
  /// Parameters:
  /// - [scannerSize]: The width and height of the square scanner view.
  /// - [colorScheme]: Provides the border color.
  Widget _buildScanner(double scannerSize, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: _scanning ? scannerSize : 0,
      width: scannerSize,
      child: _scanning
          ? Container(
              height: scannerSize,
              width: scannerSize,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 7.5),
              ),
              child: MobileScanner(
                controller: _scannerController,
                errorBuilder: (context, error, _) => _buildCameraError(),
                onDetect: _onBarcodeDetected,
              ),
            ).clip()
          : null,
    );
  }

  /// Builds the row of "Scan" and "Share" action buttons.
  ///
  /// Parameters:
  /// - [width]: The popup content width, used to proportion button widths.
  Widget _buildActionButtons(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            width: width,
            text: "Scan",
            icon: Icons.qr_code_scanner_rounded,
            onTap: _onScanTap,
          ),
          _buildActionButton(
            width: width,
            text: "Share",
            icon: Icons.share_outlined,
            onTap: _onShareTap,
          ),
        ],
      ),
    );
  }

  /// Builds a single large vertical [StyledButton] for the action row.
  ///
  /// Parameters:
  /// - [width]: The popup content width; each button takes 2/5 of this.
  /// - [text]: Label displayed below the icon.
  /// - [icon]: Icon displayed above the label.
  /// - [onTap]: Callback invoked on tap.
  Widget _buildActionButton({
    required double width,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      width: width * 2 / 5,
      height: 100,
      child: StyledButton(
        vertical: true,
        iconSize: 40,
        text: text,
        icon: icon,
        onTap: onTap,
      ),
    );
  }

  /// Builds the bell selection popup for choosing which bell to export as a QR code.
  /// Displays a scrollable list of [BellButton] tiles, each opening [_buildQrDisplayPopup].
  Widget _buildQrSelectPopup() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Size screenSize = MediaQuery.of(context).size;

    return PopupMenu(
      child: Container(
        height: screenSize.height * .75,
        width: screenSize.width * .8,
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
                  color: colorScheme.onSurface,
                ),
              ).fit(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List<Widget>.generate(
                    ScheduleSettings.sampleBells.length,
                    (i) {
                      final String bell = ScheduleSettings.sampleBells[i];
                      return BellButton(
                        bell: bell,
                        buttonWidth: screenSize.width * .8 - 16,
                        icon: Icons.qr_code_2_outlined,
                        onTap: () => context.pushPopup(
                          _buildQrDisplayPopup(bell),
                          begin: const Offset(0, 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: StyledButton(
                text: "Done",
                width: screenSize.width * .7,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ).clip(borderRadius: BorderRadius.circular(16)),
    );
  }

  /// Builds the QR code display popup for a single bell.
  /// Shows the bell's emoji and name as a header, followed by a scannable QR code
  /// embedding the full vanity map as JSON with the X-Schedule logo at the center.
  ///
  /// Parameters:
  /// - [bell]: The bell identifier whose vanity will be encoded into the QR.
  Widget _buildQrDisplayPopup(String bell) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final Map<String, dynamic> bellVanity =
        ScheduleSettings.bellVanity[bell] ?? {};
    // Encode the bell's full vanity map as JSON for the QR payload
    final String encodedBell =
        jsonEncode({bell: ScheduleStorage.encodeBellVanity(bellVanity)});
    final String emoji = bellVanity['emoji'];
    // Only show emoji decorations if the emoji differs from the raw bell ID
    final bool hasEmoji = emoji != bell;

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
                if (hasEmoji)
                  Text('$emoji ', style: const TextStyle(fontSize: 30)),
                Container(
                  constraints: BoxConstraints(maxWidth: screenWidth * .5),
                  child: Text(
                    bellVanity['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontFamily: "Exo2",
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ).fit(),
                ),
                if (hasEmoji)
                  Text(' $emoji', style: const TextStyle(fontSize: 30)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: QrImageView(
              data: encodedBell,
              semanticsLabel: "X-Schedule",
              size: screenWidth * .75,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              embeddedImage:
                  const AssetImage("assets/images/xschedule_transparent.png"),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: Size.square(screenWidth * .25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: StyledButton(
              text: "Done",
              width: screenWidth * .7,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an error state view shown inside the scanner when camera access fails.
  /// Displays an error icon and message on a [tertiary] colored background.
  Widget _buildCameraError() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.tertiary,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: colorScheme.onTertiary, size: 64),
          const SizedBox(height: 8),
          Text(
            "Failed to access camera",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, color: colorScheme.onTertiary),
          ),
        ],
      ).fit(),
    );
  }
}
