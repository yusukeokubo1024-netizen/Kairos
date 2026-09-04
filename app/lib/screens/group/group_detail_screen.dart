import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../models/shared_group.dart';

class GroupDetailScreen extends StatelessWidget {
  final SharedGroup group;

  const GroupDetailScreen({super.key, required this.group});

  Future<void> _copyInviteCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: group.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待コードをコピーしました')),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを削除しますか？'),
        content: const Text('削除してもすぐ後なら元に戻せます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('sharedGroups').doc(group.id).delete();
    if (context.mounted) Navigator.of(context).pop();

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('グループを削除しました'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('sharedGroups')
                .doc(group.id)
                .set(group.toCreateMap());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                title: const Text('招待コード'),
                subtitle: Text(group.id),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => _copyInviteCode(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('メンバー', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...group.memberIds.map((memberId) => _MemberTile(uid: memberId)),
          ],
        ),
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
        final name = snapshot.data?.data()?['displayName'] as String?;
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(name?.isNotEmpty == true ? name! : '読み込み中...'),
        );
      },
    );
  }
}
