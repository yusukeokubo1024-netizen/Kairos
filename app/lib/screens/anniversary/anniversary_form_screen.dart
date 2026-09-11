import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/anniversary.dart';
import '../../services/analytics_service.dart';
import '../../services/audit_service.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: l10n.anniversaryFormDatePickerHelp,
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
        unawaited(AuditService.instance.logUpdate(
          collection: 'anniversaries',
          targetId: updated.id,
          oldData: widget.anniversary!.toUpdateMap(),
          newData: updated.toUpdateMap(),
        ));
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
        unawaited(AnalyticsService.instance.logAnniversaryCreated());
        unawaited(AuditService.instance.logCreate(collection: 'anniversaries', targetId: ref.id));
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
    final l10n = AppLocalizations.of(context)!;
    await AuditService.instance.softDelete(
      collection: 'anniversaries',
      targetId: anniversary.id,
      data: anniversary.toUpdateMap(),
    );
    await NotificationService.instance.cancelForAnniversary(anniversary.id);
    if (mounted) Navigator.of(context).pop();

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    // Material 3's SnackBar pauses its auto-dismiss timer while hovered
    // (desktop/web), so close it explicitly to guarantee it goes away after
    // 5 seconds regardless of the pointer.
    final snackBarController = rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l10n.anniversaryDeleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.commonUndo,
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
    Future.delayed(const Duration(seconds: 5), () => snackBarController?.close());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.anniversaryFormTitleEdit : l10n.anniversaryFormTitleNew),
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
                  decoration: InputDecoration(labelText: l10n.anniversaryFormNameLabel),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.anniversaryFormNameRequired : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.anniversaryFormDate),
                  subtitle: Text(l10n.anniversaryFormDateValue(_date.month, _date.day)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                Text(
                  l10n.anniversaryFormNotifyHint,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      : Text(l10n.commonSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
