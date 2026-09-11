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
    // Best-effort — a failure here shouldn't block account creation.
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
    }

    final ownedAnniversaries =
        await _db.collection('anniversaries').where('ownerId', isEqualTo: uid).get();
    for (final doc in ownedAnniversaries.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_db.collection('users').doc(uid));
    batch.delete(_db.collection('publicProfiles').doc(uid));

    await batch.commit();
    await user.delete();
  }
}
