import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/core/dues_math.dart';
import 'package:tropa_v2/models/models.dart';

DuesRate rate(double amount, String month) =>
    DuesRate(id: month, amount: amount, effectiveMonth: month, createdAt: DateTime(2026), updatedAt: DateTime(2026));

DuesMember member({DateTime? since, int paid = 0, bool coop = true}) => DuesMember(
      id: 'm',
      firstname: 'Juan',
      lastname: 'Dela Cruz',
      householdId: 'h',
      lgu: 'VALENCIA CITY',
      barangay: 'BAGONTAAS',
      purok: 'P-1',
      membershipDate: since,
      isCoopMember: coop,
      monthsPaid: paid,
    );

void main() {
  final oct2026 = parseMonthKey('2026-10')!;

  test('month keys round-trip', () {
    expect(monthKey(oct2026), '2026-10');
    expect(monthKey(parseMonthKey('2026-01')!), '2026-01');
    expect(parseMonthKey('2026-13'), isNull);
    expect(parseMonthKey('2026-02 to 2026-03'), isNull);
    expect(monthLabel(oct2026), 'Oct 2026');
  });

  test('membership month is billed, through the current month', () {
    final b = balanceFor(member(since: DateTime(2026, 8, 25)), [rate(20, '2026-01')], currentMonth: oct2026)!;
    expect(b.monthsBilled, 3); // Aug, Sep, Oct
    expect(b.monthsOwed, 3);
    expect(b.amountDue, 60);
    expect(b.nextUnpaidMonth, parseMonthKey('2026-08'));
    expect(b.paidThroughMonth, isNull);
  });

  test('payments cover the oldest months first', () {
    final b = balanceFor(member(since: DateTime(2026, 8, 1), paid: 2), [rate(20, '2026-01')], currentMonth: oct2026)!;
    expect(b.monthsOwed, 1);
    expect(b.nextUnpaidMonth, oct2026);
    expect(b.paidThroughMonth, parseMonthKey('2026-09'));
    expect(b.statusLabel, '1 month unpaid');
  });

  test('advance payment shows paid ahead', () {
    final b = balanceFor(member(since: DateTime(2026, 10, 1), paid: 3), [rate(20, '2026-01')], currentMonth: oct2026)!;
    expect(b.monthsOwed, -2);
    expect(b.amountDue, 0);
    expect(b.statusLabel, 'Paid ahead to Dec 2026');
  });

  test('rate changes apply per month, earliest rate covers earlier months', () {
    final rates = [rate(20, '2026-09'), rate(30, '2026-10')];
    expect(rateForMonth(parseMonthKey('2026-01')!, rates), 20);
    expect(rateForMonth(parseMonthKey('2026-09')!, rates), 20);
    expect(rateForMonth(oct2026, rates), 30);
    final b = balanceFor(member(since: DateTime(2026, 8, 1)), rates, currentMonth: oct2026)!;
    expect(b.amountDue, 20 + 20 + 30);
    expect(b.amountFor(5), 20 + 20 + 30 + 30 + 30);
  });

  test('no rates bills nothing', () {
    final b = balanceFor(member(since: DateTime(2026, 8, 1)), const [], currentMonth: oct2026)!;
    expect(b.monthsOwed, 3);
    expect(b.amountDue, 0);
  });

  test('members without a date or not in the cooperative are not billed', () {
    expect(balanceFor(member(), [rate(20, '2026-01')]), isNull);
    expect(balanceFor(member(since: DateTime(2026, 1, 1), coop: false), [rate(20, '2026-01')]), isNull);
    expect(unbilledReason(member()), 'No membership date');
  });

  test('paying ahead starts after the last paid month and is priced at the rates for those months', () {
    final rates = [rate(20, '2026-01'), rate(30, '2027-01')];
    final b = balanceFor(member(since: DateTime(2026, 10, 1), paid: 1), rates, currentMonth: oct2026)!;
    expect(b.monthsOwed, 0);
    expect(b.nextUnpaidMonth, parseMonthKey('2026-11'));
    expect(b.amountFor(4), 20 + 20 + 30 + 30); // Nov, Dec at 20; Jan, Feb at 30
    final after = b.afterPaying(4);
    expect(after.paidThroughMonth, parseMonthKey('2027-02'));
    expect(after.statusLabel, 'Paid ahead to Feb 2027');
  });

  test('payments are capped at 12 months ahead of the current month', () {
    final rates = [rate(20, '2026-01')];
    expect(balanceFor(member(since: DateTime(2026, 8, 1)), rates, currentMonth: oct2026)!.maxPayableMonths, 3 + 12);
    final ahead = balanceFor(member(since: DateTime(2026, 10, 1), paid: 5), rates, currentMonth: oct2026)!;
    expect(ahead.maxPayableMonths, 8); // paid through Feb 2027; the cap is Oct 2027
    expect(ahead.afterPaying(8).paidThroughMonth, oct2026 + 12);
    expect(balanceFor(member(since: DateTime(2026, 10, 1), paid: 13), rates, currentMonth: oct2026)!.maxPayableMonths, 0);
  });

  test('months paid ahead are used up as time passes', () {
    final paid = member(since: DateTime(2026, 10, 1), paid: 3); // Oct–Dec
    expect(balanceFor(paid, [rate(20, '2026-01')], currentMonth: oct2026)!.monthsOwed, -2);
    expect(balanceFor(paid, [rate(20, '2026-01')], currentMonth: parseMonthKey('2026-12'))!.monthsOwed, 0);
    final feb = balanceFor(paid, [rate(20, '2026-01')], currentMonth: parseMonthKey('2027-02'))!;
    expect(feb.monthsOwed, 2);
    expect(feb.amountDue, 40);
  });

  test('a later rate increase does not reprice months already paid ahead', () {
    // Paid Oct–Dec at 20; a rate of 30 from Nov is added afterwards. Paid months stay paid.
    final b = balanceFor(member(since: DateTime(2026, 10, 1), paid: 3), [rate(20, '2026-01'), rate(30, '2026-11')],
        currentMonth: parseMonthKey('2026-12'))!;
    expect(b.monthsOwed, 0);
    expect(b.amountDue, 0);
  });

  test('moving the membership date earlier turns paid-ahead months into back months', () {
    final rates = [rate(20, '2026-01')];
    final ahead = balanceFor(member(since: DateTime(2026, 10, 1), paid: 3), rates, currentMonth: oct2026)!;
    expect(ahead.statusLabel, 'Paid ahead to Dec 2026');
    final corrected = balanceFor(member(since: DateTime(2026, 6, 1), paid: 3), rates, currentMonth: oct2026)!;
    expect(corrected.paidThroughMonth, parseMonthKey('2026-08'));
    expect(corrected.monthsOwed, 2); // Sep, Oct
  });

  test('a membership date in the future owes nothing yet', () {
    final b = balanceFor(member(since: DateTime(2026, 12, 1)), [rate(20, '2026-01')], currentMonth: oct2026)!;
    expect(b.monthsOwed, 0);
    expect(b.statusLabel, 'Starts Dec 2026');
  });
}
