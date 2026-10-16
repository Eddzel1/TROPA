import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tropa_v2/services/offline_auth.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('verifies only the remembered user, email and password', () async {
    await OfflineAuth.rememberCredential(email: 'Encoder@Example.com', userId: 'u1', password: 'secret123');

    Future<bool> verify(String email, String password, String userId) =>
        OfflineAuth.verifyOffline(email: email, password: password, sessionUserId: userId);

    expect(await verify('encoder@example.com ', 'secret123', 'u1'), isTrue);
    expect(await verify('encoder@example.com', 'wrong', 'u1'), isFalse);
    expect(await verify('other@example.com', 'secret123', 'u1'), isFalse);
    expect(await verify('encoder@example.com', 'secret123', 'u2'), isFalse);
  });

  test('stores a hash, never the password', () async {
    await OfflineAuth.rememberCredential(email: 'a@b.co', userId: 'u1', password: 'secret123');
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getKeys().map((k) => prefs.get(k).toString()).join();
    expect(stored.contains('secret123'), isFalse);
  });

  test('no saved credential means no offline sign-in', () async {
    expect(await OfflineAuth.verifyOffline(email: 'a@b.co', password: 'x', sessionUserId: 'u1'), isFalse);
  });

  test('lock flag and local database owner persist', () async {
    expect(await OfflineAuth.isLocked(), isFalse);
    await OfflineAuth.setLocked(true);
    expect(await OfflineAuth.isLocked(), isTrue);
    expect(await OfflineAuth.localDbOwner(), isNull);
    await OfflineAuth.setLocalDbOwner('u1');
    expect(await OfflineAuth.localDbOwner(), 'u1');
  });
}
