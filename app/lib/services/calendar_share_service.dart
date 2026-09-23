import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/schedule.dart';

/// Lets a user publish a read-only, link-based view of their calendar for
/// someone who doesn't have the app — e.g. a partner or family member.
///
/// Design: `calendarShares/{token}` is a public-readable pointer doc keyed by
/// an unguessable random Firestore ID (never listable, so it can't be
/// enumerated — the same pattern `groupInvitePreviews` uses). Its
/// `schedules` subcollection is a denormalized mirror containing only
/// `title`/`startTime`/`endTime` for each of the owner's schedules — never
/// location, notes, or who else is on it — kept in sync by the owner's own
/// client on every create/update/delete. A user has at most one active share
/// link at a time (`users/{uid}.calendarShareToken`); creating a new one
/// revokes the previous one first.
class CalendarShareService {
  static final CalendarShareService instance = CalendarShareService._();
  CalendarShareService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String? _cachedToken;
  bool _cacheLoaded = false;

  Future<String?> activeToken() async {
    if (_cacheLoaded) return _cachedToken;
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    _cachedToken = doc.data()?['calendarShareToken'] as String?;
    _cacheLoaded = true;
    return _cachedToken;
  }

  /// Creates a fresh share link (revoking any existing one first) and does
  /// an initial mirror of every schedule the caller currently owns.
  Future<String> createShareLink() async {
    final uid = _uid;
    if (uid == null) throw StateError('createShareLink called while signed out');

    await revokeShareLink();

    final userDoc = await _db.collection('users').doc(uid).get();
    final ownerName = userDoc.data()?['display_name'] as String? ?? '';

    final shareRef = _db.collection('calendarShares').doc();
    await shareRef.set({
      'ownerId': uid,
      'ownerName': ownerName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final owned = await _db.collection('schedules').where('ownerId', isEqualTo: uid).get();
    const chunkSize = 400;
    for (var i = 0; i < owned.docs.length; i += chunkSize) {
      final batch = _db.batch();
      for (final doc in owned.docs.skip(i).take(chunkSize)) {
        final schedule = Schedule.fromFirestore(doc);
        batch.set(shareRef.collection('schedules').doc(schedule.id), _mirrorMap(schedule));
      }
      await batch.commit();
    }

    await _db.collection('users').doc(uid).set(
      {'calendarShareToken': shareRef.id},
      SetOptions(merge: true),
    );
    _cachedToken = shareRef.id;
    _cacheLoaded = true;
    return shareRef.id;
  }

  Future<void> revokeShareLink() async {
    final uid = _uid;
    if (uid == null) return;
    final token = await activeToken();
    if (token == null) return;

    final shareRef = _db.collection('calendarShares').doc(token);
    final mirrored = await shareRef.collection('schedules').get();
    const chunkSize = 400;
    for (var i = 0; i < mirrored.docs.length; i += chunkSize) {
      final batch = _db.batch();
      for (final doc in mirrored.docs.skip(i).take(chunkSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await shareRef.delete();
    await _db.collection('users').doc(uid).set(
      {'calendarShareToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
    _cachedToken = null;
  }

  Map<String, dynamic> _mirrorMap(Schedule schedule) => {
        'title': schedule.title,
        'startTime': Timestamp.fromDate(schedule.startTime),
        'endTime': Timestamp.fromDate(schedule.endTime),
      };

  /// Call after creating or updating a schedule. No-ops if there's no active
  /// share link.
  Future<void> mirrorUpsert(Schedule schedule) async {
    final token = await activeToken();
    if (token == null) return;
    await _db
        .collection('calendarShares')
        .doc(token)
        .collection('schedules')
        .doc(schedule.id)
        .set(_mirrorMap(schedule));
  }

  /// Call after deleting a schedule. No-ops if there's no active share link.
  Future<void> mirrorDelete(String scheduleId) async {
    final token = await activeToken();
    if (token == null) return;
    await _db
        .collection('calendarShares')
        .doc(token)
        .collection('schedules')
        .doc(scheduleId)
        .delete();
  }
}
