import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/models/models.dart';

void main() {
  // A Thursday.
  final today = DateTime(2026, 11, 5);

  test('presets cover the right GMT+8 days', () {
    expect(const DuesLedgerFilter().days(today), isNull);
    expect(const DuesLedgerFilter(period: LedgerPeriod.today).days(today), (from: today, to: today));
    // Weeks start on Monday.
    expect(const DuesLedgerFilter(period: LedgerPeriod.week).days(today), (from: DateTime(2026, 11, 2), to: today));
    expect(const DuesLedgerFilter(period: LedgerPeriod.month).days(today), (from: DateTime(2026, 11, 1), to: today));
  });

  test('custom range needs both ends', () {
    expect(DuesLedgerFilter(period: LedgerPeriod.custom, from: DateTime(2026, 10, 1)).days(today), isNull);
    final f = DuesLedgerFilter(period: LedgerPeriod.custom, from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31));
    expect(f.days(today), (from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31)));
  });

  test('copyWith clears location parts only when asked', () {
    const f = DuesLedgerFilter(lgu: 'VALENCIA CITY', barangay: 'LUMBO', purok: 'P-3');
    expect(f.copyWith(query: 'x').purok, 'P-3');
    final cleared = f.copyWith(barangay: () => null, purok: () => null);
    expect((cleared.lgu, cleared.barangay, cleared.purok), ('VALENCIA CITY', null, null));
    expect(f.isFiltered, isTrue);
    expect(const DuesLedgerFilter().isFiltered, isFalse);
  });
}
