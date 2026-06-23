import 'package:flutter_riverpod/legacy.dart';

class ThemeNotifier extends StateNotifier<bool> {
  // Default to dark mode (true)
  ThemeNotifier() : super(true);

  void toggleTheme() {
    state = !state;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});
