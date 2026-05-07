import 'dart:convert';

import 'package:localstorage/localstorage.dart';

/// Stores all static state for the 2026 April Fools Battle Pass feature.
///
/// Responsibilities:
/// - Defining the available decal packs and the XP required to unlock each
/// - Tracking which QR codes have been scanned and which packs have been redeemed
/// - Persisting and restoring scan/unlock state to/from [localStorage]
class BattlePass {
  // Private constructor — this class is not intended to be instantiated
  BattlePass._();

  /// Maps each decal pack name to the number of QR scans required to unlock it.
  ///
  /// A pack is unlocked when [scanned].length >= its required scan count.
  static const Map<String, int> rewards = {
    "Generic": 0,
    "English": 1,
    "Religion": 2,
    "Social Studies": 3,
    "Art": 4,
    "Science": 5,
    "Math": 6,
    "Language": 7,
    "X": 10
  };

  /// The names of all decals included in the "X" pack bonus reward.
  ///
  /// When the "X" pack is redeemed, all [xPack] decals are unlocked
  /// and stored individually as special decals in [localStorage].
  static const List<String> xPack = [
    "X",
    "Star",
    "Jester",
    "Laugh",
    "2026"
  ];

  /// The list of QR code data strings that have been scanned by the user.
  ///
  /// Each entry is the raw string value from a scanned battle pass QR code.
  /// Length determines which packs are currently unlocked per [rewards].
  static late List<String> scanned;

  /// The list of pack names the user has explicitly redeemed.
  ///
  /// A pack can only be redeemed once it is unlocked (see [rewards] and [scanned]).
  /// Redeemed packs display as `-REDEEMED-` rather than showing the "REDEEM" button.
  static late List<String> unlocked;

  /// Loads [scanned] and [unlocked] from [localStorage].
  ///
  /// Reads the stored JSON arrays for each field, defaulting to empty lists if absent.
  /// Must be called before any battle pass UI is displayed.
  static void load() {
    scanned = List<String>.from(jsonDecode(localStorage.getItem("battlePass:scanned") ?? "[]"));
    unlocked = List<String>.from(jsonDecode(localStorage.getItem("battlePass:unlocked") ?? "[]"));
  }

  /// Persists [scanned] and [unlocked] to [localStorage] as JSON arrays.
  ///
  /// Should be called immediately after modifying either list so state survives app restarts.
  static void save() {
    localStorage.setItem("battlePass:scanned", jsonEncode(scanned));
    localStorage.setItem("battlePass:unlocked", jsonEncode(unlocked));
  }

  /// Clears all in-memory battle pass progress without writing to [localStorage].
  ///
  /// Intended for use when resetting app state; call [save] afterward to persist the reset.
  static void reset() {
    scanned.clear();
    unlocked.clear();
  }
}
