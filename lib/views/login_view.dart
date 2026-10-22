import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';
import '../services/device_seed.dart';
import '../widgets/tropa_animated_logo.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version} (${info.buildNumber})');
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await ref
        .read(currentAppUserProvider.notifier)
        .signIn(email, password);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
    if (error == null) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // TROPA theme: brand-blue backdrop behind a white card.
    final brand = Theme.of(context).extension<TropaBrand>();
    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);
    final errorCol = TropaColors.errorOf(context);

    return Scaffold(
      backgroundColor: brand?.sidebarBg ?? TropaColors.backgroundOf(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: TropaColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TropaColors.borderOf(context), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header & Logo
                const Center(child: TropaAnimatedLogo(loop: true)),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? TropaColors.errorContainer.withValues(alpha: 0.4)
                          : errorCol.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: errorCol),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: errorCol),
                    ),
                  ),

                // Email
                Text(
                  'Email address',
                  style: TropaText.bodyStrong(TropaColors.textMedium(context)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                    hintText: 'user@tropa.ph',
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                Text(
                  'Password',
                  style: TropaText.bodyStrong(TropaColors.textMedium(context)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _handleLogin(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                    hintText: '••••••••',
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCol,
                    foregroundColor: onPrimaryCol,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: onPrimaryCol),
                        )
                      : Text(
                          'Sign in',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
                // First sign-in on a new device: starter database download progress.
                ValueListenableBuilder<String?>(
                  valueListenable: deviceSeedProgress,
                  builder: (context, progress, _) => progress == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            progress,
                            textAlign: TextAlign.center,
                            style: TropaText.meta(TropaColors.textMedium(context)),
                          ),
                        ),
                ),
                if (_version != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      _version!,
                      textAlign: TextAlign.center,
                      style: TropaText.meta(TropaColors.textMedium(context)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
