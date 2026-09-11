import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/shared_group.dart';
import '../../services/audit_service.dart';
import 'group_chat_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final SharedGroup group;

  const GroupDetailScreen({super.key, required this.group});

  Future<void> _copyInviteCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: group.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupDetailInviteCodeCopied)),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupDeleteConfirmTitle),
        content: Text(l10n.groupDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuditService.instance.softDelete(
      collection: 'sharedGroups',
      targetId: group.id,
      data: group.toCreateMap(),
    );
    if (context.mounted) Navigator.of(context).pop();

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    // Material 3's SnackBar pauses its auto-dismiss timer while hovered
    // (desktop/web), so close it explicitly to guarantee it goes away after
    // 5 seconds regardless of the pointer.
    final snackBarController = rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l10n.groupDeleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('sharedGroups')
                .doc(group.id)
                .set(group.toCreateMap());
          },
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 5), () => snackBarController?.close());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = group.ownerId == uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: isOwner
            ? [IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context))]
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text(l10n.groupDetailInviteCode),
                subtitle: Text(group.id),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => _copyInviteCode(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.groupDetailMembers, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...group.memberIds.map((memberId) => _MemberTile(uid: memberId)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)),
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(l10n.groupDetailChat),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String uid;

  const _MemberTile({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('publicProfiles').doc(uid).get(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        final name = snapshot.data?.data()?['displayName'] as String?;
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(name?.isNotEmpty == true ? name! : l10n.scheduleFormLoadingName),
        );
      },
    );
  }
}
