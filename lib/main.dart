import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/database/db_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Primary persistence: MySQL (XAMPP). Connects and auto-creates the schema.
  // Safe no-op if the server is unreachable — the app still runs.
  await DbService.instance.init();

  // Local cache for a few legacy boxes still backed by Hive.
  await Hive.initFlutter();
  await Hive.openBox('sales');
  await Hive.openBox('shift');
  await Hive.openBox('settings');
  await Hive.openBox('orders');

  runApp(const ProviderScope(child: NeoDiningApp()));
}

class NeoDiningApp extends ConsumerWidget {
  const NeoDiningApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Neo-Dining POS',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
