import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/services/voter_snapshot.dart';

void main() {
  test('round-trips rows in column order, mapping PC/HHL and blanking empty values', () {
    final rows = [
      {
        'id': 316917,
        'lastname': 'OHAGAN',
        'firstname': 'MERALYN',
        'middlename': 'MANLINO-AY',
        'ext': '',
        'purok': 'P-3',
        'brgy': 'NABALIWA',
        'lgu': 'PANGANTUCAN',
        'status': '-----------',
        'PC': 'NULL',
        'HHL': 'Yes',
        'precinct': '0096A',
      },
      {'id': 2, 'lastname': 'DELA CRUZ', 'firstname': 'JUAN', 'lgu': 'KALILANGAN', 'PC': null},
    ];

    final decoded = decodeVoterSnapshot(encodeVoterSnapshot(rows));

    expect(decoded, hasLength(2));
    expect(decoded[0], [
      316917, 'OHAGAN', 'MERALYN', 'MANLINO-AY', null, 'P-3', 'NABALIWA', 'PANGANTUCAN', '-----------', null, 'Yes', '0096A',
    ]);
    expect(decoded[1], [2, 'DELA CRUZ', 'JUAN', null, null, null, null, 'KALILANGAN', null, null, null, null]);
    expect(decoded[0], hasLength(voterSnapshotColumns.length));
  });

  test('compresses repetitive voter data well', () {
    final rows = [
      for (var i = 0; i < 5000; i++)
        {'id': i, 'lastname': 'LAST$i', 'firstname': 'FIRST', 'brgy': 'POBLACION', 'lgu': 'VALENCIA CITY', 'purok': 'P-${i % 12}'},
    ];
    final bytes = encodeVoterSnapshot(rows);
    expect(bytes.length / rows.length, lessThan(30));
  });
}
