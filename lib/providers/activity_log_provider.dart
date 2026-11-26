import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/ph_time.dart';
import 'auth_provider.dart';

/// Rows per page on the Audit Logs screen.
const activityLogPageSize = 50;

/// Kinds of action the Audit Logs filter offers. Each lists the action codes it covers;
/// [other] is everything the rest do not name, so new codes still show up somewhere.
enum LogActionGroup {
  all('All actions', []),
  created('Created', ['CREATE', 'CREATE_BULK', 'CREATE_USER']),
  updated('Updated', [
    'UPDATE',
    'UPDATE_USER',
    'UPDATE_MEMBERSHIP_DATE',
    'SET_DUES_START_MONTH',
    'SET_DUES_RATE',
    'SET_DUES_ALLOCATION',
    'TRANSFER',
    'CLEAR_REVIEW',
    'RESTORE_REVIEW',
    'FLAG_VOTER',
    'RESET_PASSWORD',
  ]),
  removed('Deleted & voided', ['DELETE', 'DELETE_USER', 'VOID', 'REMOVE_OFFICER']),
  uploads('Uploads & installs', ['UPLOAD_AVATAR', 'UPLOAD_HOUSE_PIC', 'UPLOAD_BLOCKLIST', 'VOTER_LIST_INSTALL']),
  access('Sign-ins & system', ['LOGIN', 'DEVICE_SETUP', 'SYSTEM_BOOT', 'SYNC_COMELEC']),
  other('Other', []);

  final String label;
  final List<String> actions;
  const LogActionGroup(this.label, this.actions);

  /// Every action code named by a group.
  static List<String> get known => [for (final g in values) ...g.actions];

  static LogActionGroup of(String action) {
    for (final g in values) {
      if (g.actions.contains(action)) return g;
    }
    return other;
  }
}

/// Record types the Audit Logs filter offers, as (label, entity_type values). Some types were
/// logged under older lower-case names, so a label can cover several values.
const logEntityGroups = <(String, List<String>)>[
  ('Households', ['Household', 'household']),
  ('Members', ['FamilyMember', 'member']),
  ('Dues payments', ['DuesPayment']),
  ('Dues settings', ['DuesRate', 'DuesAllocation', 'Barangay']),
  ('Form tracking', ['FormTracking']),
  ('Voters', ['Voter', 'VoterBlocklist', 'VoterRegistry']),
  ('Officers', ['Officer']),
  ('Locations', ['Location', 'Purok']),
  ('Users & sign-ins', ['User', 'Auth']),
  ('Devices & system', ['Device', 'System']),
];

/// What the Audit Logs screen shows: a text [query] (user, action, record type or ID), an
/// [action] group, a record type ([entity] is a label from [logEntityGroups], null for any),
/// a date [period] in GMT+8 calendar days, and the zero-based [page].
class ActivityLogFilter {
  final String query;
  final LogActionGroup action;
  final String? entity;
  final LedgerPeriod period;
  final DateTime? from;
  final DateTime? to;
  final int page;

  const ActivityLogFilter({
    this.query = '',
    this.action = LogActionGroup.all,
    this.entity,
    this.period = LedgerPeriod.all,
    this.from,
    this.to,
    this.page = 0,
  });

  bool get isFiltered =>
      query.isNotEmpty || action != LogActionGroup.all || entity != null || period != LedgerPeriod.all;

  /// First and last day (inclusive) of the period, relative to [today], or null for all time.
  ({DateTime from, DateTime to})? days(DateTime today) =>
      DuesLedgerFilter(period: period, from: from, to: to).days(today);

  /// Pass `entity: () => null` to clear the record type.
  ActivityLogFilter copyWith({
    String? query,
    LogActionGroup? action,
    String? Function()? entity,
    LedgerPeriod? period,
    DateTime? from,
    DateTime? to,
    int? page,
  }) =>
      ActivityLogFilter(
        query: query ?? this.query,
        action: action ?? this.action,
        entity: entity != null ? entity() : this.entity,
        period: period ?? this.period,
        from: from ?? this.from,
        to: to ?? this.to,
        page: page ?? this.page,
      );

  @override
  bool operator ==(Object other) =>
      other is ActivityLogFilter &&
      other.query == query &&
      other.action == action &&
      other.entity == entity &&
      other.period == period &&
      other.from == from &&
      other.to == to &&
      other.page == page;

  @override
  int get hashCode => Object.hash(query, action, entity, period, from, to, page);
}

final activityLogFilterProvider = StateProvider<ActivityLogFilter>((ref) => const ActivityLogFilter());

/// One page of activity logs matching [activityLogFilterProvider], with the total match count.
final activityLogsAsyncProvider = FutureProvider<({List<ActivityLog> logs, int total})>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final filter = ref.watch(activityLogFilterProvider);

  final days = filter.days(phToday());
  final result = await service.getActivityLogs(
    query: filter.query,
    actions: filter.action == LogActionGroup.all || filter.action == LogActionGroup.other
        ? null
        : filter.action.actions,
    excludeActions: filter.action == LogActionGroup.other ? LogActionGroup.known : null,
    entityTypes: filter.entity == null
        ? null
        : logEntityGroups.firstWhere((g) => g.$1 == filter.entity, orElse: () => (filter.entity!, [filter.entity!])).$2,
    fromDay: days?.from,
    toDay: days?.to,
    offset: filter.page * activityLogPageSize,
    limit: activityLogPageSize,
  );
  if (result.total > 0 || filter.isFiltered || filter.page > 0) return result;

  // Initial audit log items if table is brand new
  final seeds = [
    ActivityLog(
      id: 'log-seed-1',
      userId: 'usr-admin',
      userName: 'Executive Admin',
      action: 'SYSTEM_BOOT',
      entityType: 'System',
      entityId: 'tropa_v2',
      details: {'status': 'Initialized', 'version': '2.0.0+1'},
      createdAt: phNow().subtract(const Duration(minutes: 15)),
    ),
    ActivityLog(
      id: 'log-seed-2',
      userId: 'usr-admin',
      userName: 'Executive Admin',
      action: 'SYNC_COMELEC',
      entityType: 'VoterRegistry',
      entityId: 'registry-valencia',
      details: {'records_polled': 48219, 'status': 'success'},
      createdAt: phNow().subtract(const Duration(minutes: 5)),
    ),
  ];
  return (logs: seeds, total: seeds.length);
});
