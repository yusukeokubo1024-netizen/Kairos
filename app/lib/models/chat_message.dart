import 'package:cloud_firestore/cloud_firestore.dart';

/// What a chat message carries. Messages written before [type] existed have
/// no type field and are read as [text] or [stamp] (from isStamp).
enum ChatMessageType { text, stamp, image, location, voice, poll }

/// One candidate date in a schedule poll (日程調整).
class PollOption {
  final DateTime start;
  // false = a whole-day candidate (only the date matters).
  final bool hasTime;

  const PollOption({required this.start, this.hasTime = false});

  factory PollOption.fromMap(Map<String, dynamic> map) => PollOption(
        start: (map['start'] as Timestamp).toDate(),
        hasTime: map['hasTime'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {'start': Timestamp.fromDate(start), 'hasTime': hasTime};
}

/// A poll answer: ○ / △ / ×.
enum PollAnswer { yes, maybe, no }

class ChatMessage {
  final String id;
  final String senderId;
  final ChatMessageType type;
  // Text body; the emoji for a stamp; the title for a poll; '' otherwise.
  final String text;
  // emoji -> uids of people who reacted with it.
  final Map<String, List<String>> reactions;
  // uids of members (other than the sender) who have opened the chat since
  // this was sent — drives the "既読 N" count under one's own messages.
  final List<String> readBy;
  final DateTime? createdAt;

  // image / voice: download URL and the Storage path it lives at.
  final String? mediaUrl;
  final String? mediaPath;
  // voice: recording length.
  final Duration? duration;
  // location
  final double? latitude;
  final double? longitude;
  // poll
  final List<PollOption> pollOptions;
  // uid -> option index (as a string, Firestore map keys) -> answer.
  final Map<String, Map<String, PollAnswer>> votes;
  final int? decidedOption;
  final String? decidedScheduleId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = ChatMessageType.text,
    this.reactions = const {},
    this.readBy = const [],
    this.createdAt,
    this.mediaUrl,
    this.mediaPath,
    this.duration,
    this.latitude,
    this.longitude,
    this.pollOptions = const [],
    this.votes = const {},
    this.decidedOption,
    this.decidedScheduleId,
  });

  bool get isStamp => type == ChatMessageType.stamp;

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawReactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final rawType = data['type'] as String?;
    final type = ChatMessageType.values.firstWhere(
      (t) => t.name == rawType,
      orElse: () =>
          (data['isStamp'] as bool? ?? false) ? ChatMessageType.stamp : ChatMessageType.text,
    );
    final rawVotes = data['votes'] as Map<String, dynamic>? ?? {};
    final durationMs = data['durationMs'] as int?;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String? ?? '',
      type: type,
      reactions: rawReactions.map(
        (emoji, uids) => MapEntry(emoji, List<String>.from(uids as List)),
      ),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      mediaUrl: data['mediaUrl'] as String?,
      mediaPath: data['mediaPath'] as String?,
      duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      pollOptions: (data['pollOptions'] as List? ?? [])
          .map((e) => PollOption.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      votes: rawVotes.map((uid, answers) => MapEntry(
            uid,
            (answers as Map).map((index, answer) => MapEntry(
                  index as String,
                  PollAnswer.values.firstWhere((a) => a.name == answer,
                      orElse: () => PollAnswer.no),
                )),
          )),
      decidedOption: data['decidedOption'] as int?,
      decidedScheduleId: data['decidedScheduleId'] as String?,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'senderId': senderId,
      'type': type.name,
      'text': text,
      // Still written so older app versions keep rendering stamps.
      'isStamp': isStamp,
      'createdAt': FieldValue.serverTimestamp(),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaPath != null) 'mediaPath': mediaPath,
      if (duration != null) 'durationMs': duration!.inMilliseconds,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (type == ChatMessageType.poll) ...{
        'pollOptions': pollOptions.map((o) => o.toMap()).toList(),
        'votes': <String, dynamic>{},
      },
    };
  }

  /// How many members answered [answer] for the option at [index].
  int countFor(int index, PollAnswer answer) =>
      votes.values.where((v) => v['$index'] == answer).length;
}
