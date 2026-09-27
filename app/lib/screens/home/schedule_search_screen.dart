import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/schedule.dart';
import '../schedule/schedule_detail_screen.dart';

/// Finds a schedule by title/location/notes. Searches the raw documents
/// (not the calendar's expanded per-occurrence copies), so a recurring
/// schedule shows up once — as itself — rather than once per occurrence.
class ScheduleSearchScreen extends StatefulWidget {
  const ScheduleSearchScreen({super.key});

  @override
  State<ScheduleSearchScreen> createState() => _ScheduleSearchScreenState();
}

class _ScheduleSearchScreenState extends State<ScheduleSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final schedulesQuery = FirebaseFirestore.instance
        .collection('schedules')
        .where('participantIds', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.scheduleSearchHint,
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleMedium,
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
      ),
      body: _query.isEmpty
          ? Center(child: Text(l10n.scheduleSearchPrompt))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: schedulesQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _query.toLowerCase();
                final results = snapshot.data!.docs
                    .map((doc) => Schedule.fromFirestore(doc))
                    .where((s) =>
                        s.title.toLowerCase().contains(query) ||
                        s.location.toLowerCase().contains(query) ||
                        s.notes.toLowerCase().contains(query))
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

                if (results.isEmpty) {
                  return Center(child: Text(l10n.scheduleSearchNoResults));
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final schedule = results[index];
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(color: schedule.color, shape: BoxShape.circle),
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(schedule.title, overflow: TextOverflow.ellipsis)),
                          if (schedule.isRecurring) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.repeat, size: 14, color: Colors.grey.shade600),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        schedule.location.isEmpty
                            ? _formatDate(schedule.startTime)
                            : '${_formatDate(schedule.startTime)}  ${schedule.location}',
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ScheduleDetailScreen(schedule: schedule)),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
