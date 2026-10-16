import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/services/device_seed.dart';

void main() {
  test('splits a file into contiguous parts that cover every byte', () {
    const mb = 1024 * 1024;
    final ranges = seedPartRanges(95 * mb, 40 * mb);

    expect(ranges, [
      (start: 0, end: 40 * mb),
      (start: 40 * mb, end: 80 * mb),
      (start: 80 * mb, end: 95 * mb),
    ]);
  });

  test('exact multiples and small files', () {
    expect(seedPartRanges(80, 40), [(start: 0, end: 40), (start: 40, end: 80)]);
    expect(seedPartRanges(10, 40), [(start: 0, end: 10)]);
    expect(seedPartRanges(0, 40), isEmpty);
  });
}
