import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// How long a soft-deleted item stays recoverable before being purged for
/// good. Purging happens client-side (best-effort, on screen load) rather
/// than via a scheduled Cloud Function, to stay on Firebase's free tier.
const _retentionDays = 30;

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    _purgeExpired();
  }

  Future<void> _purgeExpired() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    final snapshot = await FirebaseFirestore.instance
        .collection('trash')
        .where('ownerId', isEqualTo: uid)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    var hasExpired = false;
    for (final doc in snapshot.docs) {
      final deletedAt = (doc.data()['deletedAt'] as Timestamp?)?.toDate();
      if (deletedAt != null && deletedAt.isBefore(cutoff)) {
        batch.delete(doc.reference);
        hasExpired = true;
      }
    }
    if (hasExpired) await batch.commit();
  }

  String _titleFor(String collection, Map<String, dynamic> data) {
    if (collection == 'sharedGroups') return data['name'] as String? ?? '';
    return data['title'] as String? ?? '';
  }

  String _labelFor(AppLocalizations l10n, String collection) {
    switch (collection) {
      case 'schedules':
        return l10n.trashCollectionSchedule;
      case 'tasks':
        return l10n.trashCollectionTask;
      case 'anniversaries':
        return l10n.trashCollectionAnniversary;
      case 'sharedGroups':
        return l10n.trashCollectionGroup;
      default:
        return collection;
    }
  }

  Future<void> _restore(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final l10n = AppLocalizations.of(context)!;
    final data = doc.data();
    final collection = data['collection'] as String;
    final originalId = data['originalId'] as String;
    final itemData = Map<String, dynamic>.from(data['data'] as Map);

    await FirebaseFirestore.instance.collection(collection).doc(originalId).set(itemData);
    await doc.reference.delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.trashRestored)));
    }
  }

  Future<void> _deleteForever(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = FirebaseFirestore.instance
        .collection('trash')
        .where('ownerId', isEqualTo: uid)
        .orderBy('deletedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trashTitle)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(l10n.trashEmpty));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final collection = data['collection'] as String;
              final itemData = Map<String, dynamic>.from(data['data'] as Map);
              final title = _titleFor(collection, itemData);
              final deletedAt = (data['deletedAt'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(title.isEmpty ? _labelFor(l10n, collection) : title),
                subtitle: Text(
                  deletedAt == null
                      ? _labelFor(l10n, collection)
                      : l10n.trashDeletedOn(_labelFor(l10n, collection), _formatDate(deletedAt)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: l10n.trashRestore,
                      onPressed: () => _restore(context, doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_outlined),
                      tooltip: l10n.trashDeleteForever,
                      onPressed: () => _deleteForever(doc),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
