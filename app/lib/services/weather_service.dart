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

  /// Returns up to 5 candidate matches (most specific match first isn't
  /// guaranteed, so callers should let the user pick) with full
  /// 都道府県/市区町村-level names, so "渋谷区" doesn't silently resolve to
  /// the wrong place of the same name elsewhere.
  Future<List<({double lat, double lon, String resolvedName})>> geocodeCity(String city) async {
    var results = await _searchPlaces(city);

    // Open-Meteo's geocoder indexes bare place names, so "渋谷区" or "東京都"
    // often return nothing even though "渋谷"/"東京" would match. Retry with
    // common 都道府県・市区町村 suffixes stripped before giving up.
    if (results.isEmpty) {
      const suffixes = ['都', '道', '府', '県', '市', '区', '町', '村'];
      for (final suffix in suffixes) {
        if (city.endsWith(suffix) && city.length > suffix.length) {
          results = await _searchPlaces(city.substring(0, city.length - suffix.length));
          if (results.isNotEmpty) break;
        }
      }
    }

    return [
      for (final result in results)
        (
          lat: (result['latitude'] as num).toDouble(),
          lon: (result['longitude'] as num).toDouble(),
          resolvedName: _formatPlaceName(result),
        ),
    ];
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(String name) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': name,
      'count': '5',
      'language': 'ja',
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
