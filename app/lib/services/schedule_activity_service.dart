import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../models/schedule.dart';

/// User-facing "who did what, when" feed per schedule — shown to everyone on
/// that schedule's `participantIds` (never broader, e.g. never the whole
/// group — see the privacy issue found and fixed in the group-activity-badge
/// feature this replaces). Distinct from the internal `auditLogs` collection
/// (write-only, security/forensic use only, never read back by the app).
class ScheduleActivityService {
  static final ScheduleActivityService instance = ScheduleActivityService._();
  ScheduleActivityService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> logCreate(Schedule schedule) => _log(schedule, action: 'create');

  /// Picks a specific-enough summary the way the reference UI does ("日付を
  /// 更新しました" rather than a generic "updated"), without needing to
  /// enumerate every possible field.
  Future<void> logUpdate(Schedule oldSchedule, Schedule newSchedule) {
    final action = (oldSchedule.startTime != newSchedule.startTime ||
            oldSchedule.endTime != newSchedule.endTime)
        ? 'update_time'
        : (oldSchedule.title != newSchedule.title ? 'update_title' : 'update_other');
    return _log(newSchedule, action: action);
  }

  Future<void> _log(Schedule schedule, {required String action}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db
          .collection('schedules')
          .doc(schedule.id)
          .collection('activity')
          .add({
        'action': action,
        'actorId': uid,
        'scheduleTitle': schedule.title,
        'scheduleStart': Timestamp.fromDate(schedule.startTime),
        'scheduleEnd': Timestamp.fromDate(schedule.endTime),
        'participantIds': schedule.participantIds,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      // Best-effort — a failed activity-log write shouldn't block saving the
      // schedule itself, but shouldn't vanish silently either.
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to log schedule activity', fatal: false);
    }
  }
}
