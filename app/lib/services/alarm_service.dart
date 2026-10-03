import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import 'notification_service.dart';

/// Persists Clock-tab alarms locally (SharedPreferences — a personal device
/// utility, not shared/collaborative data) and schedules/cancels their
/// underlying notifications (NotificationService.scheduleClockAlarm).
///
/// Each alarm occupies up to 7 notification ids, one per possible weekday
/// (so e.g. Mon/Wed/Fri can each repeat weekly on the OS side
/// independently), plus one more for a one-time (non-repeating) firing.
class AlarmService {
  static final AlarmService instance = AlarmService._();
  AlarmService._();

  static const _prefsKey = 'clock_alarms';

  Future<List<Alarm>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final alarms = list.map((e) => Alarm.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return _reconcileFired(alarms);
  }

  /// A one-time alarm's single underlying notification is already consumed
  /// once its firesAt instant has passed, even though nothing calls back
  /// into Dart to say so (no background notification-response handler is
  /// wired up) — so this flips its toggle back off next time the Alarm
  /// screen happens to load, instead of leaving it looking "on" forever
  /// for something that will never fire again.
  Future<List<Alarm>> _reconcileFired(List<Alarm> alarms) async {
    final now = DateTime.now();
    var changed = false;
    final result = alarms.map((a) {
      if (a.enabled && a.repeatDays.isEmpty && a.firesAt != null && a.firesAt!.isBefore(now)) {
        changed = true;
        return a.copyWith(enabled: false);
      }
      return a;
    }).toList();
    if (changed) await _save(result);
    return result;
  }

  Future<void> _save(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(alarms.map((e) => e.toJson()).toList()));
  }

  int _idFor(String alarmId, String suffix) => ('alarm_${alarmId}_$suffix').hashCode & 0x7fffffff;

  Future<void> _cancelAll(String alarmId) async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await NotificationService.instance.cancelClockAlarm(_idFor(alarmId, 'w$weekday'));
    }
    await NotificationService.instance.cancelClockAlarm(_idFor(alarmId, 'once'));
  }

  /// (Re)schedules every underlying notification for [alarm], first
  /// cancelling any previously scheduled ones — safe to call whenever an
  /// alarm is added, edited, or toggled. Returns the one-time fire instant
  /// to store as Alarm.firesAt, or null for a repeating/disabled alarm.
  Future<DateTime?> _reschedule(Alarm alarm, {String? defaultLabel}) async {
    await _cancelAll(alarm.id);
    if (!alarm.enabled) return null;

    final title = alarm.label.isNotEmpty ? alarm.label : (defaultLabel ?? '');
    final now = DateTime.now();

    if (alarm.repeatDays.isEmpty) {
      var fireTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      if (!fireTime.isAfter(now)) fireTime = fireTime.add(const Duration(days: 1));
      await NotificationService.instance.scheduleClockAlarm(
        id: _idFor(alarm.id, 'once'),
        title: title,
        body: title,
        fireTime: fireTime,
      );
      return fireTime;
    }

    for (final weekday in alarm.repeatDays) {
      // Next date (today or later) that falls on this ISO weekday.
      var fireTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      var daysToAdd = (weekday - fireTime.weekday) % 7;
      if (daysToAdd == 0 && !fireTime.isAfter(now)) daysToAdd = 7;
      fireTime = fireTime.add(Duration(days: daysToAdd));
      await NotificationService.instance.scheduleClockAlarm(
        id: _idFor(alarm.id, 'w$weekday'),
        title: title,
        body: title,
        fireTime: fireTime,
        matchComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
    return null;
  }

  Future<List<Alarm>> add(List<Alarm> current, Alarm alarm, {String? defaultLabel}) async {
    final firesAt = await _reschedule(alarm, defaultLabel: defaultLabel);
    final toStore = alarm.repeatDays.isEmpty ? alarm.copyWith(firesAt: firesAt) : alarm;
    final updated = [...current, toStore];
    await _save(updated);
    return updated;
  }

  Future<List<Alarm>> update(List<Alarm> current, Alarm alarm, {String? defaultLabel}) async {
    final firesAt = await _reschedule(alarm, defaultLabel: defaultLabel);
    final toStore = alarm.repeatDays.isEmpty ? alarm.copyWith(firesAt: firesAt) : alarm;
    final updated = current.map((a) => a.id == toStore.id ? toStore : a).toList();
    await _save(updated);
    return updated;
  }

  Future<List<Alarm>> remove(List<Alarm> current, String alarmId) async {
    final updated = current.where((a) => a.id != alarmId).toList();
    await _save(updated);
    await _cancelAll(alarmId);
    return updated;
  }
}
