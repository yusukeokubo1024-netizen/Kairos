import 'dart:convert';

import 'package:http/http.dart' as http;

/// Weather over one part of a day (morning or afternoon) — see
/// [WeatherDay.morning]/[WeatherDay.afternoon]. A single end-of-day icon
/// hides a lot: rain in the morning and clear in the afternoon (or the
/// reverse) both used to collapse into one emoji for the whole day.
class WeatherPeriod {
  final int weatherCode;
  final double temp;
  final int? precipitationProbability;

  WeatherPeriod({required this.weatherCode, required this.temp, this.precipitationProbability});

  /// Maps Open-Meteo's WMO weather codes to a simple emoji.
  /// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
  String get emoji => _emojiForWeatherCode(weatherCode);
}

/// Maps Open-Meteo's WMO weather codes to a simple emoji.
/// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
String _emojiForWeatherCode(int weatherCode) {
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

class WeatherDay {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final int? precipitationProbability;
  // Representative conditions for 6:00-11:59 and 12:00-17:59. Null if the
  // hourly data needed to compute them wasn't available (e.g. a request
  // that only asked for daily fields), in which case callers should fall
  // back to the whole-day fields above.
  final WeatherPeriod? morning;
  final WeatherPeriod? afternoon;

  WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    this.precipitationProbability,
    this.morning,
    this.afternoon,
  });

  /// Maps Open-Meteo's WMO weather codes to a simple emoji.
  /// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
  String get emoji => _emojiForWeatherCode(weatherCode);
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
      // For the 午前/午後 (morning/afternoon) breakdown — a single
      // end-of-day code hides e.g. "rain in the morning, clear by
      // afternoon". Hourly is still on Open-Meteo's free tier (no API key,
      // no cost) same as the daily fields.
      'hourly': 'weathercode,temperature_2m,precipitation_probability',
      // Must match the queried location's own timezone, not be hardcoded —
      // Open-Meteo uses this to decide each "daily"/"hourly" entry's date
      // boundaries, so a mismatched timezone shifts which calendar day (and
      // which local hour) gets labeled "today"/"9am". 'auto' resolves the
      // correct IANA timezone from lat/lon.
      'timezone': 'auto',
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

    final hourly = data['hourly'] as Map<String, dynamic>?;
    final hourlyTimes = hourly?['time'] as List<dynamic>?;
    final hourlyCodes = hourly?['weathercode'] as List<dynamic>?;
    final hourlyTemps = hourly?['temperature_2m'] as List<dynamic>?;
    final hourlyPrecip = hourly?['precipitation_probability'] as List<dynamic>?;

    // Picks a representative period (e.g. 6:00-11:59) for [date]: the
    // weather code/temp at that period's middle hour (a single snapshot is
    // plenty for an icon+temp), but the *worst-case* (max) precipitation
    // chance across the whole period, since "will it rain at some point
    // this morning" matters more for planning than one hour's number.
    WeatherPeriod? periodFor(DateTime date, int startHour, int endHourExclusive) {
      if (hourlyTimes == null || hourlyCodes == null || hourlyTemps == null) return null;
      final midHour = (startHour + endHourExclusive - 1) ~/ 2;
      int? midIndex;
      var maxPrecip = 0;
      var hasPrecip = false;
      for (var i = 0; i < hourlyTimes.length; i++) {
        final t = DateTime.parse(hourlyTimes[i] as String);
        if (t.year != date.year || t.month != date.month || t.day != date.day) continue;
        if (t.hour < startHour || t.hour >= endHourExclusive) continue;
        if (t.hour == midHour) midIndex = i;
        final p = (hourlyPrecip?[i] as num?)?.toInt();
        if (p != null) {
          hasPrecip = true;
          if (p > maxPrecip) maxPrecip = p;
        }
      }
      if (midIndex == null) return null;
      return WeatherPeriod(
        weatherCode: hourlyCodes[midIndex] as int,
        temp: (hourlyTemps[midIndex] as num).toDouble(),
        precipitationProbability: hasPrecip ? maxPrecip : null,
      );
    }

    final forecast = <WeatherDay>[
      for (var i = 0; i < dates.length; i++)
        WeatherDay(
          date: DateTime.parse(dates[i] as String),
          weatherCode: codes[i] as int,
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
          precipitationProbability: (precipitationChances?[i] as num?)?.toInt(),
          morning: periodFor(DateTime.parse(dates[i] as String), 6, 12),
          afternoon: periodFor(DateTime.parse(dates[i] as String), 12, 18),
        ),
    ];

    _cachedLocation = (lat: lat, lon: lon, resolvedName: '');
    _cachedForecast = forecast;
    _cacheTime = now;
    return forecast;
  }
}
