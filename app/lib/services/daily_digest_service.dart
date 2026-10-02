import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/app_localizations.dart';
import '../models/schedule.dart';
import 'notification_service.dart';

/// Result of a refresh — lets a caller that just toggled the digest on show
/// visible confirmation instead of it looking like nothing happened (the
/// notification itself doesn't fire until [scheduledFor], which can be
/// tomorrow morning if today's time already passed).
typedef DailyDigestRefreshResult = ({
  bool enabled,
  DateTime? scheduledFor,
  bool masterNotificationsOff,
});

/// Keeps the "today's schedules" digest notification (Settings > daily
/// digest) up to date. It's a free, on-device alternative to a real push
/// notification: see [NotificationService.scheduleDailyDigest] for why it's
/// a one-shot that has to be refreshed rather than a fixed OS repeat.
class DailyDigestService {
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Used by CalendarScreen, which already has the full, recurrence- and
  /// multi-day-expanded schedule list from its own Firestore stream — the
  /// most accurate source, but only refreshed while that screen is alive
  /// and its stream fires.
  static Future<DailyDigestRefreshResult> refreshFromExpandedSchedules(
    List<Schedule> schedules,
    AppLocalizations l10n,
  ) {
    return _refresh(schedules, l10n);
  }

  /// Used by SettingsScreen for immediate feedback right after the user
  /// toggles the digest on or changes its time, via its own one-off query.
  /// Simpler than CalendarScreen's version — it does NOT expand recurring
  /// or multi-day schedules, so a recurring-only day might look empty here
  /// until CalendarScreen's fuller refresh corrects it (next time it's
  /// opened, or already open elsewhere in the app).
  static Future<DailyDigestRefreshResult> refreshFromFirestore(AppLocalizations l10n) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return (enabled: false, scheduledFor: null, masterNotificationsOff: false);
    final snapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('participantIds', arrayContains: uid)
        .get();
    final schedules = snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
    return _refresh(schedules, l10n);
  }

  static Future<DailyDigestRefreshResult> _refresh(
    List<Schedule> schedules,
    AppLocalizations l10n,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return (enabled: false, scheduledFor: null, masterNotificationsOff: false);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final enabled = userDoc.data()?['dailyDigestEnabled'] as bool? ?? false;
    if (!enabled) {
      await NotificationService.instance.cancelDailyDigest();
      return (enabled: false, scheduledFor: null, masterNotificationsOff: false);
    }
    final masterOff = !await NotificationService.instance.notificationsEnabled();
    final hour = userDoc.data()?['dailyDigestHour'] as int? ?? 7;
    final minute = userDoc.data()?['dailyDigestMinute'] as int? ?? 0;

    final now = DateTime.now();
    final digestTimeToday = DateTime(now.year, now.month, now.day, hour, minute);
    // If today's digest time has already passed, this refresh is for
    // tomorrow's schedules instead — otherwise we'd notify at the right
    // time but with the wrong (already-past) day's plan.
    final targetDay = digestTimeToday.isBefore(now)
        ? DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
        : DateTime(now.year, now.month, now.day);

    final dayItems = schedules.where((s) => _isSameDay(s.startTime, targetDay)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final lines = dayItems.take(5).map((s) {
      final time = s.isAllDay
          ? l10n.calendarAllDay
          : '${s.startTime.hour.toString().padLeft(2, '0')}:'
              '${s.startTime.minute.toString().padLeft(2, '0')}';
      return '$time  ${s.title}';
    }).toList();

    await NotificationService.instance.scheduleDailyDigest(
      targetDate: targetDay,
      hour: hour,
      minute: minute,
      lines: lines,
      title: l10n.dailyDigestNotificationTitle,
      emptyBody: l10n.dailyDigestNotificationEmpty,
    );
    return (
      enabled: true,
      scheduledFor: DateTime(targetDay.year, targetDay.month, targetDay.day, hour, minute),
      masterNotificationsOff: masterOff,
    );
  }
}
