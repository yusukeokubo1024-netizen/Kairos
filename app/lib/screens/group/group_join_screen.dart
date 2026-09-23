import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Lets a user request to join a group by entering its invite code (the
/// group's Firestore document ID). See docs/group-invite-flow.md for the
/// design.
///
/// The pre-join preview reads from `groupInvitePreviews` (name + member
/// count only) rather than the group's own document — `sharedGroups` is
/// members-only to read, precisely so someone who only has the invite code
/// can't see the real member list before deciding to join.
///
/// Entering a valid code does not join the group immediately — it creates a
/// join request (`sharedGroups/{id}/joinRequests/{myUid}`) that the group
/// owner reviews and approves from `GroupDetailScreen`.
class GroupJoinScreen extends StatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isJoining = false;
  bool _alreadyMember = false;
  bool _alreadyRequested = false;
  bool _requestSent = false;
  String? _errorMessage;
  ({String id, String name, int memberCount})? _preview;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _preview = null;
      _alreadyMember = false;
      _alreadyRequested = false;
      _requestSent = false;
    });

    try {
      final doc =
          await FirebaseFirestore.instance.collection('groupInvitePreviews').doc(code).get();
      if (!doc.exists) {
        setState(() => _errorMessage = l10n.groupJoinNotFound);
        return;
      }
      final data = doc.data()!;

      // `get` on sharedGroups only succeeds for existing members, so a
      // successful read here (with our uid already present) means we're
      // already in the group — a permission-denied means we aren't, which
      // is the expected/normal case for someone requesting to join.
      var alreadyMember = false;
      try {
        final existing =
            await FirebaseFirestore.instance.collection('sharedGroups').doc(code).get();
        alreadyMember = (existing.data()?['memberIds'] as List?)?.contains(uid) ?? false;
      } catch (_) {
        alreadyMember = false;
      }

      var alreadyRequested = false;
      if (!alreadyMember) {
        final existingRequest = await FirebaseFirestore.instance
            .collection('sharedGroups')
            .doc(code)
            .collection('joinRequests')
            .doc(uid)
            .get();
        alreadyRequested = existingRequest.exists;
      }

      setState(() {
        _preview = (
          id: doc.id,
          name: data['name'] as String? ?? '',
          memberCount: data['memberCount'] as int? ?? 0,
        );
        _alreadyMember = alreadyMember;
        _alreadyRequested = alreadyRequested;
      });
    } catch (_) {
      setState(() => _errorMessage = l10n.groupJoinNotFound);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _join() async {
    final preview = _preview;
    if (preview == null) return;
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('sharedGroups')
          .doc(preview.id)
          .collection('joinRequests')
          .doc(uid)
          .set({
        'requesterId': uid,
        'groupId': preview.id,
        'requestedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _requestSent = true);
    } catch (_) {
      setState(() => _errorMessage = l10n.groupJoinFailed);
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = _preview;

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
                    subtitle: Text(l10n.groupJoinMembers(preview.memberCount)),
                  ),
                ),
                const SizedBox(height: 16),
                if (_alreadyMember)
                  Text(l10n.groupJoinAlreadyMember)
                else if (_requestSent)
                  Text(l10n.groupJoinRequestSent)
                else if (_alreadyRequested)
                  Text(l10n.groupJoinAlreadyRequested)
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
