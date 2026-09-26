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

  // Fanned out to each participant's own users/{uid}/activityFeed instead of
  // a single schedules/{id}/activity subcollection read via a collectionGroup
  // query — that design hit a real permission-denied in practice (Firestore
  // couldn't prove the collectionGroup `list` query safe against a
  // resource.data.participantIds-based rule the way a plain array-contains
  // query against a single collection can). Reading only from one's own
  // subdocument is the standard, reliable Firestore pattern for a per-user
  // feed and needs no such provability trick.
  Future<void> _log(Schedule schedule, {required String action}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final data = {
        'action': action,
        'actorId': uid,
        'scheduleId': schedule.id,
        'scheduleTitle': schedule.title,
        'scheduleStart': Timestamp.fromDate(schedule.startTime),
        'scheduleEnd': Timestamp.fromDate(schedule.endTime),
        'createdAt': FieldValue.serverTimestamp(),
      };
      final batch = _db.batch();
      for (final participantId in schedule.participantIds) {
        batch.set(
          _db.collection('users').doc(participantId).collection('activityFeed').doc(),
          data,
        );
      }
      await batch.commit();
    } catch (e, st) {
      // Best-effort — a failed activity-log write shouldn't block saving the
      // schedule itself, but shouldn't vanish silently either.
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'failed to log schedule activity', fatal: false);
    }
  }
}
