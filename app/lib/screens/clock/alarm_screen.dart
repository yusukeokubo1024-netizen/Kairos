import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/alarm.dart';
import '../../services/alarm_service.dart';
import '../../services/alarm_sound_service.dart';
import '../../services/locale_service.dart';
import 'alarm_sound_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<Alarm> _alarms = [];
  bool _loaded = false;
  AlarmSound? _sound;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alarms = await AlarmService.instance.load();
    final sound = await AlarmSoundService.instance.selected();
    if (!mounted) return;
    setState(() {
      _alarms = alarms;
      _sound = sound;
      _loaded = true;
    });
  }

  Future<void> _openEditor({Alarm? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AlarmEditorSheet(existing: existing),
    );
    if (result == null) return;

    final updated = existing == null
        ? await AlarmService.instance.add(_alarms, result, defaultLabel: l10n.alarmDefaultLabel)
        : await AlarmService.instance.update(_alarms, result, defaultLabel: l10n.alarmDefaultLabel);
    if (!mounted) return;
    setState(() => _alarms = updated);
  }

  Future<void> _toggle(Alarm alarm, bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    final updated = await AlarmService.instance.update(
      _alarms,
      alarm.copyWith(enabled: enabled),
      defaultLabel: l10n.alarmDefaultLabel,
    );
    if (!mounted) return;
    setState(() => _alarms = updated);
  }

  Future<bool> _confirmDelete(Alarm alarm) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.alarmDeleteConfirmTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return false;
    final updated = await AlarmService.instance.remove(_alarms, alarm.id);
    if (!mounted) return true;
    setState(() => _alarms = updated);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.alarmDeleted)));
    return true;
  }

  String _repeatSummary(Alarm alarm, AppLocalizations l10n) {
    if (alarm.repeatDays.isEmpty) return l10n.alarmRepeatNever;
    if (alarm.repeatDays.length == 7) return l10n.alarmRepeat;
    final locale = LocaleService.instance.locale.value.toLanguageTag();
    final sorted = alarm.repeatDays.toList()..sort();
    // DateTime.weekday is 1=Monday..7=Sunday; pick any week's matching date
    // to get a locale-correct short weekday name via intl.
    final monday = DateTime(2024, 1, 1); // a Monday
    return sorted
        .map((w) => DateFormat.E(locale).format(monday.add(Duration(days: w - 1))))
        .join(', ');
  }

  Future<void> _openSoundPicker() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlarmSoundScreen()));
    // The picker may also have re-scheduled (and so updated) the alarms.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [..._alarms]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    return Scaffold(
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // iOS only: Android picks its sound per notification
                // channel in Settings (NotificationSoundScreen).
                if (Platform.isIOS)
                  ListTile(
                    leading: const Icon(Icons.music_note_outlined),
                    title: Text(l10n.alarmSoundTitle),
                    subtitle: _sound == null ? null : Text(_sound!.label(l10n)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openSoundPicker,
                  ),
                if (Platform.isIOS) const Divider(height: 1),
                Expanded(
                  child: sorted.isEmpty
                      ? Center(child: Text(l10n.alarmEmpty))
                      : ListView.builder(
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final alarm = sorted[index];
                            final time =
                                '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
                            return Dismissible(
                              key: ValueKey(alarm.id),
                              confirmDismiss: (_) => _confirmDelete(alarm),
                              background: Container(
                                color: Theme.of(context).colorScheme.errorContainer,
                              ),
                              child: ListTile(
                                onTap: () => _openEditor(existing: alarm),
                                title: Text(
                                  time,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                                ),
                                subtitle: Text(
                                  [
                                    if (alarm.label.isNotEmpty) alarm.label,
                                    _repeatSummary(alarm, l10n),
                                    if (Platform.isIOS && alarm.snoozeMinutes > 0)
                                      l10n.alarmSnoozeSummary(alarm.snoozeMinutes),
                                  ].join(' · '),
                                ),
                                trailing: Switch(
                                  value: alarm.enabled,
                                  onChanged: (value) => _toggle(alarm, value),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: l10n.alarmAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AlarmEditorSheet extends StatefulWidget {
  final Alarm? existing;

  const _AlarmEditorSheet({this.existing});

  @override
  State<_AlarmEditorSheet> createState() => _AlarmEditorSheetState();
}

class _AlarmEditorSheetState extends State<_AlarmEditorSheet> {
  late DateTime _time;
  late final TextEditingController _labelController;
  late Set<int> _repeatDays;
  late int _snoozeMinutes;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _time = existing != null
        ? DateTime(now.year, now.month, now.day, existing.hour, existing.minute)
        : DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _labelController = TextEditingController(text: existing?.label ?? '');
    _repeatDays = {...(existing?.repeatDays ?? const {})};
    // New alarms snooze by default, like the built-in Clock app.
    _snoozeMinutes = existing?.snoozeMinutes ?? 5;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    final alarm = Alarm(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      hour: _time.hour,
      minute: _time.minute,
      label: _labelController.text.trim(),
      repeatDays: _repeatDays,
      enabled: widget.existing?.enabled ?? true,
      snoozeMinutes: _snoozeMinutes,
    );
    Navigator.of(context).pop(alarm);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = LocaleService.instance.locale.value.toLanguageTag();
    final monday = DateTime(2024, 1, 1);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existing == null ? l10n.alarmAddTitle : l10n.alarmEditTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(onPressed: _save, child: Text(l10n.commonSave)),
                  ],
                ),
                SizedBox(
                  height: 180,
                  // 24-hour wheel (23時59分 style) instead of AM/PM — this
                  // app targets a Japanese-first audience where that's the
                  // conventional format for this kind of picker.
                  // CupertinoDatePicker has its own use24hFormat flag and
                  // ignores MediaQuery.alwaysUse24HourFormat entirely, so
                  // that has to be passed explicitly.
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: _time,
                    onDateTimeChanged: (value) => setState(() => _time = value),
                  ),
                ),
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: l10n.alarmLabelField,
                    hintText: l10n.alarmLabelPlaceholder,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.alarmRepeat, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final weekday = i + 1;
                    final label = DateFormat.E(locale).format(monday.add(Duration(days: i)));
                    final selected = _repeatDays.contains(weekday);
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (value) => setState(() {
                        if (value) {
                          _repeatDays.add(weekday);
                        } else {
                          _repeatDays.remove(weekday);
                        }
                      }),
                    );
                  }),
                ),
                // iOS 26+ only: the AlarmKit alarm's snooze button.
                if (Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  Text(l10n.alarmSnooze, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final minutes in const [0, 5, 10, 15, 30])
                        ChoiceChip(
                          label: Text(
                            minutes == 0 ? l10n.alarmSnoozeOff : l10n.alarmSnoozeMinutes(minutes),
                          ),
                          selected: _snoozeMinutes == minutes,
                          onSelected: (_) => setState(() => _snoozeMinutes = minutes),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
