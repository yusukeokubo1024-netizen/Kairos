import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/shared_group.dart';
import '../group/group_detail_screen.dart';

/// Unified "new activity" feed across every group the user is in — the free
/// stand-in for push notifications (see sharedGroups.lastActivityAt in
/// firestore.rules). Replaces having to check each group individually for a
/// "new" badge.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Kept as plain absolute date/time (not a relative "3h ago" style string)
  // so it doesn't need per-language pluralization rules to be correct.
  String _formatWhen(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabNotifications)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          final groupLastSeen =
              userSnapshot.data?.data()?['groupLastSeen'] as Map<String, dynamic>? ?? {};

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('sharedGroups')
                .where('memberIds', arrayContains: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final groups = snapshot.data!.docs
                  .map((doc) => SharedGroup.fromFirestore(doc))
                  .where((g) => g.lastActivityAt != null)
                  .toList()
                ..sort((a, b) => b.lastActivityAt!.compareTo(a.lastActivityAt!));

              if (groups.isEmpty) {
                return Center(child: Text(l10n.notificationsEmpty));
              }

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final lastSeen = (groupLastSeen[group.id] as Timestamp?)?.toDate();
                  final isUnseen =
                      lastSeen == null || group.lastActivityAt!.isAfter(lastSeen);
                  return ListTile(
                    leading: Icon(
                      Icons.groups_outlined,
                      color: isUnseen ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      group.name,
                      style: isUnseen ? const TextStyle(fontWeight: FontWeight.bold) : null,
                    ),
                    subtitle: Text(group.lastActivityText ?? ''),
                    trailing: Text(
                      _formatWhen(group.lastActivityAt!),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
