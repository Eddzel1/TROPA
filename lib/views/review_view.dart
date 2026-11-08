import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../core/motion.dart';
import '../core/ph_time.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../services/review_flags.dart';
import '../widgets/form_fields.dart';
import '../widgets/household_compare_dialog.dart';
import '../widgets/household_view_dialog.dart';
import '../widgets/keyboard_safe_body.dart';
import '../widgets/member_form_dialog.dart';
import '../widgets/page_header.dart';

final _dateFmt = DateFormat('MMM d, y, h:mm a');
final _count = NumberFormat('#,##0');

/// Rows shown at once; filters narrow the rest.
const _maxRows = 200;

/// For Review: households and members with likely data problems (see review_flags.dart). A
/// reviewer opens the record to fix it, or clears its problems so they stop showing here.
class ReviewView extends ConsumerStatefulWidget {
  const ReviewView({super.key});

  @override
  ConsumerState<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<ReviewView> {
  final _searchCtrl = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(reviewFilterProvider).query;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _update(ReviewFilter Function(ReviewFilter) change) =>
      ref.read(reviewFilterProvider.notifier).update(change);

  Color _flagColor(BuildContext context, ReviewFlag f) {
    if (f.cleared) return TropaColors.textDisabled(context);
    return switch (f.key) {
      ReviewFlags.duplicateHousehold || ReviewFlags.dupInHousehold || ReviewFlags.dupOtherHousehold =>
        TropaColors.errorOf(context),
      ReviewFlags.severalLeaders || ReviewFlags.mergedFamilies => TropaColors.secondaryStrongOf(context),
      _ => TropaColors.primaryOf(context),
    };
  }

  Widget _dropdown({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    final style = TropaText.body(TropaColors.textHigh(context));
    return DropdownButtonFormField<String>(
      value: options.containsKey(value) ? value : options.keys.first,
      isExpanded: true,
      icon: TropaStyles.dropdownIcon(context),
      decoration: TropaStyles.filterField(context),
      dropdownColor: TropaColors.cardOf(context),
      style: style,
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value, style: style, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Future<void> _openHousehold(String householdId) async {
    final household = await ref.read(supabaseServiceProvider).getHouseholdById(householdId);
    if (!mounted) return;
    if (household == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This household could not be found.')));
      return;
    }
    await showTropaDialog<void>(context: context, builder: (_) => HouseholdViewDialog(household: household));
  }

  Future<void> _editMember(ReviewItem item) async {
    final member = await ref.read(supabaseServiceProvider).getMemberById(item.entityId);
    if (!mounted) return;
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This member could not be found.')));
      return;
    }
    await showTropaDialog<FamilyMember>(context: context, builder: (_) => MemberFormDialog(existing: member));
  }

  Future<void> _clear(ReviewItem item) async {
    // The note, or null when cancelled.
    final note = await showTropaDialog<String>(context: context, builder: (_) => _ClearReviewDialog(item: item));
    if (note == null || !mounted) return;
    try {
      await ref.read(reviewItemsProvider.notifier).clear(item, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleared ${item.title}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear: $e'), backgroundColor: TropaColors.error),
      );
    }
  }

  Future<void> _restore(ReviewItem item) async {
    try {
      await ref.read(reviewItemsProvider.notifier).restore(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} is back for review')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not restore: $e'), backgroundColor: TropaColors.error),
      );
    }
  }

