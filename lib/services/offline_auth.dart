import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-side state that lets the last signed-in user get back in without internet.
///
/// Signing out "locks" the app instead of ending the Supabase session, so the session (and sync)
/// survive. To unlock offline, the typed password is checked against a salted PBKDF2 hash saved
/// after the last successful online sign-in; the password itself is never stored.
class OfflineAuth {
  static const _credentialKey = 'offline_auth.credential';
  static const _lockedKey = 'offline_auth.locked';
  static const _ownerKey = 'offline_auth.local_db_owner';
  static const _iterations = 100000;

  static Future<bool> isLocked() async => (await SharedPreferences.getInstance()).getBool(_lockedKey) ?? false;

  static Future<void> setLocked(bool locked) async =>
      (await SharedPreferences.getInstance()).setBool(_lockedKey, locked);

  /// Supabase user id that last used the local database on this device, or null if none has.
  static Future<String?> localDbOwner() async => (await SharedPreferences.getInstance()).getString(_ownerKey);

  static Future<void> setLocalDbOwner(String userId) async =>
      (await SharedPreferences.getInstance()).setString(_ownerKey, userId);

  /// Saves a hash of [password] after a successful online sign-in, replacing any previous user's.
  static Future<void> rememberCredential({
    required String email,
    required String userId,
    required String password,
  }) async {
    final salt = Uint8List.fromList(List.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = await compute(_pbkdf2, (password: password, salt: salt));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _credentialKey,
      jsonEncode({
        'email': email.trim().toLowerCase(),
        'user_id': userId,
        'salt': base64Encode(salt),
        'hash': base64Encode(hash),
      }),
    );
  }

  /// True when [email]/[password] match the saved credential and it belongs to [sessionUserId].
  static Future<bool> verifyOffline({
    required String email,
    required String password,
    required String sessionUserId,
  }) async {
    final raw = (await SharedPreferences.getInstance()).getString(_credentialKey);
    if (raw == null) return false;
    final saved = jsonDecode(raw) as Map<String, dynamic>;
    if (saved['email'] != email.trim().toLowerCase() || saved['user_id'] != sessionUserId) return false;

    final hash = await compute(_pbkdf2, (password: password, salt: base64Decode(saved['salt'] as String)));
    final expected = base64Decode(saved['hash'] as String);
    // Constant-time comparison.
    var diff = hash.length ^ expected.length;
    for (var i = 0; i < hash.length && i < expected.length; i++) {
      diff |= hash[i] ^ expected[i];
    }
    return diff == 0;
  }

  /// PBKDF2-HMAC-SHA256, one 32-byte block.
  static Uint8List _pbkdf2(({String password, Uint8List salt}) args) {
    final hmac = Hmac(sha256, utf8.encode(args.password));
    var u = hmac.convert([...args.salt, 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }
}
