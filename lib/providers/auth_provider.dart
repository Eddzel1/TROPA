import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/db.dart';
import '../models/models.dart';
import '../services/offline_auth.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(localDbProvider));
});

// Stream of Supabase Auth state changes
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current AppUser with Role & Permissions
final currentAppUserProvider = StateNotifierProvider<AppUserNotifier, AsyncValue<AppUser?>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return AppUserNotifier(service);
});

class AppUserNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final SupabaseService _service;

  AppUserNotifier(this._service) : super(const AsyncValue.loading()) {
    refreshUser();
  }

  static const _deactivatedMessage = 'This account has been deactivated. Contact an administrator.';

  /// Set when the last [refreshUser] found a profile that is not allowed to sign in.
  String? _blockedReason;

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    try {
      // A locked app keeps its session (so sync and offline sign-in work) but shows the login screen.
      if (await OfflineAuth.isLocked()) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _service.getCurrentAppUser();
      _blockedReason = user != null && user.status != 'active' ? _deactivatedMessage : null;
      state = AsyncValue.data(_blockedReason == null ? user : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Signs in against Supabase Auth, or against the saved offline credential when there is no
  /// connection. Returns null on success, or an error message.
  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _service.client.auth.signInWithPassword(email: email, password: password);
      final userId = res.user!.id;

      // Check the profile before setting up local data (falls back to Supabase on a fresh device).
      final profile = await _service.getCurrentAppUser();
      if (profile == null || profile.status != 'active') {
        await _endSession();
        return profile == null ? 'Signed in, but no user profile could be loaded for this account.' : _deactivatedMessage;
      }
      await OfflineAuth.setLocked(false);
      await OfflineAuth.rememberCredential(email: email, userId: userId, password: password);

      final generation = dbGeneration.value;
      await useLocalDbFor(userId);
      if (dbGeneration.value != generation) {
        // A starter database was installed and the app rebuilt on top of it; this notifier belongs
        // to the old app and must not touch state. The new one signs the user in from local data.
        try {
          await SupabaseService(localDb).logActivity(action: 'LOGIN', entityType: 'Auth', details: {'email': email});
        } catch (_) {}
        return null;
      }

      await refreshUser();
      if (state.value == null) {
        await _endSession();
        return _blockedReason ?? 'Signed in, but no user profile could be loaded for this account.';
      }
    } on AuthRetryableFetchException {
      return _signInOffline(email, password);
    } on AuthException catch (e) {
      state = const AsyncValue.data(null);
      return e.message;
    } catch (_) {
      state = const AsyncValue.data(null);
      return 'Unable to reach the server. Check your connection and try again.';
    }

    await _logLogin(email, offline: false);
    return null;
  }

  /// No connection: unlock with the saved session if the password matches the last online sign-in.
  Future<String?> _signInOffline(String email, String password) async {
    final session = _service.currentSession;
    final verified = session != null &&
        await OfflineAuth.verifyOffline(email: email, password: password, sessionUserId: session.user.id);
    if (!verified) {
      state = const AsyncValue.data(null);
      return 'No internet connection. Offline sign-in only works for the last account that '
          'signed in online on this device, using the same password.';
    }

    await OfflineAuth.setLocked(false);
    await refreshUser();
    if (state.value == null) {
      await OfflineAuth.setLocked(true);
      return _blockedReason ?? 'No internet connection, and this account\'s profile has not synced to this device yet.';
    }
    await _logLogin(email, offline: true);
    return null;
  }

  Future<void> _logLogin(String email, {required bool offline}) async {
    final userId = state.value?.id;
    if (userId != null) await _service.touchLastLogin(userId);
    try {
      await _service.logActivity(
        action: 'LOGIN',
        entityType: 'Auth',
        details: {'email': email, if (offline) 'offline': true},
      );
    } catch (_) {}
  }

  /// Locks the app: shows the login screen but keeps the Supabase session and local data, so the
  /// same user can sign back in without internet and pending changes keep syncing.
  Future<void> signOut() async {
    await OfflineAuth.setLocked(true);
    state = const AsyncValue.data(null);
  }

  /// Ends the Supabase session for real (used when a sign-in is rejected after authenticating).
  Future<void> _endSession() async {
    try {
      await _service.client.auth.signOut();
    } catch (_) {}
    state = const AsyncValue.data(null);
  }

  void setDemoUser(AppUser demoUser) {
    state = AsyncValue.data(demoUser);
  }
}

// User permissions provider
final userPermissionsProvider = Provider<List<String>>((ref) {
  final userAsync = ref.watch(currentAppUserProvider);
  return userAsync.value?.permissions ?? ['all'];
});

// RBAC permission check helper
final canPermissionProvider = Provider.family<bool, String>((ref, requiredPermission) {
  final permissions = ref.watch(userPermissionsProvider);
  if (permissions.contains('all')) return true;
  return permissions.contains(requiredPermission);
});
