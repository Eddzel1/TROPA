import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../widgets/form_fields.dart';
import '../core/geo.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/form_tracking_provider.dart';
import '../providers/voter_provider.dart';
import '../widgets/form_tracking_dialog.dart';
import '../widgets/page_header.dart';
import '../core/ph_time.dart';

final _dateFmt = DateFormat('MMM d, y, h:mm a');
// Card dates: the year only matters for older submissions.
final _cardDateFmt = DateFormat('MMM d · h:mm a');
final _cardDateYearFmt = DateFormat('MMM d, y');

/// "JUN HERMOSURA" → "Jun Hermosura": names are stored in caps, which reads heavy on dense cards.
String _titleCase(String v) =>
    v.toLowerCase().split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

// Below this width the board scrolls sideways instead of squeezing the columns.
const _minBoardWidth = 1040.0;
const _columnGap = 18.0;

/// Accent colour of a pipeline stage, shared by column headers, card strips and menus.
Color _stageColor(BuildContext context, String status) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    FormTrackingStatus.completed => isDark ? TropaColors.secondaryOf(context) : const Color(0xFF059669),
    FormTrackingStatus.inProgress => TropaColors.primaryOf(context),
    FormTrackingStatus.returned => TropaColors.errorOf(context),
    _ => TropaColors.offline,
  };
}

class FormTrackingView extends ConsumerStatefulWidget {
  const FormTrackingView({super.key});

  @override
  ConsumerState<FormTrackingView> createState() => _FormTrackingViewState();
}

class _FormTrackingViewState extends ConsumerState<FormTrackingView> {
  void _openBatchDialog({FormTracking? existing, String? initialStatus}) {
    showDialog(context: context, builder: (_) => FormTrackingDialog(existing: existing, initialStatus: initialStatus));
  }

