// App Store screenshot capture. Logs into a dedicated test account
// (kairos.screenshot@kairos-3d873.firebaseapp.com) seeded with sample
// schedules/tasks/anniversaries, then walks through the main tabs taking a
// screenshot of each. Run via:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart -d <device-id>
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:app/firebase_options.dart';
import 'package:app/main.dart';
import 'package:app/services/locale_service.dart';
import 'package:app/services/notification_service.dart';

const _testEmail = 'kairos.screenshot@kairos-3d873.firebaseapp.com';
const _testPassword = String.fromEnvironment('SCREENSHOT_ACCOUNT_PASSWORD');

// Bounded so a stuck animation fails loudly within 30s instead of silently
// eating the whole build's time budget.
const _settleTimeout = Duration(seconds: 30);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture App Store screenshots', (tester) async {
    debugPrint('[screenshot_test] initializing Firebase');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signOut();
    await initializeDateFormatting('ja_JP');
    await initializeDateFormatting('en_US');
    debugPrint('[screenshot_test] initializing NotificationService');
    await NotificationService.instance.init();
    await LocaleService.instance.load();

    debugPrint('[screenshot_test] pumping KairosApp');
    await tester.pumpWidget(const KairosApp());
    await tester.pumpAndSettle(
        const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, _settleTimeout);
    debugPrint('[screenshot_test] reached login screen, entering credentials');

    await tester.enterText(find.byKey(const Key('login_email_field')), _testEmail);
    await tester.enterText(find.byKey(const Key('login_password_field')), _testPassword);
    await tester.tap(find.byKey(const Key('login_submit_button')));
    debugPrint('[screenshot_test] tapped login, waiting for sign-in');
    await tester.pumpAndSettle(
        const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, _settleTimeout);
    debugPrint('[screenshot_test] signed in, on calendar tab');

    await binding.takeScreenshot('01_calendar');
    debugPrint('[screenshot_test] captured 01_calendar');

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle(
        const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, _settleTimeout);
    await binding.takeScreenshot('02_tasks');
    debugPrint('[screenshot_test] captured 02_tasks');

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle(
        const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, _settleTimeout);
    await binding.takeScreenshot('03_groups');
    debugPrint('[screenshot_test] captured 03_groups');

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle(
        const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, _settleTimeout);
    await binding.takeScreenshot('04_settings');
    debugPrint('[screenshot_test] captured 04_settings, done');
  });
}
