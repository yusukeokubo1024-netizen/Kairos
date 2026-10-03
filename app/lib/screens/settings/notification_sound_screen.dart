import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/notification_sound_service.dart';

/// Lets the user pick, per notification category, any sound already on
/// their Android device (via the system ringtone picker). Android-only —
/// see NotificationSoundService's doc comment for why.
class NotificationSoundScreen extends StatefulWidget {
  const NotificationSoundScreen({super.key});

  @override
  State<NotificationSoundScreen> createState() => _NotificationSoundScreenState();
}

class _NotificationSoundScreenState extends State<NotificationSoundScreen> {
  final Map<SoundCategory, NotificationSoundChoice> _choices = {};
  bool _loaded = false;
  SoundCategory? _picking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await Future.wait(
      SoundCategory.values.map((c) async => MapEntry(c, await NotificationSoundService.instance.load(c))),
    );
    if (!mounted) return;
    setState(() {
      _choices.addEntries(entries);
      _loaded = true;
    });
  }

  Future<void> _pick(SoundCategory category) async {
    setState(() => _picking = category);
    final choice = await NotificationSoundService.instance.pick(category);
    if (!mounted) return;
    setState(() {
      if (choice != null) _choices[category] = choice;
      _picking = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotificationSounds)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final category in SoundCategory.values)
                  ListTile(
                    title: Text(category.labelJa),
                    subtitle: Text(_choices[category]?.title ?? l10n.commonNotSet),
                    trailing: _picking == category
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _picking != null ? null : () => _pick(category),
                  ),
              ],
            ),
    );
  }
}
