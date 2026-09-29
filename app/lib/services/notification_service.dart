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
import 'locale_service.dart';

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
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  int _scheduleNotificationId(String prefix, String docId) {
    return '$prefix$docId'.hashCode & 0x7fffffff;
  }

  bool get _isJa => LocaleService.instance.locale.value.languageCode == 'ja';

  String get _scheduleReminderBody => _isJa ? 'まもなく予定の時間です' : 'Your schedule is coming up soon';
  String get _scheduleChannelName => _isJa ? '予定のリマインダー' : 'Schedule reminders';
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
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
      default:
        return from;
    }
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

    try {
      await _plugin.zonedSchedule(
        id: _scheduleNotificationId('schedule_', schedule.id),
        title: schedule.title,
        body: _scheduleReminderBody,
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'schedule_reminders',
            _scheduleChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e, st) {
      // Most commonly a missing/revoked Android "exact alarm" permission —
      // this shouldn't block saving the schedule itself, but silently
      // swallowing it means the reminder just never fires with no trace.
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to schedule notification', fatal: false);
    }
  }

  Future<void> cancelForSchedule(String scheduleId) async {
    await _plugin.cancel(id: _scheduleNotificationId('schedule_', scheduleId));
  }

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

    tz.TZDateTime rawOccurrence(int year, int month) =>
        tz.TZDateTime(tz.local, year, month, anniversary.day, 9);

    tz.TZDateTime next;
    if (isMonthly) {
      next = rawOccurrence(now.year, now.month);
      if (next.isBefore(now)) next = rawOccurrence(now.year, now.month + 1);
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

  // Fixed id — there's only ever one daily digest notification per device.
  static const _dailyDigestId = 0x4441494c; // 'DAIL' as hex, just a stable sentinel

  String get _dailyDigestChannelName => _isJa ? '毎日の予定まとめ' : 'Daily schedule digest';

  /// Notifies once at [hour]:[minute] with today's (or tomorrow's, if that
  /// time already passed today) schedules, [lines] already formatted by the
  /// caller. Deliberately a one-shot, not a native-repeating alarm: the
  /// content changes every day, which a fixed OS repeat pattern can't
  /// express. The caller (DailyDigestService) is expected to call this
  /// again whenever the schedule list changes while the app is open, both
  /// to keep the content fresh and to roll the target date forward.
  Future<void> scheduleDailyDigest({
    required DateTime targetDate,
    required int hour,
    required int minute,
    required List<String> lines,
    required String title,
    required String emptyBody,
  }) async {
    if (!await _notificationsEnabled()) {
      await cancelDailyDigest();
      return;
    }
    final scheduledDate =
        tz.TZDateTime(tz.local, targetDate.year, targetDate.month, targetDate.day, hour, minute);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final body = lines.isEmpty ? emptyBody : lines.join('\n');
    try {
      await _plugin.zonedSchedule(
        id: _dailyDigestId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_digest',
            _dailyDigestChannelName,
            importance: Importance.high,
            priority: Priority.high,
            // Android otherwise truncates a multi-line body (up to 5
            // schedules) to a single line.
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to schedule daily digest', fatal: false);
    }
  }

  Future<void> cancelDailyDigest() async {
    await _plugin.cancel(id: _dailyDigestId);
  }

  /// Cancels every pending local notification (used when the user turns
  /// notifications off entirely in Settings).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
