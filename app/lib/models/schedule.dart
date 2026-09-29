import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String ownerId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String location;
  final String notes;
  // The group this schedule is categorized under, for calendar filtering
  // (Google Calendar-style show/hide by calendar). Null means "個人の予定".
  final String? groupId;
  final List<String> participantIds;
  final Color color;
  // Minutes before startTime (or before 9:00 on the day, for all-day
  // schedules) to send a local reminder notification. Null means no reminder.
  final int? reminderMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // 'none' | 'daily' | 'weekly' | 'monthly' | 'yearly'. Occurrences are not
  // stored as separate documents — the calendar expands this one document
  // into virtual copies for display (see CalendarScreen._expandRecurrences).
  // Editing/deleting always acts on this one document, so it affects the
  // whole series; there is no per-occurrence override in this v1.
  final String recurrence;
  // Optional last day a recurring schedule still occurs on (inclusive).
  // Null means it repeats indefinitely (display is still capped to a couple
  // of years out — see CalendarScreen._recurrenceDisplayCap).
  final DateTime? recurrenceEndDate;
  // Android only (see NotificationService.scheduleForSchedule): makes the
  // reminder notification full-screen/alarm-like instead of a normal quiet
  // notification. No effect on iOS in this v1 — Apple's equivalent (a
  // "critical alert") needs a special entitlement this app doesn't have.
  final bool alarmStyle;

  static const defaultColor = Color(0xFF2563EB);
  static const defaultReminderMinutes = 30;
  static const noRecurrence = 'none';

  bool get isRecurring => recurrence != noRecurrence;

  Schedule({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location = '',
    this.notes = '',
    this.groupId,
    required this.participantIds,
    this.color = defaultColor,
    this.reminderMinutes = defaultReminderMinutes,
    this.createdAt,
    this.updatedAt,
    this.recurrence = noRecurrence,
    this.recurrenceEndDate,
    this.alarmStyle = false,
  });

  /// A copy representing one virtual occurrence of a recurring series —
  /// same id/fields, but [startTime]/[endTime] shifted to that occurrence's
  /// date (keeping the original duration). Saving from this copy (e.g. after
  /// editing it) still writes to the same document, so it edits the series;
  /// this is safe because every occurrence shares the same weekday/day-of-
  /// month/time-of-day, so re-anchoring to any one of them doesn't change
  /// the pattern.
  Schedule copyAsOccurrence(DateTime occurrenceStart) {
    final duration = endTime.difference(startTime);
    return Schedule(
      id: id,
      ownerId: ownerId,
      title: title,
      startTime: occurrenceStart,
      endTime: occurrenceStart.add(duration),
      isAllDay: isAllDay,
      location: location,
      notes: notes,
      groupId: groupId,
      participantIds: participantIds,
      color: color,
      reminderMinutes: reminderMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      recurrence: recurrence,
      recurrenceEndDate: recurrenceEndDate,
      alarmStyle: alarmStyle,
    );
  }

  factory Schedule.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final colorValue = data['color'] as int?;
    return Schedule(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      isAllDay: data['isAllDay'] as bool? ?? false,
      location: data['location'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      groupId: data['groupId'] as String?,
      participantIds: List<String>.from(data['participantIds'] as List? ?? []),
      color: colorValue != null ? Color(colorValue) : defaultColor,
      reminderMinutes: data['reminderMinutes'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      recurrence: data['recurrence'] as String? ?? noRecurrence,
      recurrenceEndDate: (data['recurrenceEndDate'] as Timestamp?)?.toDate(),
      alarmStyle: data['alarmStyle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isAllDay': isAllDay,
      'location': location,
      'notes': notes,
      'groupId': groupId,
      'participantIds': participantIds,
      'color': color.toARGB32(),
      'reminderMinutes': reminderMinutes,
      'recurrence': recurrence,
      'recurrenceEndDate':
          recurrenceEndDate != null ? Timestamp.fromDate(recurrenceEndDate!) : null,
      'alarmStyle': alarmStyle,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isAllDay': isAllDay,
      'location': location,
      'notes': notes,
      'groupId': groupId,
      'participantIds': participantIds,
      'color': color.toARGB32(),
      'reminderMinutes': reminderMinutes,
      'recurrence': recurrence,
      'recurrenceEndDate':
          recurrenceEndDate != null ? Timestamp.fromDate(recurrenceEndDate!) : null,
      'alarmStyle': alarmStyle,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
