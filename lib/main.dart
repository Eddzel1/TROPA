import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart';
import 'data/db.dart';
import 'core/design_system.dart';
import 'core/theme_provider.dart';
import 'router/router.dart';
import 'widgets/startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw straight away: Supabase and the local database start up behind a loading screen, instead
  // of the browser showing a blank page until they are ready.
  runApp(const TropaStartup());
}

/// Starts the app's services, showing [StartupScreen] until they are ready, then the app itself.
class TropaStartup extends StatefulWidget {
  const TropaStartup({super.key});

  @override
  State<TropaStartup> createState() => _TropaStartupState();
}

class _TropaStartupState extends State<TropaStartup> {
  late Future<void> _ready = _start();

  static Future<void> _start() async {
    // 1. Environment variables
    await Env.init();

    // 2. Supabase client
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization notice: $e');
    }

    // 3. The local-first database (PowerSync), syncing if signed in
    await openLocalDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const StartupScreen();
        if (snapshot.hasError) {
          return StartupScreen(
            error: '${snapshot.error}',
            onRetry: () => setState(() => _ready = _start()),
          );
        }
        // A new scope is created whenever the local database is replaced by a starter database,
        // so nothing keeps using the closed one.
        return ValueListenableBuilder<int>(
          valueListenable: dbGeneration,
          builder: (context, generation, _) => ProviderScope(
            key: ValueKey(generation),
            child: const TropaApp(),
          ),
        );
      },
    );
  }
}

class TropaApp extends ConsumerWidget {
  const TropaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(appThemeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TROPA v2 - Tabang Respeto Og Panalipud',
      debugShowCheckedModeBanner: false,
      theme: TropaTheme.of(themeId),
      routerConfig: router,
    );
  }
}
