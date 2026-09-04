import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  // A "stamp" is an emoji sent on its own, rendered large like a sticker
  // instead of a normal chat bubble.
  final bool isStamp;
  // emoji -> uids of people who reacted with it.
  final Map<String, List<String>> reactions;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.isStamp = false,
    this.reactions = const {},
    this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawReactions = data['reactions'] as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      isStamp: data['isStamp'] as bool? ?? false,
      reactions: rawReactions.map(
        (emoji, uids) => MapEntry(emoji, List<String>.from(uids as List)),
      ),
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
