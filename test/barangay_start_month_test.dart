import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/models/models.dart';
import 'package:tropa_v2/providers/dues_provider.dart';

void main() {
  const months = {'VALENCIA CITY|POBLACION': '2026-02'};

  test('matches a barangay regardless of case and spacing, like the server trigger', () {
    expect(startMonthFor(months, 'Valencia City', ' poblacion '), '2026-02');
    expect(startMonthFor(months, 'VALENCIA CITY', 'LUMBO'), isNull);
    expect(startMonthFor(months, null, null), isNull);
  });

  test('Location reads and writes the starting month; empty means not set', () {
    final base = {'id': 'l1', 'lgu': 'VALENCIA CITY', 'barangay': 'POBLACION'};
    expect(Location.fromJson({...base, 'dues_start_month': '2026-02'}).duesStartMonth, '2026-02');
    expect(Location.fromJson({...base, 'dues_start_month': ''}).duesStartMonth, isNull);
    expect(Location.fromJson(base).duesStartMonth, isNull);
    expect(Location.fromJson({...base, 'dues_start_month': '2026-02'}).toJson()['dues_start_month'], '2026-02');
  });
}