  Future<void> _showClearing(ReviewItem item) async {
    final info = await ref.read(supabaseServiceProvider).getReviewClearing(item);
    if (!mounted || info == null) return;
    final at = parsePh(info.at);
    final parts = [
      'Cleared by ${info.by?.isNotEmpty == true ? info.by : 'unknown'}',
      if (at != null) 'on ${formatPh(_dateFmt, at)}',
      if (info.note?.isNotEmpty == true) '— "${info.note}"',
    ];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(parts.join(' '))));
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reviewFilterProvider);
    final itemsAsync = ref.watch(reviewItemsProvider);
    final permissions = ref.watch(userPermissionsProvider);
    bool can(String p) => permissions.contains(AppPermissions.systemAdmin) || permissions.contains(p);
    final canEditMembers = can(AppPermissions.manageMembers);

    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final borderCol = TropaColors.borderOf(context);
    final width = MediaQuery.of(context).size.width;
    final compact = TropaBreakpoints.isCompact(width);
    final narrow = !TropaBreakpoints.isExpanded(width);

    final all = itemsAsync.valueOrNull ?? const <ReviewItem>[];
    final shown = all.where(filter.matches).toList();
    final open = all.where((i) => !i.fullyCleared).length;

    // Places and problem counts come from the flagged records themselves.
    final lgus = {for (final i in all) if (i.lgu.isNotEmpty) i.lgu.toUpperCase()}.toList()..sort();
    final barangays = {
      for (final i in all)
        if (i.barangay.isNotEmpty && (filter.lgu == 'All' || i.lgu.toUpperCase() == filter.lgu)) i.barangay.toUpperCase(),
    }.toList()
      ..sort();
    final perFlag = <String, int>{};
    for (final i in all.where(filter.matchesExceptFlag)) {
      for (final f in i.flags) {
        if (filter.showCleared || !f.cleared) perFlag[f.key] = (perFlag[f.key] ?? 0) + 1;
      }
    }

    final search = TextField(
      controller: _searchCtrl,
      inputFormatters: const [UpperCaseFormatter()],
      textCapitalization: TextCapitalization.characters,
      style: TropaText.body(textCol),
      decoration: TropaStyles.filterField(context, hint: 'Search name or household', search: true),
      onChanged: (v) => _update((f) => f.copyWith(query: v)),
    );
    final filters = [
      _dropdown(
        value: filter.kind,
        options: const {'All': 'Households & members', 'household': 'Households', 'member': 'Members'},
        onChanged: (v) => _update((f) => f.copyWith(kind: v)),
      ),
      _dropdown(
        value: filter.flag,
        options: {
          'All': 'All problems',
          for (final e in ReviewFlags.labels.entries) e.key: '${e.value} (${_count.format(perFlag[e.key] ?? 0)})',
        },
        onChanged: (v) => _update((f) => f.copyWith(flag: v)),
      ),
      _dropdown(
        value: filter.lgu,
        options: {'All': 'All LGUs', for (final l in lgus) l: l},
        onChanged: (v) => _update((f) => f.copyWith(lgu: v, barangay: 'All')),
      ),
      _dropdown(
        value: filter.barangay,
        options: {'All': 'All Barangays', for (final b in barangays) b: b},
        onChanged: (v) => _update((f) => f.copyWith(barangay: v)),
      ),
    ];
    final showCleared = FilterChip(
      label: Text('Show cleared', style: TropaText.body(textCol)),
      selected: filter.showCleared,
      onSelected: (v) => _update((f) => f.copyWith(showCleared: v)),
    );

    return KeyboardSafeBody(
      minHeight: 560,
      padding: EdgeInsets.all(compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TropaPageHeader(
            title: 'Records For Review',
            subtitle: 'Possible duplicates and household leader problems found in the records on this device',
            actions: [
              OutlinedButton.icon(
                style: TropaStyles.secondaryAction(context),
                onPressed: () => ref.read(reviewItemsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Check again'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (narrow) ...[
            search,
            const SizedBox(height: 10),
            for (final f in filters) ...[f, const SizedBox(height: 10)],
            showCleared,
          ] else ...[
            Row(children: [
              Expanded(flex: 2, child: search),
              for (final f in filters) ...[const SizedBox(width: 10), Expanded(child: f)],
              const SizedBox(width: 10),
              showCleared,
            ]),
          ],
          const SizedBox(height: 16),
          Text(
            itemsAsync.isLoading && !itemsAsync.hasValue
                ? 'Checking households and members…'
                : 'Showing ${_count.format(shown.length > _maxRows ? _maxRows : shown.length)}'
                    '${shown.length > _maxRows ? ' of ${_count.format(shown.length)}' : ''} · '
                    '${_count.format(open)} records need review',
            style: TropaText.body(subtextCol),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: itemsAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not check records: $e', style: TropaText.body(textCol))),
              data: (_) {
                if (shown.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fact_check_outlined, size: 48, color: TropaColors.textDisabled(context)),
                        const SizedBox(height: 12),
                        Text('Nothing to review', style: TropaText.sectionTitle(textCol)),
                        const SizedBox(height: 4),
                        Text(
                          all.isEmpty ? 'No problems found in the records on this device.' : 'No records match these filters.',
                          style: TropaText.meta(subtextCol),
                        ),
                      ],
                    ),
                  );
                }
                final rows = shown.take(_maxRows).toList();
                return Container(
                  decoration: BoxDecoration(
                    color: TropaColors.cardOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                      itemBuilder: (context, index) => _row(rows[index], filter, canEditMembers, compact),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ReviewItem item, ReviewFilter filter, bool canEditMembers, bool compact) {
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final primaryCol = TropaColors.primaryOf(context);
    final flags = [for (final f in item.flags) if (filter.showCleared || !f.cleared) f];
    final hasCleared = item.flags.any((f) => f.cleared);
    final relatedIds = {
      for (final f in flags)
        for (final r in f.related) r.id,
    }..remove(item.householdId);
    final place = [item.purok, item.barangay, item.lgu].where((s) => s.isNotEmpty).join(', ');
    final encoded = 'Encoded ${item.encodedOn == null ? 'on an unknown date' : formatPh(_dateFmt, item.encodedOn!)}'
        ' by ${item.encodedBy.isEmpty ? '(unknown — old system import)' : item.encodedBy}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryCol.withValues(alpha: 0.12),
            child: Icon(item.isHousehold ? Icons.cottage_outlined : Icons.person_outline, size: 18, color: primaryCol),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(item.title, style: TropaText.bodyStrong(textCol)),
                    TropaBadge(item.isHousehold ? 'HOUSEHOLD' : 'MEMBER', color: subtextCol),
                    if (item.fullyCleared) TropaBadge('CLEARED', color: TropaColors.textDisabled(context)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.isHousehold ? place : '${item.householdName} · $place',
                  style: TropaText.meta(subtextCol),
                ),
                Text(encoded, style: TropaText.meta(subtextCol)),
                const SizedBox(height: 8),
                for (final f in flags)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TropaBadge(f.cleared ? '${f.label} (cleared)' : f.label, color: _flagColor(context, f)),
                        const SizedBox(height: 2),
                        Text(
                          f.detail,
                          style: TropaText.caption(f.cleared ? TropaColors.textDisabled(context) : textCol),
                        ),
                        // The other households named in the detail, each opening in the household modal.
                        if (f.related.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: [
                              for (final r in f.related)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _openHousehold(r.id),
                                  icon: const Icon(Icons.open_in_new, size: 14),
                                  label: Text('View ${r.name}', style: TropaText.action()),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openHousehold(item.householdId),
                      icon: const Icon(Icons.home_outlined, size: 16),
                      label: Text('Open household', style: TropaText.action()),
                    ),
                    if (relatedIds.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => showTropaDialog<void>(
                          context: context,
                          builder: (_) => HouseholdCompareDialog(householdIds: [item.householdId, ...relatedIds]),
                        ),
                        icon: const Icon(Icons.compare_arrows, size: 16),
                        label: Text('Compare households', style: TropaText.action()),
                      ),
                    if (!item.isHousehold && canEditMembers)
                      TextButton.icon(
                        onPressed: () => _editMember(item),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text('Edit member', style: TropaText.action()),
                      ),
                    if (!item.fullyCleared)
                      TextButton.icon(
                        onPressed: () => _clear(item),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: Text('Clear', style: TropaText.action()),
                      ),
                    if (hasCleared && filter.showCleared) ...[
                      TextButton.icon(
                        onPressed: () => _restore(item),
                        icon: const Icon(Icons.undo, size: 16),
                        label: Text('Restore', style: TropaText.action()),
                      ),
                      TextButton.icon(
                        onPressed: () => _showClearing(item),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: Text('Who cleared', style: TropaText.action()),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirms clearing a record's problems, with an optional note. Returns the note ('' when none)
/// or null when cancelled. Owns its controller, so it's disposed only after the closing animation.
class _ClearReviewDialog extends StatefulWidget {
  final ReviewItem item;

  const _ClearReviewDialog({required this.item});

  @override
  State<_ClearReviewDialog> createState() => _ClearReviewDialogState();
}

class _ClearReviewDialogState extends State<_ClearReviewDialog> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    return AlertDialog(
      backgroundColor: TropaColors.cardOf(context),
      title: Text('Clear for review?', style: TropaText.dialogTitle(textCol)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: TropaText.bodyStrong(textCol)),
            const SizedBox(height: 8),
            Text(
              'These problems will stop showing on this page for everyone. If a different problem is '
              'found for this ${item.isHousehold ? 'household' : 'member'} later, it shows again.',
              style: TropaText.meta(subtextCol),
            ),
            const SizedBox(height: 10),
            for (final f in item.openFlags)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${f.label}', style: TropaText.body(textCol)),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: TropaText.body(textCol),
              decoration: TropaStyles.formField(context, hint: 'Note (optional), e.g. "Checked with the family"'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, _noteCtrl.text), child: const Text('Clear')),
      ],
    );
  }
}
