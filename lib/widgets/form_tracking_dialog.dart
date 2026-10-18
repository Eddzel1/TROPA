import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../core/design_system.dart';
import '../core/geo.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/form_tracking_provider.dart';
import '../providers/voter_provider.dart';
import '../core/ph_time.dart';
import 'form_fields.dart';

/// One purok line of a new submission; each becomes its own `form_tracking` row.
class _PurokEntry {
  String? purok;
  final TextEditingController count;

  _PurokEntry({this.purok, int? forms}) : count = TextEditingController(text: forms?.toString() ?? '');
}

/// Creates submissions (LGU → barangay → one or more puroks with form counts), or edits one row
/// when [existing] is given (a single purok, no "Add Purok").
class FormTrackingDialog extends ConsumerStatefulWidget {
  final FormTracking? existing;

  /// Preselected status, e.g. Returned when a card is dropped on that pipeline stage.
  final String? initialStatus;

  const FormTrackingDialog({super.key, this.existing, this.initialStatus});

  @override
  ConsumerState<FormTrackingDialog> createState() => _FormTrackingDialogState();
}

class _FormTrackingDialogState extends ConsumerState<FormTrackingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _submittedBy;
  late final TextEditingController _returnedReceivedBy;
  late final List<_PurokEntry> _entries;
  String? _lgu;
  String? _locationId;
  String? _encodedBy;
  String? _returnedReleasedBy;
  late String _status;
  bool _locationResolved = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _submittedBy = TextEditingController(text: e?.submittedBy ?? '');
    _returnedReceivedBy = TextEditingController(text: e?.returnedReceivedBy ?? '');
    _entries = [_PurokEntry(purok: e?.purok, forms: e?.numberOfForms)];
    _encodedBy = e?.encodedBy;
    _returnedReleasedBy = e?.returnedReleasedBy;
    _status = widget.initialStatus ?? e?.status ?? FormTrackingStatus.pending;
  }

  @override
  void dispose() {
    _submittedBy.dispose();
    _returnedReceivedBy.dispose();
    for (final e in _entries) {
      e.count.dispose();
    }
    super.dispose();
  }

  /// When editing, pick the LGU/barangay of the stored barangay name once locations load.
  void _resolveLocation(List<LocationOption> locations) {
    if (_locationResolved || locations.isEmpty) return;
    _locationResolved = true;
    final barangay = widget.existing?.barangay.trim().toUpperCase();
    if (barangay == null) return;
    for (final l in locations) {
      if (l.barangay == barangay) {
        _lgu = l.lgu;
        _locationId = l.id;
        return;
      }
    }
  }

  Future<void> _save(List<LocationOption> locations, String receivedBy) async {
    if (_formKey.currentState?.validate() != true) return;
    final location = locations.firstWhere((l) => l.id == _locationId);
    final returned = _status == FormTrackingStatus.returned;
    final returnedTo = _returnedReceivedBy.text.trim().toUpperCase();
    final now = phNow();

    FormTracking build(_PurokEntry entry, {FormTracking? existing}) => FormTracking(
          id: existing?.id ?? const Uuid().v4(),
          barangay: location.barangay,
          purok: entry.purok!,
          numberOfForms: int.parse(entry.count.text.trim()),
          submittedBy: _submittedBy.text.trim().toUpperCase(),
          receivedBy: existing?.receivedBy ?? receivedBy.toUpperCase(),
          encodedBy: _encodedBy,
          status: _status,
          returnedReleasedBy: returned ? _returnedReleasedBy : null,
          returnedReceivedBy: returned && returnedTo.isNotEmpty ? returnedTo : null,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        );

    setState(() => _saving = true);
    final notifier = ref.read(formBatchNotifierProvider.notifier);
    final ok = _isEdit
        ? await notifier.updateBatch(build(_entries.single, existing: widget.existing))
        : await notifier.createBatches([for (final e in _entries) build(e)]);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save form tracking')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryCol = TropaColors.primaryOf(context);
    final onPrimaryCol = TropaColors.onPrimaryOf(context);
    final dlgBg = TropaColors.cardOf(context);
    final dlgText = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);

    final locations = ref.watch(locationsProvider).valueOrNull ?? const <LocationOption>[];
    _resolveLocation(locations);
    final users = ref.watch(adminUsersProvider).valueOrNull ?? const <AppUser>[];
    final receivedBy = widget.existing?.receivedBy ?? ref.watch(currentAppUserProvider).valueOrNull?.fullName ?? '';

    final lgus = ({
      for (final l in locations)
        if (l.lgu.isNotEmpty) l.lgu
    }).toList()
      ..sort();
    final barangays = locations.where((l) => l.lgu == _lgu && l.barangay.isNotEmpty).toList()
      ..sort((a, b) => a.barangay.compareTo(b.barangay));
    final puroks = _locationId == null
        ? const <String>[]
        : <String>[
            for (final p in ref.watch(puroksProvider(_locationId!)).valueOrNull ?? const <({String id, String name})>[])
              p.name
          ];

    // A stored id/name missing from the current lists would make the dropdown assert; drop it.
    String? known(String? v, Iterable<String> options) => options.contains(v) ? v : null;
    final userIds = users.map((u) => u.id);
    final userItems = [
      const DropdownMenuItem<String?>(value: null, child: Text('Not Assigned')),
      for (final u in users) DropdownMenuItem<String?>(value: u.id, child: Text(u.fullName)),
    ];
    String? required(Object? v) => v == null || (v is String && v.trim().isEmpty) ? 'Required' : null;

    // Compact fields: the app theme's inputs are sized for full pages, too large for this form.
    final theme = Theme.of(context);
    final fieldText = TropaText.body(dlgText);
    final compactTheme = theme.copyWith(
      visualDensity: VisualDensity.compact,
      textTheme: theme.textTheme.copyWith(titleMedium: fieldText, bodyLarge: fieldText),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: TropaText.body(subtextCol),
        floatingLabelStyle: TropaText.meta(subtextCol),
        hintStyle: TropaText.body(subtextCol),
        helperStyle: TropaText.caption(subtextCol),
        errorStyle: GoogleFonts.inter(fontSize: 11),
      ),
    );

    return Theme(
      data: compactTheme,
      child: AlertDialog(
        backgroundColor: dlgBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        title: Text(_isEdit ? 'Edit Form Tracking' : 'New Form Tracking', style: TropaText.dialogTitle(dlgText)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: 'LGU *',
                    child: DropdownButtonFormField<String>(
                      style: TropaStyles.fieldText(context),
                      key: ValueKey('lgu-$_lgu'),
                      initialValue: known(_lgu, lgus),
                      isExpanded: true,
                      decoration: TropaStyles.formField(context),
                      hint: const Text('Select LGU'),
                      items: [for (final l in lgus) DropdownMenuItem(value: l, child: Text(l))],
                      validator: required,
                      onChanged: (v) => setState(() {
                        _lgu = v;
                        _locationId = null;
                        for (final e in _entries) {
                          e.purok = null;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Barangay *',
                    child: DropdownButtonFormField<String>(
                      style: TropaStyles.fieldText(context),
                      key: ValueKey('brgy-$_lgu-$_locationId'),
                      initialValue: known(_locationId, barangays.map((l) => l.id)),
                      isExpanded: true,
                      decoration: TropaStyles.formField(context),
                      hint: Text(_lgu == null ? 'Select LGU first' : 'Select barangay'),
                      items: [for (final l in barangays) DropdownMenuItem(value: l.id, child: Text(l.barangay))],
                      validator: required,
                      onChanged: _lgu == null
                          ? null
                          : (v) => setState(() {
                                _locationId = v;
                                for (final e in _entries) {
                                  e.purok = null;
                                }
                              }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_isEdit ? 'Purok & Form Count' : 'Puroks & Form Counts',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: dlgText)),
                      ),
                      if (!_isEdit)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Purok'),
                          onPressed: _locationId == null ? null : () => setState(() => _entries.add(_PurokEntry())),
                        ),
                    ],
                  ),
                  for (var i = 0; i < _entries.length; i++) _purokRow(i, puroks, required),
                  const SizedBox(height: 10),
                  ResponsiveFieldRow(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Submitted By *',
                          child: TextFormField(
                            inputFormatters: const [UpperCaseFormatter()],
                            textCapitalization: TextCapitalization.characters,
                            style: TropaStyles.fieldText(context),
                            controller: _submittedBy,
                            decoration: TropaStyles.formField(context),
                            validator: required,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Received By',
                          child: TextFormField(
                            style: TropaStyles.fieldText(context),
                            key: ValueKey('received-$receivedBy'),
                            initialValue: receivedBy,
                            enabled: false,
                            decoration: TropaStyles.formField(context,
                                helper: _isEdit ? null : 'Automatically tracked to current user.'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Assigned To',
                    child: DropdownButtonFormField<String?>(
                      style: TropaStyles.fieldText(context),
                      initialValue: known(_encodedBy, userIds),
                      isExpanded: true,
                      decoration: TropaStyles.formField(context, helper: 'Select a user to assign this batch to.'),
                      items: userItems,
                      onChanged: (v) => setState(() => _encodedBy = v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Status',
                    child: DropdownButtonFormField<String>(
                      style: TropaStyles.fieldText(context),
                      initialValue: _status,
                      isExpanded: true,
                      decoration: TropaStyles.formField(context),
                      items: [for (final s in FormTrackingStatus.all) DropdownMenuItem(value: s, child: Text(s))],
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
                  ),
                  if (_status == FormTrackingStatus.returned) ...[
                    const SizedBox(height: 10),
                    ResponsiveFieldRow(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'Returned - Released By',
                            child: DropdownButtonFormField<String?>(
                              style: TropaStyles.fieldText(context),
                              initialValue: known(_returnedReleasedBy, userIds),
                              isExpanded: true,
                              decoration: TropaStyles.formField(context),
                              items: userItems,
                              onChanged: (v) => setState(() => _returnedReleasedBy = v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: 'Returned - Received By',
                            child: TextFormField(
                              inputFormatters: const [UpperCaseFormatter()],
                              textCapitalization: TextCapitalization.characters,
                              style: TropaStyles.fieldText(context),
                              controller: _returnedReceivedBy,
                              decoration: TropaStyles.formField(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryCol, foregroundColor: onPrimaryCol),
            onPressed: _saving ? null : () => _save(locations, receivedBy),
            child: Text(_isEdit ? 'Save Changes' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _purokRow(int i, List<String> puroks, String? Function(Object?) required) {
    final entry = _entries[i];
    // Each purok can be picked once; keep the stored purok selectable when editing an old row.
    final taken = {
      for (final e in _entries)
        if (e != entry && e.purok != null) e.purok!
    };
    final options = [
      for (final p in puroks)
        if (!taken.contains(p)) p,
      if (entry.purok != null && !puroks.contains(entry.purok) && _isEdit) entry.purok!,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: LabeledField(
              label: 'Purok *',
              child: DropdownButtonFormField<String>(
                style: TropaStyles.fieldText(context),
                key: ValueKey('purok-$i-$_locationId-${entry.purok}'),
                initialValue: options.contains(entry.purok) ? entry.purok : null,
                isExpanded: true,
                decoration: TropaStyles.formField(context),
                hint: Text(_locationId == null ? 'Select barangay first' : 'Select purok'),
                items: [for (final p in options) DropdownMenuItem(value: p, child: Text(p))],
                validator: required,
                onChanged: _locationId == null ? null : (v) => setState(() => entry.purok = v),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: LabeledField(
              label: 'Forms *',
              child: TextFormField(
                style: TropaStyles.fieldText(context),
                controller: entry.count,
                keyboardType: TextInputType.number,
                decoration: TropaStyles.formField(context),
                validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? 'Enter 1 or more' : null,
              ),
            ),
          ),
          if (_entries.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18, color: TropaColors.error),
              tooltip: 'Remove purok',
              onPressed: () {
                final removed = _entries[i];
                setState(() => _entries.removeAt(i));
                // Its field is still mounted until this frame rebuilds.
                WidgetsBinding.instance.addPostFrameCallback((_) => removed.count.dispose());
              },
            ),
        ],
      ),
    );
  }
}
