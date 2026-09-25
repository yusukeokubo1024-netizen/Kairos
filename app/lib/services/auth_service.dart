import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _googleSignInInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // Self-heals accounts created before the email-lookup feature existed
    // (see also the groupInvitePreviews backfill in group_list_screen.dart
    // for the same pattern) — best-effort, doesn't block sign-in. Only
    // actually writes once Firestore rules confirm the email is verified
    // (see ensureEmailIndexIfVerified) — otherwise anyone could squat on an
    // email they don't own by signing up with it and never verifying.
    unawaited(ensureEmailIndexIfVerified());
  }

  /// Lets another user find this account by exact email match (e.g. to
  /// invite someone to a single schedule without them being in a shared
  /// group). Only an exact-match `get` is ever allowed — see
  /// firestore.rules — never a listable/enumerable index.
  ///
  /// Deliberately requires the email to be verified first (enforced by
  /// firestore.rules too, not just here) — otherwise anyone could sign up
  /// with someone else's email, immediately claim the index entry before
  /// ever proving they control that mailbox, and get invited to that
  /// person's schedules in their place. Safe to call anytime (e.g. after
  /// sign-in, or after the user verifies) — no-ops until verified.
  Future<void> ensureEmailIndexIfVerified() async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) return;
    final email = user.email;
    if (email == null) return;
    final ref = _db.collection('emailIndex').doc(email.trim().toLowerCase());
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({'uid': user.uid});
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final user = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      createdTime: DateTime.now(),
    );
    await _db.collection('users').doc(uid).set(user.toCreateMap());
    await _writePublicProfile(uid, displayName);
    // Not verified yet at this point, so not indexed by email yet either —
    // see ensureEmailIndexIfVerified, called once they actually verify.
    unawaited(credential.user!.sendEmailVerification());
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? true;

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Public-facing profile info (display name only — no email) that other
  /// group/schedule members are allowed to look up.
  Future<void> _writePublicProfile(String uid, String displayName) async {
    await _db.collection('publicProfiles').doc(uid).set({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the display name in both the private `users` doc and the
  /// public-facing `publicProfiles` doc that group/schedule members can see.
  Future<void> updateDisplayName(String newName) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'display_name': newName,
    }, SetOptions(merge: true));
    await _writePublicProfile(uid, newName);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  /// Links a Google account to the currently signed-in user, so they can
  /// also sign in with Google going forward (in addition to email/password).
  Future<void> linkGoogleAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _ensureGoogleSignInInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await user.linkWithCredential(credential);
  }

  /// Whether the current user already has a Google account linked.
  bool get isGoogleLinked {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  /// Deletes the signed-in user's own data (schedules/tasks/groups they own)
  /// and their Firebase Authentication account.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Must run before anything below touches the `users` doc: the calendar
    // share token lives only on that one field, with no other way to find
    // it (calendarShares has no listable index by ownerId). If this ran
    // after the users doc was deleted and then a later step failed, a retry
    // would read a null token and silently skip cleanup forever, leaving a
    // live public link with no account left to ever revoke it.
    final userDocBeforeDelete = await _db.collection('users').doc(uid).get();
    final calendarShareToken = userDocBeforeDelete.data()?['calendarShareToken'] as String?;
    if (calendarShareToken != null) {
      final shareRef = _db.collection('calendarShares').doc(calendarShareToken);
      final mirrored = await shareRef.collection('schedules').get();
      const shareChunkSize = 400;
      for (var i = 0; i < mirrored.docs.length; i += shareChunkSize) {
        final mirrorBatch = _db.batch();
        for (final doc in mirrored.docs.skip(i).take(shareChunkSize)) {
          mirrorBatch.delete(doc.reference);
        }
        await mirrorBatch.commit();
      }
      await shareRef.delete();
    }

    // Available directly from the Auth user object — no Firestore read
    // needed. Otherwise this email would keep resolving to a uid whose
    // account no longer exists.
    final email = user.email;
    if (email != null) {
      await _db.collection('emailIndex').doc(email.trim().toLowerCase()).delete();
    }

    final batch = _db.batch();

    final ownedSchedules =
        await _db.collection('schedules').where('ownerId', isEqualTo: uid).get();
    for (final doc in ownedSchedules.docs) {
      batch.delete(doc.reference);
    }

    final ownedTasks = await _db.collection('tasks').where('ownerId', isEqualTo: uid).get();
    for (final doc in ownedTasks.docs) {
      batch.delete(doc.reference);
    }

    final ownedGroups =
        await _db.collection('sharedGroups').where('ownerId', isEqualTo: uid).get();
    for (final doc in ownedGroups.docs) {
      batch.delete(doc.reference);
      batch.delete(_db.collection('groupInvitePreviews').doc(doc.id));
    }

    final ownedAnniversaries =
        await _db.collection('anniversaries').where('ownerId', isEqualTo: uid).get();
    for (final doc in ownedAnniversaries.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_db.collection('users').doc(uid));
    batch.delete(_db.collection('publicProfiles').doc(uid));

    await batch.commit();

    // Trash snapshots are the user's actual deleted content (not just
    // operational metadata like auditLogs), so they must go too — otherwise
    // it silently outlives account deletion with no way to ever purge it,
    // since _purgeExpired only runs from a client the now-deleted user no
    // longer has. Deleted in its own batch(es), chunked well under
    // Firestore's 500-write-per-batch limit in case of a large trash.
    final ownedTrash = await _db.collection('trash').where('ownerId', isEqualTo: uid).get();
    const chunkSize = 400;
    for (var i = 0; i < ownedTrash.docs.length; i += chunkSize) {
      final trashBatch = _db.batch();
      for (final doc in ownedTrash.docs.skip(i).take(chunkSize)) {
        trashBatch.delete(doc.reference);
      }
      await trashBatch.commit();
    }

    await user.delete();
  }
}
