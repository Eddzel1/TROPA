import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart';
import 'data/db.dart';
import 'core/design_system.dart';
import 'core/theme_provider.dart';
import 'router/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize environment variables securely
  await Env.init();

  // 2. Initialize Supabase client
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  // 3. Open the local-first database (PowerSync) and start syncing if signed in
  await openLocalDatabase();

  // 4. Launch application within Riverpod ProviderScope. A new scope is created whenever the local
  //    database is replaced by a starter database, so nothing keeps using the closed one.
  runApp(
    ValueListenableBuilder<int>(
      valueListenable: dbGeneration,
      builder: (context, generation, _) => ProviderScope(
        key: ValueKey(generation),
        child: const TropaApp(),
      ),
    ),
  );
}

class TropaApp extends ConsumerWidget {
  const TropaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(appThemeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TROPA v2 - Tabang Respeto Og Panalipud',
      debugShowCheckedModeBanner: false,
      theme: appTheme == AppTheme.tropa ? TropaTheme.tropaTheme : TropaTheme.lightTheme,
      darkTheme: TropaTheme.darkTheme,
      themeMode: appTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
