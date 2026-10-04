import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// The Clock tab's Alarm/Timer sounds bundled into the iOS app
/// (ios/Runner/alarm_*.caf, synthesized in-house — no licence or credit
/// needed). iOS only lets a third-party app's notifications play sounds
/// from its own bundle, so these are the choices there; Android picks any
/// device sound via NotificationSoundService instead.
enum AlarmSound {
  bell('alarm_bell.caf'),
  alarmClock('alarm_alarmclock.caf'),
  birds('alarm_birds.caf'),
  digital('alarm_digital.caf'),
  marimba('alarm_marimba.caf'),
  wave('alarm_wave.caf'),
  // The plain iOS notification chime ("ポン").
  system(null);

  const AlarmSound(this.fileName);
  final String? fileName;

  String label(AppLocalizations l10n) => switch (this) {
    AlarmSound.bell => l10n.alarmSoundBell,
    AlarmSound.alarmClock => l10n.alarmSoundAlarmClock,
    AlarmSound.birds => l10n.alarmSoundBirds,
    AlarmSound.digital => l10n.alarmSoundDigital,
    AlarmSound.marimba => l10n.alarmSoundMarimba,
    AlarmSound.wave => l10n.alarmSoundWave,
    AlarmSound.system => l10n.alarmSoundSystem,
  };
}

/// Stores the chosen [AlarmSound], and loops a sound in-app — for the
/// Timer's "time's up" dialog and for previews in the sound picker. iOS
/// only (see [AlarmSound]); Android's alarm-channel notification already
/// rings on its own.
class AlarmSoundService {
  AlarmSoundService._();
  static final instance = AlarmSoundService._();

  static const _channel = MethodChannel('kairos/alarm_sound');
  static const _prefsKey = 'ios_alarm_sound';
  static const _defaultSound = AlarmSound.bell;

  Future<AlarmSound> selected() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsKey);
    return AlarmSound.values.firstWhere((s) => s.name == name, orElse: () => _defaultSound);
  }

  Future<void> select(AlarmSound sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, sound.name);
  }

  /// Loops [sound] (the selected one by default) until [stop].
  Future<void> start({AlarmSound? sound}) async {
    if (!Platform.isIOS) return;
    final toPlay = sound ?? await selected();
    try {
      await _channel.invokeMethod<void>('start', {'file': toPlay.fileName});
    } on PlatformException catch (_) {}
  }

  Future<void> stop() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (_) {}
  }
}
