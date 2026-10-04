import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Keeps the user's birthday private: it lives on their own users/{uid}
/// doc (owner-only, see firestore.rules), never on publicProfiles/{uid},
/// which anyone who knows the uid — e.g. every member of a shared group —
/// can read.
class BirthdayService {
  static final BirthdayService instance = BirthdayService._();
  BirthdayService._();

  final _db = FirebaseFirestore.instance;

  Future<void> save(String uid, int month, int day) async {
    await _db.collection('users').doc(uid).set({
      'birthMonth': month,
      'birthDay': day,
    }, SetOptions(merge: true));
    await _removeFromPublicProfile(uid);
  }

  /// Earlier versions stored the birthday on publicProfiles (and showed it
  /// on group members' calendars). Moves it to the private users doc —
  /// without overwriting one already saved there — and deletes the public
  /// copy. Cheap no-op once done; safe to call on every launch.
  Future<void> migrateFromPublicProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final profile = (await _db.collection('publicProfiles').doc(uid).get()).data();
      final month = profile?['birthMonth'] as int?;
      final day = profile?['birthDay'] as int?;
      if (month == null && day == null) return;

      if (month != null && day != null) {
        final user = (await _db.collection('users').doc(uid).get()).data();
        if (user?['birthMonth'] == null) {
          await _db.collection('users').doc(uid).set({
            'birthMonth': month,
            'birthDay': day,
          }, SetOptions(merge: true));
        }
      }
      await _removeFromPublicProfile(uid);
    } catch (e, st) {
      // Retried on the next launch.
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'failed to migrate birthday',
        fatal: false,
      );
    }
  }

  Future<void> _removeFromPublicProfile(String uid) async {
    await _db.collection('publicProfiles').doc(uid).set({
      'birthMonth': FieldValue.delete(),
      'birthDay': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
