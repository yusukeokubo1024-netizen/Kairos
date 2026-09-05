import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A city/municipality within an [AdminRegion]. Most have no further
/// subdivision ([wards] empty and directly selectable); Japan's 政令指定都市
/// (Osaka, Yokohama, Nagoya, ...) additionally break down into wards, so
/// selecting one of those is a third step rather than a final choice.
class AdminCity {
  final String name;
  final List<String> wards;

  const AdminCity({required this.name, required this.wards});

  bool get hasWards => wards.isNotEmpty;
}

/// A country's top-level administrative division (都道府県 / 시・도 / 省 /
/// state) with the cities under it, used to browse down to a specific place
/// for the weather location setting instead of relying only on free-text
/// search. Sourced from each country's own official or authoritative open
/// dataset — see the asset paths below.
class AdminRegion {
  final String name;
  final List<AdminCity> cities;

  const AdminRegion({required this.name, required this.cities});
}

/// Asset paths for each supported country's region/city dataset, keyed by
/// ISO 3166-1 alpha-2 country code.
const Map<String, String> kAdminRegionAssets = {
  'JP': 'assets/data/japan_regions.json',
  'KR': 'assets/data/korea_regions.json',
  'CN': 'assets/data/china_regions.json',
  'US': 'assets/data/us_regions.json',
};

class AdminRegions {
  AdminRegions._();

  static final Map<String, List<AdminRegion>> _cache = {};

  static Future<List<AdminRegion>> load(String countryCode) async {
    final cached = _cache[countryCode];
    if (cached != null) return cached;

    final assetPath = kAdminRegionAssets[countryCode];
    if (assetPath == null) return [];

    final jsonString = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final regions = [
      for (final entry in decoded.cast<Map<String, dynamic>>())
        AdminRegion(
          name: entry['pref'] as String,
          cities: [
            for (final city in (entry['cities'] as List<dynamic>).cast<Map<String, dynamic>>())
              AdminCity(
                name: city['name'] as String,
                wards: (city['wards'] as List<dynamic>).cast<String>(),
              ),
          ],
        ),
    ];
    _cache[countryCode] = regions;
    return regions;
  }
}
