import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';

/// Real system alarms on iOS 26+ (AlarmKit, see AppDelegate.swift). Unlike
/// a local notification, these ring at full volume with the ringer switch
/// on silent or a Focus on, and with the app not running — so the Clock
/// tab's Alarm/Timer and "alarm-style" schedule reminders use them when
/// available. [schedule] returns false (older iOS, Android, or the user
/// denied AlarmKit access) and callers then fall back to a notification.
class AlarmKitService {
  AlarmKitService._();
  static final instance = AlarmKitService._();

  static const _channel = MethodChannel('kairos/alarmkit');

  /// One-off at [fireTime], or — with [weekdays] (DateTime.weekday values,
  /// 1 = Monday … 7 = Sunday) — repeating weekly at [fireTime]'s time of
  /// day. [soundFile] is a bundled alarm_*.caf, or null for the default
  /// alarm sound. [snoozeMinutes] > 0 adds a snooze button that rings
  /// again that many minutes later.
  Future<bool> schedule({
    required String key,
    required String title,
    required String stopText,
    required DateTime fireTime,
    List<int>? weekdays,
    String? soundFile,
    int snoozeMinutes = 0,
    String snoozeText = 'Snooze',
  }) async {
    if (!Platform.isIOS) return false;
    try {
      final scheduled = await _channel.invokeMethod<bool>('schedule', {
        'key': key,
        'title': title,
        'stopText': stopText,
        'sound': soundFile,
        'snoozeMinutes': snoozeMinutes,
        'snoozeText': snoozeText,
        if (weekdays != null && weekdays.isNotEmpty) ...{
          'weekdays': weekdays,
          'hour': fireTime.hour,
          'minute': fireTime.minute,
        } else
          'fireAtMs': fireTime.millisecondsSinceEpoch,
      });
      return scheduled ?? false;
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to schedule AlarmKit alarm', fatal: false);
      return false;
    }
  }

  Future<void> cancel(String key) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('cancel', {'key': key});
    } on PlatformException catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('cancelAll');
    } on PlatformException catch (_) {}
  }
}
