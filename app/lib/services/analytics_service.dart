import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around Firebase Analytics for the small set of events worth
/// tracking. Screen views are tracked automatically via
/// [AnalyticsService.observer] on the app's NavigatorObserver — this is
/// only for named custom events.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'password');

  Future<void> logSignUp() => _analytics.logSignUp(signUpMethod: 'password');

  Future<void> logScheduleCreated() => _analytics.logEvent(name: 'schedule_created');

  Future<void> logTaskCreated() => _analytics.logEvent(name: 'task_created');

  Future<void> logGroupCreated() => _analytics.logEvent(name: 'group_created');

  Future<void> logAnniversaryCreated() => _analytics.logEvent(name: 'anniversary_created');
}
