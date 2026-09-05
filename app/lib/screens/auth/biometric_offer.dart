import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/biometric_service.dart';

/// Offers to turn on Face ID / fingerprint lock right after signing in or
/// signing up, so returning to the app afterward needs only biometrics —
/// no email/password retyping. No-ops if the device doesn't support
/// biometrics or the lock is already on.
Future<void> offerBiometricLock(BuildContext context) async {
  final alreadyEnabled = await BiometricService.instance.isLockEnabled();
  if (alreadyEnabled) return;

  final supported = await BiometricService.instance.isDeviceSupported();
  if (!supported || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.signUpBiometricOfferTitle),
      content: Text(l10n.signUpBiometricOfferBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.signUpBiometricOfferSkip),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.signUpBiometricOfferEnable),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final success = await BiometricService.instance.authenticate(l10n.biometricAuthReason);
  if (success) {
    await BiometricService.instance.setLockEnabled(true);
  }
}
