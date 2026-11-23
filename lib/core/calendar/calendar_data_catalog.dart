import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline loader for verified Ethiopian calendar JSON datasets.
///
/// Calculation logic stays in [EthiopianDateConverter] / [BahireHasab] /
/// [HolidayEngine]. This catalog exposes structured metadata + provenance
/// without requiring network access.
class CalendarDataCatalog {
  CalendarDataCatalog._();

  static const assetRoot = 'assets/data/ethiopian_calendar';

  static Map<String, dynamic>? _cache(String name) => _mem[name];
  static final Map<String, Map<String, dynamic>> _mem = {};

  static Future<Map<String, dynamic>> load(String fileName) async {
    final cached = _cache(fileName);
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('$assetRoot/$fileName');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _mem[fileName] = map;
    return map;
  }

  static Future<Map<String, dynamic>> sources() => load('sources.json');
  static Future<Map<String, dynamic>> months() => load('months.json');
  static Future<Map<String, dynamic>> weekdays() => load('weekdays.json');
  static Future<Map<String, dynamic>> geez() => load('geez_numerals.json');
  static Future<Map<String, dynamic>> fixedHolidays() => load('fixed_holidays.json');
  static Future<Map<String, dynamic>> movableFeasts() => load('movable_feasts.json');
  static Future<Map<String, dynamic>> fastingPeriods() => load('fasting_periods.json');
  static Future<Map<String, dynamic>> orthodoxSaints() => load('orthodox_saints.json');
  static Future<Map<String, dynamic>> nationalHolidays() => load('national_holidays.json');
  static Future<Map<String, dynamic>> regionalFestivals() => load('regional_festivals.json');
  static Future<Map<String, dynamic>> islamicEvents() => load('islamic_events.json');
  static Future<Map<String, dynamic>> historicalEvents() => load('historical_events.json');

  /// Prefetch core datasets used by converter / holiday UI.
  static Future<void> warmUp() async {
    await Future.wait([
      sources(),
      months(),
      weekdays(),
      fixedHolidays(),
      movableFeasts(),
      fastingPeriods(),
      orthodoxSaints(),
      nationalHolidays(),
      historicalEvents(),
    ]);
  }

  /// Top-level verification tag from a dataset file (never invent status).
  static Future<String> verificationOf(String fileName) async {
    final map = await load(fileName);
    return '${map['verification'] ?? 'reviewed'}';
  }

  /// Whether a verification tag should be treated as approximate in UI.
  static bool isApproximate(String verification) {
    return verification.startsWith('approximate') ||
        verification == 'officially_announced';
  }
}
