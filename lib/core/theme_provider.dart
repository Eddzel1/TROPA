import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_palettes.dart';

/// Id of the chosen palette in `tropaPalettes`.
final appThemeProvider = StateNotifierProvider<AppThemeNotifier, String>((ref) {
  return AppThemeNotifier();
});

class AppThemeNotifier extends StateNotifier<String> {
  AppThemeNotifier() : super(TropaPalette.defaultId) {
    _loadPreference();
  }

  static const _prefKey = 'tropa_theme_mode';

  // The old 'dark' and 'light' choices no longer exist and fall back to TROPA; 'tropa' still matches.
  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (tropaPalettes.any((p) => p.id == saved)) state = saved!;
    } catch (_) {}
  }

  Future<void> setTheme(String id) async {
    state = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, id);
    } catch (_) {}
  }
}
