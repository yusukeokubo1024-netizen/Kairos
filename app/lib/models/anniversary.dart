import 'package:cloud_firestore/cloud_firestore.dart';

/// A yearly-recurring anniversary (birthday, wedding anniversary, etc.) with
/// no specific year attached — only a month and day.
class Anniversary {
  final String id;
  final String ownerId;
  final String title;
  final int month;
  final int day;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Anniversary({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.month,
    required this.day,
    this.createdAt,
    this.updatedAt,
  });

  factory Anniversary.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Anniversary(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      month: data['month'] as int,
      day: data['day'] as int,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'month': month,
      'day': day,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'month': month,
      'day': day,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
