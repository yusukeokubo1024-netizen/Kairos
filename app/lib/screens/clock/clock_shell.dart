import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'alarm_screen.dart';
import 'stopwatch_screen.dart';
import 'timer_screen.dart';
import 'world_clock_screen.dart';

/// Hosts the Clock tab's four sub-features (World Clock / Alarm /
/// Stopwatch / Timer), mirroring the iPhone Clock app's layout — just as a
/// top TabBar instead of its own bottom bar, since this already sits one
/// level inside Kairos's own bottom navigation.
class ClockShell extends StatelessWidget {
  const ClockShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabClock),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.clockTabWorld),
              Tab(text: l10n.clockTabAlarm),
              Tab(text: l10n.clockTabStopwatch),
              Tab(text: l10n.clockTabTimer),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WorldClockScreen(),
            AlarmScreen(),
            StopwatchScreen(),
            TimerScreen(),
          ],
        ),
      ),
    );
  }
}
