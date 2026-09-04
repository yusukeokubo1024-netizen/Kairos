import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

TaskPriority priorityFromString(String value) {
  return TaskPriority.values.firstWhere(
    (p) => p.name == value,
    orElse: () => TaskPriority.medium,
  );
}

class Task {
  final String id;
  final String ownerId;
  final String title;
  final TaskPriority priority;
  final bool completed;
  final DateTime? dueDate;
  // Set when this task was auto-generated as prep for a schedule (e.g. from
  // schedule_prep_templates.dart), so it can be shown alongside that schedule.
  final String? scheduleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.priority,
    required this.completed,
    this.dueDate,
    this.scheduleId,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Task(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      priority: priorityFromString(data['priority'] as String? ?? 'medium'),
      completed: data['completed'] as bool? ?? false,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      scheduleId: data['scheduleId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'priority': priority.name,
      'completed': completed,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'scheduleId': scheduleId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'priority': priority.name,
      'completed': completed,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
