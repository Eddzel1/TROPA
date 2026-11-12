import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';
import '../core/dues_math.dart';
import '../core/motion.dart';
import '../core/ph_time.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/dues_provider.dart';
import '../providers/household_provider.dart';
import '../providers/member_provider.dart';
import 'form_fields.dart';
import 'member_form_dialog.dart';
import 'transfer_member_dialog.dart';

final _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
final _paymentDateFormat = DateFormat('MMM d, yyyy h:mm a');

class HouseholdViewDialog extends ConsumerStatefulWidget {
  final Household household;

  const HouseholdViewDialog({
    super.key,
    required this.household,
  });

  @override
  ConsumerState<HouseholdViewDialog> createState() => _HouseholdViewDialogState();
}

class _HouseholdViewDialogState extends ConsumerState<HouseholdViewDialog> {
  late Household _currentHousehold;
  List<FamilyMember> _roster = [];
  bool _isLoadingRoster = true;

  /// The household's dues receipts, newest first; null while loading.
  List<DuesReceipt>? _receipts;

  /// Payments are shown to dues collectors (and admins), within their dues scope.
  bool get _canSeePayments => ref.watch(canPermissionProvider(AppPermissions.duesCollection));

  @override
  void initState() {
    super.initState();
    _currentHousehold = widget.household;
    _fetchRoster();
    if (ref.read(canPermissionProvider(AppPermissions.duesCollection))) _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    try {
      final scope = await ref.read(duesScopeProvider.future);
      final receipts = await ref
          .read(supabaseServiceProvider)
          .getDuesReceipts(scope: scope, householdId: _currentHousehold.id, pageSize: 500);
      if (mounted) setState(() => _receipts = receipts);
    } catch (_) {
      if (mounted) setState(() => _receipts = const []);
    }
  }

