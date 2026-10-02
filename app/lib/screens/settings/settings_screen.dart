import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/admin_regions.dart';
import '../../data/countries.dart';
import '../../l10n/app_localizations.dart';
import '../../models/anniversary.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/daily_digest_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../services/theme_service.dart';
import '../../services/weather_service.dart';
import '../anniversary/anniversary_list_screen.dart';
import 'color_labels_screen.dart';
import 'packing_templates_screen.dart';
import 'support_screen.dart';
import 'trash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _isDeleting = false;
  bool _isLinkingGoogle = false;
  bool _biometricSupported = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    // The cached currentUser's emailVerified flag doesn't update itself
    // after the user taps the link in the verification email — refresh it
    // so the "please verify" banner clears once they've actually done so.
    FirebaseAuth.instance.currentUser?.reload().then((_) {
      if (mounted) setState(() {});
      // Now that verification status is fresh, this can finally succeed if
      // it hadn't already (e.g. verified without signing out/in again) —
      // see ensureEmailIndexIfVerified for why it's gated on verification.
      unawaited(_authService.ensureEmailIndexIfVerified());
    });
  }

  Future<void> _loadBiometricState() async {
    final supported = await BiometricService.instance.isDeviceSupported();
    final enabled = await BiometricService.instance.isLockEnabled();
    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometricLock(bool enabled) async {
    if (enabled) {
      final l10n = AppLocalizations.of(context)!;
      final success = await BiometricService.instance.authenticate(l10n.biometricAuthReason);
      if (!success) return;
    }
    await BiometricService.instance.setLockEnabled(enabled);
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleReadReceipts(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'read_receipts_enabled': enabled,
    }, SetOptions(merge: true));
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'notifications_enabled': enabled,
    }, SetOptions(merge: true));
    if (!enabled) {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> _toggleDailyDigest(bool enabled, int hour, int minute) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'dailyDigestEnabled': enabled,
      // Written even when just turning it on, so a first-time enable
      // always has an explicit time on record (not just the UI default).
      'dailyDigestHour': hour,
      'dailyDigestMinute': minute,
    }, SetOptions(merge: true));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (enabled) {
      final result = await DailyDigestService.refreshFromFirestore(l10n);
      if (mounted) _showDailyDigestConfirmation(result);
    } else {
      await NotificationService.instance.cancelDailyDigest();
    }
  }

  Future<void> _pickDailyDigestTime(int hour, int minute) async {
    var selected = DateTime(2000, 1, 1, hour, minute);
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: selected,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(l10n.commonSave),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'dailyDigestHour': picked.hour,
      'dailyDigestMinute': picked.minute,
    }, SetOptions(merge: true));
    if (mounted) {
      final result = await DailyDigestService.refreshFromFirestore(AppLocalizations.of(context)!);
      if (mounted) _showDailyDigestConfirmation(result);
    }
  }

  // Without this, turning the digest on (or changing its time) looks like
  // it did nothing — the notification itself doesn't fire until the next
  // scheduled time, which can be tomorrow morning if today's already
  // passed. Also flags the one silent-failure mode worth calling out: the
  // master notifications toggle being off makes this a no-op.
  void _showDailyDigestConfirmation(DailyDigestRefreshResult result) {
    final l10n = AppLocalizations.of(context)!;
    if (!result.enabled || result.scheduledFor == null) return;
    final time = result.scheduledFor!;
    final message = result.masterNotificationsOff
        ? l10n.settingsDailyDigestConfirmBlocked
        : l10n.settingsDailyDigestConfirm(
            time.month, time.day, time.hour.toString().padLeft(2, '0'),
            time.minute.toString().padLeft(2, '0'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _languageLabel(AppLocalizations l10n, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return l10n.settingsLanguageJapanese;
      case 'ko':
        return l10n.settingsLanguageKorean;
      case 'zh':
        return l10n.settingsLanguageChinese;
      default:
        return l10n.settingsLanguageEnglish;
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          for (final locale in LocaleService.supportedLocales)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, locale),
              child: Text(_languageLabel(l10n, locale)),
            ),
        ],
      ),
    );
    if (selected != null) {
      await LocaleService.instance.setLocale(selected);
    }
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeSystem;
    }
  }

  Future<void> _pickThemeMode() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsTheme),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, mode),
              child: Text(_themeModeLabel(l10n, mode)),
            ),
        ],
      ),
    );
    if (selected != null) {
      await ThemeService.instance.setThemeMode(selected);
    }
  }

  /// Asks the Android launcher to place the "today's schedules" widget on
  /// the home screen. Only some launchers support this on Android 8+ — if
  /// unsupported, tells the user to add it manually (long-press the home
  /// screen > widgets > Kairos) instead of silently doing nothing.
  Future<void> _addHomeWidget(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!context.mounted) return;
    if (supported) {
      await HomeWidget.requestPinWidget(androidName: 'TodayScheduleWidgetProvider');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsAddHomeWidgetManual)),
      );
    }
  }

  Future<void> _linkGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLinkingGoogle = true);
    try {
      await _authService.linkGoogleAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsGoogleLinkSuccess)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = e.code == 'credential-already-in-use'
            ? l10n.settingsGoogleLinkInUse
            : l10n.settingsGoogleLinkFailed;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsGoogleLinkFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLinkingGoogle = false);
    }
  }

  Future<void> _editDisplayName(String currentName) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsEditDisplayName),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await _authService.updateDisplayName(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDisplayNameSaved(newName))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDisplayNameSaveFailed('$e'))),
        );
      }
    }
  }

  /// Uses a fixed anniversary document ID so re-saving the birthday updates
  /// the same entry instead of creating duplicates.
  String _birthdayAnniversaryId(String uid) => 'birthday_$uid';

  Future<void> _setBirthday(DateTime? current, String displayName) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: l10n.settingsBirthdayPick,
    );
    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    await db.collection('publicProfiles').doc(uid).set({
      'birthMonth': picked.month,
      'birthDay': picked.day,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also register it as an anniversary so it gets a yearly reminder
    // notification, same as any other 大切な記念日.
    final anniversary = Anniversary(
      id: _birthdayAnniversaryId(uid),
      ownerId: uid,
      title: displayName.isNotEmpty ? l10n.calendarBirthdaySuffix(displayName) : l10n.settingsBirthday,
      month: picked.month,
      day: picked.day,
    );
    await db
        .collection('anniversaries')
        .doc(anniversary.id)
        .set(anniversary.toCreateMap(), SetOptions(merge: true));
    await NotificationService.instance.scheduleForAnniversary(anniversary);
  }

  bool _isSettingWeatherLocation = false;

  /// Lets the user narrow the search to one country/region first, so
  /// same-named places in different countries don't collide with Japanese
  /// ward/city names like 千代田区.
  Future<Country?> _pickCountry() async {
    final l10n = AppLocalizations.of(context)!;
    var query = '';
    // Kept outside StatefulBuilder's rebuild so it survives each keystroke;
    // reset to the top on every filter change below, otherwise the list
    // keeps its old scroll *offset* against a shorter filtered list and the
    // view visibly jumps.
    final scrollController = ScrollController();
    try {
      return await showDialog<Country>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = query.isEmpty
                ? kCountries
                : kCountries
                    .where((c) =>
                        c.nameJa.contains(query) ||
                        c.nameEn.toLowerCase().contains(query.toLowerCase()))
                    .toList();
            return AlertDialog(
              title: Text(l10n.settingsWeatherLocationCountryTitle),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.settingsWeatherLocationCountrySearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setDialogState(() => query = value);
                        if (scrollController.hasClients) {
                          scrollController.jumpTo(0);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text(l10n.settingsWeatherLocationCountryNotFound))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final country = filtered[index];
                                return ListTile(
                                  title: Text(country.nameJa),
                                  subtitle: Text(country.nameEn),
                                  onTap: () => Navigator.pop(context, country),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
              ],
            );
          },
        ),
      );
    } finally {
      scrollController.dispose();
    }
  }

  /// Sentinel returned by [_pickAdminCity] when the user wants to type a
  /// name instead of choosing from the region's city list.
  static const _manualEntrySentinel = '__manual__';

  /// A searchable, single-choice list dialog shared by the region/city/ward
  /// pickers. Pass [showManualEntry] to add a trailing "type it myself"
  /// row, returned as [_manualEntrySentinel].
  Future<String?> _pickFromList({
    required String title,
    required String searchHint,
    required List<String> items,
    bool showManualEntry = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    var query = '';
    // Kept outside StatefulBuilder's rebuild so it survives each keystroke;
    // reset to the top on every filter change below, otherwise the list
    // keeps its old scroll *offset* against a shorter filtered list and the
    // view visibly jumps.
    final scrollController = ScrollController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered =
                query.isEmpty ? items : items.where((c) => c.contains(query)).toList();
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setDialogState(() => query = value);
                        if (scrollController.hasClients) {
                          scrollController.jumpTo(0);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length + (showManualEntry ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (showManualEntry && index == filtered.length) {
                            return ListTile(
                              title: Text(l10n.settingsWeatherLocationManualEntry),
                              onTap: () => Navigator.pop(context, _manualEntrySentinel),
                            );
                          }
                          final item = filtered[index];
                          return ListTile(
                            title: Text(item),
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
              ],
            );
          },
        ),
      );
    } finally {
      scrollController.dispose();
    }
  }

  Future<AdminRegion?> _pickAdminRegion(String countryCode) async {
    final l10n = AppLocalizations.of(context)!;
    final regions = await AdminRegions.load(countryCode);
    if (!mounted) return null;
    final picked = await _pickFromList(
      title: l10n.settingsWeatherLocationPrefectureTitle,
      searchHint: l10n.settingsWeatherLocationPrefectureSearchHint,
      items: [for (final region in regions) region.name],
    );
    if (picked == null) return null;
    return regions.firstWhere((region) => region.name == picked);
  }

  Future<String?> _promptCityName(String? current) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsWeatherLocationTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.settingsWeatherLocationHint,
            helperText: l10n.settingsWeatherLocationHelper,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _setWeatherLocation(String? current) async {
    final l10n = AppLocalizations.of(context)!;
    final country = await _pickCountry();
    if (country == null || !mounted) return;

    String? city;
    // What we actually search the geocoder with — usually same as [city],
    // but a bare prefecture/state name is frequently NOT its own indexed
    // place at all (e.g. 大阪府 has no entry distinct from 大阪市 — Tokyo is
    // an exception since 東京都 doubles as its own capital-city entry), so
    // we search its prefectural capital instead while still labeling/saving
    // the location as the plain prefecture name.
    String? geocodeQuery;
    String? prefectureHint;
    var isStructuredPick = false;
    if (kAdminRegionAssets.containsKey(country.code)) {
      // 市区町村レベルまで選ばせると、フリーの地名データベースに載っていない
      // 市（羽曳野市など）でエラーになることがあったため、都道府県・州・省
      // レベルまでで止める。
      final region = await _pickAdminRegion(country.code);
      if (region == null || !mounted) return;
      prefectureHint = region.name;
      city = region.name;
      geocodeQuery = region.cities.isNotEmpty ? region.cities.first.name : region.name;
      isStructuredPick = true;
    } else {
      city = await _promptCityName(current);
      geocodeQuery = city;
    }
    if (city == null || city.isEmpty) return;

    setState(() => _isSettingWeatherLocation = true);
    List<({double lat, double lon, String resolvedName})> candidates;
    try {
      candidates = await WeatherService.instance.geocodeCity(
        geocodeQuery!,
        countryCode: country.code,
        prefectureHint: prefectureHint,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsWeatherLocationSearchFailed('$e'))),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSettingWeatherLocation = false);
    }

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsWeatherLocationNotFound)),
        );
      }
      return;
    }
    if (!mounted) return;

    // Same-named places exist in different prefectures, so always confirm
    // which one (down to the 市区町村) before saving — even with one match.
    final selected = await showDialog<({double lat, double lon, String resolvedName})>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsWeatherLocationConfirmTitle),
        children: [
          for (final candidate in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, candidate),
              child: Text(candidate.resolvedName),
            ),
        ],
      ),
    );
    if (selected == null) return;

    // When picked from the region→city→ward list, show exactly what the
    // user selected (e.g. "大阪市中央区") even if the coordinates had to
    // fall back to the parent city — Open-Meteo's free data has no
    // ward-level entry at all for many 政令指定都市, nationwide.
    final displayName = isStructuredPick
        ? city
        : (country.code == 'JP'
            ? selected.resolvedName
            : '${selected.resolvedName}（${country.nameJa}）');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'weather_lat': selected.lat,
        'weather_lon': selected.lon,
        'weather_city': displayName,
        'weather_country_code': country.code,
        // The exact string the user picked (e.g. "大阪市大正区"), used to
        // deep-link to tenki.jp's own search — it resolves wards our free
        // geocoder has no data for at all, like 大正区/浪速区.
        'weather_tenki_keyword': country.code == 'JP' ? city : null,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsWeatherLocationSaved(displayName))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsWeatherLocationSaveFailed('$e'))),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsCouldNotOpenPage)),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountConfirmTitle),
        content: Text(l10n.settingsDeleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.settingsDeleteAccountConfirmButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _authService.deleteAccount();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = e.code == 'requires-recent-login'
            ? l10n.settingsDeleteAccountRequiresRecentLogin
            : l10n.settingsDeleteAccountFailed;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      // Any other failure (e.g. a Firestore cleanup step) — report the same
      // generic failure rather than letting it surface as an unhandled
      // error with no feedback.
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.settingsDeleteAccountFailed)));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final displayName = data?['display_name'] as String? ?? '';
          final email = data?['email'] as String? ?? FirebaseAuth.instance.currentUser?.email ?? '';
          final notificationsEnabled = data?['notifications_enabled'] as bool? ?? true;
          final readReceiptsEnabled = data?['read_receipts_enabled'] as bool? ?? true;
          final dailyDigestEnabled = data?['dailyDigestEnabled'] as bool? ?? false;
          final dailyDigestHour = data?['dailyDigestHour'] as int? ?? 7;
          final dailyDigestMinute = data?['dailyDigestMinute'] as int? ?? 0;
          final isGoogleLinked = _authService.isGoogleLinked;
          final currentLocale = LocaleService.instance.locale.value;

          return ListView(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(displayName.isNotEmpty ? displayName : l10n.settingsDisplayNameUnset),
                subtitle: Text(email),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editDisplayName(displayName),
              ),
              if (!_authService.isEmailVerified)
                ListTile(
                  tileColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  leading: Icon(Icons.mark_email_unread_outlined,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(l10n.settingsEmailUnverified),
                  trailing: TextButton(
                    onPressed: () async {
                      await _authService.resendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsEmailVerificationSent)),
                        );
                      }
                    },
                    child: Text(l10n.settingsResendVerification),
                  ),
                ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('publicProfiles').doc(uid).snapshots(),
                builder: (context, profileSnapshot) {
                  final profileData = profileSnapshot.data?.data();
                  final birthMonth = profileData?['birthMonth'] as int?;
                  final birthDay = profileData?['birthDay'] as int?;
                  final current = (birthMonth != null && birthDay != null)
                      ? DateTime(2000, birthMonth, birthDay)
                      : null;
                  return ListTile(
                    leading: const Icon(Icons.cake_outlined),
                    title: Text(l10n.settingsBirthday),
                    subtitle: Text(
                      current == null
                          ? l10n.commonNotSet
                          : l10n.settingsBirthdayValue(birthMonth!, birthDay!),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _setBirthday(current, displayName),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.settingsBirthdayHint,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: Text(l10n.settingsWeatherLocation),
                subtitle: Text((data?['weather_city'] as String?) ?? l10n.commonNotSet),
                trailing: _isSettingWeatherLocation
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
                onTap: () => _setWeatherLocation(data?['weather_city'] as String?),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.settingsLanguage),
                subtitle: Text(_languageLabel(l10n, currentLocale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickLanguage,
              ),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.instance.themeMode,
                builder: (context, themeMode, _) => ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text(l10n.settingsTheme),
                  subtitle: Text(_themeModeLabel(l10n, themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickThemeMode,
                ),
              ),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(l10n.settingsAddHomeWidget),
                  subtitle: Text(l10n.settingsAddHomeWidgetHint),
                  onTap: () => _addHomeWidget(context),
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(l10n.settingsAccountLinking, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(l10n.settingsGoogleLink),
                subtitle: Text(isGoogleLinked ? l10n.settingsGoogleLinked : l10n.settingsGoogleNotLinked),
                trailing: isGoogleLinked
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : (_isLinkingGoogle
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right)),
                onTap: (isGoogleLinked || _isLinkingGoogle) ? null : _linkGoogle,
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(l10n.settingsNotifications),
                subtitle: Text(l10n.settingsNotificationsSubtitle),
                value: notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.done_all),
                title: Text(l10n.settingsReadReceipts),
                subtitle: Text(l10n.settingsReadReceiptsSubtitle),
                value: readReceiptsEnabled,
                onChanged: _toggleReadReceipts,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.view_agenda_outlined),
                title: Text(l10n.settingsDailyDigest),
                subtitle: Text(l10n.settingsDailyDigestSubtitle),
                value: dailyDigestEnabled,
                onChanged: (value) => _toggleDailyDigest(value, dailyDigestHour, dailyDigestMinute),
              ),
              if (dailyDigestEnabled)
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  title: Text(l10n.settingsDailyDigestTime),
                  subtitle: Text(
                    '${dailyDigestHour.toString().padLeft(2, '0')}:'
                    '${dailyDigestMinute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickDailyDigestTime(dailyDigestHour, dailyDigestMinute),
                ),
              if (_biometricSupported)
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: Text(l10n.settingsBiometricLock),
                  subtitle: Text(l10n.settingsBiometricLockSubtitle),
                  value: _biometricEnabled,
                  onChanged: _toggleBiometricLock,
                ),
              ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: Text(l10n.settingsAnniversaries),
                subtitle: Text(l10n.settingsAnniversariesSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnniversaryListScreen()),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.settingsPrivacyPolicy),
                onTap: () => _openUrl('https://kairos-3d873.web.app/privacy-policy.html'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.settingsTermsOfService),
                onTap: () => _openUrl('https://kairos-3d873.web.app/terms-of-service.html'),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: Text(l10n.settingsSupport),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.settingsTrash),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.settingsColorLabels),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ColorLabelsScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_outlined),
                title: Text(l10n.settingsPackingTemplates),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PackingTemplatesScreen()),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.settingsLogout),
                onTap: () => _authService.signOut(),
              ),
              ListTile(
                leading: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: Text(l10n.settingsDeleteAccount, style: const TextStyle(color: Colors.red)),
                onTap: _isDeleting ? null : _confirmDeleteAccount,
              ),
            ],
          );
        },
      ),
    );
  }
}
