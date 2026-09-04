import 'package:flutter/material.dart';

import '../group/group_list_screen.dart';
import '../settings/settings_screen.dart';
import '../task/task_list_screen.dart';
import 'calendar_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Recreating CalendarScreen with a fresh key whenever the Home tab is
  // (re-)selected resets its view back to the month calendar, instead of
  // staying on whatever format/list view it was left on.
  Key _calendarKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final screens = [
      CalendarScreen(key: _calendarKey),
      const TaskListScreen(),
      const GroupListScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            if (value == 0 && _index != 0) {
              _calendarKey = UniqueKey();
            }
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'タスク'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'グループ'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}
