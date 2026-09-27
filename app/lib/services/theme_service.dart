import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide dark mode preference (light / dark / follow system). Same
/// pattern as [LocaleService] — persisted via SharedPreferences and exposed
/// as a ValueNotifier so the app re-themes instantly from Settings without
/// a restart.
class ThemeService {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  static const _prefsKey = 'app_theme_mode';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    themeMode.value = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
