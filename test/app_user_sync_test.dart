import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/models/models.dart';

void main() {
  test('sync_assigned_only reads from Supabase (bool) and SQLite (0/1) and round-trips', () {
    final base = {'id': 'u1', 'email': 'a@b.c', 'permissions': '["dues_collection"]', 'dues_barangays': '["l1"]'};
    expect(AppUser.fromJson({...base, 'sync_assigned_only': true}).syncAssignedOnly, isTrue);
    expect(AppUser.fromJson({...base, 'sync_assigned_only': 1}).syncAssignedOnly, isTrue);
    expect(AppUser.fromJson({...base, 'sync_assigned_only': 0}).syncAssignedOnly, isFalse);
    expect(AppUser.fromJson(base).syncAssignedOnly, isFalse);
    final user = AppUser.fromJson({...base, 'sync_assigned_only': 1});
    expect(user.toJson()['sync_assigned_only'], isTrue);
    expect(AppUser.fromJson(user.toJson()).syncAssignedOnly, isTrue);
  });
}
