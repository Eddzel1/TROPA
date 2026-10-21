import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/design_system.dart';
import '../core/geo.dart';
import '../widgets/form_fields.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../providers/voter_provider.dart';
import '../widgets/member_form_dialog.dart';
import '../widgets/transfer_member_dialog.dart';
import '../widgets/keyboard_safe_body.dart';
import 'member_id_view.dart';
import '../core/ph_time.dart';

class MembersView extends ConsumerStatefulWidget {
  const MembersView({super.key});

  @override
  ConsumerState<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends ConsumerState<MembersView> {
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  Timer? _nameDebounce;
  Household? _selectedHousehold;
  bool _isPrinting = false;

  final List<String> _sectors = [
    'General',
    'Youth',
    'Student',
    'Senior Citizen',
    'PWD',
    'LGBTQ+',
    'Solo Parent',
    'Indigenous People',
  ];

  final List<String> _statuses = [
    'MEMBER',
    'RESIDENT',
  ];

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(MemberFilter Function(MemberFilter f) change) {
    ref.read(memberFilterProvider.notifier).update((f) => change(f).copyWith(page: 0));
    ref.read(memberListNotifierProvider.notifier).refresh();
  }

  void _onNameChanged() {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 400), () {
      _applyFilter((f) => f.copyWith(
            lastName: _lastNameCtrl.text.trim(),
            firstName: _firstNameCtrl.text.trim(),
            middleName: _middleNameCtrl.text.trim(),
          ));
    });
  }

  Future<void> _printMembers(List<FamilyMember> members) async {
    if (members.isEmpty) return;
    setState(() => _isPrinting = true);
    try {
      final doc = pw.Document();
      final printedOn = formatPh(DateFormat('MMM d, yyyy h:mm a'), phNow());
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TROPA Members', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('${members.length} members  •  Printed $printedOn',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ),
          build: (_) => [
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Last Name',
                'First Name',
                'Middle Name',
                'LGU',
                'Barangay',
                'Purok',
                'Sector',
                'Status',
                'Contact'
              ],
              data: [
                for (var i = 0; i < members.length; i++)
                  [
                    '${i + 1}',
                    members[i].lastname,
                    members[i].firstname,
                    members[i].middlename ?? '',
                    members[i].lgu,
                    members[i].barangay,
                    members[i].purok,
                    members[i].sector,
                    members[i].listingStatus ?? '',
                    members[i].contactNumber ?? '',
                  ],
              ],
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(name: 'TROPA Members', onLayout: (_) => doc.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not print members: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
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

  /// Type-ahead household filter; households are looked up on the server as the user types.
  Widget _householdFilter(
      bool isDark, Color textCol, Color borderCol, Color fillCol, Color primaryCol, Color subtextCol) {
    return Autocomplete<Household>(
      key: ValueKey(_selectedHousehold?.id ?? 'all-households'),
      initialValue: TextEditingValue(text: _selectedHousehold?.householdName ?? ''),
      displayStringForOption: (h) => h.householdName,
      optionsBuilder: (value) async {
        final service = ref.read(supabaseServiceProvider);
        return service.getHouseholds(query: value.text.trim(), pageSize: 20);
      },
      onSelected: (h) {
        setState(() => _selectedHousehold = h);
        _applyFilter((f) => f.copyWith(householdId: h.id));
      },
      fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
        return TextField(
          inputFormatters: const [UpperCaseFormatter()],
          textCapitalization: TextCapitalization.characters,
          controller: ctrl,
          focusNode: focusNode,
          style: TropaText.body(textCol),
          decoration: TropaStyles.filterField(context, hint: 'All Households').copyWith(
            hintStyle: TropaText.body(textCol),
            suffixIcon: _selectedHousehold != null
                ? IconButton(
                    icon: Icon(Icons.close, size: 16, color: subtextCol),
                    tooltip: 'All Households',
                    onPressed: () {
                      setState(() => _selectedHousehold = null);
                      _applyFilter((f) => f.copyWith(clearHousehold: true));
                    },
                  )
                : Icon(Icons.keyboard_arrow_down, size: 18, color: textCol),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: TropaColors.cardOf(context),
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final h = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(h.householdName, style: TropaText.body(textCol)),
                    subtitle: Text('${h.purok}, ${h.barangay}', style: TropaText.caption(subtextCol)),
                    onTap: () => onSelected(h),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _openMemberDialog([FamilyMember? existing]) {
    showDialog(
      context: context,
      builder: (_) => MemberFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(memberFilterProvider);
    // LGU and barangay options come from the locations table; barangays narrow to the chosen LGU.
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
    final membersAsync = ref.watch(memberListNotifierProvider);
    final canDelete = ref.watch(canPermissionProvider(AppPermissions.deleteRecords));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = TropaColors.cardOf(context);
    final borderCol = TropaColors.borderOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final chipBg = TropaColors.chipOf(context);
    final primaryCol = TropaColors.primaryOf(context);
    final fieldFill = TropaColors.fieldFillOf(context);
    final counts = ref.watch(memberCountsProvider);

    final addButton = ElevatedButton.icon(
      style: TropaStyles.primaryAction(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Member'),
      onPressed: () => _openMemberDialog(),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(builder: (context, constraints) {
        // Phones and tablets: filters scroll sideways, row actions fold into a menu.
        final narrow = constraints.maxWidth < 900;
        final compact = TropaBreakpoints.isCompact(constraints.maxWidth);
        // Filter slot: shares the row on desktop, fixed width in the sideways-scrolling row.
        Widget slot(int flex, Widget child) =>
            narrow ? SizedBox(width: 56.0 * flex, child: child) : Expanded(flex: flex, child: child);

        final lastNameField = TextField(
          inputFormatters: const [UpperCaseFormatter()],
          textCapitalization: TextCapitalization.characters,
          controller: _lastNameCtrl,
          style: TropaText.body(textCol),
          decoration: TropaStyles.filterField(context, hint: 'Last Name', search: true),
          onChanged: (_) => _onNameChanged(),
        );

        final filterRow = IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  slot(
                    3,
                    _filterDropdown(
                      value: filter.lgu,
                      allLabel: 'All LGUs',
                      options: lgus,
                      onChanged: (v) => _applyFilter((f) => f.copyWith(lgu: v, barangay: 'All')),
                      isDark: isDark,
                      textCol: textCol,
                      borderCol: borderCol,
                      fillCol: fieldFill,
                      primaryCol: primaryCol,
                      subtextCol: subtextCol,
                    ),
                  ),
                  const SizedBox(width: 10),
                  slot(
                    3,
                    _filterDropdown(
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
                  const SizedBox(width: 10),
                  slot(
                    3,
                    _filterDropdown(
                      value: filter.sector,
                      allLabel: 'All Sectors',
                      options: _sectors,
                      onChanged: (v) => _applyFilter((f) => f.copyWith(sector: v)),
                      isDark: isDark,
                      textCol: textCol,
                      borderCol: borderCol,
                      fillCol: fieldFill,
                      primaryCol: primaryCol,
                      subtextCol: subtextCol,
                    ),
                  ),
                  const SizedBox(width: 10),
                  slot(
                    4,
                    _householdFilter(isDark, textCol, borderCol, fieldFill, primaryCol, subtextCol),
                  ),
                  const SizedBox(width: 10),
                  slot(
                    3,
                    _filterDropdown(
                      value: filter.listingStatus,
                      allLabel: 'All Status',
                      options: _statuses,
                      onChanged: (v) => _applyFilter((f) => f.copyWith(listingStatus: v)),
                      isDark: isDark,
                      textCol: textCol,
                      borderCol: borderCol,
                      fillCol: fieldFill,
                      primaryCol: primaryCol,
                      subtextCol: subtextCol,
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message: filter.archived ? 'Show active members' : 'Show archived members',
                      child: OutlinedButton.icon(
                        style: filter.archived
                            ? TropaStyles.secondaryAction(context)
                            : OutlinedButton.styleFrom(
                                foregroundColor: subtextCol,
                                backgroundColor: fieldFill,
                                side: BorderSide(color: borderCol),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: TropaText.body(subtextCol),
                              ),
                        icon: const Icon(Icons.archive_outlined, size: 16),
                        label: const Text('Archived'),
                        onPressed: () => _applyFilter((f) => f.copyWith(archived: !filter.archived)),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Print Members',
                    child: OutlinedButton(
                      style: TropaStyles.secondaryAction(context).copyWith(
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
                        minimumSize: const WidgetStatePropertyAll(Size.zero),
                      ),
                      onPressed: _isPrinting ? null : () => _printMembers(membersAsync.valueOrNull ?? const []),
                      child: _isPrinting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: primaryCol))
                          : const Icon(Icons.print_outlined, size: 18, semanticLabel: 'Print Members'),
                    ),
                  ),
                  if (!narrow) ...[
                    const SizedBox(width: 10),
                    addButton,
                  ],
                ],
              ),
            );

        // Typing on a phone shrinks the room below the fixed search rows; then the page scrolls.
        return KeyboardSafeBody(
        minHeight: 560,
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TROPA Members Directory', style: TropaText.pageTitle(textCol)),
                      Text('Community roster, voter verification, and mutual-aid TROPA Members',
                          style: TropaText.meta(subtextCol)),
                    ],
                  ),
                ),
                if (narrow) ...[
                  const SizedBox(width: 12),
                  addButton,
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Filters — Row 1: name search (last name gets its own line on phones)
            if (compact) ...[
              lastNameField,
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                if (!compact) ...[
                  Expanded(child: lastNameField),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: TextField(
                    inputFormatters: const [UpperCaseFormatter()],
                    textCapitalization: TextCapitalization.characters,
                    controller: _firstNameCtrl,
                    style: TropaText.body(textCol),
                    decoration: TropaStyles.filterField(context, hint: 'First Name', search: true),
                    onChanged: (_) => _onNameChanged(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    inputFormatters: const [UpperCaseFormatter()],
                    textCapitalization: TextCapitalization.characters,
                    controller: _middleNameCtrl,
                    style: TropaText.body(textCol),
                    decoration: TropaStyles.filterField(context, hint: 'Middle Name', search: true),
                    onChanged: (_) => _onNameChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filters — Row 2: location, sector, household, status + actions.
            // IntrinsicHeight + stretch gives the buttons the same height as the fields.
            if (narrow) SingleChildScrollView(scrollDirection: Axis.horizontal, child: filterRow) else filterRow,
            const SizedBox(height: 16),
            Text(
              'Showing ${NumberFormat('#,##0').format(membersAsync.valueOrNull?.length ?? 0)}${counts.matched > (membersAsync.valueOrNull?.length ?? 0) ? ' of ${NumberFormat('#,##0').format(counts.matched)}' : ''} matching out of ${NumberFormat('#,##0').format(counts.total)} ${filter.archived ? 'archived' : 'total'} members',
              style: TropaText.body(subtextCol),
            ),
            const SizedBox(height: 12),

            // Members List
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading members: $err', style: TextStyle(color: textCol))),
                data: (members) {
                  if (members.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_outlined, size: 48, color: TropaColors.textDisabled(context)),
                          const SizedBox(height: 12),
                          Text(filter.archived ? 'No archived members' : 'No members found',
                              style: TropaText.sectionTitle(textCol)),
                          const SizedBox(height: 4),
                          Text('Try broadening your search or registering a new member.',
                              style: TropaText.meta(subtextCol)),
                        ],
                      ),
                    );
                  }

                  return Container(
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
                      child: ListView.separated(
                        itemCount: members.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                        itemBuilder: (context, index) {
                          final m = members[index];
                          final actions = <({IconData icon, String label, Color? color, VoidCallback onTap})>[
                            (
                              icon: Icons.badge_outlined,
                              label: 'View TROPA ID',
                              color: null,
                              onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => MemberIdView(member: m)),
                                  ),
                            ),
                            (
                              icon: Icons.swap_horiz,
                              label: 'Transfer to Household',
                              color: null,
                              onTap: () => showDialog<bool>(
                                    context: context,
                                    builder: (_) => TransferMemberDialog(member: m),
                                  ),
                            ),
                            if (canDelete)
                              (
                                icon: m.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                label: m.isArchived ? 'Restore TROPA Member' : 'Archive TROPA Member',
                                color: null,
                                onTap: () => _toggleArchived(context, m),
                              ),
                            if (canDelete)
                              (
                                icon: Icons.delete_outline,
                                label: 'Delete TROPA Member',
                                color: TropaColors.error,
                                onTap: () => _confirmDelete(context, m),
                              ),
                          ];
                          final badges = [
                            if (m.isCooperativeMember) TropaBadge('TROPA MEMBER', color: primaryCol, icon: Icons.verified),
                            if (m.isVoter) TropaBadge('VOTER', color: TropaColors.secondaryStrongOf(context)),
                          ];
                          final editButton = IconButton(
                            icon: Icon(Icons.edit_outlined, size: 18, color: TropaColors.textMedium(context)),
                            tooltip: 'Edit TROPA Member',
                            onPressed: () => _openMemberDialog(m),
                          );
                          final meta = Text(
                            '${m.sector} • ${m.purok}, ${m.barangay} • Contact: ${m.contactNumber ?? "N/A"}',
                            style: TropaText.meta(subtextCol),
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 8),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: m.isCooperativeMember ? primaryCol.withValues(alpha: 0.15) : chipBg,
                              child: Text(
                                m.firstname.isNotEmpty ? m.firstname[0].toUpperCase() : 'M',
                                style: TextStyle(
                                  color: m.isCooperativeMember ? primaryCol : textCol,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(m.fullName,
                                      style: TropaText.bodyStrong(textCol), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                if (m.isHouseholdLeader)
                                  TropaBadge('HHL', color: TropaColors.secondaryStrongOf(context)),
                              ],
                            ),
                            // Narrow rows carry the badges under the details instead of beside the actions.
                            subtitle: narrow && badges.isNotEmpty
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      meta,
                                      const SizedBox(height: 6),
                                      Wrap(spacing: 6, runSpacing: 4, children: badges),
                                    ],
                                  )
                                : meta,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: narrow
                                  ? [
                                      editButton,
                                      PopupMenuButton<int>(
                                        icon: Icon(Icons.more_vert, size: 18, color: TropaColors.textMedium(context)),
                                        tooltip: 'More actions',
                                        onSelected: (i) => actions[i].onTap(),
                                        itemBuilder: (_) => [
                                          for (var i = 0; i < actions.length; i++)
                                            PopupMenuItem<int>(
                                              value: i,
                                              child: Row(
                                                children: [
                                                  Icon(actions[i].icon,
                                                      size: 18, color: actions[i].color ?? TropaColors.textMedium(context)),
                                                  const SizedBox(width: 12),
                                                  Text(actions[i].label, style: TextStyle(color: actions[i].color)),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ]
                                  : [
                                      for (final b in badges) ...[b, const SizedBox(width: 8)],
                                      const SizedBox(width: 2),
                                      IconButton(
                                        icon: Icon(actions[0].icon, size: 18, color: TropaColors.textMedium(context)),
                                        tooltip: actions[0].label,
                                        onPressed: actions[0].onTap,
                                      ),
                                      editButton,
                                      for (final a in actions.skip(1))
                                        IconButton(
                                          icon: Icon(a.icon, size: 18, color: a.color ?? TropaColors.textMedium(context)),
                                          tooltip: a.label,
                                          onPressed: a.onTap,
                                        ),
                                    ],
                            ),
                          );
                        },
                      ),
                    ),
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

  Future<void> _toggleArchived(BuildContext context, FamilyMember m) async {
    final cardBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final archive = !m.isArchived;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(archive ? 'Archive TROPA Member?' : 'Restore TROPA Member?',
            style: TextStyle(color: textCol)),
        content: Text(
          archive
              ? 'Archive ${m.fullName}? They will be hidden from the members list. You can restore them from the Archived filter.'
              : 'Restore ${m.fullName} to the members list?',
          style: TextStyle(color: subtextCol),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(archive ? 'Archive' : 'Restore')),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ref
        .read(memberListNotifierProvider.notifier)
        .setMemberArchived(m, archive);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '${m.fullName} ${archive ? 'archived' : 'restored'}'
          : 'Could not ${archive ? 'archive' : 'restore'} ${m.fullName}'),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, FamilyMember m) async {
    final cardBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Delete TROPA Member?', style: TextStyle(color: textCol)),
        content: Text('Delete ${m.fullName}?', style: TextStyle(color: subtextCol)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child:
                  const Text('Delete', style: TextStyle(color: TropaColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(memberListNotifierProvider.notifier).deleteMember(m.id);
    }
  }
}
