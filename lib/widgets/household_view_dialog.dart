import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/household_provider.dart';
import '../providers/member_provider.dart';
import 'bulk_add_member_dialog.dart';
import 'member_form_dialog.dart';
import 'transfer_member_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _currentHousehold = widget.household;
    _fetchRoster();
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
    final result = await showDialog<FamilyMember>(
      context: context,
      builder: (ctx) => MemberFormDialog(presetHousehold: _currentHousehold),
    );
    if (result != null) {
      _fetchRoster();
      ref.read(householdListNotifierProvider.notifier).refresh();
    }
  }

  void _openBulkAddDirect() async {
    final result = await showDialog<List<FamilyMember>>(
      context: context,
      builder: (ctx) => BulkAddMemberDialog(presetHousehold: _currentHousehold),
    );
    if (result != null && result.isNotEmpty) {
      _fetchRoster();
      ref.read(householdListNotifierProvider.notifier).refresh();
    }
  }

  void _openEditMember(FamilyMember member) async {
    final result = await showDialog<FamilyMember>(
      context: context,
      builder: (ctx) => MemberFormDialog(existing: member, presetHousehold: _currentHousehold),
    );
    if (result != null) {
      _fetchRoster();
      ref.read(householdListNotifierProvider.notifier).refresh();
    }
  }

  void _openTransferMember(FamilyMember member) async {
    final moved = await showDialog<bool>(
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
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = ref.watch(canPermissionProvider(AppPermissions.deleteRecords));
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
                          Text('No Photo', style: TropaText.caption(Colors.grey)),
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

                  // Direct Registration Buttons
                  Wrap(
                    direction: compact ? Axis.horizontal : Axis.vertical,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.table_chart, size: 16),
                        label: Text('Bulk Add', style: TropaText.action()),
                        onPressed: _openBulkAddDirect,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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

            // Family Roster Table / List
            Expanded(
              child: _isLoadingRoster
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
                                const SizedBox(height: 4),
                                Text(
                                  'Click "Add Member" or "Bulk Add" above to register dependents with pre-filled household data.',
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
                                      ? PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 18),
                                          tooltip: 'Member actions',
                                          onSelected: (v) => switch (v) {
                                            'edit' => _openEditMember(m),
                                            'transfer' => _openTransferMember(m),
                                            _ => _confirmRemove(m),
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(value: 'edit', child: Text('Edit Dependent')),
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
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        tooltip: 'Edit Dependent',
                                        onPressed: () => _openEditMember(m),
                                      ),
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
                        )),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(FamilyMember m) async {
    final dlgBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final confirm = await showDialog<bool>(
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
