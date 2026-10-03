import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/world_clock_city.dart';

/// Persists the World Clock tab's saved cities locally — same
/// SharedPreferences-JSON pattern as [ThemeService]/[LocaleService].
class WorldClockService {
  static final WorldClockService instance = WorldClockService._();
  WorldClockService._();

  static const _prefsKey = 'world_clock_cities';

  Future<List<WorldClockCity>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => WorldClockCity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> save(List<WorldClockCity> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(cities.map((e) => e.toJson()).toList()));
  }
}
