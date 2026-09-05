import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherDay {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final int? precipitationProbability;

  WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    this.precipitationProbability,
  });

  /// Maps Open-Meteo's WMO weather codes to a simple emoji.
  /// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '🌤️';
    if (weatherCode == 45 || weatherCode == 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '❄️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌦️';
    if (weatherCode >= 85 && weatherCode <= 86) return '🌨️';
    if (weatherCode >= 95) return '⛈️';
    return '☁️';
  }
}

/// Free weather forecasts via Open-Meteo (no API key, no cost — see
/// https://open-meteo.com). Geocodes a city name to coordinates, then
/// fetches a daily forecast. Results are cached in memory for the session.
class WeatherService {
  static final WeatherService instance = WeatherService._();
  WeatherService._();

  ({double lat, double lon, String resolvedName})? _cachedLocation;
  List<WeatherDay>? _cachedForecast;
  DateTime? _cacheTime;

  /// Returns up to 10 candidate matches (most specific match first isn't
  /// guaranteed, so callers should let the user pick) with full
  /// 都道府県/市区町村-level names, so "渋谷区" doesn't silently resolve to
  /// the wrong place of the same name elsewhere. Pass [countryCode] (ISO
  /// 3166-1 alpha-2) to scope the search to one country worldwide, which
  /// also disambiguates identically-named places in different countries.
  /// Pass [prefectureHint] (a 都道府県 name) when known, so a same-named
  /// ward in a different prefecture (中央区 exists in several designated
  /// cities) isn't picked by mistake.
  // Requesting results in each country's own language keeps Open-Meteo's
  // returned admin1 (prefecture/state/province) name matching the strings
  // in our own region datasets, so prefectureHint comparisons actually hit.
  static const _languageByCountry = {'JP': 'ja', 'KR': 'ko', 'CN': 'zh'};

  Future<List<({double lat, double lon, String resolvedName})>> geocodeCity(
    String city, {
    String? countryCode,
    String? prefectureHint,
  }) async {
    final language = _languageByCountry[countryCode] ?? 'en';

    // Strictly require a match in the right prefecture/state whenever we
    // know it, since plenty of place names recur elsewhere — e.g. 中央区
    // in several designated cities, or Korea's 강남구 also matching an
    // unrelated mountain pass in a different province. Accepting an
    // unfiltered same-name match would risk silently resolving to the
    // wrong place, which is worse than "not found".
    //
    // Compared suffix-insensitively because Open-Meteo is inconsistent
    // about it for Chinese provinces — e.g. it reports "广东" for our
    // "广东省", but keeps the full "北京市" for our "北京市".
    final normalizedHint = prefectureHint == null ? null : _stripAdminSuffix(prefectureHint);
    List<Map<String, dynamic>> requirePrefecture(List<Map<String, dynamic>> candidates) {
      if (normalizedHint == null) return candidates;
      return candidates
          .where((r) => r['admin1'] is String && _stripAdminSuffix(r['admin1'] as String) == normalizedHint)
          .toList();
    }

    Future<List<Map<String, dynamic>>> search(String name) =>
        _searchPlaces(name, countryCode: countryCode, language: language);

    var results = requirePrefecture(await search(city));

    // Open-Meteo's geocoder indexes bare place names, so "渋谷区" or "東京都"
    // often return nothing even though "渋谷"/"東京" would match. Retry with
    // common 都道府県・市区町村 suffixes stripped before giving up.
    if (results.isEmpty) {
      const suffixes = ['都', '道', '府', '県', '市', '区', '町', '村'];
      for (final suffix in suffixes) {
        if (city.endsWith(suffix) && city.length > suffix.length) {
          results = requirePrefecture(await search(city.substring(0, city.length - suffix.length)));
          if (results.isNotEmpty) break;
        }
      }
    }

    // 政令指定都市の区 are indexed by their bare ward name (like Tokyo's
    // wards), not "<city>市<ward>区" — so "大阪市中央区" finds nothing until
    // it's narrowed down to "中央区".
    final wardMatch = RegExp(r'^(.+市)(.+[区])$').firstMatch(city);
    if (results.isEmpty && wardMatch != null) {
      results = requirePrefecture(await search(wardMatch.group(2)!));
    }

    // Many countries' sub-city districts (政令指定都市の区, Korea's 구,
    // ...) aren't indexed as their own place at all — fall back to the
    // parent city, then to the prefecture/state itself, rather than
    // "not found".
    if (results.isEmpty && wardMatch != null) {
      results = requirePrefecture(await search(wardMatch.group(1)!));
    }
    if (results.isEmpty && prefectureHint != null) {
      results = await search(prefectureHint);
      if (results.isEmpty) {
        results = await search(normalizedHint!);
      }
    }

    // GeoNames sometimes carries near-duplicate points for the very same
    // place (e.g. two entries for 八戸 a few hundred meters apart, both
    // "青森県 八戸市") — they'd otherwise show as identical-looking options.
    final seenNames = <String>{};
    return [
      for (final result in results)
        if (seenNames.add(_formatPlaceName(result)))
          (
            lat: (result['latitude'] as num).toDouble(),
            lon: (result['longitude'] as num).toDouble(),
            resolvedName: _formatPlaceName(result),
          ),
    ];
  }

