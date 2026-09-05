import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/shared_group.dart';

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
  ];

  static const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, String> _nameCache = {};
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
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
      final message = ChatMessage(id: '', senderId: uid, text: text, isStamp: isStamp);
      await FirebaseFirestore.instance
          .collection('sharedGroups')
          .doc(widget.group.id)
          .collection('messages')
          .add(message.toCreateMap());
    } finally {
      if (mounted) setState(() => _isSending = false);
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
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
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
        ),
      ),
    );
  }

  void _openStampPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final messagesQuery = FirebaseFirestore.instance
        .collection('sharedGroups')
        .doc(widget.group.id)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupChatTitle(widget.group.name))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: messagesQuery.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages =
                      snapshot.data!.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
                  if (messages.isEmpty) {
                    return Center(child: Text(l10n.groupChatEmpty));
                  }
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
                        onLongPress: () => _openReactionPicker(message),
                        onReactionTap: (emoji) => _toggleReaction(message, emoji),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _openStampPicker,
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    tooltip: l10n.groupChatStampTooltip,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(hintText: l10n.groupChatInputHint),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: const Icon(Icons.send),
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
  final VoidCallback onLongPress;
  final ValueChanged<String> onReactionTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUid,
    required this.resolveName,
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
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onLongPress: onLongPress,
                child: message.isStamp
                    ? Text(message.text, style: const TextStyle(fontSize: 48))
                    : ConstrainedBox(
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
