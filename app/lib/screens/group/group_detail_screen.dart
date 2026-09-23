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
    await FirebaseFirestore.instance.collection('groupInvitePreviews').doc(group.id).delete();
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

  Future<void> _decrementPreviewCount() async {
    try {
      await FirebaseFirestore.instance
          .collection('groupInvitePreviews')
          .doc(group.id)
          .update({'memberCount': FieldValue.increment(-1)});
    } catch (_) {
      // Best-effort — the preview count is only used for display before
      // joining, so a missed decrement here isn't worth failing the
      // leave/removal for.
    }
  }

  Future<void> _leaveGroup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupLeaveConfirmTitle),
        content: Text(l10n.groupLeaveConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.groupLeaveTooltip)),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('sharedGroups').doc(group.id).update({
        'memberIds': FieldValue.arrayRemove([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _decrementPreviewCount();
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupLeft)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupLeaveFailed)));
      }
    }
  }

  Future<void> _approveRequest(BuildContext context, String requesterId) async {
    final l10n = AppLocalizations.of(context)!;
    final db = FirebaseFirestore.instance;
    try {
      final batch = db.batch();
      batch.update(db.collection('sharedGroups').doc(group.id), {
        'memberIds': FieldValue.arrayUnion([requesterId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.delete(
        db.collection('sharedGroups').doc(group.id).collection('joinRequests').doc(requesterId),
      );
      batch.update(db.collection('groupInvitePreviews').doc(group.id), {
        'memberCount': FieldValue.increment(1),
      });
      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupJoinRequestApproved)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.groupJoinRequestApproveFailed)));
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requesterId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection('sharedGroups')
          .doc(group.id)
          .collection('joinRequests')
          .doc(requesterId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupJoinRequestRejected)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.groupJoinRequestRejectFailed)));
      }
    }
  }

  Future<void> _removeMember(BuildContext context, String memberId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupRemoveMemberConfirmTitle),
        content: Text(l10n.groupRemoveMemberConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.groupRemoveMemberTooltip)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('sharedGroups').doc(group.id).update({
        'memberIds': FieldValue.arrayRemove([memberId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _decrementPreviewCount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupMemberRemoved)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupRemoveMemberFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = group.ownerId == uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (isOwner)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context))
          else
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: l10n.groupLeaveTooltip,
              onPressed: () => _leaveGroup(context),
            ),
        ],
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
            if (isOwner) ...[
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('sharedGroups')
                    .doc(group.id)
                    .collection('joinRequests')
                    .snapshots(),
                builder: (context, snapshot) {
                  final requests = snapshot.data?.docs ?? [];
                  if (requests.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.groupDetailJoinRequests,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...requests.map((doc) => _JoinRequestTile(
                            uid: doc.data()['requesterId'] as String? ?? doc.id,
                            onApprove: () => _approveRequest(context, doc.id),
                            onReject: () => _rejectRequest(context, doc.id),
                          )),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.groupDetailMembers, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...group.memberIds.map((memberId) => _MemberTile(
                  uid: memberId,
                  onRemove: (isOwner && memberId != uid) ? () => _removeMember(context, memberId) : null,
                )),
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

class _JoinRequestTile extends StatelessWidget {
  final String uid;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JoinRequestTile({required this.uid, required this.onApprove, required this.onReject});

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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: l10n.groupJoinRequestApprove,
                onPressed: onApprove,
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: l10n.groupJoinRequestReject,
                onPressed: onReject,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String uid;
  final VoidCallback? onRemove;

  const _MemberTile({required this.uid, this.onRemove});

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
          trailing: onRemove == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.person_remove_outlined),
                  tooltip: l10n.groupRemoveMemberTooltip,
                  onPressed: onRemove,
                ),
        );
      },
    );
  }
}
