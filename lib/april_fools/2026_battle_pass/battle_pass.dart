import 'dart:convert';

import 'package:localstorage/localstorage.dart';

class BattlePass {
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

  static const List<String> xPack = [
    "X",
    "Star",
    "Jester",
    "Laugh",
    "2026"
  ];

  static late List<String> scanned;
  static late List<String> unlocked;

  static void load() {
    scanned = List<String>.from(jsonDecode(localStorage.getItem("battlePass:scanned") ?? "[]"));
    unlocked = List<String>.from(jsonDecode(localStorage.getItem("battlePass:unlocked") ?? "[]"));
  }

  static void save() {
    localStorage.setItem("battlePass:scanned", jsonEncode(scanned));
    localStorage.setItem("battlePass:unlocked", jsonEncode(unlocked));
  }

  static void reset() {
    scanned.clear();
    unlocked.clear();
  }
}