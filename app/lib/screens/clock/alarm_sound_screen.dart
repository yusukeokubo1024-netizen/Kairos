import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/alarm_service.dart';
import '../../services/alarm_sound_service.dart';

/// iOS picker for the Alarm/Timer sound (see [AlarmSound]). Tapping a sound
/// selects it and plays a short preview.
class AlarmSoundScreen extends StatefulWidget {
  const AlarmSoundScreen({super.key});

  @override
  State<AlarmSoundScreen> createState() => _AlarmSoundScreenState();
}

class _AlarmSoundScreenState extends State<AlarmSoundScreen> {
  static const _previewLength = Duration(seconds: 6);

  AlarmSound? _selected;
  AlarmSound? _previewing;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    AlarmSoundService.instance.selected().then((s) {
      if (mounted) setState(() => _selected = s);
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    AlarmSoundService.instance.stop();
    super.dispose();
  }

  Future<void> _choose(AlarmSound sound) async {
    final l10n = AppLocalizations.of(context)!;
    final changed = sound != _selected;
    setState(() {
      _selected = sound;
      _previewing = sound;
    });

    _previewTimer?.cancel();
    await AlarmSoundService.instance.start(sound: sound);
    _previewTimer = Timer(_previewLength, () {
      AlarmSoundService.instance.stop();
      if (mounted) setState(() => _previewing = null);
    });

    if (changed) {
      await AlarmSoundService.instance.select(sound);
      // Already-scheduled alarms keep their old sound until re-created.
      await AlarmService.instance.rescheduleAll(defaultLabel: l10n.alarmDefaultLabel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.alarmSoundTitle)),
      body: _selected == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(l10n.alarmSoundHint, style: Theme.of(context).textTheme.bodySmall),
                ),
                for (final sound in AlarmSound.values)
                  ListTile(
                    leading: Icon(
                      _previewing == sound ? Icons.volume_up : Icons.music_note_outlined,
                    ),
                    title: Text(sound.label(l10n)),
                    trailing: sound == _selected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => _choose(sound),
                  ),
              ],
            ),
    );
  }
}
