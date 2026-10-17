import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';
import 'tropa_animated_logo.dart';

/// Shown while Supabase and the local database start up, so the app draws at once instead of a
/// blank page. Matches the login page (brand-blue backdrop, white card, animated logo), so the
/// hand-over to the login screen is seamless. With [error], offers a retry instead.
class StartupScreen extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;

  const StartupScreen({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TropaTheme.tropaTheme,
      home: Scaffold(
        backgroundColor: TropaColors.tropaBlue,
        body: Center(
          child: Container(
            width: 360,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TropaAnimatedLogo(loop: true),
                const SizedBox(height: 28),
                if (error == null) ...[
                  const SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(minHeight: 3, color: TropaColors.tropaBlue),
                  ),
                  const SizedBox(height: 12),
                  Text('Starting TROPA…', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                ] else ...[
                  Text(
                    'TROPA could not start on this device.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(error!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onRetry, child: const Text('Try again')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
