import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A group's name kept live from Firestore, so a rename (see
/// GroupDetailScreen) shows up immediately on screens that were opened with
/// the old SharedGroup. [builder] formats it (e.g. the chat's "〇〇のトーク").
class LiveGroupName extends StatelessWidget {
  final String groupId;
  final String initialName;
  final Widget Function(String name)? builder;

  const LiveGroupName({super.key, required this.groupId, required this.initialName, this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('sharedGroups').doc(groupId).snapshots(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['name'] as String? ?? initialName;
        return builder?.call(name) ?? Text(name);
      },
    );
  }
}
