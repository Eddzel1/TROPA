import '../models/models.dart';
import 'ph_time.dart';

/// Months are counted as `year * 12 + (month - 1)`, so consecutive months differ by 1.
int monthIndexOf(DateTime d) => d.year * 12 + d.month - 1;

/// The current month in GMT+8.
int currentMonthIndex() => monthIndexOf(phToday());

/// `YYYY-MM` for a month index.
String monthKey(int index) => '${index ~/ 12}-${(index % 12 + 1).toString().padLeft(2, '0')}';

/// Month index of a `YYYY-MM` string, or null when it isn't one.
int? parseMonthKey(String? key) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(key?.trim() ?? '');
  if (m == null) return null;
  final month = int.parse(m.group(2)!);
  if (month < 1 || month > 12) return null;
  return int.parse(m.group(1)!) * 12 + month - 1;
}

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Short label for a month index, e.g. `Oct 2026`.
String monthLabel(int index) => '${_monthNames[index % 12]} ${index ~/ 12}';

/// `Oct 2026` or `Oct 2026 – Dec 2026` for [count] months starting at [first].
String monthRangeLabel(int first, int count) =>
    count <= 1 ? monthLabel(first) : '${monthLabel(first)} – ${monthLabel(first + count - 1)}';

/// Months a ledger receipt pays for, e.g. "Oct 2026 – Dec 2026".
String receiptMonthRange(DuesReceipt r) {
  final first = parseMonthKey(r.firstMonth);
  final last = parseMonthKey(r.lastMonth);
  return first == null ? (r.firstMonth ?? '') : monthRangeLabel(first, (last ?? first) - first + 1);
}

/// [receiptMonthRange], plus member-months when the receipt covers several members.
String receiptMonthsLabel(DuesReceipt r) {
  final range = receiptMonthRange(r);
  return r.memberCount > 1 ? '$range · ${r.monthsCovered} member-months' : range;
}

/// The rate for [month]: the latest rate effective on or before it. The earliest rate also covers
/// months before it, so setting a rate never makes past months free. 0 when there are no rates.
double rateForMonth(int month, List<DuesRate> rates) {
  double? earliest;
  int? earliestMonth;
  double? best;
  int? bestMonth;
  for (final r in rates) {
    final m = parseMonthKey(r.effectiveMonth);
    if (m == null) continue;
    if (earliestMonth == null || m < earliestMonth) {
      earliestMonth = m;
      earliest = r.amount;
    }
    if (m <= month && (bestMonth == null || m > bestMonth)) {
      bestMonth = m;
      best = r.amount;
    }
  }
  return best ?? earliest ?? 0;
}

/// A percentage to at most two decimals without trailing zeros: "60%", "7.5%", "55.33%".
String percentLabel(double value) {
  final text = ((value * 100).round() / 100).toStringAsFixed(2);
  return '${text.replaceFirst(RegExp(r'\.?0+$'), '')}%';
}

/// The agreed split, used until a split is saved in Settings.
const defaultAllocation = {
  DuesFund.mortuary: 60.0,
  DuesFund.livelihood: 30.0,
  DuesFund.purokOperations: 7.0,
  DuesFund.federationOperations: 3.0,
};

/// The split row in force for [month], picked like [rateForMonth]: the latest effective on or
/// before it, the earliest also covering months before it. Null when there are none.
DuesAllocation? allocationRowForMonth(int month, List<DuesAllocation> allocations) {
  DuesAllocation? earliest;
  int? earliestMonth;
  DuesAllocation? best;
  int? bestMonth;
  for (final a in allocations) {
    final m = parseMonthKey(a.effectiveMonth);
    if (m == null) continue;
    if (earliestMonth == null || m < earliestMonth) {
      earliestMonth = m;
      earliest = a;
    }
    if (m <= month && (bestMonth == null || m > bestMonth)) {
      bestMonth = m;
      best = a;
    }
  }
  return best ?? earliest;
}

/// Each fund's percentage for dues paid in [month].
Map<DuesFund, double> allocationForMonth(int month, List<DuesAllocation> allocations) =>
    allocationRowForMonth(month, allocations)?.percents ?? defaultAllocation;

