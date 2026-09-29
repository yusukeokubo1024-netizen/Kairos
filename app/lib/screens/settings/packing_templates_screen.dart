import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A user-defined "packing list" template (e.g. "プール" → 水着・タオル・帽子),
/// stored as a plain list on `users/{uid}.packingTemplates` — private to
/// this user, used to quickly fill in a schedule's packing checklist (see
/// ScheduleFormScreen). Not the same as the built-in keyword-based
/// suggestions in schedule_prep_templates.dart (which create Tasks, not a
/// per-schedule checklist, and aren't user-editable).
class PackingTemplatesScreen extends StatefulWidget {
  const PackingTemplatesScreen({super.key});

  @override
  State<PackingTemplatesScreen> createState() => _PackingTemplatesScreenState();
}

class _PackingTemplatesScreenState extends State<PackingTemplatesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<({String name, List<String> items})> _templates = [];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await _userRef.get();
    final raw = doc.data()?['packingTemplates'] as List? ?? [];
    if (mounted) {
      setState(() {
        _templates = raw.cast<Map<String, dynamic>>().map((e) {
          return (
            name: e['name'] as String,
            items: List<String>.from(e['items'] as List? ?? []),
          );
        }).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _persist() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      await _userRef.set({
        'packingTemplates': [
          for (final template in _templates) {'name': template.name, 'items': template.items},
        ],
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.packingTemplatesSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addOrEdit({int? editIndex}) async {
    final l10n = AppLocalizations.of(context)!;
    final existing = editIndex != null ? _templates[editIndex] : null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final itemsController = TextEditingController(text: existing?.items.join('\n') ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<({String name, List<String> items})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? l10n.packingTemplatesAddButton : l10n.commonSave),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.packingTemplatesNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.packingTemplatesNameRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: itemsController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: l10n.packingTemplatesItemsLabel,
                    helperText: l10n.packingTemplatesItemsHelper,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.packingTemplatesItemsRequired
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final items = itemsController.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Navigator.pop(context, (name: nameController.text.trim(), items: items));
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (result == null) return;

    setState(() {
      if (editIndex != null) {
        _templates[editIndex] = result;
      } else {
        _templates.add(result);
      }
    });
    await _persist();
  }

  Future<void> _delete(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.packingTemplatesDeleteConfirmTitle),
        content: Text(l10n.packingTemplatesDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _templates.removeAt(index));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.packingTemplatesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isSaving ? null : () => _addOrEdit(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.packingTemplatesExplanation),
                  const SizedBox(height: 16),
                  if (_templates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text(l10n.packingTemplatesEmpty)),
                    )
                  else
                    ...List.generate(_templates.length, (index) {
                      final template = _templates[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.checklist_outlined),
                          title: Text(template.name),
                          subtitle: Text(template.items.join('、')),
                          onTap: () => _addOrEdit(editIndex: index),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(index),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
