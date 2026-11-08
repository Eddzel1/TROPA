import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/models/models.dart';

void main() {
  FormTracking row({String? statusChangedAt}) => FormTracking.fromJson({
        'id': 'f1',
        'status': FormTrackingStatus.inProgress,
        'created_at': '2026-11-01T09:00:00+08:00',
        'updated_at': '2026-11-01T09:00:00+08:00',
        'status_changed_at': statusChangedAt,
      });

  test('days count from status_changed_at in PH calendar days', () {
    // 11 PM Nov 3 PH to 1 AM Nov 4 PH is two hours but crosses midnight: one day.
    final r = row(statusChangedAt: '2026-11-03T23:00:00+08:00');
    expect(r.daysInStatus(DateTime.parse('2026-11-03T23:30:00+08:00')), 0);
    expect(r.daysInStatus(DateTime.parse('2026-11-04T01:00:00+08:00')), 1);
    expect(r.daysInStatus(DateTime.parse('2026-11-10T08:00:00+08:00')), 7);
  });

  test('rows without status_changed_at count from created_at', () {
    expect(row().daysInStatus(DateTime.parse('2026-11-06T12:00:00+08:00')), 5);
  });

  test('copyWith keeps status_changed_at', () {
    final r = row(statusChangedAt: '2026-11-03T10:00:00+08:00');
    expect(r.copyWith(numberOfForms: 3).statusChangedAt, r.statusChangedAt);
  });
}
