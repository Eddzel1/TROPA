import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../core/motion.dart';
import '../models/models.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_header.dart';
import '../widgets/tropa_pager.dart';
import '../providers/activity_log_provider.dart';
import '../core/ph_time.dart';

final _dayFormat = DateFormat('MMM d');

class ActivityLogsView extends ConsumerStatefulWidget {
  const ActivityLogsView({super.key});

  @override
  ConsumerState<ActivityLogsView> createState() => _ActivityLogsViewState();
}

class _ActivityLogsViewState extends ConsumerState<ActivityLogsView> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ref.read(activityLogFilterProvider).query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Any filter or search change starts again from page 1.
  void _applyFilter(ActivityLogFilter Function(ActivityLogFilter f) update) {
    ref.read(activityLogFilterProvider.notifier).update((f) => update(f).copyWith(page: 0));
  }

  void _onSearchChanged(String value) {
    setState(() {}); // show or hide the clear button
    _debounce?.cancel();
    _debounce = Timer(TropaMotion.searchDebounce, () => _applyFilter((f) => f.copyWith(query: value.trim())));
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchCtrl.clear();
    ref.read(activityLogFilterProvider.notifier).state = const ActivityLogFilter();
  }

  Future<void> _pickRange(ActivityLogFilter filter) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: phToday(),
      initialDateRange: filter.from != null && filter.to != null ? DateTimeRange(start: filter.from!, end: filter.to!) : null,
    );
    if (picked == null) return;
    _applyFilter((f) => f.copyWith(period: LedgerPeriod.custom, from: picked.start, to: picked.end));
  }

  Widget _dropdown<T>({
    required T value,
    required List<(T, String)> options,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: TropaStyles.dropdownIcon(context),
      dropdownColor: TropaColors.cardOf(context),
      style: TropaStyles.fieldText(context),
      decoration: TropaStyles.filterField(context),
      items: [
        for (final (v, label) in options)
          DropdownMenuItem(value: v, child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _filterBar(ActivityLogFilter filter, bool narrow) {
    final searchField = TextField(
      controller: _searchCtrl,
      style: TropaStyles.fieldText(context),
      decoration: TropaStyles.filterField(context, hint: 'Search by name, user, action or record ID...', search: true)
          .copyWith(
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Clear search',
                onPressed: () {
                  _debounce?.cancel();
                  _searchCtrl.clear();
                  setState(() {});
                  _applyFilter((f) => f.copyWith(query: ''));
                },
              )
            : null,
      ),
      onChanged: _onSearchChanged,
      onSubmitted: (v) {
        _debounce?.cancel();
        _applyFilter((f) => f.copyWith(query: v.trim()));
      },
    );
    final actionFilter = _dropdown<LogActionGroup>(
      value: filter.action,
      options: [for (final g in LogActionGroup.values) (g, g.label)],
      onChanged: (v) => _applyFilter((f) => f.copyWith(action: v)),
    );
    final entityFilter = _dropdown<String?>(
      value: filter.entity,
      options: [(null, 'All record types'), for (final (label, _) in logEntityGroups) (label, label)],
      onChanged: (v) => _applyFilter((f) => f.copyWith(entity: () => v)),
    );

    final customLabel = filter.period == LedgerPeriod.custom && filter.from != null && filter.to != null
        ? '${_dayFormat.format(filter.from!)} – ${_dayFormat.format(filter.to!)}'
        : 'Custom…';
    final periodChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (p, label) in [
          (LedgerPeriod.all, 'All time'),
          (LedgerPeriod.today, 'Today'),
          (LedgerPeriod.week, 'This week'),
          (LedgerPeriod.month, 'This month'),
        ])
          ChoiceChip(
            label: Text(label),
            selected: filter.period == p,
            onSelected: (_) => _applyFilter((f) => f.copyWith(period: p)),
          ),
        ChoiceChip(
          avatar: const Icon(Icons.date_range, size: 16),
          label: Text(customLabel),
          selected: filter.period == LedgerPeriod.custom,
          onSelected: (_) => _pickRange(filter),
        ),
        if (filter.isFiltered)
          TextButton.icon(
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Clear filters'),
            onPressed: _clearFilters,
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (narrow) ...[
          searchField,
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: actionFilter),
            const SizedBox(width: 10),
            Expanded(child: entityFilter),
          ]),
        ] else
          Row(children: [
            Expanded(flex: 2, child: searchField),
            const SizedBox(width: 12),
            Expanded(child: actionFilter),
            const SizedBox(width: 12),
            Expanded(child: entityFilter),
          ]),
        const SizedBox(height: 12),
        periodChips,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(activityLogFilterProvider);
    final logsAsync = ref.watch(activityLogsAsyncProvider);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = TropaColors.cardOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final payloadBg = TropaColors.subtleOf(context);

    // Phones: the action badge joins the title instead of taking a fixed leading slot.
    final compact = context.isCompactScreen;

    Widget emptyState(IconData icon, String title, String body, {Widget? action}) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: TropaColors.textDisabled(context)),
              const SizedBox(height: 12),
              Text(title, style: TropaText.sectionTitle(textCol)),
              const SizedBox(height: 4),
              Text(body, style: TropaText.meta(subtextCol), textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 12), action],
            ],
          ),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        return Padding(
          padding: EdgeInsets.all(compact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TropaPageHeader(
                title: 'Audit Logs & Mutation Inspector',
                subtitle: 'Immutable trail of all database mutations, uploads, and session authentications',
                actions: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Poll Latest Logs',
                    onPressed: () => ref.invalidate(activityLogsAsyncProvider),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _filterBar(filter, narrow),
              const SizedBox(height: 16),
              Expanded(
                child: logsAsync.when(
                  skipLoadingOnReload: true,
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('Error loading audit log: $err', style: TextStyle(color: textCol))),
                  data: (result) {
                    final logs = result.logs;
                    if (logs.isEmpty) {
                      return filter.isFiltered
                          ? emptyState(
                              Icons.search_off,
                              'Nothing matches these filters',
                              'Try a different search, action, record type or date range.',
                              action: TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
                            )
                          : emptyState(
                              Icons.receipt_long_outlined,
                              'No mutation logs recorded yet',
                              'Database operations (create, update, delete) will populate here in real-time.',
                            );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderCol),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              // Keyed by the filter: a new page or filter starts at the top with
                              // every entry closed.
                              child: ListView.separated(
                                key: ValueKey(filter),
                                itemCount: logs.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                                itemBuilder: (context, index) {
                                  final l = logs[index];
                                  final group = LogActionGroup.of(l.action);
                                  final badgeColor = switch (group) {
                                    LogActionGroup.removed => TropaColors.errorOf(context),
                                    LogActionGroup.created => TropaColors.secondaryStrongOf(context),
                                    _ => TropaColors.primaryOf(context),
                                  };

                                  return ExpansionTile(
                                    tilePadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 4),
                                    leading: compact ? null : TropaBadge(l.action, color: badgeColor),
                                    title: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (compact) TropaBadge(l.action, color: badgeColor),
                                        Text(l.entityType, style: TropaText.bodyStrong(textCol)),
                                        if (l.entityId != null)
                                          Text(
                                            '[ID: ${l.entityId!.substring(0, l.entityId!.length > 8 ? 8 : l.entityId!.length)}...]',
                                            style: TropaText.meta(subtextCol),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'By: ${l.userName} • ${formatPh(dateFormat, l.createdAt)}',
                                      style: TropaText.caption(subtextCol),
                                    ),
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: payloadBg,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: borderCol),
                                        ),
                                        child: SelectableText(
                                          [
                                            if (l.entityId != null) 'Record ID: ${l.entityId}',
                                            l.details != null
                                                ? const JsonEncoder.withIndent('  ').convert(l.details)
                                                : 'No additional payload details provided.',
                                          ].join('\n\n'),
                                          style: GoogleFonts.jetBrainsMono(
                                              fontSize: 11, color: TropaColors.primaryOf(context)),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TropaPager(
                          page: filter.page,
                          pageSize: activityLogPageSize,
                          total: result.total,
                          shown: logs.length,
                          noun: 'log entries',
                          onPage: (p) => ref.read(activityLogFilterProvider.notifier).update((f) => f.copyWith(page: p)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
