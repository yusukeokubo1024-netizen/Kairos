import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/anniversary.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/notification_service.dart';
import '../../services/weather_service.dart';
import '../anniversary/anniversary_list_screen.dart';

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
      final success = await BiometricService.instance.authenticate();
      if (!success) return;
    }
    await BiometricService.instance.setLockEnabled(enabled);
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'uid': uid,
      'notifications_enabled': enabled,
    });
    if (!enabled) {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> _linkGoogle() async {
    setState(() => _isLinkingGoogle = true);
    try {
      await _authService.linkGoogleAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Googleアカウントと連携しました')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = e.code == 'credential-already-in-use'
            ? 'このGoogleアカウントは既に別のKairosアカウントで使われています'
            : 'Google連携に失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google連携に失敗しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLinkingGoogle = false);
    }
  }

  Future<void> _editDisplayName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('表示名を編集'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    await _authService.updateDisplayName(newName);
  }

  /// Uses a fixed anniversary document ID so re-saving the birthday updates
  /// the same entry instead of creating duplicates.
  String _birthdayAnniversaryId(String uid) => 'birthday_$uid';

  Future<void> _setBirthday(DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '生年月日を選択',
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
      title: '誕生日',
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

  Future<void> _setWeatherLocation(String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final city = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お住まいの地域'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '例: 渋谷、横浜、札幌',
            helperText: '「〜区」「〜都」などを付けずに地名だけで検索してください',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (city == null || city.isEmpty) return;

    setState(() => _isSettingWeatherLocation = true);
    List<({double lat, double lon, String resolvedName})> candidates;
    try {
      candidates = await WeatherService.instance.geocodeCity(city);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地域の検索に失敗しました: $e')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSettingWeatherLocation = false);
    }

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地域が見つかりませんでした')),
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
        title: const Text('この地域でよろしいですか？'),
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

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'uid': uid,
      'weather_lat': selected.lat,
      'weather_lon': selected.lon,
      'weather_city': selected.resolvedName,
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ページを開けませんでした')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Text(
          'プロフィール、所有する予定・タスク・グループを含むすべてのデータが削除されます。'
          'この操作は取り消せません。複数人で共有しているグループがある場合は、'
          '先にメンバーを整理してください。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する', style: TextStyle(color: Colors.red)),
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
            ? 'セキュリティのため、一度ログアウトしてから再度ログインし、もう一度お試しください'
            : 'アカウントの削除に失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final displayName = data?['display_name'] as String? ?? '';
          final email = data?['email'] as String? ?? FirebaseAuth.instance.currentUser?.email ?? '';
          final notificationsEnabled = data?['notifications_enabled'] as bool? ?? true;
          final isGoogleLinked = _authService.isGoogleLinked;

          return ListView(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(displayName.isNotEmpty ? displayName : '(表示名未設定)'),
                subtitle: Text(email),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editDisplayName(displayName),
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
                    title: const Text('生年月日'),
                    subtitle: Text(
                      current == null ? '未設定' : '$birthMonth月$birthDay日',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _setBirthday(current),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '生年月日を登録すると、毎年カレンダーとグループの友人・家族にも誕生日として表示されます',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('お住まいの地域（天気予報）'),
                subtitle: Text((data?['weather_city'] as String?) ?? '未設定'),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('アカウント連携', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Googleと連携'),
                subtitle: Text(isGoogleLinked ? '連携済み' : '未連携'),
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
                title: const Text('通知'),
                subtitle: const Text('予定・タスク・記念日のリマインダー通知'),
                value: notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              if (_biometricSupported)
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Face ID / 指紋認証でロック'),
                  subtitle: const Text('アプリを開くたびに認証を求めます'),
                  value: _biometricEnabled,
                  onChanged: _toggleBiometricLock,
                ),
              ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: const Text('大切な記念日'),
                subtitle: const Text('毎年通知したい記念日を登録'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnniversaryListScreen()),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('プライバシーポリシー'),
                onTap: () => _openUrl('https://kairos-3d873.web.app/privacy-policy.html'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('利用規約'),
                onTap: () => _openUrl('https://kairos-3d873.web.app/terms-of-service.html'),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('サポート'),
                onTap: () => _openUrl('https://kairos-3d873.web.app/'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
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
                title: const Text('アカウントを削除', style: TextStyle(color: Colors.red)),
                onTap: _isDeleting ? null : _confirmDeleteAccount,
              ),
            ],
          );
        },
      ),
    );
  }
}
