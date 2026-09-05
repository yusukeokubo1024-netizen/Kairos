import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/shared_group.dart';
import 'group_detail_screen.dart';
import 'group_form_screen.dart';
import 'group_join_screen.dart';

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: groupsQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups =
              snapshot.data!.docs.map((doc) => SharedGroup.fromFirestore(doc)).toList();
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                ),
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
