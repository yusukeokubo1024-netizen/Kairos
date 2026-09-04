import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/task.dart';
import '../../services/notification_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _priority = task.priority;
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    try {
      if (_isEditing) {
        final updated = Task(
          id: widget.task!.id,
          ownerId: widget.task!.ownerId,
          title: _titleController.text.trim(),
          priority: _priority,
          completed: widget.task!.completed,
          dueDate: _dueDate,
        );
        await db.collection('tasks').doc(updated.id).update(updated.toUpdateMap());
        if (!updated.completed) {
          await NotificationService.instance.scheduleForTask(updated);
        }
      } else {
        final newTask = Task(
          id: '',
          ownerId: uid,
          title: _titleController.text.trim(),
          priority: _priority,
          completed: false,
          dueDate: _dueDate,
        );
        final ref = await db.collection('tasks').add(newTask.toCreateMap());
        await NotificationService.instance.scheduleForTask(
          Task(
            id: ref.id,
            ownerId: newTask.ownerId,
            title: newTask.title,
            priority: newTask.priority,
            completed: false,
            dueDate: newTask.dueDate,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null) return;
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
    await NotificationService.instance.cancelForTask(task.id);
    if (mounted) Navigator.of(context).pop();

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('タスクを削除しました'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            await FirebaseFirestore.instance.collection('tasks').doc(task.id).set(task.toCreateMap());
            if (!task.completed) {
              await NotificationService.instance.scheduleForTask(task);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'タスクを編集' : 'タスクを作成'),
        actions: _isEditing
            ? [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete)]
            : null,
      ),
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
                const SizedBox(height: 16),
                const Text('優先度', style: TextStyle(fontWeight: FontWeight.bold)),
                SegmentedButton<TaskPriority>(
                  segments: const [
                    ButtonSegment(value: TaskPriority.low, label: Text('低')),
                    ButtonSegment(value: TaskPriority.medium, label: Text('中')),
                    ButtonSegment(value: TaskPriority.high, label: Text('高')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selection) => setState(() => _priority = selection.first),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('期限'),
                  subtitle: Text(
                    _dueDate == null
                        ? '設定なし'
                        : '${_dueDate!.year}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                      const Icon(Icons.edit_calendar_outlined),
                    ],
                  ),
                  onTap: _pickDueDate,
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
