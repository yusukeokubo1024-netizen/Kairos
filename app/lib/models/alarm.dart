/// A user-defined alarm clock entry (Settings > Clock > Alarm), stored
/// locally only (SharedPreferences via AlarmService) — this is a personal
/// device utility, not shared/collaborative data like schedules.
class Alarm {
  final String id;
  final int hour;
  final int minute;
  final String label;
  // ISO weekday numbers (1=Monday..7=Sunday) this alarm repeats on. Empty
  // means a one-time alarm that fires once then disables itself.
  final Set<int> repeatDays;
  final bool enabled;
  // The exact instant a one-time (non-repeating) alarm's underlying
  // notification is scheduled to fire. Null for a repeating alarm (not
  // needed — it just keeps firing). Used only to detect, next time the
  // Alarm screen loads, that a one-time alarm has already rung so its
  // toggle can be flipped back off (see AlarmService._reconcileFired) —
  // the single OS notification is already consumed by then regardless.
  final DateTime? firesAt;
  // Minutes until a snoozed alarm rings again; 0 = no snooze button.
  // Only honoured by AlarmKit alarms (iOS 26+).
  final int snoozeMinutes;

  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.repeatDays = const {},
    this.enabled = true,
    this.firesAt,
    this.snoozeMinutes = 0,
  });

  bool get isRepeating => repeatDays.isNotEmpty;

  Alarm copyWith({
    int? hour,
    int? minute,
    String? label,
    Set<int>? repeatDays,
    bool? enabled,
    DateTime? firesAt,
    int? snoozeMinutes,
  }) {
    return Alarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      firesAt: firesAt ?? this.firesAt,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? '',
      repeatDays: Set<int>.from((json['repeatDays'] as List? ?? []).map((e) => e as int)),
      enabled: json['enabled'] as bool? ?? true,
      firesAt: json['firesAt'] != null ? DateTime.parse(json['firesAt'] as String) : null,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'repeatDays': repeatDays.toList(),
        'enabled': enabled,
        'firesAt': firesAt?.toIso8601String(),
        'snoozeMinutes': snoozeMinutes,
      };
}
