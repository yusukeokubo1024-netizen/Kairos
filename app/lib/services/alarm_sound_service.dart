import 'dart:io';

import 'package:flutter/services.dart';

/// Loops the system alarm sound while the app itself is showing a "time's
/// up" screen. iOS doesn't reliably present the scheduled Timer
/// notification while Kairos is in the foreground, so the app rings on its
/// own instead (the same approach as the built-in Clock app). Android's
/// alarm-channel notification already rings in the foreground, so this is
/// iOS only.
class AlarmSoundService {
  AlarmSoundService._();
  static final instance = AlarmSoundService._();

  static const _channel = MethodChannel('kairos/alarm_sound');

  Future<void> start() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('start');
    } on PlatformException catch (_) {}
  }

  Future<void> stop() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (_) {}
  }
}
