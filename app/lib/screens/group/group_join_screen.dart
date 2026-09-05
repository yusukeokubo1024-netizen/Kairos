import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/shared_group.dart';

/// Lets a user join a group by entering its invite code (the group's
/// Firestore document ID). See docs/group-invite-flow.md for the design.
class GroupJoinScreen extends StatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isJoining = false;
  String? _errorMessage;
  SharedGroup? _preview;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('sharedGroups').doc(code).get();
      if (!doc.exists) {
        setState(() => _errorMessage = l10n.groupJoinNotFound);
        return;
      }
      setState(() => _preview = SharedGroup.fromFirestore(doc));
    } catch (_) {
      setState(() => _errorMessage = l10n.groupJoinNotFound);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _join() async {
    final group = _preview;
    if (group == null) return;
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('sharedGroups').doc(group.id).update({
        'memberIds': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _errorMessage = l10n.groupJoinFailed);
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final preview = _preview;
    final alreadyMember = preview != null && preview.memberIds.contains(uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupJoinTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.groupJoinInstructions),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(labelText: l10n.groupJoinCodeLabel),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _isLoading ? null : _lookupCode,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.groupJoinConfirmButton),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              if (preview != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(preview.name),
                    subtitle: Text(l10n.groupJoinMembers(preview.memberIds.length)),
                  ),
                ),
                const SizedBox(height: 16),
                if (alreadyMember)
                  Text(l10n.groupJoinAlreadyMember)
                else
                  FilledButton(
                    onPressed: _isJoining ? null : _join,
                    child: _isJoining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.groupJoinButton),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
