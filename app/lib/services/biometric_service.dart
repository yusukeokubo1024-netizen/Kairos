import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps local_auth (Face ID / Touch ID / Android biometrics) for an
/// optional app-lock. This is a device-local setting — it is not synced
/// via Firestore since biometric availability is per-device.
class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const _prefsKey = 'biometric_lock_enabled';

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  /// Prompts Face ID / Touch ID / device biometrics. Returns false (instead
  /// of throwing) if the platform has no biometric support at all.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Kairosを開くには認証が必要です',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