  Future<void> _fetchRoster() async {
    setState(() => _isLoadingRoster = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final members = await service.getMembers(householdId: _currentHousehold.id, pageSize: 100);
      if (mounted) {
        setState(() {
          _roster = members;
          _isLoadingRoster = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoster = false);
    }
  }

  void _openAddMemberDirect() async {
    final result = await showTropaDialog<FamilyMember>(
      context: context,
      builder: (ctx) => MemberFormDialog(presetHousehold: _currentHousehold),
    );
    if (result != null) {
      _fetchRoster();
      ref.read(householdListNotifierProvider.notifier).refresh();
    }
  }

  void _openEditMember(FamilyMember member) async {
    final result = await showTropaDialog<FamilyMember>(
      context: context,
      builder: (ctx) => MemberFormDialog(existing: member, presetHousehold: _currentHousehold),
    );
    if (result != null) {
      _fetchRoster();
      ref.read(householdListNotifierProvider.notifier).refresh();
    }
  }

  void _openTransferMember(FamilyMember member) async {
    final moved = await showTropaDialog<bool>(
      context: context,
      builder: (ctx) => TransferMemberDialog(member: member),
    );
    if (moved != true || !mounted) return;
    // The household closes itself when its last member leaves (it was deleted by the transfer).
    if (_roster.length <= 1) {
      Navigator.of(context).pop();
      return;
    }
    _fetchRoster();
    // The member's dues payments go with them.
    if (_receipts != null) _fetchPayments();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = ref.watch(canPermissionProvider(AppPermissions.deleteRecords));
    final canEdit = ref.watch(canPermissionProvider(AppPermissions.manageMembers));
    final canEditHousehold = ref.watch(canPermissionProvider(AppPermissions.manageHouseholds));
    final dlgBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final cardSectionBg = TropaColors.subtleOf(context);
    final borderCol = TropaColors.borderOf(context);
    final chipBg = TropaColors.chipOf(context);
    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);

    final leader = _roster.where((m) => m.isHouseholdLeader).toList();
    final leaderName = leader.isNotEmpty ? leader.first.fullName : 'No Leader Designated';

    // Phones and tablets: overview stacks, roster badges move under the details and row actions
    // fold into a menu (a wide trailing row makes ListTile throw and blanks the dialog).
    final screen = MediaQuery.sizeOf(context);
    final compact = TropaBreakpoints.isCompact(screen.width);
    final narrow = screen.width < 900;
    final pad = compact ? 16.0 : 24.0;

    final Widget rosterList = _isLoadingRoster
        ? const Center(child: CircularProgressIndicator())
        : (_roster.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  color: cardSectionBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 40, color: TropaColors.textDisabled(context)),
                      const SizedBox(height: 10),
                      Text(
                        'No family members registered yet',
                        style: TropaText.sectionTitle(textCol),
                      ),
                      if (canEdit) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Click "Add TROPA Member" above to register dependents with pre-filled household data.',
                        style: TropaText.caption(subtextCol),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCol,
                          foregroundColor: onPrimaryCol,
                        ),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Add First TROPA Member'),
                        onPressed: _openAddMemberDirect,
                      ),
                      ],
                    ],
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: dlgBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    itemCount: _roster.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                    itemBuilder: (context, index) {
                      final m = _roster[index];
                      final badges = <Widget>[
                        if (m.isCooperativeMember)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration:
                                BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
                            child: Text('TROPA MEMBER', style: TropaText.badge(primaryCol)),
                          ),
                        if (m.isVoter)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration:
                                BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
                            child:
                                Text('VOTER', style: TropaText.badge(TropaColors.secondaryOf(context))),
                          ),
                        if (m.phicMember == true)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration:
                                BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
                            child: Text('PHIC', style: TropaText.badge(primaryCol)),
                          ),
                      ];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: m.isHouseholdLeader
                              ? TropaColors.secondaryOf(context).withValues(alpha: 0.2)
                              : chipBg,
                          child: Text(
                            m.firstname.isNotEmpty ? m.firstname[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: m.isHouseholdLeader ? TropaColors.secondaryOf(context) : primaryCol,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                m.fullName,
                                style: TropaText.bodyStrong(textCol),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (m.isHouseholdLeader)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: TropaColors.secondaryOf(context).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'LEADER',
                                  style: TropaText.badge(TropaColors.secondaryOf(context)),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.sector} · ${m.gender ?? "Gender not set"} · Age: ${m.age ?? "N/A"} · Contact: ${(m.contactNumber ?? '').trim().isEmpty ? "None" : m.contactNumber}',
                              style: TropaText.caption(subtextCol),
                            ),
                            if (narrow && badges.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(runSpacing: 4, children: badges),
                            ],
                          ],
                        ),
                        trailing: narrow
                            ? (!canEdit && !canDelete)
                                ? null
                                : PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                tooltip: 'Member actions',
                                onSelected: (v) => switch (v) {
                                  'edit' => _openEditMember(m),
                                  'transfer' => _openTransferMember(m),
                                  _ => _confirmRemove(m),
                                },
                                itemBuilder: (_) => [
                                  if (canEdit) const PopupMenuItem(value: 'edit', child: Text('Edit Dependent')),
                                  if (canEdit)
                                    const PopupMenuItem(value: 'transfer', child: Text('Transfer to Household')),
                                  if (canDelete)
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Remove from Roster',
                                            style: TextStyle(color: TropaColors.error))),
                                ],
                              )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...badges,
                            if (canEdit)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                tooltip: 'Edit Dependent',
                                onPressed: () => _openEditMember(m),
                              ),
                            if (canEdit)
                              IconButton(
                                icon: const Icon(Icons.swap_horiz, size: 16),
                                tooltip: 'Transfer to Household',
                                onPressed: () => _openTransferMember(m),
                              ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: TropaColors.error),
                                tooltip: 'Remove from Roster',
                                onPressed: () => _confirmRemove(m),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ));

    return AlertDialog(
      backgroundColor: dlgBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16) : null,
      titlePadding: EdgeInsets.fromLTRB(pad, 20, compact ? 8 : pad, 12),
      contentPadding: EdgeInsets.symmetric(horizontal: pad, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryCol.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cottage, color: primaryCol, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _currentHousehold.householdName,
                          style: TropaText.dialogTitle(textCol),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (canEditHousehold)
                        IconButton(
                          tooltip: 'Rename household',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.edit_outlined, size: 18, color: subtextCol),
                          onPressed: _renameHousehold,
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _currentHousehold.status == 'active'
                              ? TropaColors.secondaryOf(context).withValues(alpha: 0.15)
                              : chipBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentHousehold.status.toUpperCase(),
                          style: TropaText.badge(_currentHousehold.status == 'active'
                              ? TropaColors.secondaryOf(context)
                              : TropaColors.textDisabled(context)),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_currentHousehold.purok}, ${_currentHousehold.barangay}, ${_currentHousehold.lgu}',
                    style: TropaText.meta(subtextCol),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              ),
            ],
          ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: subtextCol, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 840,
        height: compact ? screen.height * 0.75 : 580,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Household Overview Metrics & House Picture
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardSectionBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  if (!compact && _currentHousehold.housePictureUrl != null && _currentHousehold.housePictureUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentHousehold.housePictureUrl!,
                        width: 90,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 70,
                          color: chipBg,
                          child: Icon(Icons.home_work, color: primaryCol),
                        ),
                      ),
                    )
                  else if (!compact)
                    Container(
                      width: 90,
                      height: 70,
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_outlined, color: TropaColors.textDisabled(context), size: 28),
                          const SizedBox(height: 4),
                          Text('No Photo', style: TropaText.caption(TropaColors.textDisabled(context))),
                        ],
                      ),
                    ),
                  if (!compact) const SizedBox(width: 16),

                  Flexible(
                    // Tight on desktop (fills beside the photo); no flex when stacked on phones.
                    flex: compact ? 0 : 1,
                    fit: compact ? FlexFit.loose : FlexFit.tight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_pin, size: 16, color: primaryCol),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Household Head: $leaderName',
                                style: TropaText.bodyStrong(textCol),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 0,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '${_roster.length} Verified Dependents',
                                style: TropaText.badge(textCol),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '${_roster.where((m) => m.isCooperativeMember).length} TROPA Members',
                                style: TropaText.badge(TropaColors.secondaryOf(context)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '${_roster.where((m) => m.isVoter).length} COMELEC Voters',
                                style: TropaText.badge(primaryCol),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (compact) const SizedBox(height: 12),

                  // Direct Registration Button
                  if (canEdit)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryCol,
                        foregroundColor: onPrimaryCol,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: Text('Add TROPA Member', style: TropaText.action()),
                      onPressed: _openAddMemberDirect,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!_canSeePayments) ...[
              // Family Roster Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 2,
                children: [
                  Text(
                    'Family Roster & Dependents (${_roster.length})',
                    style: TropaText.sectionTitle(textCol),
                  ),
                  Text(
                    'Auto-assigned to this household cluster',
                    style: TropaText.caption(subtextCol),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: rosterList),
            ] else
              // Roster and payments share the space below the overview as two tabs.
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: [
                          Tab(text: 'Family Roster (${_roster.length})'),
                          Tab(text: _receipts == null ? 'Payments' : 'Payments (${_receipts!.length})'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: TabBarView(
                          children: [rosterList, _paymentsTab(textCol, subtextCol, borderCol, dlgBg, cardSectionBg)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (canDelete)
          TextButton.icon(
            onPressed: _confirmDeleteHousehold,
            icon: const Icon(Icons.delete_outline, size: 18, color: TropaColors.error),
            label: const Text('Delete Household', style: TextStyle(color: TropaColors.error)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Deletes this household and all its members after a confirmation listing them, e.g. a household
  /// encoded twice. Not offered when it has dues payments (they'd lose their member).
  /// Renames the household. Offers the leader's name as it's spelled now ("LAST, FIRST MIDDLE
  /// SUFFIX FAMILY"), the quick fix when the name and the leader's record disagree.
  Future<void> _renameHousehold() async {
    final h = _currentHousehold;
    final leaders = _roster.where((m) => m.isHouseholdLeader).toList();
    final suggested = leaders.length == 1
        ? Household.familyNameFor(
            lastname: leaders.single.lastname,
            firstname: leaders.single.firstname,
            middlename: leaders.single.middlename,
            suffix: leaders.single.extension,
          )
        : null;
    final newName = await showTropaDialog<String>(
      context: context,
      builder: (_) => _RenameHouseholdDialog(current: h.householdName, suggested: suggested),
    );
    if (newName == null || newName == h.householdName.trim().toUpperCase() || !mounted) return;

    final renamed = h.copyWith(householdName: newName);
    final ok = await ref.read(householdListNotifierProvider.notifier).updateHousehold(renamed);
    if (!mounted) return;
    if (ok) setState(() => _currentHousehold = renamed);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Renamed to $newName' : 'Could not rename the household'),
      backgroundColor: ok ? null : TropaColors.error,
    ));
  }

  Future<void> _confirmDeleteHousehold() async {
    final deleted = await confirmAndDeleteHousehold(context, ref, _currentHousehold);
    if (deleted && mounted) Navigator.of(context).pop();
  }

  /// Totals and the receipt list for the Payments tab. Read-only: voiding stays on the Dues page.
  Widget _paymentsTab(Color textCol, Color subtextCol, Color borderCol, Color dlgBg, Color sectionBg) {
    final receipts = _receipts;
    if (receipts == null) return const Center(child: CircularProgressIndicator());
    if (receipts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: sectionBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 40, color: TropaColors.textDisabled(context)),
              const SizedBox(height: 10),
              Text('No payments recorded yet', style: TropaText.sectionTitle(textCol)),
              const SizedBox(height: 4),
              Text('Dues collected for this family on the Dues page show up here.',
                  style: TropaText.caption(subtextCol)),
            ],
          ),
        ),
      );
    }

    final paid = receipts.where((r) => !r.isVoid).toList();
    final total = paid.fold<double>(0, (sum, r) => sum + r.total);
    final accent = TropaColors.secondaryStrongOf(context);

    Widget stat(String label, String value, [Color? valueCol]) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sectionBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TropaText.caption(subtextCol)),
              Text(value,
                  style: TropaText.bodyStrong(valueCol ?? textCol)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            stat('Total paid', _peso.format(total), accent),
            stat('Receipts', '${paid.length}'),
            if (paid.isNotEmpty) stat('Last payment', formatPh(DateFormat('MMM d, yyyy'), paid.first.paymentDate)),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: dlgBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                itemCount: receipts.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                itemBuilder: (context, i) {
                  final r = receipts[i];
                  final amountCol = r.isVoid ? subtextCol : accent;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(r.isVoid ? Icons.block : Icons.receipt, color: r.isVoid ? subtextCol : accent),
                    title: Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _peso.format(r.total),
                          style: TropaText.sectionTitle(amountCol).copyWith(
                            decoration: r.isVoid ? TextDecoration.lineThrough : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(r.memberNames, style: TropaText.bodyStrong(textCol)),
                        if (r.isVoid) TropaBadge('VOID', color: TropaColors.errorOf(context)),
                      ],
                    ),
                    subtitle: Text(
                      [
                        receiptMonthsLabel(r),
                        r.paymentMethod,
                        if (r.referenceNumber != null) 'Ref ${r.referenceNumber}',
                        formatPh(_paymentDateFormat, r.paymentDate),
                        if (r.collectedBy.isNotEmpty) 'by ${r.collectedBy}',
                        if (r.isVoid && r.voidReason != null) 'Voided: ${r.voidReason}',
                      ].join(' · '),
                      style: TropaText.caption(subtextCol),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(FamilyMember m) async {
    final dlgBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final confirm = await showTropaDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: dlgBg,
        title: Text('Delete Member?', style: TextStyle(color: textCol)),
        content: Text(
            'Are you sure you want to remove ${m.fullName} from ${widget.household.householdName}?',
            style: TextStyle(color: subtextCol)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete',
                  style: TextStyle(color: TropaColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(memberListNotifierProvider.notifier).deleteMember(m.id);
      _fetchRoster();
      ref.read(householdListNotifierProvider.notifier).refresh();
    }
  }
}

/// Name field for renaming a household. Owns its controller, so the field is disposed only after
/// the dialog's closing animation (disposing it from the caller crashed mid-animation).
class _RenameHouseholdDialog extends StatefulWidget {
  final String current;

  /// The leader's name as recorded, offered as a one-click fix; null to not offer it.
  final String? suggested;

  const _RenameHouseholdDialog({required this.current, this.suggested});

  @override
  State<_RenameHouseholdDialog> createState() => _RenameHouseholdDialogState();
}

class _RenameHouseholdDialogState extends State<_RenameHouseholdDialog> {
  late final _ctrl = TextEditingController(text: widget.current);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) Navigator.pop(context, _ctrl.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final suggested = widget.suggested;
    return AlertDialog(
      backgroundColor: TropaColors.cardOf(context),
      title: Text('Rename Household', style: TextStyle(color: textCol)),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _ctrl,
                autofocus: true,
                inputFormatters: const [UpperCaseFormatter()],
                textCapitalization: TextCapitalization.characters,
                style: TropaText.body(textCol),
                decoration: TropaStyles.formField(context, hint: 'LAST, FIRST MIDDLE FAMILY'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a household name' : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (suggested != null && suggested != widget.current.trim().toUpperCase()) ...[
                const SizedBox(height: 10),
                Text("Leader's name as recorded:", style: TropaText.caption(subtextCol)),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: () => _ctrl.text = suggested,
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: Text('Use $suggested', style: TropaText.action()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Deletes [h] with all its members after confirming. Refuses a household with dues payments, and
/// lists the members first. Used by the household dialog and the Households page; never delete only
/// the household row (its members would be left behind, and Supabase refuses it, so it comes back).
/// Returns whether the household was deleted.
Future<bool> confirmAndDeleteHousehold(BuildContext context, WidgetRef ref, Household h) async {
  final service = ref.read(supabaseServiceProvider);
  final dlgBg = TropaColors.cardOf(context);
  final textCol = TropaColors.textHigh(context);
  final subtextCol = TropaColors.textMedium(context);

  final payments = await service.countHouseholdPayments(h.id);
  if (!context.mounted) return false;
  if (payments > 0) {
    await showTropaDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: dlgBg,
        title: Text("Can't delete this household", style: TextStyle(color: textCol)),
        content: Text(
          '${h.householdName} has $payments dues payment${payments == 1 ? '' : 's'}. Deleting it would '
          'leave those receipts without a member. Transfer the members or move the payments first.',
          style: TextStyle(color: subtextCol),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
    return false;
  }

  final members = await service.getHouseholdMemberRows(h.id, includeArchived: true);
  if (!context.mounted) return false;
  String name(Map<String, dynamic> m) => [
        '${m['lastname'] ?? ''},',
        m['firstname'] ?? '',
        if ((m['middlename'] ?? '').toString().trim().isNotEmpty) m['middlename'],
      ].join(' ');
  final confirm = await showTropaDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: dlgBg,
      title: Text('Delete Household?', style: TextStyle(color: textCol)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.householdName, style: TropaText.bodyStrong(textCol)),
            Text([h.purok, h.barangay, h.lgu].where((s) => s.trim().isNotEmpty).join(', '),
                style: TropaText.meta(subtextCol)),
            const SizedBox(height: 12),
            Text(
              members.isEmpty
                  ? 'This household has no members.'
                  : 'Its ${members.length} member${members.length == 1 ? '' : 's'} will be deleted too:',
              style: TextStyle(color: subtextCol),
            ),
            if (members.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final m in members)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${name(m)}${m['is_archived'] == 1 ? ' (archived)' : ''}',
                            style: TropaText.body(textCol),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'This cannot be undone. If anyone here belongs in another household, use Transfer first.',
              style: TropaText.bodyStrong(TropaColors.error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Delete Household', style: TextStyle(color: TropaColors.error)),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return false;

  try {
    await service.deleteHouseholdWithMembers(h);
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e is StateError ? e.message : 'Could not delete the household: $e'),
      backgroundColor: TropaColors.error,
    ));
    return false;
  }
  ref.read(householdListNotifierProvider.notifier).refresh();
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Deleted ${h.householdName} and ${members.length} member(s)')));
  }
  return true;
}
