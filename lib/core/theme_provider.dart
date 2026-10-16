import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-level theme choice. `light` and `tropa` both render with light brightness.
enum AppTheme { dark, light, tropa }

final appThemeProvider = StateNotifierProvider<AppThemeNotifier, AppTheme>((ref) {
  return AppThemeNotifier();
});

class AppThemeNotifier extends StateNotifier<AppTheme> {
  AppThemeNotifier() : super(AppTheme.tropa) {
    _loadPreference();
  }

  static const _prefKey = 'tropa_theme_mode';

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      for (final t in AppTheme.values) {
        if (t.name == saved) state = t;
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, theme.name);
    } catch (_) {}
  }
}
