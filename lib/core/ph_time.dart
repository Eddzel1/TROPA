import 'package:intl/intl.dart';

/// All app timestamps are GMT+8 (Asia/Manila, no DST), regardless of the device timezone.
const phOffset = Duration(hours: 8);

final _hasTime = RegExp(r'[T ]\d');
final _hasOffset = RegExp(r'(Z|[+-]\d{2}(:?\d{2})?)$', caseSensitive: false);

/// The current instant. Safe for comparisons and differences; format it with [formatPh].
DateTime phNow() => DateTime.now().toUtc();

/// Wall-clock view of [dt] in GMT+8: its year/month/day/hour fields are Manila time.
DateTime toPh(DateTime dt) => dt.toUtc().add(phOffset);

/// Today's calendar date in GMT+8, as a midnight date with no time part.
DateTime phToday() {
  final p = toPh(DateTime.now());
  return DateTime(p.year, p.month, p.day);
}

/// Serializes [dt] with an explicit offset, e.g. `2026-10-16T14:03:00.000+08:00`.
String toPhIso(DateTime dt) {
  final s = toPh(dt).toIso8601String();
  return '${s.substring(0, s.length - 1)}+08:00';
}

/// Parses a timestamp string. Strings without `Z` or an offset are read as GMT+8 wall time,
/// not device-local time.
DateTime? parsePh(String? s) {
  if (s == null) return null;
  s = s.trim();
  if (s.isEmpty) return null;
  final hasTime = _hasTime.hasMatch(s);
  if (hasTime && _hasOffset.hasMatch(s)) return DateTime.tryParse(s)?.toUtc();
  return DateTime.tryParse(hasTime ? '${s}Z' : '${s}T00:00:00Z')?.subtract(phOffset);
}

/// Formats [dt] in GMT+8.
String formatPh(DateFormat fmt, DateTime dt) => fmt.format(toPh(dt));
