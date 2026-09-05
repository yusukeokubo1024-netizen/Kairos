import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calendar_month), label: l10n.tabHome),
          NavigationDestination(
              icon: const Icon(Icons.check_circle_outline), label: l10n.tabTasks),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), label: l10n.tabGroups),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined), label: l10n.tabSettings),
        ],
      ),
    );
  }
}
