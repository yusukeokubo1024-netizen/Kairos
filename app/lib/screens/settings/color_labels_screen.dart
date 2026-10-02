import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

// 3 shades (medium/dark/darker) across 17 hues, trimmed to 50 — picked from
// medium-to-dark shades only (not pastels), so a white checkmark/text stays
// legible on top of any of them.
const colorLabelPalette = <Color>[
  Color(0xFFEF4444), // red 500
  Color(0xFFDC2626), // red 600
  Color(0xFFB91C1C), // red 700
  Color(0xFFF97316), // orange 500
  Color(0xFFEA580C), // orange 600
  Color(0xFFC2410C), // orange 700
  Color(0xFFF59E0B), // amber 500
  Color(0xFFD97706), // amber 600
  Color(0xFFB45309), // amber 700
  Color(0xFFCA8A04), // yellow 600
  Color(0xFFA16207), // yellow 700
  Color(0xFF84CC16), // lime 500
  Color(0xFF65A30D), // lime 600
  Color(0xFF4D7C0F), // lime 700
  Color(0xFF22C55E), // green 500
  Color(0xFF16A34A), // green 600
  Color(0xFF15803D), // green 700
  Color(0xFF10B981), // emerald 500
  Color(0xFF059669), // emerald 600
  Color(0xFF047857), // emerald 700
  Color(0xFF14B8A6), // teal 500
  Color(0xFF0D9488), // teal 600
  Color(0xFF0F766E), // teal 700
  Color(0xFF06B6D4), // cyan 500
  Color(0xFF0891B2), // cyan 600
  Color(0xFF0E7490), // cyan 700
  Color(0xFF0EA5E9), // sky 500
  Color(0xFF0284C7), // sky 600
  Color(0xFF0369A1), // sky 700
  Color(0xFF3B82F6), // blue 500
  Color(0xFF2563EB), // blue 600
  Color(0xFF1D4ED8), // blue 700
  Color(0xFF6366F1), // indigo 500
  Color(0xFF4F46E5), // indigo 600
  Color(0xFF4338CA), // indigo 700
  Color(0xFF8B5CF6), // violet 500
  Color(0xFF7C3AED), // violet 600
  Color(0xFF6D28D9), // violet 700
  Color(0xFFA855F7), // purple 500
  Color(0xFF9333EA), // purple 600
  Color(0xFF7E22CE), // purple 700
  Color(0xFFD946EF), // fuchsia 500
  Color(0xFFC026D3), // fuchsia 600
  Color(0xFFA21CAF), // fuchsia 700
  Color(0xFFEC4899), // pink 500
  Color(0xFFDB2777), // pink 600
  Color(0xFFBE185D), // pink 700
  Color(0xFFF43F5E), // rose 500
  Color(0xFFE11D48), // rose 600
  Color(0xFFBE123C), // rose 700
];

/// A user-defined "person → color" mapping (e.g. "自分" → blue, "妻" → pink),
/// stored as a plain list on `users/{uid}.colorLabels` — private to this
/// user only, purely for their own organization, not shared with anyone
/// else (unlike `participantIds`, which are real Kairos accounts).
class ColorLabelsScreen extends StatefulWidget {
  const ColorLabelsScreen({super.key});

  @override
  State<ColorLabelsScreen> createState() => _ColorLabelsScreenState();
}

class _ColorLabelsScreenState extends State<ColorLabelsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<({String name, Color color})> _labels = [];

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
    final raw = doc.data()?['colorLabels'] as List? ?? [];
    if (mounted) {
      setState(() {
        _labels = raw
            .cast<Map<String, dynamic>>()
            .map((e) => (name: e['name'] as String, color: Color(e['color'] as int)))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _persist() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      await _userRef.set({
        'colorLabels': [
          for (final label in _labels) {'name': label.name, 'color': label.color.toARGB32()},
        ],
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.colorLabelsSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addOrEdit({int? editIndex}) async {
    final l10n = AppLocalizations.of(context)!;
    final existing = editIndex != null ? _labels[editIndex] : null;
    final controller = TextEditingController(text: existing?.name ?? '');
    var selectedColor = existing?.color ?? colorLabelPalette.first;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<({String name, Color color})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.colorLabelsAddButton : l10n.commonSave),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.colorLabelsNameLabel),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.colorLabelsNameRequired : null,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colorLabelPalette.map((color) {
                    final selected = color.toARGB32() == selectedColor.toARGB32();
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, (name: controller.text.trim(), color: selectedColor));
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    setState(() {
      if (editIndex != null) {
        _labels[editIndex] = result;
      } else {
        _labels.add(result);
      }
    });
    await _persist();
  }

  Future<void> _delete(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.colorLabelsDeleteConfirmTitle),
        content: Text(l10n.colorLabelsDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _labels.removeAt(index));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.colorLabelsTitle),
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
                  Text(l10n.colorLabelsExplanation),
                  const SizedBox(height: 16),
                  if (_labels.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text(l10n.colorLabelsEmpty)),
                    )
                  else
                    ...List.generate(_labels.length, (index) {
                      final label = _labels[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: label.color),
                          title: Text(label.name),
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
