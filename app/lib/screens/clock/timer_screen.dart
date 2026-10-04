import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/alarm_sound_service.dart';
import '../../services/notification_service.dart';

const _timerNotificationId = 900000001;

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Duration _setDuration = const Duration(minutes: 5);
  Duration _remaining = const Duration(minutes: 5);
  DateTime? _endTime;
  bool _running = false;
  Timer? _ticker;

  bool get _isPaused => !_running && _endTime == null && _remaining != _setDuration;

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context)!;
    final endTime = DateTime.now().add(_remaining);
    setState(() {
      _endTime = endTime;
      _running = true;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    await NotificationService.instance.scheduleClockAlarm(
      id: _timerNotificationId,
      title: l10n.timerUpTitle,
      body: l10n.timerUpTitle,
      fireTime: endTime,
    );
  }

  void _tick() {
    final remaining = _endTime!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      setState(() {
        // Back to the picker/"Start" state (not "paused"/"Resume") — there's
        // nothing left to resume once a timer has actually rung out.
        _remaining = _setDuration;
        _running = false;
        _endTime = null;
      });
      _ringTimeUp();
      return;
    }
    setState(() => _remaining = remaining);
  }

  /// Rings in-app until dismissed — the scheduled notification alone made
  /// no sound at all while the app was open on iOS.
  Future<void> _ringTimeUp() async {
    final l10n = AppLocalizations.of(context)!;
    await AlarmSoundService.instance.start();
    if (!mounted) {
      await AlarmSoundService.instance.stop();
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.timer_outlined, size: 40),
        title: Text(l10n.timerUpTitle),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ringingStop),
          ),
        ],
      ),
    );
    await AlarmSoundService.instance.stop();
    // Also clears the already-delivered notification from Notification Center.
    await NotificationService.instance.cancelClockAlarm(_timerNotificationId);
  }

  Future<void> _pause() async {
    _ticker?.cancel();
    setState(() {
      _remaining = _endTime!.difference(DateTime.now());
      _running = false;
      _endTime = null;
    });
    await NotificationService.instance.cancelClockAlarm(_timerNotificationId);
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    setState(() {
      _remaining = _setDuration;
      _running = false;
      _endTime = null;
    });
    await NotificationService.instance.cancelClockAlarm(_timerNotificationId);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    AlarmSoundService.instance.stop();
    super.dispose();
  }

  String _format(Duration d) {
    // Round up to the nearest whole second rather than truncating: a
    // Timer.periodic(1s) callback almost never fires at exactly N.000s —
    // it's typically a few milliseconds late — so flooring a real
    // remaining duration of e.g. 3.995s straight to 3 made the countdown
    // visibly skip numbers (5,4,3,2,1 would show as 5,3,1,0).
    final totalSeconds = (d.inMilliseconds / 1000).ceil();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final hh = h > 0 ? '${h.toString().padLeft(2, '0')}:' : '';
    return '$hh${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final idle = !_running && !_isPaused;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (idle)
              SizedBox(
                height: 220,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: _setDuration,
                  onTimerDurationChanged: (value) => setState(() {
                    _setDuration = value;
                    _remaining = value;
                  }),
                ),
              )
            else
              Text(
                _format(_remaining),
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPaused) ...[
                  OutlinedButton(onPressed: _reset, child: Text(l10n.timerResetAction)),
                  const SizedBox(width: 24),
                ],
                FilledButton(
                  onPressed: _setDuration == Duration.zero && idle
                      ? null
                      : (_running ? _pause : _start),
                  child: Text(_running
                      ? l10n.timerPauseAction
                      : (_isPaused ? l10n.timerResumeAction : l10n.timerStart)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
