import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:xschedule/april_fools/2026_battle_pass/battle_pass.dart';
import 'package:xschedule/extensions/build_context_extension.dart';
import 'package:xschedule/extensions/widget_extension.dart';
import 'package:xschedule/schedule/schedule_settings.dart';
import 'package:xschedule/widgets/styled_button.dart';

import '../../widgets/popup_menu.dart';

/// The main page for the 2026 April Fools Battle Pass feature.
///
/// Responsibilities:
/// - Displaying a progress bar and the list of unlockable decal packs
/// - Animating pack redemption with a fall animation overlay
/// - Hosting a QR code scanner for recording battle pass scans
class BattlePassPage extends StatefulWidget {
  const BattlePassPage({super.key});

  @override
  State<StatefulWidget> createState() => _BattlePassPageState();
}

/// Private [State] for [BattlePassPage].
///
/// Responsibilities:
/// - Managing the animation controllers for pack redemption and confetti
/// - Building the progress bar, decal pack stack, and QR scanner popup
/// - Handling QR scan detection and pack unlock logic
class _BattlePassPageState extends State<BattlePassPage>
    with TickerProviderStateMixin {
  /// Vertical spacing in pixels between each decal pack row in the progress stack.
  static const double packSpacing = 120;

  /// Height in pixels of each decal pack tile.
  static const double packHeight = 64;

  /// Corner radius applied to each decal pack container.
  static const double packBorderRadius = 8;

  /// Controls the live QR camera scanner; configured for back-facing camera and QR format only.
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  /// Controls the one-shot confetti burst played on first page open.
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));

  /// Animates a redeemed pack tile falling off the screen after redemption.
  ///
  /// This method:
  /// - Creates a brief rise followed by a longer fall animation via staggered [Interval]s
  /// - Fades the tile out during the fall
  /// - Overlays the animation via an [OverlayEntry] so it renders above the page content
  /// - Unlocks the pack in [BattlePass.unlocked], granting [BattlePass.xPack] decals if "X"
  /// - Cleans up the overlay and animation controller once complete
  ///
  /// Parameters:
  /// - [pack]: The name of the pack being redeemed
  /// - [globalPosition]: The screen-space top-left position of the pack tile
  /// - [width]: The width of the pack tile in pixels
  /// - [height]: The height of the pack tile in pixels
  void _animatePack(
      String pack, Offset globalPosition, double width, double height) {
    late OverlayEntry entry;
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final riseAnim = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final navBarHeight =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;
    final clipBottom = screenHeight - navBarHeight;
    final fallDistance = clipBottom - globalPosition.dy + height + 100;

    final fallAnim = Tween<double>(begin: 0, end: fallDistance).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );

    final opacityAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final dy = riseAnim.value + fallAnim.value;
            return Positioned.fill(
              child: ClipRect(
                clipper: _BottomClipper(clipBottom),
                child: Stack(
                  children: [
                    Positioned(
                      left: globalPosition.dx,
                      top: globalPosition.dy + dy,
                      width: width,
                      height: height,
                      child: Opacity(
                        opacity: opacityAnim.value,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(packBorderRadius),
                          clipBehavior: Clip.antiAlias,
                          child: _buildDecalPackContent(pack,
                              isAnimatingCopy: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(entry);
    setState(() {
      BattlePass.unlocked.add(pack);
      if (pack == "X") {
        for (String decal in BattlePass.xPack) {
          localStorage.setItem("specialDecal:$decal", "T");
          ScheduleSettings.addSpecialDecals();
        }
      }
      BattlePass.save();
    });

    controller.forward().whenComplete(() {
      entry.remove();
      controller.dispose();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double width = min(48, mediaQuery.size.width * .2);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (localStorage.getItem("battlePass:confetti") != "T") {
        await Future.delayed(const Duration(milliseconds: 100));
        _confettiController.play();
        localStorage.setItem("battlePass:confetti", "T");
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      appBar: _buildAppBar(colorScheme, mediaQuery.size.width),
      // "Scan QR Code" button is only shown while the event is live (before April 3, 2026)
      bottomNavigationBar: DateTime.now().isBefore(DateTime(2026, 4, 3)) ? _buildDoneButton(context, mediaQuery.size.width) : null,
      extendBody: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  width: mediaQuery.size.width - 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surface,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "🎉 The X-Schedule Battle Pass is here!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Exo_2",
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: colorScheme.onSurface,
                        ),
                      ).fit(),
                      Text(
                        "Scan QR codes at club meetings & school events to level up and unlock exclusive decal packs for decorating your schedule.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Exo_2",
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: colorScheme.onSurface.withAlpha(200),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            "Scan  →  Level Up  →  Unlock Decals",
                            style: TextStyle(
                              fontFamily: "Exo_2",
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Row(
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Stack(
                              children: [
                                // Background track for the progress bar
                                Container(
                                  height: 10 * 120 + 64,
                                  width: width,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    color: colorScheme.surface,
                                  ),
                                ),
                                // Tick marks along the progress bar track
                                Column(
                                  children: List<Widget>.generate(10, (i) {
                                    return Container(
                                        margin: EdgeInsets.only(
                                            top: i == 0
                                                ? packSpacing - 2.5 + 32
                                                : packSpacing - 2.5,
                                            left: 8,
                                            right: 8),
                                        height: 2.5,
                                        width: width - 16,
                                        color: colorScheme.onSurface
                                            .withAlpha(128));
                                  }),
                                ),
                                // Animated fill bar showing current progress
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1500),
                                  height:
                                      min(BattlePass.scanned.length, 10) * 120 +
                                          64,
                                  width: width,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.secondary
                                          ])),
                                )
                              ],
                            )),
                        // Stack of decal pack tiles positioned alongside the progress bar
                        Stack(
                          children: List<Widget>.generate(
                              BattlePass.rewards.length, (i) {
                            return _buildDecalPack(
                                BattlePass.rewards.keys.toList()[i]);
                          }),
                        )
                      ],
                    ))
              ],
            ),
          ),
          // Top fade overlay to blend scroll content with the background
          IgnorePointer(
              child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withAlpha(0)
                      ])))),
          // Bottom fade overlay to blend scroll content with the background
          IgnorePointer(
              child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                height: 32,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withAlpha(0)
                    ]))),
          )),
          // Confetti burst played once on first page open
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child:
              ConfettiWidget(
                confettiController: _confettiController,
                numberOfParticles: 150,
                blastDirectionality: BlastDirectionality.explosive,
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Builds a single decal pack tile positioned at its unlock level on the progress stack.
  ///
  /// Appearance: A rounded rectangle containing the pack's background image and
  /// either a "REDEEM" button, a "-REDEEMED-" label, or the required scan count.
  ///
  /// Parameters:
  /// - [pack]: The pack name, used to look up its unlock level in [BattlePass.rewards]
  Widget _buildDecalPack(String pack) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double width =
        mediaQuery.size.width - min(48, mediaQuery.size.width * .2) - 48;

    final key = GlobalKey();
    return Padding(
      padding: EdgeInsets.only(
          top: BattlePass.rewards[pack]! * packSpacing, right: 16),
      child: Container(
        key: key,
        width: width,
        height: packHeight,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(packBorderRadius)),
        clipBehavior: Clip.antiAlias,
        child: _buildDecalPackContent(pack, packKey: key),
      ),
    );
  }

  /// Builds the visual content inside a decal pack tile.
  ///
  /// Appearance: A [Stack] with the pack's background image at 50% opacity,
  /// a colored overlay (primary when redeemable, surface when redeemed),
  /// the pack name, and either a "REDEEM" button or status label.
  ///
  /// Parameters:
  /// - [pack]: The pack name displayed in the tile
  /// - [isAnimatingCopy]: When `true`, hides the action button and status label
  ///   (used for the falling animation overlay copy)
  /// - [packKey]: The [GlobalKey] of the original tile, used to locate its
  ///   screen position when triggering the fall animation
  Widget _buildDecalPackContent(String pack,
      {bool isAnimatingCopy = false, GlobalKey? packKey}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double width =
        mediaQuery.size.width - min(48, mediaQuery.size.width * .2) - 64;

    final bool unlocked =
        BattlePass.rewards[pack]! <= BattlePass.scanned.length;
    final bool redeemed = BattlePass.unlocked.contains(pack);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/decals/$pack.png',
          fit: BoxFit.cover,
        ).withOpacity(0.5),
        Container(
          color: redeemed && !isAnimatingCopy
              ? colorScheme.surface.withAlpha(64)
              : colorScheme.primary.withAlpha(64),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              ' $pack Pack ',
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
            if (isAnimatingCopy)
              const SizedBox.shrink()
            else if (redeemed)
              Text(
                '-REDEEMED-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
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
              )
            else if (unlocked)
              Container(
                width: width / 2,
                height: 24,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: StyledButton(
                  text: "REDEEM",
                  onTap: () {
                    if (packKey?.currentContext != null) {
                      final RenderBox box = packKey!.currentContext!
                          .findRenderObject() as RenderBox;
                      final Offset globalPos = box.localToGlobal(Offset.zero);
                      _animatePack(
                          pack, globalPos, box.size.width, box.size.height);
                    } else {
                      setState(() {
                        BattlePass.unlocked.add(pack);
                        BattlePass.save();
                      });
                    }
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Builds the custom app bar with the "X-SCHEDULE BATTLE PASS" title and a shadow divider.
  ///
  /// Appearance: A bottom-aligned title in bold Exo_2 font with a full-width shadow divider below.
  ///
  /// Parameters:
  /// - [colorScheme]: Provides text and shadow colors
  /// - [screenWidth]: Used to size the divider
  PreferredSizeWidget _buildAppBar(
      ColorScheme colorScheme, double screenWidth) {
    return PreferredSize(
      preferredSize: Size(screenWidth, 55),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "X-SCHEDULE BATTLE PASS",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                fontFamily: "Exo_2",
                color: colorScheme.onSurface,
              ),
            ).fit(),
            Container(
              color: colorScheme.shadow,
              height: 2.5,
              width: screenWidth - 10,
              margin: const EdgeInsets.only(top: 5),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "Scan QR Code" button pinned to the bottom of the screen.
  /// Opens the QR scanner popup when tapped.
  ///
  /// Appearance: A horizontally centered [StyledButton] with a QR scanner icon.
  ///
  /// Parameters:
  /// - [context]: Used to push the scanner popup
  /// - [screenWidth]: Used to center the button horizontally
  Widget _buildDoneButton(BuildContext context, double screenWidth) {
    return Container(
        height: 40,
        margin:
            EdgeInsets.symmetric(vertical: 20, horizontal: screenWidth * .25),
        child: StyledButton(
          text: "Scan QR Code",
          icon: Icons.qr_code_scanner_rounded,
          borderRadius: null,
          onTap: () {
            context.pushPopup(_buildScanner());
            _scannerController.start();
          },
        ));
  }

  /// Builds the QR scanner popup widget.
  ///
  /// Appearance: A [PopupMenu] containing a title, dividers, a square live scanner view,
  /// and a second divider at the bottom.
  Widget _buildScanner() {
    final double width = min(MediaQuery.of(context).size.width * .95, 500);
    final double scannerSize = width * .6;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PopupMenu(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: width),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              "Scan QR Code",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFamily: "Exo2",
                color: colorScheme.onSurface,
              ),
            ).fit(),
          ),
          Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: const Divider(),
          ),
          Container(
            height: scannerSize,
            width: scannerSize,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.primary, width: 7.5),
            ),
            child: MobileScanner(
              controller: _scannerController,
              errorBuilder: (context, error) => _buildCameraLoading(),
              onDetect: _onBarcodeDetected,
            ),
          ).clip(),
          Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: const Divider(),
          ),
        ],
      ),
    );
  }

  /// Regex that matches a valid battle pass QR code payload.
  ///
  /// Captures:
  /// - Full match: any string beginning with `xschedule_bp:` (e.g. `xschedule_bp:event123`)
  final regex = RegExp(r'^xschedule_bp:.*');

  /// Handles a detected barcode from the scanner.
  ///
  /// This method:
  /// - Iterates the first barcode in [capture]
  /// - Validates the payload matches [regex] and has not already been scanned
  /// - On success, closes the popup, stops the scanner, and records the scan
  /// - On failure, shows a snackbar error
  ///
  /// Parameters:
  /// - [capture]: The barcode capture event from [MobileScanner]
  void _onBarcodeDetected(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      try {
        final String data = barcode.displayValue!;
        if (regex.hasMatch(data) && !BattlePass.scanned.contains(data)) {
          Navigator.pop(context);
          _scannerController.stop();
          setState(() {
            BattlePass.scanned.add(data);
            BattlePass.save();
          });
        }
        // Stop processing after the first valid barcode
        break;
      } catch (e) {
        context.showSnackBar("Failed to scan QR Code.");
      }
    }
  }

  /// Builds a loading view shown inside the scanner while camera access is being established.
  ///
  /// Appearance: A [tertiary]-colored background with a centered [CircularProgressIndicator]
  /// and an "Accessing Camera..." label.
  Widget _buildCameraLoading() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.tertiary,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(color: colorScheme.onTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            "Accessing Camera...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, color: colorScheme.onTertiary),
          ),
        ],
      ).fit(),
    );
  }
}

/// A [CustomClipper] that clips a [Rect] to a fixed bottom boundary.
///
/// Used by the pack fall animation to prevent the animated tile from
/// rendering below the bottom navigation bar.
class _BottomClipper extends CustomClipper<Rect> {
  /// The maximum y-coordinate (in logical pixels) below which content is clipped.
  final double clipBottom;

  const _BottomClipper(this.clipBottom);

  /// Returns a [Rect] that spans the full width and clips at [clipBottom] minus 8px.
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, clipBottom - 8);

  /// Reclips only when [clipBottom] has changed.
  @override
  bool shouldReclip(_BottomClipper old) => old.clipBottom != clipBottom;
}
