import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../views/settings/settings_common.dart';
import '../core/ph_time.dart';
import 'form_fields.dart';
import 'keyboard_safe_body.dart';

/// Assigns a member to an officer position of a barangay federation or of one purok,
/// or changes the holder/position of an existing [officer].
class OfficerFormDialog extends ConsumerStatefulWidget {
  final Location location;
  final ({String id, String name})? purok;
  final String initialPosition;
  final Officer? officer;

  /// Officers already assigned at this level, used to hide unique positions that are taken.
  final List<Officer> current;

  const OfficerFormDialog({
    super.key,
    required this.location,
    this.purok,
    required this.initialPosition,
    this.officer,
    this.current = const [],
  });

  @override
  ConsumerState<OfficerFormDialog> createState() => _OfficerFormDialogState();
}

class _OfficerFormDialogState extends ConsumerState<OfficerFormDialog> {
  late String _position = widget.initialPosition;
  late String? _memberId = widget.officer?.memberId;
  late String _memberName = widget.officer?.memberName ?? '';
  late bool _onlyPurokMembers = widget.purok != null;
  String _query = '';
  List<FamilyMember> _results = [];
  bool _searching = false;
  bool _saving = false;
  Timer? _debounce;

  bool get _isNew => widget.officer == null;

  SupabaseService get _service => ref.read(supabaseServiceProvider);

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<String> get _availablePositions {
    final taken = widget.current
        .where((o) => o.id != widget.officer?.id && OfficerPositions.unique.contains(o.position))
        .map((o) => o.position)
        .toSet();
    return OfficerPositions.all.where((pos) => !taken.contains(pos)).toList();
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    final results = await _service.searchMembersForOfficer(
      widget.location,
      purokId: _onlyPurokMembers ? widget.purok?.id : null,
      query: _query,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _onQueryChanged(String v) {
    _query = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _save() async {
    if (_memberId == null) {
      showSettingsMessage(context, 'Select the member who holds this position.', error: true);
      return;
    }
    final memberId = _memberId!;
    final existing = widget.officer;
    final duplicate =
        widget.current.where((o) => o.id != existing?.id && o.memberId == memberId && o.position == _position);
    if (duplicate.isNotEmpty) {
      showSettingsMessage(context, '$_memberName is already a $_position here.', error: true);
      return;
    }

    setState(() => _saving = true);
    final now = phNow();
    try {
      await _service.saveOfficer(
        Officer(
          id: existing?.id ?? SupabaseService.uuid.v4(),
          level: widget.purok == null ? Officer.levelBarangay : Officer.levelPurok,
          locationId: widget.location.id,
          purokId: widget.purok?.id,
          position: _position,
          memberId: memberId,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
        isNew: _isNew,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final scope = widget.purok == null
        ? '${widget.location.barangay} Federation'
        : '${widget.purok!.name}, ${widget.location.barangay}';
    final positions = _availablePositions;
    if (!positions.contains(_position)) positions.insert(0, _position);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isNew ? 'Assign Officer' : 'Change Officer'),
          Text(scope, style: p.caption),
        ],
      ),
      content: SizedBox(
        width: 480,
        // Keeps its 460 px on desktop; scrolls when a phone keyboard leaves less room.
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: KeyboardSafeBody(
        minHeight: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Position *',
              child: DropdownButtonFormField<String>(
                initialValue: _position,
                style: TropaStyles.fieldText(context),
                decoration: TropaStyles.formField(context),
                items: [for (final pos in positions) DropdownMenuItem(value: pos, child: Text(pos))],
                onChanged: (v) => setState(() => _position = v ?? _position),
              ),
            ),
            const SizedBox(height: 12),
            if (_memberId != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(color: p.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.how_to_reg, size: 18, color: p.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_memberName, style: p.body.copyWith(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Member *',
              child: TextField(
                inputFormatters: const [UpperCaseFormatter()],
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                style: TropaStyles.fieldText(context),
                decoration: TropaStyles.formField(context, icon: Icons.search, hint: 'Search member by name...'),
                onChanged: _onQueryChanged,
              ),
            ),
            if (widget.purok != null)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _onlyPurokMembers,
                title: Text('Only members registered in ${widget.purok!.name}', style: p.caption),
                onChanged: (v) {
                  setState(() => _onlyPurokMembers = v ?? false);
                  _search();
                },
              ),
            const SizedBox(height: 4),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                              'No members found in this ${widget.purok == null || !_onlyPurokMembers ? 'barangay' : 'purok'}.',
                              style: p.caption))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final m = _results[i];
                            final selected = m.id == _memberId;
                            return ListTile(
                              dense: true,
                              selected: selected,
                              leading:
                                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18),
                              title: Text(m.fullName, style: p.body),
                              subtitle: Text(
                                  [m.purok, m.contactNumber].where((s) => s != null && s.isNotEmpty).join(' • '),
                                  style: p.meta),
                              onTap: () => setState(() {
                                _memberId = m.id;
                                _memberName = m.fullName;
                              }),
                            );
                          },
                        ),
            ),
          ],
        )),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_isNew ? 'Assign' : 'Save')),
      ],
    );
  }
}
