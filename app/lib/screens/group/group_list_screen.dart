import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/shared_group.dart';
import 'group_chat_screen.dart';
import 'group_form_screen.dart';
import 'group_join_screen.dart';

// Groups created before the `groupInvitePreviews` collection existed (added
// 2026-09-12 to stop non-members reading the full member list via invite
// code) never got a preview doc, so their invite code looks like it "doesn't
// exist" to joiners even though the group itself is fine. Self-heals the gap
// the first time the owner opens their group list, instead of requiring a
// one-off admin migration. Checked once per group per app session.
final Set<String> _previewCheckedGroupIds = {};

Future<void> _ensureInvitePreviewExists(SharedGroup group) async {
  if (_previewCheckedGroupIds.contains(group.id)) return;
  _previewCheckedGroupIds.add(group.id);
  try {
    final ref = FirebaseFirestore.instance.collection('groupInvitePreviews').doc(group.id);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'name': group.name,
        'memberCount': group.memberIds.length,
        'ownerId': group.ownerId,
      });
    }
  } catch (_) {
    // Best-effort — worst case the invite code stays broken until the next
    // time this runs, not worth surfacing an error for.
    _previewCheckedGroupIds.remove(group.id);
  }
}

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final groupsQuery =
        FirebaseFirestore.instance.collection('sharedGroups').where('memberIds', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: l10n.groupJoinTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GroupJoinScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          final chatLastSeen =
              userSnapshot.data?.data()?['chatLastSeen'] as Map<String, dynamic>? ?? {};
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: groupsQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups =
              snapshot.data!.docs.map((doc) => SharedGroup.fromFirestore(doc)).toList();
          for (final group in groups) {
            if (group.ownerId == uid) unawaited(_ensureInvitePreviewExists(group));
          }
          if (groups.isEmpty) {
            return Center(child: Text(l10n.groupListEmpty));
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(group.name),
                subtitle: Text(l10n.groupListMembers(group.memberIds.length)),
                trailing: _UnreadBadge(
                  groupId: group.id,
                  uid: uid,
                  lastSeen: (chatLastSeen[group.id] as Timestamp?)?.toDate(),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)),
                ),
              );
            },
          );
        },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GroupFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Count of chat messages from other members newer than the last time this
/// user opened the group's chat — the free stand-in for a push notification
/// (real push would need Cloud Functions / the paid Blaze plan). Looks only
/// at the latest 30 messages, so it caps at "30+".
class _UnreadBadge extends StatelessWidget {
  final String groupId;
  final String uid;
  final DateTime? lastSeen;

  const _UnreadBadge({required this.groupId, required this.uid, required this.lastSeen});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sharedGroups')
          .doc(groupId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final unread = docs.where((doc) {
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          return data['senderId'] != uid &&
              createdAt != null &&
              (lastSeen == null || createdAt.isAfter(lastSeen!));
        }).length;
        if (unread == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            unread >= 30 ? '30+' : '$unread',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }
}
