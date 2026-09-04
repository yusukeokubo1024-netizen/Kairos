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

  static const defaultColor = Color(0xFF2563EB);
  static const defaultReminderMinutes = 30;

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
  });

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
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
