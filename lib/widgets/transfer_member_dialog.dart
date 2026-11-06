import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import 'form_fields.dart';

/// Moves a member into another existing household as a regular member, e.g. when they were
/// encoded as a household leader by mistake, or out into a new household of their own as its
/// leader. Pops `true` once the transfer is saved.
class TransferMemberDialog extends ConsumerStatefulWidget {
  final FamilyMember member;

  const TransferMemberDialog({super.key, required this.member});

  @override
  ConsumerState<TransferMemberDialog> createState() => _TransferMemberDialogState();
}

class _TransferMemberDialogState extends ConsumerState<TransferMemberDialog> {
  Household? _currentHousehold;
  Household? _target;

  /// Moving out into a new household they lead, instead of joining [_target].
  bool _ownHousehold = false;
  bool _leavesEmpty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final service = ref.read(supabaseServiceProvider);
    final householdId = widget.member.householdId;
    final household = await service.getHouseholdById(householdId);
    final count = await service.countHouseholdMembers(householdId);
    if (!mounted) return;
    setState(() {
      _currentHousehold = household;
      _leavesEmpty = household != null && count <= 1;
    });
  }

  Future<void> _save() async {
    final target = _target;
    if (!_ownHousehold && target == null) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(memberListNotifierProvider.notifier);
    try {
      final String message;
      final bool deletedOld;
      if (_ownHousehold) {
        final result = await notifier.transferMemberToNewHousehold(widget.member.id);
        deletedOld = result.deletedOld;
        message = '${widget.member.fullName} now leads ${result.household.householdName}';
      } else {
        deletedOld = await notifier.transferMember(widget.member.id, target!.id);
        message = '${widget.member.fullName} moved to ${target.householdName}';
      }
      messenger.showSnackBar(SnackBar(
        content: Text('$message${deletedOld ? '; the empty household was removed.' : '.'}'),
      ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(content: Text('Transfer failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dlgBg = TropaColors.cardOf(context);
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);
    final currentName = _currentHousehold?.householdName ?? '—';
    final m = widget.member;
    final newName = Household.familyNameFor(lastname: m.lastname, firstname: m.firstname, middlename: m.middlename);

    return AlertDialog(
      backgroundColor: dlgBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Transfer to Household', style: TextStyle(color: textCol)),
      content: SizedBox(
        width: 440,
        // Scrolls when a phone keyboard leaves less room than the search and list need.
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.member.fullName, style: TropaText.body(textCol).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Current household: $currentName', style: TropaText.caption(subtextCol)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(
                    value: false,
                    icon: Icon(Icons.home_work_outlined, size: 18),
                    label: Text('Existing household'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.add_home_outlined, size: 18),
                    label: const Text('Own household'),
                    // Already alone in their household, so a new one would change nothing.
                    enabled: !_leavesEmpty,
                    tooltip: _leavesEmpty ? 'Already the only member of their household' : null,
                  ),
                ],
                selected: {_ownHousehold},
                onSelectionChanged: _isSaving ? null : (v) => setState(() => _ownHousehold = v.first),
              ),
            ),
            const SizedBox(height: 16),
            if (_ownHousehold) ...[
              _newHouseholdPreview(newName, textCol, subtextCol),
              const SizedBox(height: 12),
              Text(
                'A new household is created with this name, at the member\'s current barangay and purok, '
                'and the member becomes its leader.',
                style: TropaText.caption(subtextCol),
              ),
            ] else ...[
              _householdPicker(isDark, textCol, subtextCol),
              const SizedBox(height: 12),
              Text(
                'The member joins as a regular household member (not leader) and takes on the new household\'s barangay and purok.',
                style: TropaText.caption(subtextCol),
              ),
            ],
            if (m.isHouseholdLeader && !_leavesEmpty && _currentHousehold != null) ...[
              const SizedBox(height: 8),
              Text(
                '"$currentName" will have no leader until you set a new one.',
                style: TropaText.caption(subtextCol),
              ),
            ],
            if (_leavesEmpty && !_ownHousehold) ...[
              const SizedBox(height: 8),
              Text(
                '"$currentName" will be deleted because it has no other members.',
                style: TropaText.caption(TropaColors.error),
              ),
            ],
          ],
        ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: (!_ownHousehold && _target == null) || _isSaving ? null : _save,
          child: Text(_ownHousehold
              ? (_isSaving ? 'Creating…' : 'Create household')
              : (_isSaving ? 'Transferring…' : 'Transfer')),
        ),
      ],
    );
  }

  /// The household that "Own household" will create, shown in place of the search field.
  Widget _newHouseholdPreview(String name, Color textCol, Color subtextCol) {
    final m = widget.member;
    final place = [m.purok, m.barangay].where((p) => p.trim().isNotEmpty).join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TropaColors.fieldFillOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TropaColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.add_home_outlined, size: 18, color: subtextCol),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TropaText.bodyStrong(textCol)),
                if (place.isNotEmpty) Text(place, style: TropaText.caption(subtextCol)),
              ],
            ),
          ),
          TropaBadge('NEW', color: TropaColors.primaryOf(context)),
        ],
      ),
    );
  }

  /// Type-ahead over households, excluding the member's current one.
  Widget _householdPicker(bool isDark, Color textCol, Color subtextCol) {
    return Autocomplete<Household>(
      displayStringForOption: (h) => h.householdName,
      optionsBuilder: (value) async {
        final service = ref.read(supabaseServiceProvider);
        final results = await service.getHouseholds(query: value.text.trim(), pageSize: 20);
        return results.where((h) => h.id != widget.member.householdId);
      },
      onSelected: (h) => setState(() => _target = h),
      fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
        return TextField(
          inputFormatters: const [UpperCaseFormatter()],
          textCapitalization: TextCapitalization.characters,
          controller: ctrl,
          focusNode: focusNode,
          style: TropaText.body(textCol),
          onChanged: (_) {
            if (_target != null) setState(() => _target = null);
          },
          decoration: TropaStyles.filterField(context, hint: 'Search target household', search: true),
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
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 440),
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
}
