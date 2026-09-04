import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherDay {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;

  WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
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

  Future<({double lat, double lon, String resolvedName})?> geocodeCity(String city) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': city,
      'count': '1',
      'language': 'ja',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    return (
      lat: (first['latitude'] as num).toDouble(),
      lon: (first['longitude'] as num).toDouble(),
      resolvedName: first['name'] as String? ?? city,
    );
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
      'daily': 'weathercode,temperature_2m_max,temperature_2m_min',
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

    final forecast = <WeatherDay>[
      for (var i = 0; i < dates.length; i++)
        WeatherDay(
          date: DateTime.parse(dates[i] as String),
          weatherCode: codes[i] as int,
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
        ),
    ];

    _cachedLocation = (lat: lat, lon: lon, resolvedName: '');
    _cachedForecast = forecast;
    _cacheTime = now;
    return forecast;
  }
}
