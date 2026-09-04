import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/anniversary.dart';
import '../models/schedule.dart';
import '../models/task.dart';

/// Wraps flutter_local_notifications for on-device reminders.
/// No server-side push is used in the free v1 release.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings: initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  int _scheduleNotificationId(String prefix, String docId) {
    return '$prefix$docId'.hashCode & 0x7fffffff;
  }

  /// Whether the signed-in user has notifications turned on in Settings.
  /// Defaults to true (e.g. for signed-out callers, or if the field is unset).
  Future<bool> _notificationsEnabled() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return true;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['notifications_enabled'] as bool? ?? true;
  }

  /// Reminds the user 30 minutes before a schedule starts.
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
    final reminderTime = baseTime.subtract(Duration(minutes: reminderMinutes));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _scheduleNotificationId('schedule_', schedule.id),
      title: schedule.title,
      body: 'まもなく予定の時間です',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_reminders',
          '予定のリマインダー',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
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

    await _plugin.zonedSchedule(
      id: _scheduleNotificationId('task_', task.id),
      title: task.title,
      body: '今日が期限のタスクです',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'タスクのリマインダー',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelForTask(String taskId) async {
    await _plugin.cancel(id: _scheduleNotificationId('task_', taskId));
  }

  /// Schedules a notification that repeats every year on the anniversary's
  /// month/day, at 9:00. flutter_local_notifications re-fires this
  /// automatically each year (DateTimeComponents.dateAndTime), no manual
  /// rescheduling needed.
  Future<void> scheduleForAnniversary(Anniversary anniversary) async {
    if (!await _notificationsEnabled()) {
      await cancelForAnniversary(anniversary.id);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, anniversary.month, anniversary.day, 9);
    if (next.isBefore(now)) {
      next = tz.TZDateTime(tz.local, now.year + 1, anniversary.month, anniversary.day, 9);
    }

    await _plugin.zonedSchedule(
      id: _scheduleNotificationId('anniversary_', anniversary.id),
      title: anniversary.title,
      body: '今日は「${anniversary.title}」の日です',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'anniversary_reminders',
          '記念日の通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelForAnniversary(String anniversaryId) async {
    await _plugin.cancel(id: _scheduleNotificationId('anniversary_', anniversaryId));
  }

  /// Cancels every pending local notification (used when the user turns
  /// notifications off entirely in Settings).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
