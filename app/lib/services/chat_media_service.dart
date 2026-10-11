import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../models/schedule.dart';
import 'notification_service.dart';

/// Why a location couldn't be sent.
enum LocationFailure { serviceOff, denied }

/// Sends the non-text group chat messages: photos, current location, voice
/// messages and schedule polls (日程調整), and records poll votes/decisions.
/// Photos and voice recordings go to Cloud Storage at chat/{groupId}/… (see
/// firebase/storage.rules — only that group's members can read them).
class ChatMediaService {
  ChatMediaService._();
  static final instance = ChatMediaService._();

  final _picker = ImagePicker();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _messages(String groupId) => FirebaseFirestore
      .instance
      .collection('sharedGroups')
      .doc(groupId)
      .collection('messages');

  Future<void> _add(String groupId, ChatMessage message) =>
      _messages(groupId).add(message.toCreateMap());

  Future<({String url, String path})> _upload(
    String groupId,
    File file, {
    required String extension,
    required String contentType,
  }) async {
    final path = 'chat/$groupId/${DateTime.now().millisecondsSinceEpoch}_$_uid.$extension';
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return (url: await ref.getDownloadURL(), path: path);
  }

  /// Picks photo(s) from the camera or library, shrinks them and sends each
  /// as its own message. Returns how many were sent (0 if cancelled).
  Future<int> sendPhotos(String groupId, {required bool fromCamera}) async {
    // Picked at full size and re-encoded below, rather than using the
    // picker's own resizing, which can carry the original metadata over.
    final List<XFile> picked;
    if (fromCamera) {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      picked = photo == null ? [] : [photo];
    } else {
      picked = await _picker.pickMultiImage(limit: 10);
    }
    var sent = 0;
    for (final photo in picked) {
      // Re-encoded without Exif, so the photo carries no GPS location (or
      // camera/device details) — phone photos usually embed where they were
      // taken. Also shrinks it (phone screen size is plenty) to keep uploads
      // small. If re-encoding fails the photo is skipped rather than sent
      // with its metadata intact.
      final bytes = await FlutterImageCompress.compressWithFile(
        photo.path,
        minWidth: 1600,
        minHeight: 1600,
        quality: 80,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (bytes == null) continue;
      final path = 'chat/$groupId/${DateTime.now().millisecondsSinceEpoch}_$_uid.jpg';
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      await _add(
        groupId,
        ChatMessage(
          id: '',
          senderId: _uid,
          text: '',
          type: ChatMessageType.image,
          mediaUrl: await ref.getDownloadURL(),
          mediaPath: path,
        ),
      );
      sent++;
    }
    return sent;
  }

  /// Sends the device's current location, asking for permission if needed.
  /// Returns null on success.
  Future<LocationFailure?> sendCurrentLocation(String groupId) async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationFailure.serviceOff;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return LocationFailure.denied;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    await _add(
      groupId,
      ChatMessage(
        id: '',
        senderId: _uid,
        text: '',
        type: ChatMessageType.location,
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
    return null;
  }

  /// Uploads a finished voice recording (an .m4a file) and sends it.
  Future<void> sendVoice(String groupId, File recording, Duration duration) async {
    final uploaded = await _upload(
      groupId,
      recording,
      extension: 'm4a',
      contentType: 'audio/mp4',
    );
    await _add(
      groupId,
      ChatMessage(
        id: '',
        senderId: _uid,
        text: '',
        type: ChatMessageType.voice,
        mediaUrl: uploaded.url,
        mediaPath: uploaded.path,
        duration: duration,
      ),
    );
  }

  Future<void> sendPoll(String groupId, String title, List<PollOption> options) => _add(
        groupId,
        ChatMessage(
          id: '',
          senderId: _uid,
          text: title,
          type: ChatMessageType.poll,
          pollOptions: options,
        ),
      );

  /// Sets (or, with null, clears) the signed-in user's answer for one option.
  Future<void> vote(String groupId, ChatMessage poll, int option, PollAnswer? answer) {
    final mine = Map<String, String>.from(
      (poll.votes[_uid] ?? const {}).map((k, v) => MapEntry(k, v.name)),
    );
    if (answer == null) {
      mine.remove('$option');
    } else {
      mine['$option'] = answer.name;
    }
    // Only this user's own entry is written (see firestore.rules).
    return _messages(groupId).doc(poll.id).update({'votes.$_uid': mine});
  }

  /// 転送: sends a copy of [message] to another group the user belongs to.
  /// The photo/recording is shared by URL rather than re-uploaded, and the
  /// copy carries no Storage path, so unsending the copy can't delete the
  /// original's file.
  Future<void> forward(String targetGroupId, ChatMessage message) => _add(
        targetGroupId,
        ChatMessage(
          id: '',
          senderId: _uid,
          text: message.text,
          type: message.type,
          mediaUrl: message.mediaUrl,
          duration: message.duration,
          latitude: message.latitude,
          longitude: message.longitude,
        ),
      );

  /// 送信取り消し: blanks the message for everyone (it stays as an "unsent"
  /// placeholder) and deletes its photo/recording. Sender only.
  Future<void> unsend(String groupId, ChatMessage message) async {
    await _messages(groupId).doc(message.id).update({
      'unsent': true,
      'type': ChatMessageType.text.name,
      'text': '',
      'isStamp': false,
      'reactions': <String, dynamic>{},
      for (final field in [
        'mediaUrl',
        'mediaPath',
        'durationMs',
        'latitude',
        'longitude',
        'pollOptions',
        'votes',
      ])
        field: FieldValue.delete(),
    });
    final path = message.mediaPath;
    if (path != null) {
      try {
        await FirebaseStorage.instance.ref(path).delete();
      } catch (_) {
        // Best-effort — the message itself no longer points at the file.
      }
    }
  }

  /// 削除: hides a message from the signed-in user's own chat only.
  Future<void> hideForMe(String groupId, String messageId) {
    return FirebaseFirestore.instance.collection('users').doc(_uid).update({
      'hiddenChatMessages': FieldValue.arrayUnion(['$groupId/$messageId']),
    });
  }

  /// Turns the chosen option into a schedule shared with every group member
  /// and marks the poll as decided. Only the poll's creator can do this.
  Future<void> decide(String groupId, ChatMessage poll, int option) async {
    final db = FirebaseFirestore.instance;
    final group = await db.collection('sharedGroups').doc(groupId).get();
    final memberIds = List<String>.from(group.data()?['memberIds'] as List? ?? [_uid]);
    final chosen = poll.pollOptions[option];
    final start = chosen.hasTime
        ? chosen.start
        : DateTime(chosen.start.year, chosen.start.month, chosen.start.day);
    final schedule = Schedule(
      id: '',
      ownerId: _uid,
      title: poll.text,
      startTime: start,
      endTime: chosen.hasTime ? start.add(const Duration(hours: 1)) : start,
      isAllDay: !chosen.hasTime,
      groupId: groupId,
      participantIds: {_uid, ...memberIds}.toList(),
    );
    final ref = await db.collection('schedules').add(schedule.toCreateMap());
    await _messages(groupId).doc(poll.id).update({
      'decidedOption': option,
      'decidedScheduleId': ref.id,
    });
    final created = await ref.get();
    await NotificationService.instance.scheduleForSchedule(Schedule.fromFirestore(created));
  }
}
