import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tropa_v2/core/ph_time.dart';

void main() {
  final instant = DateTime.utc(2026, 10, 16, 16, 30);

  test('toPhIso writes Manila wall time with +08:00', () {
    expect(toPhIso(instant), '2026-10-17T00:30:00.000+08:00');
  });

  test('parsePh round-trips toPhIso', () {
    expect(parsePh(toPhIso(instant)), instant);
  });

  test('parsePh keeps explicit offsets', () {
    expect(parsePh('2026-10-16T16:30:00Z'), instant);
    expect(parsePh('2026-10-16 16:30:00+00'), instant);
  });

  test('parsePh reads offset-less strings as GMT+8', () {
    expect(parsePh('2026-10-17T00:30:00'), instant);
    expect(parsePh('2026-10-17'), DateTime.utc(2026, 10, 16, 16));
    expect(parsePh(''), isNull);
    expect(parsePh(null), isNull);
  });

  test('formatPh shows Manila time', () {
    expect(formatPh(DateFormat('yyyy-MM-dd HH:mm'), instant), '2026-10-17 00:30');
  });
}
