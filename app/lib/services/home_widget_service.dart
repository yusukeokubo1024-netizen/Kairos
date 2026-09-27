import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Pushes "today's schedules" (already formatted by the caller, one per
/// line) to the Android home-screen widget (TodayScheduleWidgetProvider).
///
/// Android only for now — an iOS widget needs a WidgetKit extension added
/// in Xcode, which isn't buildable without a Mac.
///
/// Data only refreshes while the app is open and its calendar screen is
/// subscribed to Firestore — there's no background refresh/WorkManager job
/// in this v1, so the widget can show a stale day's plan until the app is
/// opened again.
class HomeWidgetService {
  static const _androidProviderName = 'TodayScheduleWidgetProvider';

  static String? _lastPushed;

  static Future<void> updateTodaySchedules(List<String> lines) async {
    if (!Platform.isAndroid) return;

    final payload = lines.join('\n');
    if (payload == _lastPushed) return;
    _lastPushed = payload;

    try {
      await HomeWidget.saveWidgetData<String>('today_schedules', payload);
      await HomeWidget.updateWidget(androidName: _androidProviderName);
    } catch (_) {
      // Best-effort — a stale/missing widget provider shouldn't break the app.
    }
  }
}
