import 'dart:async';
import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'services/analytics_service.dart';
import 'services/biometric_service.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';

/// App-wide messenger key so screens can show a SnackBar (e.g. an "undo"
/// action after a delete) even after they've already been popped off the
/// navigation stack.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check: attaches an attestation token (Play Integrity on Android,
  // App Attest/DeviceCheck on iOS) to every Firebase request, so tampered
  // apps/bots/scripts show up as "unverified" in the App Check dashboard.
  // Deliberately NOT flipping Firestore/Auth to "Enforce" in the Firebase
  // Console yet — start in monitoring-only mode and only enforce once
  // verified request metrics look healthy, to avoid risking an outage for
  // legitimate users from a misconfiguration.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  // Crash/error reporting. Skipped in local debug builds so development
  // noise doesn't pollute the Crashlytics dashboard.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await initializeDateFormatting('ja_JP');
  await initializeDateFormatting('en_US');
  await NotificationService.instance.init();
  await LocaleService.instance.load();
  runApp(const KairosApp());
}

class KairosApp extends StatelessWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Kairos',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          navigatorObservers: [AnalyticsService.instance.observer],
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF2563EB),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const BiometricGate(child: HomeShell());
        }
        return const LoginScreen();
      },
    );
  }
}

/// Requires Face ID / Touch ID / device biometrics before showing [child],
/// but only when the user has turned this on in Settings and the device
/// actually supports it. Re-locks every time this widget is (re)created,
/// i.e. on cold start and on sign-in.
class BiometricGate extends StatefulWidget {
  final Widget child;

  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  bool _checking = true;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final enabled = await BiometricService.instance.isLockEnabled();
    final supported = enabled && await BiometricService.instance.isDeviceSupported();
    if (!mounted) return;
    if (!supported) {
      setState(() {
        _checking = false;
        _unlocked = true;
      });
      return;
    }
    setState(() => _checking = false);
    await _authenticate();
  }

  Future<void> _authenticate() async {
    final l10n = AppLocalizations.of(context)!;
    final success = await BiometricService.instance.authenticate(l10n.biometricAuthReason);
    if (mounted) setState(() => _unlocked = success);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_unlocked) {
      return widget.child;
    }
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text(l10n.appLocked),
            const SizedBox(height: 16),
            FilledButton(onPressed: _authenticate, child: Text(l10n.authenticate)),
          ],
        ),
      ),
    );
  }
}
