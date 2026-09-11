import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Security-audit trail: records who did what, to which document, and when.
/// Write-only from the app's perspective (Firestore rules deny read to
/// regular users) — this is for investigation via the Firebase console, not
/// a user-facing activity feed. Also backs the "trash" soft-delete/restore
/// feature: deleting through [softDelete] snapshots the document into the
/// `trash` collection before removing it, so it can be restored later.
class AuditService {
  static final AuditService instance = AuditService._();
  AuditService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _log({
    required String action,
    required String collection,
    required String targetId,
    List<String>? changedFields,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('auditLogs').add({
        'actorId': uid,
        'action': action,
        'collection': collection,
        'targetId': targetId,
        if (changedFields != null) 'changedFields': changedFields,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      // Best-effort: an audit log write failing shouldn't break the actual
      // user-facing action that triggered it, but shouldn't disappear
      // silently either — report it so gaps in the trail are visible.
      FirebaseCrashlytics.instance.recordError(e, st, reason: 'audit log write failed', fatal: false);
    }
  }

  Future<void> logCreate({required String collection, required String targetId}) {
    return _log(action: 'create', collection: collection, targetId: targetId);
  }

  /// Compares [oldData] and [newData] field-by-field (ignoring bookkeeping
  /// fields like updatedAt) and logs which ones actually changed.
  Future<void> logUpdate({
    required String collection,
    required String targetId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
  }) async {
    const ignoredKeys = {'updatedAt', 'createdAt'};
    final changed = <String>[];
    for (final key in newData.keys) {
      if (ignoredKeys.contains(key)) continue;
      if (_describe(oldData[key]) != _describe(newData[key])) {
        changed.add(key);
      }
    }
    if (changed.isEmpty) return;
    await _log(
      action: 'update',
      collection: collection,
      targetId: targetId,
      changedFields: changed,
    );
  }

  String _describe(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    return value.toString();
  }

  /// Snapshots [data] into the `trash` collection and deletes the original
  /// document as a single atomic batch (so a rejected/failed delete can
  /// never leave an orphaned trash entry, or vice versa) — used instead of
  /// calling `.delete()` directly so the item can be restored later from
  /// Settings > ゴミ箱. Firestore's rules independently re-verify that the
  /// caller actually owns [targetId] before the trash write is accepted.
  Future<void> softDelete({
    required String collection,
    required String targetId,
    required Map<String, dynamic> data,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('AuditService.softDelete called while signed out');
    }
    final batch = _db.batch();
    batch.set(_db.collection('trash').doc(), {
      'ownerId': uid,
      'collection': collection,
      'originalId': targetId,
      'data': data,
      'deletedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_db.collection(collection).doc(targetId));
    await batch.commit();
    await _log(action: 'delete', collection: collection, targetId: targetId);
  }
}
