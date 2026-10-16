import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/design_system.dart';
import '../widgets/form_fields.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../widgets/member_form_dialog.dart';
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

  final List<String> _lgus = [
    'VALENCIA CITY',
    'MALAYBALAY CITY',
    'MARAMAG',
    'QUEZON',
  ];

  final List<String> _barangays = [
    'BANLAG',
    'POBLACION',
    'LILINGAYON',
    'BAROBO',
    'SINABUAGAN',
    'BATANGAN',
    'GUINOYORAN',
    'LURUGAN',
    'MAILAG',
    'LUMBO',
    'BAGONTAAS',
    'SINAYAWAN',
    'SUGOD',
    'PINATILAN',
    'DAGATKIDAVAO',
    'MALINAO',
    'PAMOTOLON',
  ];

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
              pw.Text('${members.length} members  •  Printed $printedOn', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ),
          build: (_) => [
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Last Name', 'First Name', 'Middle Name', 'LGU', 'Barangay', 'Purok', 'Sector', 'Status', 'Contact'],
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
      dropdownColor: isDark ? TropaColors.darkSurface8dp : Colors.white,
      style: style,
      items: [
        DropdownMenuItem(value: 'All', child: Text(allLabel, style: style, overflow: TextOverflow.ellipsis)),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: style, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  /// Type-ahead household filter; households are looked up on the server as the user types.
  Widget _householdFilter(bool isDark, Color textCol, Color borderCol, Color fillCol, Color primaryCol, Color subtextCol) {
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
            color: isDark ? TropaColors.darkSurface8dp : Colors.white,
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
    final membersAsync = ref.watch(memberListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? TropaColors.darkSurface1dp : TropaColors.lightSurface;
    final borderCol = isDark ? TropaColors.darkOutlineVariant : TropaColors.lightSurfaceHighest;
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
    final chipBg = isDark ? TropaColors.darkSurface2dp : TropaColors.lightSurfaceLow;
    final primaryCol = TropaColors.primaryOf(context);
    final fieldFill = isDark ? TropaColors.darkSurface : Colors.white;
    final counts = ref.watch(memberCountsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TROPA Members Directory', style: TropaText.pageTitle(textCol)),
                    Text('Community roster, voter verification, and mutual-aid TROPA Members', style: TropaText.meta(subtextCol)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters — Row 1: name search
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lastNameCtrl,
                    style: TropaText.body(textCol),
                    decoration: TropaStyles.filterField(context, hint: 'Last Name', search: true),
                    onChanged: (_) => _onNameChanged(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _firstNameCtrl,
                    style: TropaText.body(textCol),
                    decoration: TropaStyles.filterField(context, hint: 'First Name', search: true),
                    onChanged: (_) => _onNameChanged(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _middleNameCtrl,
                    style: TropaText.body(textCol),
                    decoration: TropaStyles.filterField(context, hint: 'Middle Name', search: true),
                    onChanged: (_) => _onNameChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filters — Row 2: location, sector, household, status + actions
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _filterDropdown(
                    value: filter.lgu,
                    allLabel: 'All LGUs',
                    options: _lgus,
                    onChanged: (v) => _applyFilter((f) => f.copyWith(lgu: v)),
                    isDark: isDark, textCol: textCol, borderCol: borderCol, fillCol: fieldFill, primaryCol: primaryCol, subtextCol: subtextCol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _filterDropdown(
                    value: filter.barangay,
                    allLabel: 'All Barangays',
                    options: _barangays,
                    onChanged: (v) => _applyFilter((f) => f.copyWith(barangay: v)),
                    isDark: isDark, textCol: textCol, borderCol: borderCol, fillCol: fieldFill, primaryCol: primaryCol, subtextCol: subtextCol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _filterDropdown(
                    value: filter.sector,
                    allLabel: 'All Sectors',
                    options: _sectors,
                    onChanged: (v) => _applyFilter((f) => f.copyWith(sector: v)),
                    isDark: isDark, textCol: textCol, borderCol: borderCol, fillCol: fieldFill, primaryCol: primaryCol, subtextCol: subtextCol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: _householdFilter(isDark, textCol, borderCol, fieldFill, primaryCol, subtextCol),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _filterDropdown(
                    value: filter.listingStatus,
                    allLabel: 'All Status',
                    options: _statuses,
                    onChanged: (v) => _applyFilter((f) => f.copyWith(listingStatus: v)),
                    isDark: isDark, textCol: textCol, borderCol: borderCol, fillCol: fieldFill, primaryCol: primaryCol, subtextCol: subtextCol,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: TropaStyles.secondaryAction(context),
                  icon: _isPrinting
                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: primaryCol))
                      : const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print Members'),
                  onPressed: _isPrinting ? null : () => _printMembers(membersAsync.valueOrNull ?? const []),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: TropaStyles.primaryAction(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Member'),
                  onPressed: () => _openMemberDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Showing ${NumberFormat('#,##0').format(membersAsync.valueOrNull?.length ?? 0)}${counts.matched > (membersAsync.valueOrNull?.length ?? 0) ? ' of ${NumberFormat('#,##0').format(counts.matched)}' : ''} matching out of ${NumberFormat('#,##0').format(counts.total)} total members',
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
                          const Icon(Icons.group_outlined, size: 48, color: TropaColors.darkOutline),
                          const SizedBox(height: 12),
                          Text('No members found', style: TropaText.sectionTitle(textCol)),
                          const SizedBox(height: 4),
                          Text('Try broadening your search or registering a new member.', style: TropaText.meta(subtextCol)),
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
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: m.isCooperativeMember
                                  ? primaryCol.withValues(alpha: 0.15)
                                  : chipBg,
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
                                Text(m.fullName, style: TropaText.bodyStrong(textCol)),
                                const SizedBox(width: 8),
                                if (m.isHouseholdLeader)
                                  TropaBadge('HHL', color: TropaColors.secondaryStrongOf(context)),
                              ],
                            ),
                            subtitle: Text(
                              '${m.sector} • ${m.purok}, ${m.barangay} • Contact: ${m.contactNumber ?? "N/A"}',
                              style: TropaText.meta(subtextCol),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (m.isCooperativeMember)
                                  TropaBadge('TROPA MEMBER', color: primaryCol, icon: Icons.verified),
                                const SizedBox(width: 8),
                                if (m.isVoter)
                                  TropaBadge('VOTER', color: TropaColors.secondaryStrongOf(context)),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? null : Colors.grey[700]),
                                  tooltip: 'Edit TROPA Member',
                                  onPressed: () => _openMemberDialog(m),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: TropaColors.error),
                                  tooltip: 'Delete TROPA Member',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        backgroundColor: cardBg,
                                        title: Text('Delete TROPA Member?', style: TextStyle(color: textCol)),
                                        content: Text('Delete ${m.fullName}?', style: TextStyle(color: subtextCol)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: TropaColors.error))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(memberListNotifierProvider.notifier).deleteMember(m.id);
                                    }
                                  },
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
      ),
    );
  }
}
