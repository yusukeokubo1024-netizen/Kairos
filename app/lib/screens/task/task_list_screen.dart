import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/task.dart';
import '../../services/audit_service.dart';
import '../../services/notification_service.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Future<void> _toggleCompleted(Task task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
      'ownerId': task.ownerId,
      'completed': !task.completed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    unawaited(AuditService.instance.logUpdate(
      collection: 'tasks',
      targetId: task.id,
      oldData: {'completed': task.completed},
      newData: {'completed': !task.completed},
    ));
    if (!task.completed) {
      await NotificationService.instance.cancelForTask(task.id);
    }
  }

  Future<void> _delete(BuildContext context, Task task) async {
    final l10n = AppLocalizations.of(context)!;
    await AuditService.instance.softDelete(
      collection: 'tasks',
      targetId: task.id,
      data: task.toUpdateMap(),
    );
    await NotificationService.instance.cancelForTask(task.id);

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    // Material 3's SnackBar pauses its auto-dismiss timer while hovered
    // (desktop/web), so close it explicitly to guarantee it goes away after
    // 5 seconds regardless of the pointer.
    final snackBarController = rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(l10n.taskDeleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () async {
            await FirebaseFirestore.instance.collection('tasks').doc(task.id).set(task.toCreateMap());
            if (!task.completed) {
              await NotificationService.instance.scheduleForTask(task);
            }
          },
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 5), () => snackBarController?.close());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final tasksQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('ownerId', isEqualTo: uid);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.taskListTitle),
          bottom: TabBar(tabs: [Tab(text: l10n.taskListPending), Tab(text: l10n.taskListDone)]),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: tasksQuery.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final tasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();
            tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));

            final pending = tasks.where((t) => !t.completed).toList();
            final done = tasks.where((t) => t.completed).toList();

            return TabBarView(
              children: [
                _TaskList(
                  tasks: pending,
                  emptyText: l10n.taskListEmptyPending,
                  priorityColor: _priorityColor,
                  onToggle: _toggleCompleted,
                  onDelete: (task) => _delete(context, task),
                ),
                _TaskList(
                  tasks: done,
                  emptyText: l10n.taskListEmptyDone,
                  priorityColor: _priorityColor,
                  onToggle: _toggleCompleted,
                  onDelete: (task) => _delete(context, task),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String emptyText;
  final Color Function(TaskPriority) priorityColor;
  final Future<void> Function(Task) onToggle;
  final Future<void> Function(Task) onDelete;

  const _TaskList({
    required this.tasks,
    required this.emptyText,
    required this.priorityColor,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (tasks.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => onDelete(task),
          child: ListTile(
            leading: Checkbox(
              value: task.completed,
              onChanged: (_) => onToggle(task),
            ),
            title: Text(
              task.title,
              style: task.completed
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: task.scheduleId != null ? Text(l10n.taskListFromSchedule) : null,
            trailing: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: priorityColor(task.priority),
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
            ),
          ),
        );
      },
    );
  }
}
