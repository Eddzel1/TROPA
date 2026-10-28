import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design_system.dart';
import '../widgets/form_fields.dart';
import '../models/models.dart';
import '../providers/voter_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/voter_snapshot_status.dart';
import '../widgets/page_header.dart';
import 'dues_sheet_print.dart';
import 'voter_list_print.dart';

class TropaFinderView extends ConsumerStatefulWidget {
  const TropaFinderView({super.key});

  @override
  ConsumerState<TropaFinderView> createState() => _TropaFinderViewState();
}

class _TropaFinderViewState extends ConsumerState<TropaFinderView> {
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  Timer? _nameDebounce;

  static const double _actionWidth = 96;
  /// Table columns and the `voters` column each one sorts by (PC / HHL sorts by PC).
  static const _columns = [
    (label: 'LAST NAME', flex: 3, sort: 'lastname'),
    (label: 'FIRST NAME', flex: 3, sort: 'firstname'),
    (label: 'MIDDLE NAME', flex: 3, sort: 'middlename'),
    (label: 'EXT.', flex: 1, sort: 'ext'),
    (label: 'LGU', flex: 3, sort: 'lgu'),
    (label: 'BARANGAY', flex: 3, sort: 'brgy'),
    (label: 'PUROK', flex: 2, sort: 'purok'),
    (label: 'STATUS', flex: 3, sort: 'status'),
    (label: 'PC / HHL', flex: 4, sort: 'pc'),
  ];

  /// A column header that sorts by its column; clicking the sorted column again flips the order.
  Widget _sortHeader(
      ({String label, int flex, String sort}) c, VoterFilter filter, Color subtextCol, Color primaryCol) {
    final active = filter.sortBy == c.sort;
    final color = active ? primaryCol : subtextCol;
    return Expanded(
      flex: c.flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _applyFilter((f) => f.copyWith(
                  sortBy: c.sort,
                  sortAscending: active ? !f.sortAscending : true,
                )),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(c.label, style: TropaText.tableHeader(color), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 2),
                Icon(
                  active
                      ? (filter.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 14,
                  color: active ? primaryCol : subtextCol.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String? text, int flex, TextStyle style) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(text == null || text.isEmpty ? '—' : text, style: style, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _pageBody({required bool scroll, required EdgeInsets padding, required Widget child}) =>
      scroll ? SingleChildScrollView(padding: padding, child: child) : Padding(padding: padding, child: child);

  /// Flagging voters is switched off for now; flagged voters still show HOLD.
  static const _flaggingEnabled = false;

  Widget _flagAction(Voter v) => v.isFlagged
      ? const TropaBadge('HOLD', color: TropaColors.error)
      : !_flaggingEnabled
          ? const SizedBox.shrink()
          : OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: TropaColors.error, visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.flag_outlined, size: 16),
          label: Text('Flag', style: TropaText.action()),
          onPressed: () => _openFlagDialog(v),
        );

  /// Phone/tablet row: name, location, status and PC/HHL stacked, flag action on the right.
  Widget _stackedVoterRow(Voter v, String statusText, Color textCol, Color subtextCol, Color primaryCol) {
    final nameCol = v.isFlagged ? TropaColors.error : textCol;
    final name = [
      '${v.lastname},',
      v.firstname,
      if ((v.middlename ?? '').trim().isNotEmpty) v.middlename!.trim(),
      if ((v.ext ?? '').trim().isNotEmpty) v.ext!.trim(),
    ].join(' ');
    final place = [v.purok, v.barangay, v.lgu].where((x) => (x ?? '').trim().isNotEmpty).join(', ');
    final pc = v.pc?.trim() ?? '';
    final hhl = v.hhl?.trim() ?? '';
    return Tooltip(
      message: v.isFlagged ? 'FLAG: ${v.flagReason ?? ''}' : '',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TropaText.bodyStrong(nameCol)),
                  if (place.isNotEmpty) Text(place, style: TropaText.meta(subtextCol)),
                  if (statusText != '—' || pc.isNotEmpty || hhl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (statusText != '—')
                          TropaBadge(statusText, color: statusText == 'MEMBER' ? primaryCol : subtextCol),
                        if (pc.isNotEmpty) Text('PC: $pc', style: TropaText.caption(subtextCol)),
                        if (hhl.isNotEmpty) Text('HHL: $hhl', style: TropaText.caption(subtextCol)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _flagAction(v),
          ],
        ),
      ),
    );
  }

