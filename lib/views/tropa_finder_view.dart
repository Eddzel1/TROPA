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
  static const _columns = [
    (label: 'LAST NAME', flex: 3),
    (label: 'FIRST NAME', flex: 3),
    (label: 'MIDDLE NAME', flex: 3),
    (label: 'EXT.', flex: 1),
    (label: 'LGU', flex: 3),
    (label: 'BARANGAY', flex: 3),
    (label: 'PUROK', flex: 2),
    (label: 'STATUS', flex: 3),
    (label: 'PC / HHL', flex: 4),
  ];

  Widget _cell(String? text, int flex, TextStyle style) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(text == null || text.isEmpty ? '—' : text, style: style, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  String _formatStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final upper = raw.trim().toUpperCase();
    if (upper == 'MEMBER' || upper == 'COOP' || upper == 'COOPERATIVE') {
      return 'TROPA MEMBER';
    }
    return raw.trim();
  }

  Widget _statusCell(String text, int flex, bool isDark, Color primaryCol, TextStyle defaultStyle) {
    if (text == '—') return _cell('—', flex, defaultStyle);
    final isTropa = text == 'TROPA MEMBER';
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

  void _applyFilter(VoterFilter Function(VoterFilter) update) {
    ref.read(voterFilterProvider.notifier).update(update);
    ref.read(voterNotifierProvider.notifier).refresh();
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

  Widget _nameField(TextEditingController ctrl, String hint, Color textCol, Color borderCol, Color fillCol, Color primaryCol, Color subtextCol) {
    return TextField(
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

  void _openFlagDialog(Voter voter) {
    final reasonCtrl = TextEditingController(text: 'Dual Precinct Registration Hold');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dlgBg = isDark ? TropaColors.darkSurface : Colors.white;
    final dlgText = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = TropaColors.primaryOf(context);
    final cardBg = isDark ? TropaColors.darkSurface1dp : Colors.white;
    final borderCol = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0);
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
    final chipBg = isDark ? TropaColors.darkSurface2dp : const Color(0xFFF1F5F9);
    final fieldFill = isDark ? TropaColors.darkSurface : Colors.white;
    final filter = ref.watch(voterFilterProvider);
    final locations = ref.watch(locationsProvider).valueOrNull ?? const [];
    final lgus = ({for (final l in locations) if (l.lgu.isNotEmpty) l.lgu}).toList()..sort();
    final barangays = ({
      for (final l in locations)
        if (l.barangay.isNotEmpty && (filter.lgu == 'All' || l.lgu == filter.lgu)) l.barangay
    }).toList()
      ..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Tropa Finder — Voter Verification', style: TropaText.pageTitle(textCol)),
                        const SizedBox(width: 10),
                        TropaBadge('COMELEC SYNC', color: TropaColors.secondaryStrongOf(context)),
                      ],
                    ),
                    Text('Real-time cross-referencing of registered voters, COMELEC precinct records, and TROPA Member status', style: TropaText.meta(subtextCol)),
                    const SizedBox(height: 4),
                    const VoterSnapshotStatusLine(),
                  ],
                ),
                OutlinedButton.icon(
                  style: TropaStyles.secondaryAction(context),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Blocklist CSV'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
                    if (result != null && result.files.first.bytes != null) {
                      final service = ref.read(supabaseServiceProvider);
                      await service.uploadVoterBlocklist(
                        bytes: result.files.first.bytes!,
                        fileName: result.files.first.name,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Uploaded ${result.files.first.name} to voter_blocklist storage bucket.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters — Row 1: name search (COMELEC `voters` table)
            Row(
              children: [
                Expanded(child: _nameField(_lastNameCtrl, 'Last Name', textCol, borderCol, fieldFill, primaryCol, subtextCol)),
                const SizedBox(width: 10),
                Expanded(child: _nameField(_firstNameCtrl, 'First Name', textCol, borderCol, fieldFill, primaryCol, subtextCol)),
                const SizedBox(width: 10),
                Expanded(child: _nameField(_middleNameCtrl, 'Middle Name', textCol, borderCol, fieldFill, primaryCol, subtextCol)),
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
                    isDark: isDark, textCol: textCol, borderCol: borderCol, fillCol: fieldFill, primaryCol: primaryCol, subtextCol: subtextCol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filterDropdown(
                    value: filter.barangay,
                    allLabel: 'All Barangays',
                    options: barangays,
                    onChanged: (v) => _applyFilter((f) => f.copyWith(barangay: v)),
                    isDark: isDark, textCol: textCol, borderCol: borderCol, fillCol: fieldFill, primaryCol: primaryCol, subtextCol: subtextCol,
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
            const SizedBox(height: 20),

            // Voter Cross-reference list
            Expanded(
              child: votersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error querying voters: $e', style: TextStyle(color: textCol))),
                data: (voters) {
                  if (voters.isEmpty) {
                    return Center(
                      child: Text('No registered voters match these filters.', style: TropaText.body(subtextCol)),
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
                      child: Column(
                        children: [
                          // Column header
                          Container(
                            color: chipBg,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                for (final c in _columns) _cell(c.label, c.flex, TropaText.tableHeader(subtextCol)),
                                const SizedBox(width: _actionWidth),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: borderCol),
                          Expanded(
                            child: ListView.separated(
                              itemCount: voters.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                              itemBuilder: (context, index) {
                                final v = voters[index];
                                final rowStyle = TropaText.body(v.isFlagged ? TropaColors.error : textCol);
                                final statusText = _formatStatus(v.status);
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
                                          width: _actionWidth,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: v.isFlagged
                                                ? const TropaBadge('HOLD', color: TropaColors.error)
                                                : OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(foregroundColor: TropaColors.error, visualDensity: VisualDensity.compact),
                                                    icon: const Icon(Icons.flag_outlined, size: 16),
                                                    label: Text('Flag', style: TropaText.action()),
                                                    onPressed: () => _openFlagDialog(v),
                                                  ),
                                          ),
                                        ),
                                      ],
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
