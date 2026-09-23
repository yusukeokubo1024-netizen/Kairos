import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/calendar_share_service.dart';

const _shareBaseUrl = 'https://kairos-3d873.web.app/share.html';

class CalendarShareScreen extends StatefulWidget {
  const CalendarShareScreen({super.key});

  @override
  State<CalendarShareScreen> createState() => _CalendarShareScreenState();
}

class _CalendarShareScreenState extends State<CalendarShareScreen> {
  bool _isLoading = true;
  bool _isWorking = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await CalendarShareService.instance.activeToken();
    if (mounted) {
      setState(() {
        _token = token;
        _isLoading = false;
      });
    }
  }

  String get _shareUrl => '$_shareBaseUrl?token=$_token';

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isWorking = true);
    try {
      final token = await CalendarShareService.instance.createShareLink();
      if (mounted) setState(() => _token = token);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.calendarShareCreateFailed)));
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.calendarShareRevokeConfirmTitle),
        content: Text(l10n.calendarShareRevokeConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.calendarShareRevokeButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isWorking = true);
    try {
      await CalendarShareService.instance.revokeShareLink();
      if (mounted) {
        setState(() => _token = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.calendarShareRevoked)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.calendarShareRevokeFailed)));
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _copyLink() async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.calendarShareCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarShareTitle)),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.calendarShareExplanation),
                    const SizedBox(height: 24),
                    if (_token == null)
                      FilledButton(
                        onPressed: _isWorking ? null : _create,
                        child: _isWorking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.calendarShareCreateButton),
                      )
                    else ...[
                      Card(
                        child: ListTile(
                          title: Text(l10n.calendarShareLinkLabel),
                          subtitle: Text(_shareUrl),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: _copyLink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _isWorking ? null : _revoke,
                        child: _isWorking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.calendarShareRevokeButton),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
