import 'package:cloud_firestore/cloud_firestore.dart';

class SharedGroup {
  final String id;
  final String ownerId;
  final String name;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Denormalized "someone just added a schedule" indicator, so group members
  // can see there's something new without a real push notification (which
  // would need Cloud Functions / the paid Blaze plan). Any member may set
  // these two fields — see firestore.rules.
  final DateTime? lastActivityAt;
  final String? lastActivityText;

  SharedGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.memberIds,
    this.createdAt,
    this.updatedAt,
    this.lastActivityAt,
    this.lastActivityText,
  });

  factory SharedGroup.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SharedGroup(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      name: data['name'] as String,
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate(),
      lastActivityText: data['lastActivityText'] as String?,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