  /// Moves a card to another stage. Returned needs the returned-by details, so it goes through the dialog.
  Future<void> _move(FormTracking b, String status) async {
    if (b.status == status) return;
    if (status == FormTrackingStatus.returned) {
      _openBatchDialog(existing: b, initialStatus: status);
      return;
    }
    final ok = await ref.read(formBatchNotifierProvider.notifier).moveBatch(b, status);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not move submission to $status')));
    }
  }

  void _applyFilter(FormTrackingFilter Function(FormTrackingFilter) update) {
    ref.read(formTrackingFilterProvider.notifier).update(update);
    ref.read(formBatchNotifierProvider.notifier).refresh();
  }

  Widget _filterDropdown({
    required String value,
    String? allLabel,
    required List<String> options,
    required ValueChanged<String> onChanged,
    required bool isDark,
    required Color textCol,
    required Color borderCol,
    required Color fillCol,
    required Color primaryCol,
  }) {
    final style = TropaText.body(textCol);
    // Without [allLabel] there is no "All" entry (e.g. sort order), so fall back to the first option.
    final selected = options.contains(value) ? value : (allLabel == null ? options.first : 'All');
    return DropdownButtonFormField<String>(
      key: ValueKey('$allLabel-$selected'),
      initialValue: selected,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textCol),
      decoration: TropaStyles.filterField(context),
      dropdownColor: TropaColors.cardOf(context),
      style: style,
      items: [
        if (allLabel != null)
          DropdownMenuItem(value: 'All', child: Text(allLabel, style: style, overflow: TextOverflow.ellipsis)),
        ...options
            .map((o) => DropdownMenuItem(value: o, child: Text(o, style: style, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Future<void> _confirmDelete(FormTracking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete submission?'),
        content: Text('${b.numberOfForms} pcs from ${b.submittedBy} for ${b.purok}, ${b.barangay} '
            '(${formatPh(_dateFmt, b.createdAt)}) will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TropaColors.errorLight),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await ref.read(formBatchNotifierProvider.notifier).deleteBatch(b.id);
    if (!deleted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete submission')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(formBatchNotifierProvider);
    final canDelete = ref.watch(canPermissionProvider(AppPermissions.deleteRecords));
    final users = ref.watch(adminUsersProvider).valueOrNull ?? const <AppUser>[];
    final userNames = {for (final u in users) u.id: u.fullName};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final fieldFill = TropaColors.fieldFillOf(context);
    final filter = ref.watch(formTrackingFilterProvider);
    final locations = ref.watch(locationsProvider).valueOrNull ?? const <LocationOption>[];
    final lgus = ({
      for (final l in locations)
        if (l.lgu.isNotEmpty) l.lgu
    }).toList()
      ..sort();
    final barangays = ({
      for (final l in locations)
        if (l.barangay.isNotEmpty && (filter.lgu == 'All' || l.lgu == filter.lgu)) l.barangay
    }).toList()
      ..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(context.isCompactScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TropaPageHeader(
              title: 'Form Tracking & Field Intake',
              subtitle: 'Physical forms submitted per purok, who received them and who is encoding them',
              actions: [
                ElevatedButton.icon(
                  style: TropaStyles.primaryAction(context),
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('Log Form Submission'),
                  onPressed: () => _openBatchDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _filterDropdown(
                    value: filter.lgu,
                    allLabel: 'All LGUs',
                    options: lgus,
                    // Barangay list depends on the LGU, so reset it when the LGU changes
                    onChanged: (v) => _applyFilter((f) => f.copyWith(lgu: v, barangay: 'All')),
                    isDark: isDark, textCol: textCol, borderCol: borderCol, fillCol: fieldFill, primaryCol: primaryCol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filterDropdown(
                    value: filter.barangay,
                    allLabel: 'All Barangays',
                    options: barangays,
                    onChanged: (v) => _applyFilter((f) => f.copyWith(barangay: v)),
                    isDark: isDark,
                    textCol: textCol,
                    borderCol: borderCol,
                    fillCol: fieldFill,
                    primaryCol: primaryCol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filterDropdown(
                    value: filter.sort,
                    options: const [FormTrackingFilter.newestFirst, FormTrackingFilter.oldestFirst],
                    onChanged: (v) => _applyFilter((f) => f.copyWith(sort: v)),
                    isDark: isDark,
                    textCol: textCol,
                    borderCol: borderCol,
                    fillCol: fieldFill,
                    primaryCol: primaryCol,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: batchesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading submissions: $err', style: TextStyle(color: textCol))),
                data: (batches) => LayoutBuilder(
                  builder: (context, constraints) {
                    const stages = FormTrackingStatus.all;
                    final width = math.max(constraints.maxWidth, _minBoardWidth);
                    final columnWidth = (width - _columnGap * (stages.length - 1)) / stages.length;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        height: constraints.maxHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, status) in stages.indexed) ...[
                              if (i > 0) const SizedBox(width: _columnGap),
                              SizedBox(
                                width: columnWidth,
                                child: _StageColumn(
                                  status: status,
                                  items: [
                                    for (final b in batches)
                                      if (b.status == status) b
                                  ],
                                  userNames: userNames,
                                  cardWidth: columnWidth - 24,
                                  onMove: _move,
                                  onEdit: (b) => _openBatchDialog(existing: b),
                                  onDelete: canDelete ? _confirmDelete : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One pipeline stage: a header with count and form total, and a drop zone of submission cards.
class _StageColumn extends StatelessWidget {
  final String status;
  final List<FormTracking> items;
  final Map<String, String> userNames;
  final double cardWidth;
  final void Function(FormTracking, String) onMove;
  final void Function(FormTracking) onEdit;

  /// Null when the user may not delete.
  final void Function(FormTracking)? onDelete;

  const _StageColumn({
    required this.status,
    required this.items,
    required this.userNames,
    required this.cardWidth,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(context, status);
    final laneBg = TropaColors.chipOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final totalForms = items.fold(0, (sum, b) => sum + b.numberOfForms);

    return DragTarget<FormTracking>(
      onWillAcceptWithDetails: (d) => d.data.status != status,
      onAcceptWithDetails: (d) => onMove(d.data, status),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: hovering ? color.withValues(alpha: 0.08) : laneBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hovering ? color : borderCol, width: hovering ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(status.toUpperCase(),
                            style: TropaText.badge(textCol), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    TropaBadge('${items.length}', color: color),
                    const Spacer(),
                    Text('$totalForms pcs', style: TropaText.meta(subtextCol)),
                  ],
                ),
              ),
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (hovering ? color : subtextCol).withValues(alpha: 0.35)),
                          ),
                          child: Text(hovering ? 'Drop to move here' : 'No submissions',
                              style: TropaText.caption(subtextCol)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final b = items[i];
                          return _SubmissionCard(
                            batch: b,
                            assignedTo: b.encodedBy == null ? null : userNames[b.encodedBy] ?? 'Unknown user',
                            width: cardWidth,
                            onMove: (s) => onMove(b, s),
                            onEdit: () => onEdit(b),
                            onDelete: onDelete == null ? null : () => onDelete!(b),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A draggable submission card; its ⋮ menu offers the same stage moves for touch and precise use.
class _SubmissionCard extends StatelessWidget {
  final FormTracking batch;
  final String? assignedTo;
  final double width;
  final ValueChanged<String> onMove;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _SubmissionCard({
    required this.batch,
    required this.assignedTo,
    required this.width,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final body = _body(context);
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<FormTracking>(
        data: batch,
        feedback: Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: width, child: body),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: body),
        child: body,
      ),
    );
  }

  Widget _body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = TropaColors.cardOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final primaryCol = TropaColors.primaryOf(context);
    final submitted = _titleCase(batch.submittedBy);
    final received = _titleCase(batch.receivedBy);
    final createdPh = toPh(batch.createdAt);
    final date = createdPh.year == toPh(DateTime.now()).year
        ? _cardDateFmt.format(createdPh)
        : _cardDateYearFmt.format(createdPh);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Where: purok is the title, barangay and date sit under it.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch.purok,
                          style: TropaText.bodyStrong(textCol), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${batch.barangay} · $date',
                          style: TropaText.caption(subtextCol), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // How many: the one number worth scanning for.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${batch.numberOfForms}', style: TropaText.kpi(textCol, size: 18)),
                    const SizedBox(width: 3),
                    Text('pcs', style: TropaText.caption(subtextCol)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Chain of custody on one line; the tooltip has it in full when it is cut off.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Submitted by $submitted\nReceived by $received'
                  '${batch.returnedReceivedBy != null ? '\nReturned to ${_titleCase(batch.returnedReceivedBy!)}' : ''}',
              child: Row(
                children: [
                  Flexible(
                      child: Text(submitted, style: TropaText.caption(subtextCol), overflow: TextOverflow.ellipsis)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.arrow_forward, size: 12, color: subtextCol),
                  ),
                  Flexible(
                      child: Text(received, style: TropaText.caption(subtextCol), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
          if (batch.status == FormTrackingStatus.returned && batch.returnedReceivedBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Row(
                children: [
                  Icon(Icons.undo, size: 12, color: subtextCol),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Returned to ${_titleCase(batch.returnedReceivedBy!)}',
                        style: TropaText.caption(subtextCol), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Who: assignee avatar, plus the actions menu.
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: assignedTo == null ? borderCol : primaryCol.withValues(alpha: 0.12),
                child: assignedTo == null
                    ? Icon(Icons.person_outline, size: 13, color: subtextCol)
                    : Text(_initials(assignedTo!), style: TropaText.badge(primaryCol).copyWith(fontSize: 9)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assignedTo == null ? 'Not assigned' : _titleCase(assignedTo!),
                  style: assignedTo == null ? TropaText.caption(subtextCol) : TropaText.body(textCol),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _menu(context, subtextCol),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  Widget _menu(BuildContext context, Color iconCol) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: Icon(Icons.more_horiz, size: 18, color: iconCol),
      padding: EdgeInsets.zero,
      iconSize: 18,
      style: IconButton.styleFrom(minimumSize: const Size(28, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      constraints: const BoxConstraints(minWidth: 180),
      onSelected: (v) => switch (v) {
        'edit' => onEdit(),
        'delete' => onDelete?.call(),
        _ => onMove(v),
      },
      itemBuilder: (context) => [
        for (final s in FormTrackingStatus.all)
          if (s != batch.status)
            PopupMenuItem(
              value: s,
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: _stageColor(context, s)),
                  const SizedBox(width: 10),
                  Text('Move to $s'),
                ],
              ),
            ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 10), Text('Edit')]),
        ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 16, color: TropaColors.error),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: TropaColors.error)),
            ]),
          ),
      ],
    );
  }
}
