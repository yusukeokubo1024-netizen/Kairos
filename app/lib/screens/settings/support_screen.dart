import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/locale_service.dart';

const _supportEmail = 'kairos19900927@gmail.com';

// Google AI Studio (https://aistudio.google.com/apikey) free-tier key,
// injected at build time with --dart-define=GEMINI_API_KEY=... so it never
// enters source control. Same trade-off as the web support page either way:
// this ships inside the compiled app bundle, so it's restricted to
// low-stakes free-tier usage rather than anything billed or sensitive.
const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const _geminiModel = 'gemini-flash-latest';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // FAQ content lives in Firestore (config/support_<locale>) so wording can
  // be edited without an app update/store review. Falls back to the
  // bundled translations below if that document is missing or unreachable
  // (e.g. offline, or not seeded yet), so the FAQ is never empty.
  List<(String, String)>? _remoteFaqs;

  @override
  void initState() {
    super.initState();
    _loadRemoteFaqs();
  }

  Future<void> _loadRemoteFaqs() async {
    try {
      final locale = LocaleService.instance.locale.value.languageCode;
      final doc =
          await FirebaseFirestore.instance.collection('config').doc('support_$locale').get();
      final items = doc.data()?['faq'];
      if (items is! List) return;
      final parsed = items
          .whereType<Map<String, dynamic>>()
          .map((e) => (e['q'] as String? ?? '', e['a'] as String? ?? ''))
          .where((pair) => pair.$1.isNotEmpty && pair.$2.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty && mounted) {
        setState(() => _remoteFaqs = parsed);
      }
    } catch (_) {
      // Keep using the bundled fallback FAQ below.
    }
  }

  Future<void> _emailSupport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(scheme: 'mailto', path: _supportEmail);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsCouldNotOpenPage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = _remoteFaqs ??
        [
          (l10n.supportFaqPasswordQ, l10n.supportFaqPasswordA),
          (l10n.supportFaqBiometricQ, l10n.supportFaqBiometricA),
          (l10n.supportFaqGroupQ, l10n.supportFaqGroupA),
          (l10n.supportFaqWeatherQ, l10n.supportFaqWeatherA),
          (l10n.supportFaqNotificationQ, l10n.supportFaqNotificationA),
          (l10n.supportFaqLanguageQ, l10n.supportFaqLanguageA),
          (l10n.supportFaqDeleteQ, l10n.supportFaqDeleteA),
        ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.supportFaqTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (question, answer) in faqs)
                  ExpansionTile(
                    title: Text(question),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(answer)],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.supportAiTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(l10n.supportAiDescription, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          _AiChat(faqs: faqs),
          const SizedBox(height: 28),
          Text(l10n.supportContactTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(l10n.supportContactBody),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _emailSupport(context),
            child: Text(
              _supportEmail,
              style: const TextStyle(color: Color(0xFF2563EB), decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChat extends StatefulWidget {
  final List<(String, String)> faqs;

  const _AiChat({required this.faqs});

  @override
  State<_AiChat> createState() => _AiChatState();
}

class _ChatEntry {
  final bool isUser;
  final String text;
  final DateTime time;

  _ChatEntry({required this.isUser, required this.text, required this.time});
}

class _AiChatState extends State<_AiChat> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatEntry> _messages = [];
  final List<Map<String, dynamic>> _history = [];
  bool _isSending = false;
  String? _status;
  bool _greeted = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _languageName(AppLocalizations l10n) {
    switch (LocaleService.instance.locale.value.languageCode) {
      case 'en':
        return 'English';
      case 'ko':
        return '한국어 (Korean)';
      case 'zh':
        return '中文 (Chinese)';
      default:
        return '日本語 (Japanese)';
    }
  }

  String _systemInstruction(AppLocalizations l10n) {
    final faqText = widget.faqs.map((f) => 'Q: ${f.$1}\nA: ${f.$2}').join('\n');
    return '''You are a helpful assistant embedded in the calendar-sharing app "Kairos". For
questions about Kairos itself, answer concisely using the information below, in
${_languageName(l10n)}. If you don't know the answer to a Kairos-specific question, honestly
say you can't help and suggest contacting $_supportEmail. You may also answer general
questions unrelated to Kairos to the best of your ability.

Kairos features: shared calendars/schedules, group schedule sharing (join via invite code),
task management with auto-added prep tasks from schedules, anniversary/birthday tracking with
yearly notifications, group chat with stamps/reactions, weather forecast (set via Settings >
Your location, choosing country then prefecture/state/province then city), Face ID/fingerprint
app lock, 4 languages (switch via Settings > Language), email/password login (Google sign-in
was removed; linking is still available from Settings).

FAQ:
$faqText''';
  }

  /// Google's free-tier flash model occasionally returns 503 (temporary
  /// overload) rather than an actual problem with the request — retrying
  /// once after a short pause clears most of these automatically.
  Future<Map<String, dynamic>> _callGemini(AppLocalizations l10n) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': _systemInstruction(l10n)}
            ],
          },
          'contents': _history,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final isRetryable =
          (response.statusCode == 503 || response.statusCode == 429) && attempt < maxAttempts;
      if (!isRetryable) throw Exception('status ${response.statusCode}');
      setState(() => _status = l10n.supportAiRetrying(attempt, maxAttempts));
      await Future.delayed(Duration(milliseconds: 1200 * attempt));
    }
    throw Exception('unreachable');
  }

  /// Pulls the reply text out of a generateContent response, tolerating any
  /// missing field along the way instead of throwing.
  String? _extractAnswer(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = candidates.first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;
    final text = parts.first['text'];
    return text is String ? text : null;
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final question = _textController.text.trim();
    if (question.isEmpty) return;

    if (_geminiApiKey.isEmpty) {
      setState(() => _status = l10n.supportAiNotConfigured);
      return;
    }

    setState(() {
      _messages.add(_ChatEntry(isUser: true, text: question, time: DateTime.now()));
      _history.add({
        'role': 'user',
        'parts': [
          {'text': question}
        ],
      });
      _textController.clear();
      _isSending = true;
      _status = l10n.supportAiThinking;
    });
    _scrollToBottom();

    try {
      final data = await _callGemini(l10n);
      final resolvedAnswer = _extractAnswer(data) ?? l10n.supportAiError;
      _history.add({
        'role': 'model',
        'parts': [
          {'text': resolvedAnswer}
        ],
      });
      if (mounted) {
        setState(() {
          _messages.add(_ChatEntry(isUser: false, text: resolvedAnswer, time: DateTime.now()));
          _status = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatEntry(isUser: false, text: l10n.supportAiError, time: DateTime.now()));
          _status = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_greeted) {
      _greeted = true;
      _messages.add(_ChatEntry(isUser: false, text: l10n.supportAiGreeting, time: DateTime.now()));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 320,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final entry = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment:
                        entry.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!entry.isUser) ...[
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFF0B6962),
                          child: Text('AI', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment:
                              entry.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: entry.isUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                entry.text,
                                style: TextStyle(
                                  color: entry.isUser ? Theme.of(context).colorScheme.onPrimary : null,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _formatTime(entry.time),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 4),
            Text(_status!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !_isSending,
                  decoration: InputDecoration(
                    hintText: l10n.supportAiInputHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  ),
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
        ],
      ),
    );
  }
}
