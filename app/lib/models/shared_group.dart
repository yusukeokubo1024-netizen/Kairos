import 'package:cloud_firestore/cloud_firestore.dart';

class SharedGroup {
  final String id;
  final String ownerId;
  final String name;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SharedGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.memberIds,
    this.createdAt,
    this.updatedAt,
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
