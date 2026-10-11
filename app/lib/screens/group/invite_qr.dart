import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';

/// QR codes for group invites: the same invite code as GroupJoinScreen
/// accepts (short code or long group id), prefixed so a scan of some
/// unrelated QR code isn't mistaken for one.
const _invitePrefix = 'kairos-invite:';

String inviteQrData(String inviteCode) => '$_invitePrefix$inviteCode';

/// The invite code in a scanned QR code, or null if it isn't a Kairos invite.
String? parseInviteQr(String raw) {
  final value = raw.trim();
  if (!value.startsWith(_invitePrefix)) return null;
  final code = value.substring(_invitePrefix.length).trim();
  return code.isEmpty ? null : code;
}

/// Shows a group's invite QR code for someone nearby to scan.
Future<void> showInviteQrDialog(BuildContext context, {required String inviteCode}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.groupInviteQrTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White background so it scans even in dark mode.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: inviteQrData(inviteCode),
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(inviteCode,
              style: const TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.groupInviteQrHint, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(MaterialLocalizations.of(context).closeButtonLabel)),
      ],
    ),
  );
}

/// Camera scanner for invite QR codes; pops with the invite code.
class InviteQrScanScreen extends StatefulWidget {
  const InviteQrScanScreen({super.key});

  @override
  State<InviteQrScanScreen> createState() => _InviteQrScanScreenState();
}

class _InviteQrScanScreenState extends State<InviteQrScanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;
  bool _showedWrongCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final code = parseInviteQr(raw);
      if (code != null) {
        _done = true;
        Navigator.of(context).pop(code);
        return;
      }
      if (!_showedWrongCode) {
        _showedWrongCode = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.groupInviteQrNotKairos)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupInviteQrScan)),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.groupInviteQrScanHint,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
