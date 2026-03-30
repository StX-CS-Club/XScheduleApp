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

class BattlePassPage extends StatefulWidget {
  const BattlePassPage({super.key});

  @override
  State<StatefulWidget> createState() => _BattlePassPageState();
}

class _BattlePassPageState extends State<BattlePassPage>
    with TickerProviderStateMixin {
  static const double packSpacing = 120;
  static const double packHeight = 64;
  static const double packBorderRadius = 8;

  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));

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
                                Container(
                                  height: 10 * 120 + 64,
                                  width: width,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    color: colorScheme.surface,
                                  ),
                                ),
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
              errorBuilder: (context, error) => _buildCameraError(),
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

  final regex = RegExp(r'^xschedule_bp:.*');

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

class _BottomClipper extends CustomClipper<Rect> {
  final double clipBottom;

  const _BottomClipper(this.clipBottom);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, clipBottom - 8);

  @override
  bool shouldReclip(_BottomClipper old) => old.clipBottom != clipBottom;
}
