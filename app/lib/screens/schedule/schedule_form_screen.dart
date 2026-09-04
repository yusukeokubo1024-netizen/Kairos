import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/schedule.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_prep_templates.dart';
import '../../models/shared_group.dart';
import '../../models/task.dart';
import '../../services/notification_service.dart';

/// Create or edit a schedule. Pass [schedule] to edit an existing one,
/// otherwise a new schedule is created starting on [initialDate].
class ScheduleFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Schedule? schedule;

  const ScheduleFormScreen({super.key, this.initialDate, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  static const _palette = <Color>[
    Color(0xFF2563EB), // blue
    Color(0xFF0EA5E9), // sky
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFFA855F7), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF64748B), // slate
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  bool _isAllDay = false;
  late Color _color;
  // uids of people (besides the owner) to share this schedule with.
  final Set<String> _selectedPersonIds = {};
  bool _isSaving = false;
  int? _reminderMinutes;
  // Which group calendar this schedule is categorized under (null = 個人の予定).
  // Used only for show/hide filtering on the home calendar.
  String? _groupId;

  static const _reminderOptions = <int?, String>{
    null: '通知しない',
    5: '5分前',
    15: '15分前',
    30: '30分前',
    60: '1時間前',
    1440: '1日前',
  };

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (schedule != null) {
      _titleController.text = schedule.title;
      _locationController.text = schedule.location;
      _notesController.text = schedule.notes;
      _start = schedule.startTime;
      _end = schedule.endTime;
      _isAllDay = schedule.isAllDay;
      _color = schedule.color;
      _reminderMinutes = schedule.reminderMinutes;
      _groupId = schedule.groupId;
      _selectedPersonIds.addAll(schedule.participantIds.where((id) => id != uid));
    } else {
      final base = widget.initialDate ?? DateTime.now();
      _start = DateTime(base.year, base.month, base.day, 9, 0);
      _end = _start.add(const Duration(hours: 1));
      _color = Schedule.defaultColor;
      _reminderMinutes = Schedule.defaultReminderMinutes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;

    DateTime combined;
    if (_isAllDay) {
      // All-day schedules have no time-of-day: start is midnight, end is the
      // last moment of its day, so a multi-day all-day event still works.
      combined = isStart
          ? DateTime(date.year, date.month, date.day)
          : DateTime(date.year, date.month, date.day, 23, 59, 59);
    } else {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
      );
      if (time == null) return;
      combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    setState(() {
      if (isStart) {
        _start = combined;
        if (_end.isBefore(_start)) {
          _end = _isAllDay ? _start.add(const Duration(hours: 23, minutes: 59)) : _start.add(const Duration(hours: 1));
        }
      } else {
        _end = combined;
      }
    });
  }

  void _onAllDayChanged(bool value) {
    setState(() {
      _isAllDay = value;
      if (value) {
        _start = DateTime(_start.year, _start.month, _start.day);
        _end = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);
      } else {
        _start = DateTime(_start.year, _start.month, _start.day, 9, 0);
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('終了時刻は開始時刻より後にしてください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    final participantIds = <String>{uid, ..._selectedPersonIds};

    try {
      if (_isEditing) {
        final updated = Schedule(
          id: widget.schedule!.id,
          ownerId: widget.schedule!.ownerId,
          title: _titleController.text.trim(),
          startTime: _start,
          endTime: _end,
          isAllDay: _isAllDay,
          location: _locationController.text.trim(),
          notes: _notesController.text.trim(),
          groupId: _groupId,
          participantIds: participantIds.toList(),
          color: _color,
          reminderMinutes: _reminderMinutes,
        );
        await db.collection('schedules').doc(updated.id).update(updated.toUpdateMap());
        await NotificationService.instance.scheduleForSchedule(updated);
      } else {
        final newSchedule = Schedule(
          id: '',
          ownerId: uid,
          title: _titleController.text.trim(),
          startTime: _start,
          endTime: _end,
          isAllDay: _isAllDay,
          location: _locationController.text.trim(),
          notes: _notesController.text.trim(),
          groupId: _groupId,
          participantIds: participantIds.toList(),
          color: _color,
          reminderMinutes: _reminderMinutes,
        );
        final ref = await db.collection('schedules').add(newSchedule.toCreateMap());
        await NotificationService.instance.scheduleForSchedule(
          Schedule(
            id: ref.id,
            ownerId: newSchedule.ownerId,
            title: newSchedule.title,
            startTime: newSchedule.startTime,
            endTime: newSchedule.endTime,
            isAllDay: newSchedule.isAllDay,
            location: newSchedule.location,
            notes: newSchedule.notes,
            groupId: newSchedule.groupId,
            participantIds: newSchedule.participantIds,
            color: newSchedule.color,
            reminderMinutes: newSchedule.reminderMinutes,
          ),
        );
        if (mounted) await _offerPrepTasks(ref.id, newSchedule.title);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// After creating a schedule, offers keyword-matched prep items (e.g.
  /// "参観" → 上履き・プリント確認) as tasks linked back to this schedule.
  Future<void> _offerPrepTasks(String scheduleId, String title) async {
    final suggestions = suggestPrepItems(title);
    if (suggestions.isEmpty) return;

    final selected = Set<String>.from(suggestions);
    final confirmed = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('準備するものはありますか？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in suggestions)
                CheckboxListTile(
                  title: Text(item),
                  value: selected.contains(item),
                  onChanged: (checked) {
                    setDialogState(() {
                      checked == true ? selected.add(item) : selected.remove(item);
                    });
                  },
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('追加しない')),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('タスクに追加'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == null || confirmed.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (final item in confirmed) {
      final task = Task(
        id: '',
        ownerId: uid,
        title: item,
        priority: TaskPriority.medium,
        completed: false,
        scheduleId: scheduleId,
      );
      batch.set(db.collection('tasks').doc(), task.toCreateMap());
    }
    await batch.commit();
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final groupsQuery =
        FirebaseFirestore.instance.collection('sharedGroups').where('memberIds', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '予定を編集' : '予定を作成')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'タイトルを入力してください' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('終日'),
                  value: _isAllDay,
                  onChanged: _onAllDayChanged,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('開始'),
                  subtitle: Text(_isAllDay ? _formatDate(_start) : _formatDateTime(_start)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _pickDateTime(isStart: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('終了'),
                  subtitle: Text(_isAllDay ? _formatDate(_end) : _formatDateTime(_end)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _pickDateTime(isStart: false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: '場所',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'メモ',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('色', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: _palette.map((color) {
                    final selected = color.toARGB32() == _color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: selected ? 18 : 15,
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('通知', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: _reminderMinutes,
                  items: _reminderOptions.entries
                      .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                      .toList(),
                  onChanged: (value) => setState(() => _reminderMinutes = value),
                ),
                const SizedBox(height: 16),
                const Text('カレンダー', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text(
                  'ホーム画面のフィルターで表示/非表示を切り替えるための分類です',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: groupsQuery.snapshots(),
                  builder: (context, snapshot) {
                    final groups = snapshot.hasData
                        ? snapshot.data!.docs.map((doc) => SharedGroup.fromFirestore(doc)).toList()
                        : <SharedGroup>[];
                    // Keep the current value selectable even if its group
                    // hasn't loaded into the stream yet.
                    final groupIds = groups.map((g) => g.id).toSet();
                    final value = (_groupId == null || groupIds.contains(_groupId))
                        ? _groupId
                        : null;

                    return DropdownButtonFormField<String?>(
                      initialValue: value,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: _CategoryOption(
                            icon: Icons.label_outline,
                            label: personalCategoryDefaultLabel,
                          ),
                        ),
                        ...personalCategories.entries.map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: _CategoryOption(icon: Icons.label_outline, label: entry.value),
                          ),
                        ),
                        ...groups.map(
                          (group) => DropdownMenuItem(
                            value: group.id,
                            child: _CategoryOption(
                              icon: Icons.groups_outlined,
                              label: '${group.name}（グループ）',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (selected) {
                        setState(() {
                          _groupId = selected;
                          for (final group in groups) {
                            if (group.id == selected) {
                              // Selecting a group defaults its members into
                              // the share list; existing selections are kept.
                              _selectedPersonIds.addAll(group.memberIds.where((id) => id != uid));
                              break;
                            }
                          }
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('共有する相手', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text(
                  'グループのメンバーの中から、この予定を共有する人だけを選べます',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: groupsQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final groups = snapshot.data!.docs
                        .map((doc) => SharedGroup.fromFirestore(doc))
                        .toList();

                    final candidateIds = <String>{};
                    for (final group in groups) {
                      candidateIds.addAll(group.memberIds);
                    }
                    candidateIds.remove(uid);

                    if (candidateIds.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('共有できる相手がいません。まずグループでメンバーを増やしてください。'),
                      );
                    }

                    return Column(
                      children: candidateIds.map((personId) {
                        return _PersonCheckbox(
                          uid: personId,
                          value: _selectedPersonIds.contains(personId),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedPersonIds.add(personId);
                              } else {
                                _selectedPersonIds.remove(personId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dropdown item label with a small icon distinguishing a personal
/// category from an actual shared group — they can share the same name
/// (e.g. a "家族" category and a "家族" group) so the icon avoids confusion.
class _CategoryOption extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryOption({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _PersonCheckbox extends StatelessWidget {
  final String uid;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _PersonCheckbox({required this.uid, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('publicProfiles').doc(uid).get(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['displayName'] as String?;
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(name?.isNotEmpty == true ? name! : '読み込み中...'),
          value: value,
          onChanged: onChanged,
        );
      },
    );
  }
}
