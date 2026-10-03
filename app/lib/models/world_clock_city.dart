/// A saved city/timezone in the World Clock tab, stored locally only
/// (SharedPreferences via WorldClockService).
class WorldClockCity {
  final String timezoneId; // e.g. "America/New_York"
  final String displayName; // e.g. "New York"

  const WorldClockCity({required this.timezoneId, required this.displayName});

  factory WorldClockCity.fromJson(Map<String, dynamic> json) {
    return WorldClockCity(
      timezoneId: json['timezoneId'] as String,
      displayName: json['displayName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'timezoneId': timezoneId, 'displayName': displayName};
}
