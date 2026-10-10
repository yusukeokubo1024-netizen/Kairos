import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../services/chat_media_service.dart';
import '../../services/locale_service.dart';

/// Bubble bodies for the non-text group chat messages: photos, locations,
/// voice messages and date polls (日程調整).

String _localeTag() => LocaleService.instance.locale.value.toLanguageTag();

/// "12/20(土) 19:00", or just the date for a whole-day option.
String formatPollOption(PollOption option) {
  final date = DateFormat.MMMEd(_localeTag()).format(option.start);
  return option.hasTime ? '$date ${DateFormat.Hm(_localeTag()).format(option.start)}' : date;
}

class ChatImageContent extends StatelessWidget {
  final ChatMessage message;

  const ChatImageContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl;
    if (url == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _FullScreenImage(url: url)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 280),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const SizedBox(
                    width: 160,
                    height: 160,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
            errorBuilder: (context, _, _) => SizedBox(
              width: 160,
              height: 60,
              child: Center(child: Text(AppLocalizations.of(context)!.chatImageFailed)),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;

  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: InteractiveViewer(maxScale: 5, child: Image.network(url)),
      ),
    );
  }
}

class ChatLocationContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const ChatLocationContent({super.key, required this.message, required this.isMine});

  Future<void> _open() async {
    final lat = message.latitude, lng = message.longitude;
    if (lat == null || lng == null) return;
    // Apple Maps on iOS (always installed); Google Maps' universal URL
    // elsewhere, which opens the app if present or the browser otherwise.
    final uri = Platform.isIOS
        ? Uri.https('maps.apple.com', '/', {'ll': '$lat,$lng', 'q': '📍'})
        : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$lat,$lng'});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final fg = isMine ? scheme.onPrimary : null;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: isMine ? fg : scheme.error, size: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.chatLocationTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, color: fg)),
                Text(l10n.chatLocationOpen,
                    style: TextStyle(fontSize: 12, color: fg, decoration: TextDecoration.underline)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatVoiceContent extends StatefulWidget {
  final ChatMessage message;
  final bool isMine;

  const ChatVoiceContent({super.key, required this.message, required this.isMine});

  @override
  State<ChatVoiceContent> createState() => _ChatVoiceContentState();
}

class _ChatVoiceContentState extends State<ChatVoiceContent> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;
  bool _playing = false;

  @override
  void dispose() {
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.message.mediaUrl;
    if (url == null) return;
    // Created lazily so a long chat doesn't hold one player per message.
    var player = _player;
    if (player == null) {
      player = _player = AudioPlayer();
      _stateSub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player!.pause();
          player.seek(Duration.zero);
        }
        if (mounted) {
          setState(() => _playing =
              state.playing && state.processingState != ProcessingState.completed);
        }
      });
      await player.setUrl(url);
    }
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  String _format(Duration? d) {
    if (d == null) return '';
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = widget.isMine ? scheme.onPrimary : scheme.onSurface;
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isMine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_playing ? Icons.pause : Icons.play_arrow, color: fg),
            const SizedBox(width: 6),
            Icon(Icons.graphic_eq, color: fg, size: 18),
            const SizedBox(width: 6),
            Text(_format(widget.message.duration), style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }
}

class ChatPollContent extends StatelessWidget {
  final ChatMessage message;
  final String groupId;
  final String currentUid;
  final Future<String> Function(String uid) resolveName;

  const ChatPollContent({
    super.key,
    required this.message,
    required this.groupId,
    required this.currentUid,
    required this.resolveName,
  });

  static const _marks = {PollAnswer.yes: '○', PollAnswer.maybe: '△', PollAnswer.no: '×'};

  Future<void> _vote(BuildContext context, int index, PollAnswer answer) async {
    final current = message.votes[currentUid]?['$index'];
    try {
      // Tapping your current answer again clears it.
      await ChatMediaService.instance
          .vote(groupId, message, index, current == answer ? null : answer);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatSendFailed)),
        );
      }
    }
  }

  Future<void> _decide(BuildContext context, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final label = formatPollOption(message.pollOptions[index]);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.pollDecideConfirm(label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.pollDecideButton)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ChatMediaService.instance.decide(groupId, message, index);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.chatSendFailed)));
      }
    }
  }

  Future<void> _showVoters(BuildContext context, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final entries = <({String uid, PollAnswer answer})>[
      for (final e in message.votes.entries)
        if (e.value['$index'] != null) (uid: e.key, answer: e.value['$index']!),
    ]..sort((a, b) => a.answer.index.compareTo(b.answer.index));
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(l10n.pollVotersTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(formatPollOption(message.pollOptions[index])),
            ),
            if (entries.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(l10n.pollNoVotes)),
            for (final e in entries)
              ListTile(
                leading: Text(_marks[e.answer]!, style: const TextStyle(fontSize: 20)),
                title: FutureBuilder<String>(
                  future: resolveName(e.uid),
                  builder: (context, snapshot) => Text(snapshot.data ?? '...'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final decided = message.decidedOption;
    final isCreator = message.senderId == currentUid;
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, size: 18, color: scheme.primary),
              const SizedBox(width: 4),
              Text(l10n.pollCardLabel, style: TextStyle(fontSize: 12, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(message.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (decided != null && decided < message.pollOptions.length)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.pollDecided(formatPollOption(message.pollOptions[decided])),
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          const Divider(),
          for (var i = 0; i < message.pollOptions.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatPollOption(message.pollOptions[i]),
                    style: TextStyle(
                      fontWeight: decided == i ? FontWeight.bold : null,
                      color: decided == i ? scheme.primary : null,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showVoters(context, i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      '○${message.countFor(i, PollAnswer.yes)} '
                      '△${message.countFor(i, PollAnswer.maybe)} '
                      '×${message.countFor(i, PollAnswer.no)}',
                      style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
            if (decided == null)
              Row(
                children: [
                  for (final answer in PollAnswer.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 4),
                      child: ChoiceChip(
                        label: Text(_marks[answer]!),
                        visualDensity: VisualDensity.compact,
                        selected: message.votes[currentUid]?['$i'] == answer,
                        onSelected: (_) => _vote(context, i, answer),
                      ),
                    ),
                  const Spacer(),
                  if (isCreator)
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _decide(context, i),
                      child: Text(l10n.pollDecide, style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
