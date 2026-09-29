import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/anniversary.dart';
import '../../services/notification_service.dart';
import 'anniversary_form_screen.dart';

// A business-day-adjusted anniversary's notification is scheduled as a
// one-shot for just its next occurrence (see NotificationService docs), so
// it needs re-scheduling once that's passed to pick up the following
// month's/year's date. Re-checked once per anniversary per app session the
// first time this screen is opened — cheap and idempotent, so no harm if
// it's a little stale between sessions.
final Set<String> _rescheduledAnniversaryIds = {};

class AnniversaryListScreen extends StatelessWidget {
  const AnniversaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = FirebaseFirestore.instance
        .collection('anniversaries')
        .where('ownerId', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.anniversaryListTitle)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final anniversaries =
              snapshot.data!.docs.map((doc) => Anniversary.fromFirestore(doc)).toList()
                ..sort((a, b) {
                  final cmp = (a.month ?? 13).compareTo(b.month ?? 13);
                  return cmp != 0 ? cmp : a.day.compareTo(b.day);
                });

          for (final anniversary in anniversaries) {
            if (anniversary.businessDayAdjust &&
                _rescheduledAnniversaryIds.add(anniversary.id)) {
              unawaited(NotificationService.instance.scheduleForAnniversary(anniversary));
            }
          }

          if (anniversaries.isEmpty) {
            return Center(child: Text(l10n.anniversaryListEmpty));
          }

          return ListView.builder(
            itemCount: anniversaries.length,
            itemBuilder: (context, index) {
              final anniversary = anniversaries[index];
              final isMonthly = anniversary.recurrence == Anniversary.monthly;
              return ListTile(
                leading: Icon(isMonthly ? Icons.event_repeat_outlined : Icons.cake_outlined),
                title: Text(anniversary.title),
                subtitle: Text(
                  isMonthly
                      ? l10n.anniversaryListMonthly(anniversary.day)
                      // Yearly entries always have a month (only monthly
                      // ones omit it — see the Anniversary model doc).
                      : l10n.anniversaryListYearly(anniversary.month!, anniversary.day),
                ),
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
