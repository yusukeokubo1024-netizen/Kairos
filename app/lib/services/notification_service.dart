import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/anniversary.dart';
import '../models/schedule.dart';
import '../models/task.dart';
import '../utils/business_day.dart';
import 'alarm_kit_service.dart';
import 'alarm_sound_service.dart';
import 'locale_service.dart';
import 'notification_sound_service.dart';

/// Wraps flutter_local_notifications for on-device reminders.
/// No server-side push is used in the free v1 release.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Set only for the automated App Store screenshot capture run — skips
  // requesting notification permission entirely, since the resulting native
  // iOS system alert sits outside the Flutter widget tree and would
  // otherwise block integration_test's automation forever.
  static const _skipPermissionRequest = bool.fromEnvironment('SCREENSHOT_MODE');

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = _skipPermissionRequest
        ? const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          )
        : const DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings: initSettings);

    if (!_skipPermissionRequest) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      // Android 12+ requires this *separate* permission for exact-time
      // alarms (the kind "5分前" reminders rely on) — just declaring
      // SCHEDULE_EXACT_ALARM in the manifest isn't enough on every
      // device/OEM. Without it, reminders can silently never fire at all
      // rather than just arrive late, with no error visible anywhere in the
      // app (zonedSchedule's own exception was only ever logged to
      // Crashlytics — see the fallback added below for when it does throw).
      await android?.requestExactAlarmsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      // Normally a channel is only created lazily, the first time a local
      // notification actually fires on it. But the server push
      // (functions/src/scheduledReminders.ts, chatNotifications.ts) also
      // targets channels by id directly via FCM — if a push arrives before
      // any local notification ever has (e.g. a brand new install),
      // Android has no channel to use yet and the notification can show
      // with no sound. Creating them explicitly up front guarantees they
      // always exist, using whichever sound the user has already chosen
      // (see NotificationSoundService) or the system default otherwise.
      await NotificationSoundService.instance.ensureChannelsExist();
    }

    _initialized = true;
  }

  int _scheduleNotificationId(String prefix, String docId) {
    return '$prefix$docId'.hashCode & 0x7fffffff;
  }

  bool get _isJa => LocaleService.instance.locale.value.languageCode == 'ja';

  String get _scheduleReminderBody => _isJa ? 'まもなく予定の時間です' : 'Your schedule is coming up soon';
  String get _scheduleChannelName => _isJa ? '予定のリマインダー' : 'Schedule reminders';
  String get _scheduleAlarmChannelName => _isJa ? '予定のアラーム' : 'Schedule alarms';
  String get _scheduleAlarmChannelDescription => _isJa
      ? 'アラームのように、画面ロック中でも大きく表示される通知です'
      : 'Full-screen, alarm-style notifications for schedules you\'ve marked as important';
  String get _taskReminderBody => _isJa ? '今日が期限のタスクです' : 'A task is due today';
  String get _taskChannelName => _isJa ? 'タスクのリマインダー' : 'Task reminders';
  String get _anniversaryChannelName => _isJa ? '記念日の通知' : 'Anniversary reminders';
  String _anniversaryBody(String title) => _isJa ? '今日は「$title」の日です' : 'Today is "$title"';

  /// Whether the signed-in user has notifications turned on in Settings.
  /// Defaults to true (e.g. for signed-out callers, or if the field is unset).
  Future<bool> _notificationsEnabled() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return true;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['notifications_enabled'] as bool? ?? true;
  }

  /// One step forward along a recurrence pattern, used only to roll an
  /// already-past reminder time forward to its next future occurrence
  /// before handing it to zonedSchedule (which requires a future date even
  /// when [matchDateTimeComponents] makes it repeat after that).
  DateTime _stepForward(String recurrence, DateTime from) {
    switch (recurrence) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
        return _nextMonthWithDay(from.year, from.month, from.day, from.hour, from.minute);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
      default:
        return from;
    }
  }

  /// The next month after (year, month) that actually has [day] as a valid
  /// date, skipping any that don't (e.g. day 31 skips April, June,
  /// September, November, February). Plain `DateTime(year, month+1, day,
  /// ...)` would instead silently overflow into a different day next
  /// month — harmless for a one-off date, but here that overflowed date
  /// becomes the anchor for a *native, permanently-repeating* monthly
  /// notification (matchDateTimeComponents.dayOfMonthAndTime), so the
  /// wrong day would otherwise get baked in forever instead of just
  /// affecting a single occurrence.
  DateTime _nextMonthWithDay(int year, int month, int day, int hour, int minute) {
    var y = year;
    var m = month;
    for (var i = 0; i < 24; i++) {
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
      final daysInMonth = DateTime(y, m + 1, 0).day;
      if (day <= daysInMonth) {
        return DateTime(y, m, day, hour, minute);
      }
    }
    // Shouldn't happen — every day 1-31 has a valid month within a couple
    // of tries — but fall back rather than loop forever or throw.
    return DateTime(year, month + 1, day, hour, minute);
  }

  /// The [DateTimeComponents] that makes zonedSchedule repeat matching a
  /// recurrence pattern natively (one alarm the OS re-fires itself), or null
  /// for a one-off, non-repeating schedule.
  DateTimeComponents? _matchComponentsFor(String recurrence) {
    switch (recurrence) {
      case 'daily':
        return DateTimeComponents.time;
      case 'weekly':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'monthly':
        return DateTimeComponents.dayOfMonthAndTime;
      case 'yearly':
        return DateTimeComponents.dateAndTime;
      default:
        return null;
    }
  }

  /// Reminds the user before a schedule starts (30 minutes by default). For
  /// a recurring schedule this is scheduled once as a natively-repeating
  /// alarm (same mechanism as [scheduleForAnniversary]) rather than one
  /// notification per occurrence, so it isn't limited by iOS's ~64 pending
  /// local notification cap. The trade-off: [Schedule.recurrenceEndDate] and
  /// a single skipped occurrence aren't honored by the reminder itself —
  /// it just keeps firing until the schedule/reminder is edited or deleted.
  Future<void> scheduleForSchedule(Schedule schedule) async {
    final reminderMinutes = schedule.reminderMinutes;
    if (reminderMinutes == null || !await _notificationsEnabled()) {
      await cancelForSchedule(schedule.id);
      return;
    }
    // All-day schedules have no meaningful time-of-day, so reminders count
    // back from 9:00 on the start day instead of from midnight.
    final baseTime = schedule.isAllDay
        ? DateTime(schedule.startTime.year, schedule.startTime.month, schedule.startTime.day, 9)
        : schedule.startTime;
    var reminderTime = baseTime.subtract(Duration(minutes: reminderMinutes));

    final matchComponents = _matchComponentsFor(schedule.recurrence);
    if (matchComponents == null) {
      if (reminderTime.isBefore(DateTime.now())) return;
    } else {
      // Roll a past anchor forward to the next future occurrence — capped
      // so a stale/corrupt date can't loop indefinitely.
      for (var i = 0; i < 2000 && reminderTime.isBefore(DateTime.now()); i++) {
        reminderTime = _stepForward(schedule.recurrence, reminderTime);
      }
      if (reminderTime.isBefore(DateTime.now())) return;
    }

    // "Alarm-style" on iOS 26+: a real AlarmKit alarm, which rings even on
    // silent and with the app closed. AlarmKit only repeats weekly, so a
    // monthly/yearly schedule gets just its next occurrence (re-scheduled
    // whenever the schedule is saved again).
    final alarmKitKey = _scheduleAlarmKitKey(schedule.id);
    if (schedule.alarmStyle) {
      final usedAlarmKit = await AlarmKitService.instance.schedule(
        key: alarmKitKey,
        title: schedule.title,
        stopText: _alarmStopText,
        fireTime: reminderTime,
        weekdays: switch (schedule.recurrence) {
          'daily' => const [1, 2, 3, 4, 5, 6, 7],
          'weekly' => [reminderTime.weekday],
          _ => null,
        },
        soundFile: (await AlarmSoundService.instance.selected()).fileName,
      );
      if (usedAlarmKit) {
        await _plugin.cancel(id: _scheduleNotificationId('schedule_', schedule.id));
        return;
      }
    } else {
      await AlarmKitService.instance.cancel(alarmKitKey);
    }

    // "Alarm-style" (Android only): full-screen, shows over the lock
    // screen, on its own channel so the user can pick a louder sound for it
    // in system settings than the regular reminder channel. Not a true
    // alarm-clock — it's still a notification, so silent mode/Do Not
    // Disturb can still mute it unless the user has separately granted
    // "Alarms & reminders" access, and Android 14+ requires the full-screen
    // permission to be turned on manually (see AndroidManifest.xml).
    final android = schedule.alarmStyle
        ? AndroidNotificationDetails(
            'schedule_alarms',
            _scheduleAlarmChannelName,
            channelDescription: _scheduleAlarmChannelDescription,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            autoCancel: false,
          )
        : AndroidNotificationDetails(
            (await NotificationSoundService.instance.load(SoundCategory.schedule)).channelId,
            _scheduleChannelName,
            importance: Importance.high,
            priority: Priority.high,
          );

    final notificationDetails = NotificationDetails(
      android: android,
      iOS: const DarwinNotificationDetails(),
    );
    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: _scheduleNotificationId('schedule_', schedule.id),
        title: schedule.title,
        body: _scheduleReminderBody,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e, st) {
      // Most commonly a missing/revoked Android "exact alarm" permission —
      // some OEMs/Android versions reject exact scheduling outright instead
      // of just degrading it. Falling back to inexact (OS-batched, can be a
      // few minutes late but still fires) means the reminder still arrives
      // instead of silently never firing at all with no trace anywhere but
      // Crashlytics.
      FirebaseCrashlytics.instance.recordError(e, st,
          reason: 'failed to schedule exact notification, retrying inexact', fatal: false);
      try {
        await _plugin.zonedSchedule(
          id: _scheduleNotificationId('schedule_', schedule.id),
          title: schedule.title,
          body: _scheduleReminderBody,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchComponents,
        );
      } catch (e2, st2) {
        FirebaseCrashlytics.instance
            .recordError(e2, st2, reason: 'failed to schedule notification', fatal: false);
      }
    }
  }

  Future<void> cancelForSchedule(String scheduleId) async {
    await _plugin.cancel(id: _scheduleNotificationId('schedule_', scheduleId));
    await AlarmKitService.instance.cancel(_scheduleAlarmKitKey(scheduleId));
  }

  String _scheduleAlarmKitKey(String scheduleId) => 'schedule_$scheduleId';

  /// Reminds the user the morning of a task's due date, if it has one.
  Future<void> scheduleForTask(Task task) async {
    final dueDate = task.dueDate;
    if (dueDate == null || !await _notificationsEnabled()) return;
    final reminderTime = DateTime(dueDate.year, dueDate.month, dueDate.day, 9);
    if (reminderTime.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        id: _scheduleNotificationId('task_', task.id),
        title: task.title,
        body: _taskReminderBody,
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            _taskChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to schedule notification', fatal: false);
    }
  }

  Future<void> cancelForTask(String taskId) async {
    await _plugin.cancel(id: _scheduleNotificationId('task_', taskId));
  }

  /// Schedules a notification for an anniversary (yearly on its month/day,
  /// or monthly on its day), at 9:00.
  ///
  /// Without [Anniversary.businessDayAdjust], this is a single native
  /// repeating alarm (matchDateTimeComponents) that flutter_local_notifications
  /// re-fires itself every year/month — no rescheduling needed.
  ///
  /// With it, each occurrence's date depends on that specific month's
  /// calendar (does the 25th land on a weekend this month or not?), which a
  /// fixed OS-repeat pattern can't express — shifting this occurrence to,
  /// say, the 27th would make the OS repeat on the 27th every month after,
  /// not re-check next month's 25th. So this case schedules a one-shot
  /// notification for just the next adjusted occurrence; the caller is
  /// expected to call this again once that's passed (AnniversaryListScreen
  /// does this on open) so the following month's date gets picked up.
  Future<void> scheduleForAnniversary(Anniversary anniversary) async {
    if (!await _notificationsEnabled()) {
      await cancelForAnniversary(anniversary.id);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final isMonthly = anniversary.recurrence == Anniversary.monthly;

    // Null for a month that doesn't have anniversary.day at all (e.g. day
    // 31 in April) — skipped rather than letting the TZDateTime
    // constructor silently overflow into a different day, since that
    // overflowed date would otherwise become the notification's date.
    tz.TZDateTime? monthlyOccurrence(int year, int month) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (anniversary.day > daysInMonth) return null;
      return tz.TZDateTime(tz.local, year, month, anniversary.day, 9);
    }

    tz.TZDateTime next;
    if (isMonthly) {
      var year = now.year;
      var month = now.month;
      tz.TZDateTime? found;
      for (var i = 0; i < 24 && found == null; i++) {
        final candidate = monthlyOccurrence(year, month);
        if (candidate != null && !candidate.isBefore(now)) {
          found = candidate;
        } else {
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
      }
      // Fallback shouldn't happen — every day 1-31 has a valid month within
      // a couple of tries — but avoids leaving `next` unset.
      next = found ?? tz.TZDateTime(tz.local, now.year, now.month, 28, 9);
    } else {
      final month = anniversary.month ?? now.month;
      next = tz.TZDateTime(tz.local, now.year, month, anniversary.day, 9);
      if (next.isBefore(now)) next = tz.TZDateTime(tz.local, now.year + 1, month, anniversary.day, 9);
    }

    DateTimeComponents? matchComponents = isMonthly
        ? DateTimeComponents.dayOfMonthAndTime
        : DateTimeComponents.dateAndTime;
    if (anniversary.businessDayAdjust) {
      final adjusted = adjustToNextBusinessDay(next);
      next = tz.TZDateTime(tz.local, adjusted.year, adjusted.month, adjusted.day, 9);
      matchComponents = null; // one-shot — see doc comment above
    }

    try {
      await _plugin.zonedSchedule(
        id: _scheduleNotificationId('anniversary_', anniversary.id),
        title: anniversary.title,
        body: _anniversaryBody(anniversary.title),
        scheduledDate: next,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'anniversary_reminders',
            _anniversaryChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to schedule notification', fatal: false);
    }
  }

  Future<void> cancelForAnniversary(String anniversaryId) async {
    await _plugin.cancel(id: _scheduleNotificationId('anniversary_', anniversaryId));
  }

  /// A loud, full-screen "alarm-style" notification (same mechanism as a
  /// schedule's alarmStyle reminder) for the Clock tab's Alarm/Timer
  /// features — not a true looping alarm-clock sound, just the loudest,
  /// most attention-grabbing thing flutter_local_notifications can do
  /// without a dedicated native alarm plugin. [matchComponents] makes it
  /// natively repeat on the OS side (e.g. for a specific weekday) instead
  /// of firing once.
  ///
  /// On iOS 26+ this schedules a real AlarmKit alarm instead (rings on
  /// silent and with the app closed) and returns true; otherwise falls back
  /// to the notification and returns false.
  Future<bool> scheduleClockAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime fireTime,
    DateTimeComponents? matchComponents,
    int snoozeMinutes = 0,
  }) async {
    final soundFile = (await AlarmSoundService.instance.selected()).fileName;
    final usedAlarmKit = await AlarmKitService.instance.schedule(
      key: _clockAlarmKitKey(id),
      title: title,
      stopText: _alarmStopText,
      fireTime: fireTime,
      weekdays:
          matchComponents == DateTimeComponents.dayOfWeekAndTime ? [fireTime.weekday] : null,
      soundFile: soundFile,
      snoozeMinutes: snoozeMinutes,
      snoozeText: _isJa ? 'スヌーズ' : 'Snooze',
    );
    if (usedAlarmKit) {
      // Don't also ring a second time via a notification.
      await _plugin.cancel(id: id);
      return true;
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        (await NotificationSoundService.instance.load(SoundCategory.alarm)).channelId,
        _isJa ? '時計のアラーム' : 'Clock alarms',
        channelDescription: _isJa
            ? 'アラーム・タイマー機能の通知です'
            : 'Notifications for the Alarm and Timer features',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        autoCancel: false,
      ),
      iOS: DarwinNotificationDetails(
        // The bundled alarm_*.caf the user picked (AlarmSoundService); null
        // = the plain default chime.
        sound: soundFile,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to schedule clock alarm', fatal: false);
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchComponents,
        );
      } catch (e2, st2) {
        FirebaseCrashlytics.instance
            .recordError(e2, st2, reason: 'failed to schedule clock alarm', fatal: false);
      }
    }
    return false;
  }

  Future<void> cancelClockAlarm(int id) async {
    await _plugin.cancel(id: id);
    await AlarmKitService.instance.cancel(_clockAlarmKitKey(id));
  }

  String _clockAlarmKitKey(int id) => 'clock_$id';

  String get _alarmStopText => _isJa ? '停止' : 'Stop';

  /// Cancels every pending local notification and system alarm (used when
  /// the user turns notifications off entirely in Settings).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await AlarmKitService.instance.cancelAll();
  }
}
