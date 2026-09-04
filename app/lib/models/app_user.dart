import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdTime;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdTime,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['display_name'] as String? ?? '',
      createdTime: (data['created_time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'created_time': FieldValue.serverTimestamp(),
    };
  }
}
