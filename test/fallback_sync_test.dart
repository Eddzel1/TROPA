import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/services/fallback_sync.dart';

void main() {
  test('toLocalRow stores booleans as 1/0 and JSON columns as text, leaving the rest alone', () {
    final member = toLocalRow('family_members', {
      'id': 'm1',
      'is_voter': true,
      'is_household_leader': false,
      'firstname': 'JUAN',
      'age': 50,
      'latitude': '7.94',
    });
    expect(member, {'id': 'm1', 'is_voter': 1, 'is_household_leader': 0, 'firstname': 'JUAN', 'age': 50, 'latitude': '7.94'});

    final user = toLocalRow('users', {'id': 'u1', 'permissions': ['view_members', 'manage_members']});
    expect(user['permissions'], '["view_members","manage_members"]');

    // Booleans in tables without boolean columns are left as they are.
    expect(toLocalRow('households', {'flag': true})['flag'], true);
  });

  test('initialCursor starts 15 minutes before the last PowerSync sync, in UTC', () {
    expect(initialCursor(DateTime.utc(2026, 10, 16, 6, 0)), '2026-10-16T05:45:00.000Z');
  });

  test('deletionsByTable groups ids and ignores tables this device does not store', () {
    final grouped = deletionsByTable([
      {'table_name': 'family_members', 'record_id': 'a'},
      {'table_name': 'family_members', 'record_id': 'b'},
      {'table_name': 'households', 'record_id': 'h'},
      {'table_name': 'voters', 'record_id': '123'},
      {'table_name': null, 'record_id': 'x'},
    ]);
    expect(grouped, {
      'family_members': ['a', 'b'],
      'households': ['h'],
    });
  });
}
