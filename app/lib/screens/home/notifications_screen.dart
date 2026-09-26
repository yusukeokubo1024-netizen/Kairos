import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// "Who did what, when" activity feed, grouped by schedule — reads
/// `schedules/*/activity` (see schedule_activity_service.dart) across every
/// schedule the signed-in user is a participant on, via a collectionGroup
/// query. Firestore rules scope each activity entry's visibility to that
/// schedule's own participantIds, so this can never show more than the user
/// could already see by opening the schedule itself.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _actionLabel(AppLocalizations l10n, String action) {
    switch (action) {
      case 'create':
        return l10n.scheduleActivityCreated;
      case 'update_time':
        return l10n.scheduleActivityUpdatedTime;
      case 'update_title':
        return l10n.scheduleActivityUpdatedTitle;
      default:
        return l10n.scheduleActivityUpdatedOther;
    }
  }

  String _formatRange(BuildContext context, DateTime start, DateTime end) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale).format(start);
    final startTime = DateFormat.Hm(locale).format(start);
    final endTime = DateFormat.Hm(locale).format(end);
    return '$date $startTime - $endTime';
  }

  String _formatWhen(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).toString();
    return '${DateFormat.MMMd(locale).format(dateTime)} ${DateFormat.Hm(locale).format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final activityQuery = FirebaseFirestore.instance
        .collectionGroup('activity')
        .where('participantIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(60);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabNotifications)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: activityQuery.snapshots(),
        builder: (context, snapshot) {
          // Without this check, any stream error (e.g. a still-building
          // Firestore composite index right after this feature ships) left
          // the spinner running forever instead of showing anything.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(l10n.notificationsEmpty));
          }

          // Group entries by their parent schedule, keeping the order each
          // schedule first appears in (== its most recent activity, since
          // the query is already newest-first).
          final scheduleOrder = <String>[];
          final bySchedule = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
          for (final doc in docs) {
            final scheduleId = doc.reference.parent.parent!.id;
            (bySchedule[scheduleId] ??= []).add(doc);
            if (bySchedule[scheduleId]!.length == 1) scheduleOrder.add(scheduleId);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: scheduleOrder.length,
            itemBuilder: (context, index) {
              final entries = bySchedule[scheduleOrder[index]]!;
              final latest = entries.first.data();
              final title = latest['scheduleTitle'] as String? ?? '';
              final start = (latest['scheduleStart'] as Timestamp?)?.toDate();
              final end = (latest['scheduleEnd'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (start != null && end != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 10),
                          child: Text(
                            _formatRange(context, start, end),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...entries.map((doc) {
                        final data = doc.data();
                        final actorId = data['actorId'] as String? ?? '';
                        final action = data['action'] as String? ?? 'update_other';
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ActorAvatar(uid: actorId),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_actionLabel(l10n, action))),
                              if (createdAt != null)
                                Text(
                                  _formatWhen(context, createdAt),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActorAvatar extends StatelessWidget {
  final String uid;

  const _ActorAvatar({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('publicProfiles').doc(uid).get(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['displayName'] as String?;
        final initial = (name != null && name.isNotEmpty) ? name.substring(0, 1) : '?';
        return CircleAvatar(
          radius: 12,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        );
      },
    );
  }
}
