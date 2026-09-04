import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  // A "stamp" is an emoji sent on its own, rendered large like a sticker
  // instead of a normal chat bubble.
  final bool isStamp;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.isStamp = false,
    this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      isStamp: data['isStamp'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'senderId': senderId,
      'text': text,
      'isStamp': isStamp,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
