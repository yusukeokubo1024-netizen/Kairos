import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The notification categories whose Android sound the user can pick
/// independently. Each maps to its own notification channel — Android
/// channels are immutable once created, so picking a new sound means
/// creating a brand-new channel id and switching to it, rather than
/// editing the existing one.
enum SoundCategory {
  alarm('clock_alarms', 'アラーム・タイマー'),
  schedule('schedule_reminders', '予定のリマインダー'),
  chat('chat_messages', 'グループチャット');

  const SoundCategory(this.baseChannelId, this.labelJa);
  final String baseChannelId;
  final String labelJa;
}

class NotificationSoundChoice {
  final String channelId;
  final String? uri; // null = never customized — system default sound
  final String title;

  const NotificationSoundChoice({required this.channelId, this.uri, required this.title});

  factory NotificationSoundChoice.fromJson(Map<String, dynamic> json) => NotificationSoundChoice(
        channelId: json['channelId'] as String,
        uri: json['uri'] as String?,
        title: json['title'] as String,
      );

  Map<String, dynamic> toJson() => {'channelId': channelId, 'uri': uri, 'title': title};
}

/// Lets the user pick any notification sound already on their Android
/// device (via the system ringtone picker, see MainActivity.kt) for each
/// [SoundCategory], independently. iOS has no equivalent system picker API
/// for third-party apps, so this is Android-only — iOS keeps the default
/// notification sound.
class NotificationSoundService {
  static final NotificationSoundService instance = NotificationSoundService._();
  NotificationSoundService._();

  static const _platform = MethodChannel('com.kairos.app/ringtone_picker');
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  String _prefsKey(SoundCategory category) => 'notification_sound_${category.name}';

  Future<NotificationSoundChoice> load(SoundCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(category));
    if (raw == null) {
      return NotificationSoundChoice(channelId: category.baseChannelId, title: 'デフォルト');
    }
    return NotificationSoundChoice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _save(SoundCategory category, NotificationSoundChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(category), jsonEncode(choice.toJson()));

    // The Cloud Functions that push schedule reminders / chat messages
    // need to know which channel id to target so the server push lands on
    // the right (custom-sound) channel too, not just locally-scheduled
    // notifications.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'notificationChannels': {category.name: choice.channelId},
    }, SetOptions(merge: true));
  }

  AndroidNotificationChannel _channelFor(SoundCategory category, NotificationSoundChoice choice) {
    final sound = choice.uri != null ? UriAndroidNotificationSound(choice.uri!) : null;
    return switch (category) {
      SoundCategory.alarm => AndroidNotificationChannel(
          choice.channelId,
          category.labelJa,
          description: 'アラーム・タイマー機能の通知です',
          importance: Importance.max,
          sound: sound,
        ),
      SoundCategory.schedule => AndroidNotificationChannel(
          choice.channelId,
          category.labelJa,
          importance: Importance.high,
          sound: sound,
        ),
      SoundCategory.chat => AndroidNotificationChannel(
          choice.channelId,
          category.labelJa,
          description: 'グループチャットの新着メッセージ通知です',
          importance: Importance.high,
          sound: sound,
        ),
    };
  }

  /// Opens the system ringtone picker; returns the newly chosen sound, or
  /// null if the user cancelled. Also creates the new Android channel and
  /// persists the choice (locally + Firestore) before returning.
  Future<NotificationSoundChoice?> pick(SoundCategory category) async {
    final current = await load(category);
    final result = await _platform.invokeMapMethod<String, dynamic>(
      'pickRingtone',
      {'currentUri': current.uri},
    );
    if (result == null) return null;

    final choice = NotificationSoundChoice(
      channelId: '${category.baseChannelId}_${DateTime.now().millisecondsSinceEpoch}',
      uri: result['uri'] as String,
      title: result['title'] as String,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channelFor(category, choice));
    await _save(category, choice);
    return choice;
  }

  /// Ensures every category's currently-chosen channel exists — called at
  /// app startup, since a channel only persists across reinstalls/app
  /// updates if it's (re)created, and a brand new install needs its
  /// default-sound base channels to exist before anything (local or
  /// pushed) can target them.
  Future<void> ensureChannelsExist() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final category in SoundCategory.values) {
      final choice = await load(category);
      await android.createNotificationChannel(_channelFor(category, choice));
    }
  }
}
