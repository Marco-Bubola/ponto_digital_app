import 'package:flutter/material.dart';
import 'session_service.dart';

class ThemeService {
  // ValueNotifier to allow the app to listen for theme changes
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  // Initialize from persisted preference
  static Future<void> init() async {
    final raw = await SessionService.getThemeMode();
    if (raw == null) {
      themeModeNotifier.value = ThemeMode.system;
      return;
    }
    switch (raw) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final raw = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await SessionService.saveThemeMode(raw);
  }
}
