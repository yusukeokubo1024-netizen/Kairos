import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Registers this device's FCM token so the sendDueReminders Cloud Function
/// (functions/src/scheduledReminders.ts) can push schedule reminders even
/// when the app isn't running. Local notifications (NotificationService)
/// still handle on-device scheduling — this is purely additive, for the
/// "app is closed/killed" case local alarms can't always cover.
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();
  bool _listenersAttached = false;

  Future<void> init() async {
    if (!_listenersAttached) {
      // A push notification arriving while the app is in the foreground
      // isn't shown by the OS automatically — show it ourselves via the
      // same local-notification channel the on-device reminders use.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        _localPlugin.show(
          id: message.hashCode & 0x7fffffff,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'schedule_reminders',
              '予定のリマインダー',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((_) => registerCurrentToken());
      _listenersAttached = true;
    }
    await registerCurrentToken();
  }

  /// Saves this device's current FCM token under the signed-in user's
  /// deviceTokens/{uid} doc. Safe to call repeatedly (e.g. on every sign-in)
  /// — arrayUnion is a no-op if the token is already stored.
  Future<void> registerCurrentToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('deviceTokens').doc(uid).set({
      'tokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Removes this device's token on sign-out so a signed-out device stops
  /// receiving pushes meant for whoever signs in next on it.
  Future<void> unregisterCurrentToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('deviceTokens').doc(uid).update({
      'tokens': FieldValue.arrayRemove([token]),
    }).catchError((_) {});
  }
}