/// What each fund gets from [collectedByMonth] (amount paid per payment month), each month split
/// with the percentages in force then. Amounts are in centavos-exact pesos; the rounding remainder
/// goes to Mortuary so the funds always add up to what was collected.
Map<DuesFund, double> allocate(Map<int, double> collectedByMonth, List<DuesAllocation> allocations) {
  final cents = {for (final f in DuesFund.values) f: 0};
  for (final e in collectedByMonth.entries) {
    final total = (e.value * 100).round();
    final percents = allocationForMonth(e.key, allocations);
    var rest = total;
    for (final f in DuesFund.values.skip(1)) {
      final share = (total * (percents[f] ?? 0) / 100).round();
      cents[f] = cents[f]! + share;
      rest -= share;
    }
    cents[DuesFund.mortuary] = cents[DuesFund.mortuary]! + rest;
  }
  return {for (final e in cents.entries) e.key: e.value / 100};
}

/// The months among [months] where a different split takes over from the one before, in order,
/// e.g. to note that a report's period spans a change.
List<int> allocationChanges(Iterable<int> months, List<DuesAllocation> allocations) {
  final sorted = months.toSet().toList()..sort();
  final changes = <int>[];
  DuesAllocation? previous;
  for (var i = 0; i < sorted.length; i++) {
    final row = allocationRowForMonth(sorted[i], allocations);
    if (i > 0 && row?.id != previous?.id) changes.add(sorted[i]);
    previous = row;
  }
  return changes;
}

/// Sum of the rates for [count] months starting at [first].
double amountForMonths(int first, int count, List<DuesRate> rates) {
  var total = 0.0;
  for (var m = first; m < first + count; m++) {
    total += rateForMonth(m, rates);
  }
  return total;
}

/// How far past the current month dues may be paid in advance.
const maxMonthsAhead = 12;

/// Where one member stands. Payments always cover the oldest unpaid months first, so the months a
/// member has paid are always [startMonth] .. [startMonth] + [monthsPaid] - 1.
class DuesBalance {
  /// The membership month, which is billed.
  final int startMonth;
  final int monthsPaid;
  final int currentMonth;
  final List<DuesRate> rates;

  const DuesBalance({
    required this.startMonth,
    required this.monthsPaid,
    required this.currentMonth,
    required this.rates,
  });

  /// Months from the membership month through the current month (0 if membership starts later).
  int get monthsBilled => currentMonth < startMonth ? 0 : currentMonth - startMonth + 1;

  /// Unpaid months up to the current month. Negative when paid ahead.
  int get monthsOwed => monthsBilled - monthsPaid;

  /// The first month a new payment covers.
  int get nextUnpaidMonth => startMonth + monthsPaid;

  /// Last month covered, or null when nothing has been paid.
  int? get paidThroughMonth => monthsPaid > 0 ? startMonth + monthsPaid - 1 : null;

  double get amountDue => monthsOwed > 0 ? amountForMonths(nextUnpaidMonth, monthsOwed, rates) : 0;

  /// The most months one payment may cover: everything owed plus [maxMonthsAhead] months ahead.
  int get maxPayableMonths => monthsOwed + maxMonthsAhead < 0 ? 0 : monthsOwed + maxMonthsAhead;

  /// The price of paying [months] more, starting at [nextUnpaidMonth].
  double amountFor(int months) => months > 0 ? amountForMonths(nextUnpaidMonth, months, rates) : 0;

  /// The balance after paying [months] more.
  DuesBalance afterPaying(int months) =>
      DuesBalance(startMonth: startMonth, monthsPaid: monthsPaid + months, currentMonth: currentMonth, rates: rates);

  /// e.g. `3 months unpaid`, `Paid through Oct 2026`, `Paid ahead to Dec 2026`.
  String get statusLabel {
    if (monthsOwed > 0) return '$monthsOwed month${monthsOwed == 1 ? '' : 's'} unpaid';
    if (monthsOwed < 0) return 'Paid ahead to ${monthLabel(paidThroughMonth!)}';
    if (monthsBilled == 0) return 'Starts ${monthLabel(startMonth)}';
    return 'Paid through ${monthLabel(paidThroughMonth!)}';
  }
}

/// [member]'s balance, or null when they aren't billed: not a cooperative member, or no
/// membership date yet.
DuesBalance? balanceFor(DuesMember member, List<DuesRate> rates, {int? currentMonth}) {
  final date = member.membershipDate;
  if (!member.isCoopMember || date == null) return null;
  return DuesBalance(
    startMonth: monthIndexOf(date),
    monthsPaid: member.monthsPaid,
    currentMonth: currentMonth ?? currentMonthIndex(),
    rates: rates,
  );
}

/// Why [member] has no balance, for display.
String unbilledReason(DuesMember member) =>
    !member.isCoopMember ? 'Not a cooperative member' : 'No membership date';
