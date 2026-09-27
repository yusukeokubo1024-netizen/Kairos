import 'package:cloud_firestore/cloud_firestore.dart';

class SharedGroup {
  final String id;
  final String ownerId;
  final String name;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Short, easy-to-type invite code (e.g. "K7QX9M") that resolves to this
  // group's id via the groupShortCodes collection — see
  // GroupDetailScreen._ensureShortCode. Null until the owner's detail screen
  // has generated one (self-heals the first time they open it, same as
  // groupInvitePreviews).
  final String? shortCode;

  SharedGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.memberIds,
    this.createdAt,
    this.updatedAt,
    this.shortCode,
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
      shortCode: data['shortCode'] as String?,
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
