import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/anniversary.dart';
import '../../services/notification_service.dart';

class AnniversaryFormScreen extends StatefulWidget {
  final Anniversary? anniversary;

  const AnniversaryFormScreen({super.key, this.anniversary});

  @override
  State<AnniversaryFormScreen> createState() => _AnniversaryFormScreenState();
}

class _AnniversaryFormScreenState extends State<AnniversaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late DateTime _date;
  bool _isSaving = false;

  bool get _isEditing => widget.anniversary != null;

  @override
  void initState() {
    super.initState();
    final anniversary = widget.anniversary;
    final now = DateTime.now();
    if (anniversary != null) {
      _titleController.text = anniversary.title;
      _date = DateTime(now.year, anniversary.month, anniversary.day);
    } else {
      _date = now;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: '月日を選択（年は使いません）',
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    try {
      if (_isEditing) {
        final updated = Anniversary(
          id: widget.anniversary!.id,
          ownerId: widget.anniversary!.ownerId,
          title: _titleController.text.trim(),
          month: _date.month,
          day: _date.day,
        );
        await db.collection('anniversaries').doc(updated.id).update(updated.toUpdateMap());
        await NotificationService.instance.scheduleForAnniversary(updated);
      } else {
        final newAnniversary = Anniversary(
          id: '',
          ownerId: uid,
          title: _titleController.text.trim(),
          month: _date.month,
          day: _date.day,
        );
        final ref = await db.collection('anniversaries').add(newAnniversary.toCreateMap());
        await NotificationService.instance.scheduleForAnniversary(
          Anniversary(
            id: ref.id,
            ownerId: newAnniversary.ownerId,
            title: newAnniversary.title,
            month: newAnniversary.month,
            day: newAnniversary.day,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final anniversary = widget.anniversary;
    if (anniversary == null) return;
    await FirebaseFirestore.instance.collection('anniversaries').doc(anniversary.id).delete();
    await NotificationService.instance.cancelForAnniversary(anniversary.id);
    if (mounted) Navigator.of(context).pop();

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('記念日を削除しました'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('anniversaries')
                .doc(anniversary.id)
                .set(anniversary.toCreateMap());
            await NotificationService.instance.scheduleForAnniversary(anniversary);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '記念日を編集' : '記念日を追加'),
        actions: _isEditing
            ? [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete)]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '名前（例：結婚記念日、誕生日）'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '名前を入力してください' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('日付（毎年）'),
                  subtitle: Text('${_date.month}月${_date.day}日'),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                const Text(
                  '毎年この日の朝9時に通知します',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
