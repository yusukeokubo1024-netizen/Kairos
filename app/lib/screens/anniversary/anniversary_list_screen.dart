import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/anniversary.dart';
import 'anniversary_form_screen.dart';

class AnniversaryListScreen extends StatelessWidget {
  const AnniversaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = FirebaseFirestore.instance
        .collection('anniversaries')
        .where('ownerId', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(title: const Text('大切な記念日')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final anniversaries =
              snapshot.data!.docs.map((doc) => Anniversary.fromFirestore(doc)).toList()
                ..sort((a, b) {
                  final cmp = a.month.compareTo(b.month);
                  return cmp != 0 ? cmp : a.day.compareTo(b.day);
                });

          if (anniversaries.isEmpty) {
            return const Center(child: Text('まだ記念日が登録されていません'));
          }

          return ListView.builder(
            itemCount: anniversaries.length,
            itemBuilder: (context, index) {
              final anniversary = anniversaries[index];
              return ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: Text(anniversary.title),
                subtitle: Text('毎年 ${anniversary.month}月${anniversary.day}日'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnniversaryFormScreen(anniversary: anniversary),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnniversaryFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