  /// Strips a trailing administrative-division suffix so region names
  /// compare equal even when Open-Meteo reports them inconsistently (e.g.
  /// "广东" vs our "广东省", but "北京市" left as-is for our "北京市").
  static const _adminSuffixes = [
    '特别行政区',
    '壮族自治区',
    '维吾尔自治区',
    '回族自治区',
    '自治区',
    '특별자치도',
    '특별자치시',
    '광역시',
    '특별시',
    '都',
    '道',
    '府',
    '県',
    '省',
    '市',
    '도',
  ];

  String _stripAdminSuffix(String name) {
    for (final suffix in _adminSuffixes) {
      if (name.endsWith(suffix) && name.length > suffix.length) {
        return name.substring(0, name.length - suffix.length);
      }
    }
    return name;
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(
    String name, {
    String? countryCode,
    String language = 'en',
  }) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': name,
      'count': '10',
      'language': language,
      'countryCode': ?countryCode,
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null) return [];
    return results.cast<Map<String, dynamic>>();
  }

  /// Builds a "地名（都道府県 市区町村）" style label without duplicating a
  /// part that's already equal to the place name itself.
  String _formatPlaceName(Map<String, dynamic> result) {
    final name = result['name'] as String? ?? '';
    final context = <String>{
      if (result['admin2'] is String) result['admin2'] as String,
      if (result['admin1'] is String) result['admin1'] as String,
    }..remove(name);

    return context.isEmpty ? name : '$name（${context.join(' ')}）';
  }

  /// Returns the forecast for [lat]/[lon], covering roughly the next two
  /// weeks (Open-Meteo's free daily forecast horizon).
  Future<List<WeatherDay>> fetchForecast({required double lat, required double lon}) async {
    final now = DateTime.now();
    if (_cachedForecast != null &&
        _cachedLocation != null &&
        _cachedLocation!.lat == lat &&
        _cachedLocation!.lon == lon &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < const Duration(hours: 3)) {
      return _cachedForecast!;
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'daily':
          'weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'Asia/Tokyo',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return _cachedForecast ?? [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List<dynamic>;
    final codes = daily['weathercode'] as List<dynamic>;
    final maxTemps = daily['temperature_2m_max'] as List<dynamic>;
    final minTemps = daily['temperature_2m_min'] as List<dynamic>;
    final precipitationChances = daily['precipitation_probability_max'] as List<dynamic>?;

    final forecast = <WeatherDay>[
      for (var i = 0; i < dates.length; i++)
        WeatherDay(
          date: DateTime.parse(dates[i] as String),
          weatherCode: codes[i] as int,
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
          precipitationProbability: (precipitationChances?[i] as num?)?.toInt(),
        ),
    ];

    _cachedLocation = (lat: lat, lon: lon, resolvedName: '');
    _cachedForecast = forecast;
    _cacheTime = now;
    return forecast;
  }
}
