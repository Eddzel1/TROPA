import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/household_provider.dart';
import '../providers/member_provider.dart';
import 'bulk_add_member_dialog.dart';
import 'member_form_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dlgBg = isDark ? TropaColors.darkSurface8dp : TropaColors.lightSurface;
    final textCol = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface;
    final subtextCol = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
    final cardSectionBg = isDark ? TropaColors.darkSurface1dp : TropaColors.lightSurfaceLow;
    final borderCol = isDark ? TropaColors.darkOutlineVariant : TropaColors.lightSurfaceHighest;
    final chipBg = isDark ? TropaColors.darkSurface2dp : TropaColors.lightSurfaceLow;
    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);

    final leader = _roster.where((m) => m.isHouseholdLeader).toList();
    final leaderName = leader.isNotEmpty ? leader.first.fullName : 'No Leader Designated';

    return AlertDialog(
      backgroundColor: dlgBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _currentHousehold.householdName,
                        style: TropaText.dialogTitle(textCol),
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
                                : (isDark ? TropaColors.darkOutline : TropaColors.lightOutline)),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_currentHousehold.purok}, ${_currentHousehold.barangay}, ${_currentHousehold.lgu}',
                    style: TropaText.meta(subtextCol),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, color: subtextCol, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 840,
        height: 580,
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
              child: Row(
                children: [
                  if (_currentHousehold.housePictureUrl != null && _currentHousehold.housePictureUrl!.isNotEmpty)
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
                  else
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
                          const Icon(Icons.home_outlined, color: TropaColors.darkOutline, size: 28),
                          const SizedBox(height: 4),
                          Text('No Photo', style: TropaText.caption(Colors.grey)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_pin, size: 16, color: primaryCol),
                            const SizedBox(width: 6),
                            Text(
                              'Household Head: $leaderName',
                              style: TropaText.bodyStrong(textCol),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
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

                  // Direct Registration Buttons
                  Wrap(
                    direction: Axis.vertical,
                    spacing: 8,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                const Icon(Icons.people_outline, size: 40, color: TropaColors.darkOutline),
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
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                        color: m.isHouseholdLeader
                                            ? TropaColors.secondaryOf(context)
                                            : primaryCol,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        m.fullName,
                                        style: TropaText.bodyStrong(textCol),
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
                                  subtitle: Text(
                                    '${m.sector} · ${m.gender ?? "Gender not set"} · Age: ${m.age ?? "N/A"} · Contact: ${(m.contactNumber ?? '').trim().isEmpty ? "None" : m.contactNumber}',
                                    style: TropaText.caption(subtextCol),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (m.isCooperativeMember)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
                                          child: Text('TROPA MEMBER', style: TropaText.badge(primaryCol)),
                                        ),
                                      if (m.isVoter)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
                                          child: Text('VOTER', style: TropaText.badge(TropaColors.secondaryOf(context))),
                                        ),
                                      if (m.phicMember == true)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
                                          child: Text('PHIC', style: TropaText.badge(primaryCol)),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        tooltip: 'Edit Dependent',
                                        onPressed: () => _openEditMember(m),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: TropaColors.error),
                                        tooltip: 'Remove from Roster',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              backgroundColor: dlgBg,
                                              title: Text('Delete Member?', style: TextStyle(color: textCol)),
                                              content: Text('Are you sure you want to remove ${m.fullName} from ${widget.household.householdName}?', style: TextStyle(color: subtextCol)),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: TropaColors.error))),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(memberListNotifierProvider.notifier).deleteMember(m.id);
                                            _fetchRoster();
                                            ref.read(householdListNotifierProvider.notifier).refresh();
                                          }
                                        },
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
}
