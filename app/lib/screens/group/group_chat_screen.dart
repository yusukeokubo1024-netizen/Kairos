import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/shared_group.dart';
import '../../services/chat_media_service.dart';
import '../../services/locale_service.dart';
import 'chat_message_content.dart';
import 'group_detail_screen.dart';
import 'live_group_name.dart';
import 'poll_create_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final SharedGroup group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  static const _stamps = [
    '👍', '👎', '❤️', '😂', '😢', '😮', '🎉', '🙏',
    '👏', '😴', '🔥', '💦', '❓', '❗', '😆', '😭',
    '😡', '🥳', '🤔', '😱', '👌', '💪', '🙌', '✨',
    '😊', '😉', '😘', '🥰', '🤗', '😅', '🙄', '😇',
    '🙆', '🙇', '🤝', '👋', '✋', '🫶', '💯', '💤',
    '☕', '🍰', '🎂', '🍺', '🎁', '📅', '🚗', '✈️',
    '🏠', '⭐', '🌙', '☀️', '☔', '❄️', '🌸', '📸',
  ];

  static const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, String> _nameCache = {};
  bool _isSending = false;
  bool _hasText = false;
  // Voice input (speech-to-text into the text field).
  final _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  String _textBeforeDictation = '';
  // Voice messages.
  final _recorder = AudioRecorder();
  DateTime? _recordingSince;
  Timer? _recordingTicker;
  static const _maxRecording = Duration(minutes: 3);
  // Messages this session has already marked as read, so a snapshot rebuild
  // doesn't re-send the same write.
  final Set<String> _markedRead = {};
  bool _readReceiptsEnabled = true;
  // Created once: a new .snapshots() stream on every build made the list
  // re-subscribe whenever anything on screen changed.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream = FirebaseFirestore.instance
      .collection('sharedGroups')
      .doc(widget.group.id)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _loadReadReceiptsSetting();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _markChatSeen();
  }

  /// Records when this chat was last open, independent of read receipts, so
  /// the unread badge on the group list clears (and keeps working even if the
  /// user has turned read receipts off). Called on open and again on close
  /// to cover messages that arrived while the chat was on screen.
  void _markChatSeen() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'chatLastSeen.${widget.group.id}': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  Future<void> _loadReadReceiptsSetting() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _readReceiptsEnabled = doc.data()?['read_receipts_enabled'] as bool? ?? true;
    } catch (_) {
      _readReceiptsEnabled = true;
    }
  }

  /// Adds the signed-in user's uid to `readBy` on every message from someone
  /// else they haven't yet marked — unless they've turned read receipts off
  /// in Settings. Firestore rules only allow appending one's own uid.
  Future<void> _markRead(List<ChatMessage> messages) async {
    if (!_readReceiptsEnabled) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final unread = messages
        .where((m) =>
            m.senderId != uid && !m.readBy.contains(uid) && !_markedRead.contains(m.id))
        .toList();
    if (unread.isEmpty) return;
    _markedRead.addAll(unread.map((m) => m.id));
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final message in unread) {
        batch.update(
          FirebaseFirestore.instance
              .collection('sharedGroups')
              .doc(widget.group.id)
              .collection('messages')
              .doc(message.id),
          {'readBy': FieldValue.arrayUnion([uid])},
        );
      }
      await batch.commit();
    } catch (_) {
      _markedRead.removeAll(unread.map((m) => m.id));
    }
  }

  @override
  void dispose() {
    _markChatSeen();
    _textController.dispose();
    _speech.cancel();
    _recordingTicker?.cancel();
    _recorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _resolveName(String uid) async {
    final cached = _nameCache[uid];
    if (cached != null) return cached;
    final doc = await FirebaseFirestore.instance.collection('publicProfiles').doc(uid).get();
    final name = doc.data()?['displayName'] as String? ?? '?';
    _nameCache[uid] = name;
    return name;
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _sendMessage(text, isStamp: false);
  }

  Future<void> _sendStamp(String emoji) async {
    Navigator.of(context).pop(); // close the stamp picker sheet
    await _sendMessage(emoji, isStamp: true);
  }

  Future<void> _sendMessage(String text, {required bool isStamp}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _isSending = true);
    try {
      final message = ChatMessage(
        id: '',
        senderId: uid,
        text: text,
        type: isStamp ? ChatMessageType.stamp : ChatMessageType.text,
      );
      await FirebaseFirestore.instance
          .collection('sharedGroups')
          .doc(widget.group.id)
          .collection('messages')
          .add(message.toCreateMap());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a media send with the "sending" state and a generic error message.
  Future<void> _runSend(Future<void> Function() send) async {
    setState(() => _isSending = true);
    try {
      await send();
    } catch (_) {
      if (mounted) _showError(AppLocalizations.of(context)!.chatSendFailed);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _openAttachMenu() {
    final l10n = AppLocalizations.of(context)!;
    final groupId = widget.group.id;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        void pick(Future<void> Function() action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.chatAttachCamera),
                onTap: () => pick(() => _runSend(
                    () => ChatMediaService.instance.sendPhotos(groupId, fromCamera: true))),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chatAttachPhoto),
                onTap: () => pick(() => _runSend(
                    () => ChatMediaService.instance.sendPhotos(groupId, fromCamera: false))),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(l10n.chatAttachLocation),
                onTap: () => pick(() => _runSend(() async {
                  final failure = await ChatMediaService.instance.sendCurrentLocation(groupId);
                  if (failure == LocationFailure.serviceOff) _showError(l10n.chatLocationServiceOff);
                  if (failure == LocationFailure.denied) _showError(l10n.chatLocationDenied);
                })),
              ),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: Text(l10n.chatAttachPoll),
                onTap: () => pick(() => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PollCreateScreen(groupId: groupId)),
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _speechLocaleId => switch (LocaleService.instance.locale.value.languageCode) {
        'en' => 'en_US',
        'ko' => 'ko_KR',
        'zh' => 'zh_CN',
        _ => 'ja_JP',
      };

  /// Speech-to-text into the text field; tap again to stop.
  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    }
    if (!_speechReady) {
      if (mounted) _showError(AppLocalizations.of(context)!.chatDictationUnavailable);
      return;
    }
    final before = _textController.text;
    _textBeforeDictation = before.isEmpty || before.endsWith(' ') ? before : '$before ';
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(partialResults: true, localeId: _speechLocaleId),
      onResult: (result) {
        final text = _textBeforeDictation + result.recognizedWords;
        _textController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    if (_listening) await _toggleDictation();
    if (!await _recorder.hasPermission()) {
      if (mounted) _showError(AppLocalizations.of(context)!.chatMicDenied);
      return;
    }
    final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, numChannels: 1),
      path: path,
    );
    setState(() => _recordingSince = DateTime.now());
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (DateTime.now().difference(_recordingSince!) >= _maxRecording) {
        _finishRecording(send: true);
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _finishRecording({required bool send}) async {
    final since = _recordingSince;
    if (since == null) return;
    _recordingTicker?.cancel();
    _recordingTicker = null;
    final duration = DateTime.now().difference(since);
    setState(() => _recordingSince = null);
    final path = await _recorder.stop();
    if (path == null) return;
    final file = File(path);
    // Under a second is almost always an accidental tap.
    if (!send || duration < const Duration(seconds: 1)) {
      if (await file.exists()) await file.delete();
      return;
    }
    await _runSend(() async {
      await ChatMediaService.instance.sendVoice(widget.group.id, file, duration);
      if (await file.exists()) await file.delete();
    });
  }

  Widget _buildRecordingBar(AppLocalizations l10n) {
    final elapsed = DateTime.now().difference(_recordingSince!);
    final label =
        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return Row(
      children: [
        const Icon(Icons.fiber_manual_record, color: Colors.red),
        const SizedBox(width: 8),
        Text('${l10n.chatVoiceRecording} $label'),
        const Spacer(),
        TextButton(
          onPressed: () => _finishRecording(send: false),
          child: Text(l10n.chatVoiceCancel),
        ),
        FilledButton.icon(
          onPressed: () => _finishRecording(send: true),
          icon: const Icon(Icons.send),
          label: Text(l10n.chatVoiceSend),
        ),
      ],
    );
  }

  Future<void> _reportMessage(ChatMessage message) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupChatReportConfirmTitle),
        content: Text(l10n.groupChatReportConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.groupChatReport)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('messageReports').add({
        'reporterId': FirebaseAuth.instance.currentUser!.uid,
        'groupId': widget.group.id,
        'messageId': message.id,
        'messageSenderId': message.senderId,
        'messageText': message.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupChatReported)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupChatReportFailed)));
      }
    }
  }

  Future<void> _toggleReaction(ChatMessage message, String emoji) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final alreadyReacted = message.reactions[emoji]?.contains(uid) ?? false;
    final ref = FirebaseFirestore.instance
        .collection('sharedGroups')
        .doc(widget.group.id)
        .collection('messages')
        .doc(message.id);
    await ref.update({
      'reactions.$emoji':
          alreadyReacted ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
    });
  }

  void _openReactionPicker(ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isMine = message.senderId == uid;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                children: [
                  for (final emoji in _quickReactions)
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _toggleReaction(message, emoji);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                ],
              ),
              if (!isMine) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(l10n.groupChatReport),
                  onTap: () {
                    Navigator.of(context).pop();
                    _reportMessage(message);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openStampPicker() {
    showModalBottomSheet<void>(
      context: context,
      // Stamps grew from 24 to ~50 entries, so the sheet needs its own scroll
      // area instead of shrink-wrapping to content height (which could
      // overflow the screen on smaller phones).
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final stamp in _stamps)
                  InkWell(
                    onTap: () => _sendStamp(stamp),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(child: Text(stamp, style: const TextStyle(fontSize: 32))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: LiveGroupName(
          groupId: widget.group.id,
          initialName: widget.group.name,
          builder: (name) => Text(l10n.groupChatTitle(name)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: l10n.groupChatInfo,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GroupDetailScreen(group: widget.group)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages =
                      snapshot.data!.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
                  if (messages.isEmpty) {
                    return Center(child: Text(l10n.groupChatEmpty));
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) => _markRead(messages));
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderId == uid;
                      return _MessageBubble(
                        message: message,
                        isMine: isMine,
                        currentUid: uid,
                        resolveName: _resolveName,
                        cachedName: (uid) => _nameCache[uid],
                        groupId: widget.group.id,
                        onLongPress: () => _openReactionPicker(message),
                        onReactionTap: (emoji) => _toggleReaction(message, emoji),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            if (_isSending) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _recordingSince != null
                  ? _buildRecordingBar(l10n)
                  : Row(
                      children: [
                        IconButton(
                          onPressed: _isSending ? null : _openAttachMenu,
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: l10n.chatAttachTooltip,
                        ),
                        IconButton(
                          onPressed: _openStampPicker,
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          tooltip: l10n.groupChatStampTooltip,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: _listening
                                  ? l10n.chatDictationListening
                                  : l10n.groupChatInputHint,
                              suffixIcon: IconButton(
                                icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                                    color: _listening ? Colors.red : null),
                                tooltip: l10n.chatDictationTooltip,
                                onPressed: _toggleDictation,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Send when there's text; otherwise record a voice message.
                        _hasText
                            ? IconButton.filled(
                                onPressed: _isSending ? null : _send,
                                icon: const Icon(Icons.send),
                              )
                            : IconButton.filledTonal(
                                onPressed: _isSending ? null : _startRecording,
                                icon: const Icon(Icons.keyboard_voice),
                                tooltip: l10n.chatVoiceTooltip,
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String currentUid;
  final Future<String> Function(String uid) resolveName;
  // Already-known names, shown straight away — otherwise every rebuild
  // (e.g. read receipts being written when the chat opens) flashed each
  // sender's name to "..." for a frame while the FutureBuilder restarted.
  final String? Function(String uid) cachedName;
  final String groupId;
  final VoidCallback onLongPress;
  final ValueChanged<String> onReactionTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUid,
    required this.resolveName,
    required this.cachedName,
    required this.groupId,
    required this.onLongPress,
    required this.onReactionTap,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            FutureBuilder<String>(
              future: resolveName(message.senderId),
              initialData: cachedName(message.senderId),
              builder: (context, snapshot) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  snapshot.data ?? '...',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isMine) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.readBy.isNotEmpty)
                      Text(
                        AppLocalizations.of(context)!.groupChatReadCount(message.readBy.length),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    Text(
                      _formatTime(message.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onLongPress: onLongPress,
                child: switch (message.type) {
                  ChatMessageType.stamp =>
                    Text(message.text, style: const TextStyle(fontSize: 48)),
                  ChatMessageType.image => ChatImageContent(message: message),
                  ChatMessageType.location =>
                    ChatLocationContent(message: message, isMine: isMine),
                  ChatMessageType.voice => ChatVoiceContent(message: message, isMine: isMine),
                  ChatMessageType.poll => ChatPollContent(
                      message: message,
                      groupId: groupId,
                      currentUid: currentUid,
                      resolveName: resolveName,
                    ),
                  ChatMessageType.text => ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isMine ? Theme.of(context).colorScheme.onPrimary : null,
                            ),
                          ),
                        ),
                      ),
                },
              ),
              if (!isMine) ...[
                const SizedBox(width: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 4,
                children: [
                  for (final entry in message.reactions.entries)
                    if (entry.value.isNotEmpty)
                      _ReactionChip(
                        emoji: entry.key,
                        count: entry.value.length,
                        isMine: entry.value.contains(currentUid),
                        onTap: () => onReactionTap(entry.key),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isMine;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine ? Theme.of(context).colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Text('$emoji $count', style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
