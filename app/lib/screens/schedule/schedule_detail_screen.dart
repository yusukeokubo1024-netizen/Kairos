import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/schedule.dart';
import '../../services/notification_service.dart';
import 'schedule_form_screen.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailScreen({super.key, required this.schedule});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定を削除しますか？'),
        content: const Text('削除してもすぐ後なら元に戻せます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('schedules').doc(schedule.id).delete();
    await NotificationService.instance.cancelForSchedule(schedule.id);
    if (context.mounted) Navigator.of(context).pop();

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('予定を削除しました'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('schedules')
                .doc(schedule.id)
                .set(schedule.toCreateMap());
            await NotificationService.instance.scheduleForSchedule(schedule);
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = schedule.ownerId == uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('予定の詳細'),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ScheduleFormScreen(schedule: schedule)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: schedule.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(schedule.title, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    schedule.isAllDay
                        ? '${_formatDate(schedule.startTime)} 〜 ${_formatDate(schedule.endTime)} (終日)'
                        : '${_formatDateTime(schedule.startTime)} 〜 ${_formatDateTime(schedule.endTime)}',
                  ),
                ],
              ),
              if (schedule.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(schedule.location)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text('参加者 ${schedule.participantIds.length}人'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.notifications_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    schedule.reminderMinutes == null
                        ? '通知しない'
                        : '${schedule.reminderMinutes}分前に通知',
                  ),
                ],
              ),
              if (schedule.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(schedule.notes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
