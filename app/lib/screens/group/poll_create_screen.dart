import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../services/chat_media_service.dart';
import 'chat_message_content.dart' show formatPollOption;

/// Creates a date poll (日程調整) in a group chat: a title plus candidate
/// dates (optionally with a time), which members then answer ○/△/×.
class PollCreateScreen extends StatefulWidget {
  final String groupId;

  const PollCreateScreen({super.key, required this.groupId});

  @override
  State<PollCreateScreen> createState() => _PollCreateScreenState();
}

class _PollCreateScreenState extends State<PollCreateScreen> {
  final _titleController = TextEditingController();
  final List<PollOption> _options = [];
  bool _includeTime = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addOption() async {
    final now = DateTime.now();
    final last = _options.isNotEmpty ? _options.last.start : now;
    final date = await showDatePicker(
      context: context,
      initialDate: last.isBefore(now) ? now : last,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    var start = DateTime(date.year, date.month, date.day);
    if (_includeTime) {
      final time = await showTimePicker(
        context: context,
        initialTime: _options.isNotEmpty && _options.last.hasTime
            ? TimeOfDay.fromDateTime(_options.last.start)
            : const TimeOfDay(hour: 19, minute: 0),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (time == null || !mounted) return;
      start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
    setState(() {
      _options
        ..add(PollOption(start: start, hasTime: _includeTime))
        ..sort((a, b) => a.start.compareTo(b.start));
      _error = null;
    });
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.pollNeedTitle);
      return;
    }
    if (_options.isEmpty) {
      setState(() => _error = l10n.pollNeedOptions);
      return;
    }
    setState(() => _sending = true);
    try {
      await ChatMediaService.instance.sendPoll(widget.groupId, title, _options);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = l10n.chatSendFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pollCreateTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.pollTitleLabel,
                hintText: l10n.pollTitleHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.pollOptionsLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pollIncludeTime),
              value: _includeTime,
              onChanged: (value) => setState(() => _includeTime = value),
            ),
            for (final option in _options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(formatPollOption(option)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _options.remove(option)),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: Text(l10n.pollAddOption),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _create,
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.pollCreateButton),
            ),
          ],
        ),
      ),
    );
  }
}