  Widget _statusCell(String text, int flex, bool isDark, Color primaryCol, TextStyle defaultStyle) {
    if (text == '—') return _cell('—', flex, defaultStyle);
    final isTropa = text == 'MEMBER';
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: isTropa
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? primaryCol.withValues(alpha: 0.2) : primaryCol.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    text,
                    style: TropaText.badge(primaryCol),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(
                  text,
                  style: defaultStyle,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }

  Widget _pcHhlCell(String? pc, String? hhl, int flex, TextStyle style, Color subtextCol) {
    final cleanPc = pc?.trim() ?? '';
    final cleanHhl = hhl?.trim() ?? '';
    final hasPc = cleanPc.isNotEmpty;
    final hasHhl = cleanHhl.isNotEmpty;

    if (!hasPc && !hasHhl) {
      return _cell('—', flex, style);
    }

    return Expanded(
      flex: flex,
      child: Tooltip(
        message: 'PC: ${hasPc ? cleanPc : '—'}\nHHL: ${hasHhl ? cleanHhl : '—'}',
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PC: ',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: subtextCol),
                  ),
                  Flexible(
                    child: Text(
                      hasPc ? cleanPc : '—',
                      style: style.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HHL: ',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: subtextCol),
                  ),
                  Flexible(
                    child: Text(
                      hasHhl ? cleanHhl : '—',
                      style: style.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final filter = ref.read(voterFilterProvider);
    _lastNameCtrl.text = filter.lastName;
    _firstNameCtrl.text = filter.firstName;
    _middleNameCtrl.text = filter.middleName;
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    super.dispose();
  }

  /// Applies a filter change and goes back to the first page.
  void _applyFilter(VoterFilter Function(VoterFilter) update) {
    ref.read(voterFilterProvider.notifier).update((f) => update(f).copyWith(page: 0));
    ref.read(voterNotifierProvider.notifier).refresh();
  }

  void _goToPage(int page) {
    ref.read(voterFilterProvider.notifier).update((f) => f.copyWith(page: page));
    ref.read(voterNotifierProvider.notifier).refresh();
  }

  /// Opens the print preview at once and lists every voter matching the current filters (not just
  /// this page), up to [voterPrintLimit]; the voters load behind the preview's spinner.
  void _printList() {
    final f = ref.read(voterFilterProvider);
    // Read once and shared by every paper size the preview builds
    final fetched = ref.read(supabaseServiceProvider).getVoters(
          lastName: f.lastName,
          firstName: f.firstName,
          middleName: f.middleName,
          lgu: f.lgu,
          barangay: f.barangay,
          flaggedOnly: f.flaggedOnly,
          status: f.status,
          notTropaMember: f.notTropaMember,
          // One extra row tells whether the list was cut short
          limit: voterPrintLimit + 1,
          sortBy: f.sortBy,
          sortAscending: f.sortAscending,
        );
    final filtersLabel = [
      f.barangay == 'All' ? 'All barangays' : f.barangay,
      f.lgu == 'All' ? 'All LGUs' : f.lgu,
      f.status == 'All' ? 'MEMBER / HHL / PC' : f.status,
      if (f.notTropaMember) 'Not member',
      if ([f.lastName, f.firstName, f.middleName].any((s) => s.isNotEmpty))
        'Name: ${[f.lastName, f.firstName, f.middleName].where((s) => s.isNotEmpty).join(' ')}',
    ].join('  •  ');
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DuesSheetPreview(
        title: 'Voter List · ${f.barangay == 'All' ? 'All barangays' : f.barangay}',
        build: (format) async {
          final voters = await fetched;
          return buildVoterList(
            voters: voters.take(voterPrintLimit).toList(),
            filtersLabel: filtersLabel,
            truncated: voters.length > voterPrintLimit,
            format: format,
          );
        },
      ),
    ));
  }

  /// Footer with the shown row range and previous/next page buttons.
  Widget _pager(VoterFilter filter, int shown, bool hasNext, Color borderCol, Color subtextCol) {
    final first = filter.page * voterPageSize + 1;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: borderCol))),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text('Page ${filter.page + 1} · rows $first–${first + shown - 1}',
                style: TropaText.meta(subtextCol)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
            onPressed: filter.page > 0 ? () => _goToPage(filter.page - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next page',
            onPressed: hasNext ? () => _goToPage(filter.page + 1) : null,
          ),
        ],
      ),
    );
  }

  void _onNameChanged() {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 400), _applyNames);
  }

  void _applyNames() {
    _nameDebounce?.cancel();
    _applyFilter((f) => f.copyWith(
          lastName: _lastNameCtrl.text.trim(),
          firstName: _firstNameCtrl.text.trim(),
          middleName: _middleNameCtrl.text.trim(),
        ));
  }

  Widget _nameField(TextEditingController ctrl, String hint, Color textCol, Color borderCol, Color fillCol,
      Color primaryCol, Color subtextCol) {
    return TextField(
      inputFormatters: const [UpperCaseFormatter()],
      textCapitalization: TextCapitalization.characters,
      controller: ctrl,
      style: TropaText.body(textCol),
      decoration: TropaStyles.filterField(context, hint: hint, search: true),
      onChanged: (_) => _onNameChanged(),
      onSubmitted: (_) => _applyNames(),
    );
  }

  Widget _filterDropdown({
    required String value,
    required String allLabel,
    required List<String> options,
    required ValueChanged<String> onChanged,
    required bool isDark,
    required Color textCol,
    required Color borderCol,
    required Color fillCol,
    required Color primaryCol,
    required Color subtextCol,
  }) {
    final style = TropaText.body(textCol);
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : 'All',
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textCol),
      decoration: TropaStyles.filterField(context),
      dropdownColor: TropaColors.cardOf(context),
      style: style,
      items: [
        DropdownMenuItem(value: 'All', child: Text(allLabel, style: style, overflow: TextOverflow.ellipsis)),
        ...options
            .map((o) => DropdownMenuItem(value: o, child: Text(o, style: style, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  void _openFlagDialog(Voter voter) {
    final reasonCtrl = TextEditingController(text: 'Dual Precinct Registration Hold');
    final dlgBg = TropaColors.cardOf(context);
    final dlgText = TropaColors.textHigh(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dlgBg,
        title: Text('Flag Voter Record', style: TropaText.dialogTitle(TropaColors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add ${voter.fullName} to Discrepancy Watchlist.', style: TropaText.body(dlgText)),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Flagging Audit Reason *',
              child: TextField(
                inputFormatters: const [UpperCaseFormatter()],
                textCapitalization: TextCapitalization.characters,
                style: TropaStyles.fieldText(context),
                controller: reasonCtrl,
                decoration: TropaStyles.formField(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TropaColors.error, foregroundColor: Colors.black),
            onPressed: () async {
              await ref.read(voterNotifierProvider.notifier).flagVoter(voter.id, reasonCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Flag / Hold Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final votersAsync = ref.watch(voterNotifierProvider);
    final compact = context.isCompactScreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final cardBg = TropaColors.cardOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final chipBg = TropaColors.chipOf(context);
    final fieldFill = TropaColors.fieldFillOf(context);
    final filter = ref.watch(voterFilterProvider);
    final locations = ref.watch(locationsProvider).valueOrNull ?? const [];
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
      // Phones scroll the whole page so the header and filters move out of the way of the results.
      body: _pageBody(
        scroll: compact,
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TropaPageHeader(
              title: 'Tropa Finder — Voter Verification',
              titleTrailing: TropaBadge('COMELEC SYNC', color: TropaColors.secondaryStrongOf(context)),
              subtitle:
                  'Real-time cross-referencing of registered voters, COMELEC precinct records, and TROPA Member status',
              below: const [SizedBox(height: 4), VoterSnapshotStatusLine()],
              actions: [
                OutlinedButton.icon(
                  style: TropaStyles.secondaryAction(context),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print List'),
                  onPressed: _printList,
                ),
                OutlinedButton.icon(
                  style: TropaStyles.secondaryAction(context),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Blocklist CSV'),
                  onPressed: () async {
                    final result =
                        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
                    if (result != null && result.files.first.bytes != null) {
                      final service = ref.read(supabaseServiceProvider);
                      await service.uploadVoterBlocklist(
                        bytes: result.files.first.bytes!,
                        fileName: result.files.first.name,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Uploaded ${result.files.first.name} to voter_blocklist storage bucket.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters — Row 1: name search (COMELEC `voters` table)
            if (compact) ...[
              _nameField(_lastNameCtrl, 'Last Name', textCol, borderCol, fieldFill, primaryCol, subtextCol),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                if (!compact) ...[
                  Expanded(
                      child: _nameField(
                          _lastNameCtrl, 'Last Name', textCol, borderCol, fieldFill, primaryCol, subtextCol)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                    child: _nameField(
                        _firstNameCtrl, 'First Name', textCol, borderCol, fieldFill, primaryCol, subtextCol)),
                const SizedBox(width: 10),
                Expanded(
                    child: _nameField(
                        _middleNameCtrl, 'Middle Name', textCol, borderCol, fieldFill, primaryCol, subtextCol)),
              ],
            ),
            const SizedBox(height: 10),

            // Filters — Row 2: location + refresh
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
                    subtextCol: subtextCol,
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
                    subtextCol: subtextCol,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Poll COMELEC Registry',
                  onPressed: () => ref.read(voterNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filters — Row 3: listing status + not-yet-member prospects
            Row(
              children: [
                Expanded(
                  child: _filterDropdown(
                    value: filter.status,
                    allLabel: 'All Statuses',
                    options: const ['MEMBERS', 'HHL', 'PC'],
                    onChanged: (v) => _applyFilter((f) => f.copyWith(status: v)),
                    isDark: isDark,
                    textCol: textCol,
                    borderCol: borderCol,
                    fillCol: fieldFill,
                    primaryCol: primaryCol,
                    subtextCol: subtextCol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      label: Text('Not member', style: TropaText.body(textCol)),
                      tooltip: 'Voters with no matching cooperative member record',
                      selected: filter.notTropaMember,
                      onSelected: (sel) => _applyFilter((f) => f.copyWith(notTropaMember: sel)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Voter Cross-reference list
            Flexible(
              flex: compact ? 0 : 1,
              fit: compact ? FlexFit.loose : FlexFit.tight,
              child: votersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error querying voters: $e', style: TextStyle(color: textCol))),
                data: (fetched) {
                  // The notifier fetches one row past the page to know whether a next page exists
                  final hasNext = fetched.length > voterPageSize;
                  final voters = fetched.take(voterPageSize).toList();
                  if (voters.isEmpty && filter.page > 0) {
                    return Center(
                      child: TextButton(onPressed: () => _goToPage(0), child: const Text('Back to first page')),
                    );
                  }
                  if (voters.isEmpty) {
                    return Center(
                      child: Text(
                          filter.notTropaMember
                              ? 'No non-members match these filters.'
                              : 'No MEMBER / HHL / PC voters match these filters.',
                          style: TropaText.body(subtextCol)),
                    );
                  }
                  // Ten columns need ~1000px; narrower screens show each voter as a stacked row.
                  return LayoutBuilder(builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 1000;
                    return Container(
                    height: compact ? null : constraints.maxHeight,
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
                      child: Column(
                        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                        children: [
                          // Column header
                          if (!stacked) ...[
                          Container(
                            color: chipBg,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                for (final c in _columns) _sortHeader(c, filter, subtextCol, primaryCol),
                                const SizedBox(width: _flaggingEnabled ? _actionWidth : 64),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: borderCol),
                          ],
                          Flexible(
                            flex: compact ? 0 : 1,
                            fit: compact ? FlexFit.loose : FlexFit.tight,
                            child: ListView.separated(
                              // At most one page of rows, so phones lay them all out inside the page scroll.
                              shrinkWrap: compact,
                              physics: compact ? const NeverScrollableScrollPhysics() : null,
                              itemCount: voters.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                              itemBuilder: (context, index) {
                                final v = voters[index];
                                final rowStyle = TropaText.body(v.isFlagged ? TropaColors.error : textCol);
                                final statusText = formatVoterStatus(v.status);
                                if (stacked) return _stackedVoterRow(v, statusText, textCol, subtextCol, primaryCol);
                                return Tooltip(
                                  message: v.isFlagged ? 'FLAG: ${v.flagReason ?? ''}' : '',
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    child: Row(
                                      children: [
                                        _cell(v.lastname, 3, rowStyle.copyWith(fontWeight: FontWeight.w600)),
                                        _cell(v.firstname, 3, rowStyle.copyWith(fontWeight: FontWeight.w600)),
                                        _cell(v.middlename, 3, rowStyle),
                                        _cell(v.ext, 1, rowStyle),
                                        _cell(v.lgu, 3, rowStyle),
                                        _cell(v.barangay, 3, rowStyle),
                                        _cell(v.purok, 2, rowStyle),
                                        _statusCell(statusText, 3, isDark, primaryCol, rowStyle),
                                        _pcHhlCell(v.pc, v.hhl, 4, rowStyle, subtextCol),
                                        SizedBox(
                                          width: _flaggingEnabled ? _actionWidth : 64,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: _flagAction(v),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (filter.page > 0 || hasNext)
                            _pager(filter, voters.length, hasNext, borderCol, subtextCol),
                        ],
                      ),
                    ),
                  );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
