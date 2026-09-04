import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/task.dart';
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
    if (!task.completed) {
      await NotificationService.instance.cancelForTask(task.id);
    }
  }

  Future<void> _delete(Task task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
    await NotificationService.instance.cancelForTask(task.id);

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('タスクを削除しました'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            await FirebaseFirestore.instance.collection('tasks').doc(task.id).set(task.toCreateMap());
            if (!task.completed) {
              await NotificationService.instance.scheduleForTask(task);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final tasksQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('ownerId', isEqualTo: uid);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('タスク'),
          bottom: const TabBar(tabs: [Tab(text: '未完了'), Tab(text: '完了済み')]),
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
                  emptyText: '未完了のタスクはありません',
                  priorityColor: _priorityColor,
                  onToggle: _toggleCompleted,
                  onDelete: _delete,
                ),
                _TaskList(
                  tasks: done,
                  emptyText: '完了したタスクはありません',
                  priorityColor: _priorityColor,
                  onToggle: _toggleCompleted,
                  onDelete: _delete,
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
            subtitle: task.scheduleId != null ? const Text('予定の準備リストから追加') : null,
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
