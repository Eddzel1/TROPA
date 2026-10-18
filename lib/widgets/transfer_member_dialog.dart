import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import 'form_fields.dart';

/// Moves a member into another existing household as a regular member, e.g. when they were
/// encoded as a household leader by mistake. Pops `true` once the transfer is saved.
class TransferMemberDialog extends ConsumerStatefulWidget {
  final FamilyMember member;

  const TransferMemberDialog({super.key, required this.member});

  @override
  ConsumerState<TransferMemberDialog> createState() => _TransferMemberDialogState();
}

class _TransferMemberDialogState extends ConsumerState<TransferMemberDialog> {
  Household? _currentHousehold;
  Household? _target;
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
    if (target == null) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final deletedOld =
          await ref.read(memberListNotifierProvider.notifier).transferMember(widget.member.id, target.id);
      messenger.showSnackBar(SnackBar(
        content: Text('${widget.member.fullName} moved to ${target.householdName}'
            '${deletedOld ? '; the empty household was removed.' : '.'}'),
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

    return AlertDialog(
      backgroundColor: dlgBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Transfer to Household', style: TextStyle(color: textCol)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.member.fullName, style: TropaText.body(textCol).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Current household: $currentName', style: TropaText.caption(subtextCol)),
            const SizedBox(height: 16),
            _householdPicker(isDark, textCol, subtextCol),
            const SizedBox(height: 12),
            Text(
              'The member joins as a regular household member (not leader) and takes on the new household\'s barangay and purok.',
              style: TropaText.caption(subtextCol),
            ),
            if (_leavesEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"$currentName" will be deleted because it has no other members.',
                style: TropaText.caption(TropaColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _target == null || _isSaving ? null : _save,
          child: Text(_isSaving ? 'Transferring…' : 'Transfer'),
        ),
      ],
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
