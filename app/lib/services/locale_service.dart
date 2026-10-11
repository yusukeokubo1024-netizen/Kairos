import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language selection, independent of the device's system locale.
/// Backed by SharedPreferences so the choice persists across launches, and
/// exposed as a ValueNotifier so the whole app rebuilds immediately when it
/// changes in Settings — no restart needed.
class LocaleService {
  static final LocaleService instance = LocaleService._();
  LocaleService._();

  static const _prefsKey = 'app_locale';
  static const supportedLocales = [Locale('ja'), Locale('en'), Locale('ko'), Locale('zh')];

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ja'));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
      locale.value = Locale(code);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
    await saveToAccount();
  }

  /// Mirrors the language to users/{uid}.locale so push notifications sent
  /// by the server (chat messages, reminders) use it too. Best-effort.
  Future<void> saveToAccount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'locale': locale.value.languageCode}, SetOptions(merge: true));
    } catch (_) {}
  }
}
