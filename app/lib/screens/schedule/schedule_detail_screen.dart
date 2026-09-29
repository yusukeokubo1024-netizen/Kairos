import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/schedule.dart';
import '../../services/audit_service.dart';
import '../../services/notification_service.dart';
import 'schedule_form_screen.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailScreen({super.key, required this.schedule});

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scheduleDeleteConfirmTitle),
        content: Text(l10n.scheduleDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;

    // [schedule] may be one virtual occurrence of a recurring series (see
    // CalendarScreen._expandRecurrences) with its startTime/endTime shifted
    // to that occurrence's date, not the series' real anchor date. Deleting
    // by id is safe either way (same document), but snapshotting/recreating
    // from the shifted copy would silently re-anchor the whole series (or
    // the trash/undo record) to whichever date the user happened to tap —
    // discarding the series' real start. Re-read the canonical document so
    // the trash record and undo always use its true stored dates.
    final canonicalDoc =
        await FirebaseFirestore.instance.collection('schedules').doc(schedule.id).get();
    final canonical = canonicalDoc.exists ? Schedule.fromFirestore(canonicalDoc) : schedule;

    await AuditService.instance.softDelete(
      collection: 'schedules',
      targetId: canonical.id,
      data: canonical.toUpdateMap(),
    );
    await NotificationService.instance.cancelForSchedule(canonical.id);
    if (context.mounted) Navigator.of(context).pop();

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    // Material 3's SnackBar pauses its auto-dismiss timer while hovered
    // (desktop/web), so close it explicitly to guarantee it goes away after
    // 5 seconds regardless of the pointer.
    final snackBarController = rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l10n.scheduleDeleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('schedules')
                .doc(canonical.id)
                .set(canonical.toCreateMap());
            await NotificationService.instance.scheduleForSchedule(canonical);
          },
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 5), () => snackBarController?.close());
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  String _recurrenceLabel(AppLocalizations l10n, String recurrence, DateTime? endDate) {
    final pattern = switch (recurrence) {
      'daily' => l10n.scheduleFormRecurrenceDaily,
      'weekly' => l10n.scheduleFormRecurrenceWeekly,
      'monthly' => l10n.scheduleFormRecurrenceMonthly,
      'yearly' => l10n.scheduleFormRecurrenceYearly,
      _ => '',
    };
    if (endDate == null) return pattern;
    return '$pattern (${l10n.scheduleFormRecurrenceEndDate} ${_formatDate(endDate)})';
  }

  Future<void> _openInMaps(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': schedule.location,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scheduleCouldNotOpenMap)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = schedule.ownerId == uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleDetailTitle),
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
                        ? '${_formatDate(schedule.startTime)} 〜 ${_formatDate(schedule.endTime)} ${l10n.scheduleAllDaySuffix}'
                        : '${_formatDateTime(schedule.startTime)} 〜 ${_formatDateTime(schedule.endTime)}',
                  ),
                ],
              ),
              if (schedule.isRecurring) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.repeat, size: 20),
                    const SizedBox(width: 8),
                    Text(_recurrenceLabel(l10n, schedule.recurrence, schedule.recurrenceEndDate)),
                  ],
                ),
              ],
              if (schedule.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _openInMaps(context),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schedule.location,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.scheduleParticipants(schedule.participantIds.length)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.notifications_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    schedule.reminderMinutes == null
                        ? l10n.scheduleReminderNone
                        : l10n.scheduleReminderBefore(schedule.reminderMinutes!),
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
