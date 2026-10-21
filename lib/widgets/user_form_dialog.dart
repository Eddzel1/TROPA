import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../core/geo.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'form_fields.dart';
import '../views/settings/settings_common.dart';
import '../core/ph_time.dart';

/// Creates a staff account (with [user] null) or edits an existing user's permissions.
class UserFormDialog extends ConsumerStatefulWidget {
  final AppUser? user;

  /// Editing your own account: keeps 'system_admin'/'manage_users' so you can't lock yourself out.
  final bool isSelf;

  const UserFormDialog({super.key, this.user, this.isSelf = false});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  final _password = TextEditingController();
  late final _firstname = TextEditingController(text: widget.user?.firstname ?? '');
  late final _lastname = TextEditingController(text: widget.user?.lastname ?? '');
  late Set<String> _permissions = {...(widget.user?.permissions ?? AppPermissions.presets['Field Encoder']!)};
  late final Set<String> _duesBarangays = {...?widget.user?.duesBarangays};
  late bool _syncAssignedOnly = widget.user?.syncAssignedOnly ?? false;
  List<LocationOption> _locations = const [];
  bool _saving = false;
  bool _showPassword = false;

  bool get _isNew => widget.user == null;
  bool get _isSystemAdmin => _permissions.contains(AppPermissions.systemAdmin);

  /// Dues collectors are limited to the barangays chosen here; System Admins collect everywhere.
  bool get _picksDuesBarangays => !_isSystemAdmin && _permissions.contains(AppPermissions.duesCollection);

  @override
  void initState() {
    super.initState();
    ref.read(supabaseServiceProvider).getLocations().then((l) {
      if (!mounted) return;
      l.sort((a, b) => '${a.lgu}|${a.barangay}'.compareTo('${b.lgu}|${b.barangay}'));
      setState(() => _locations = l);
    });
  }

  Future<void> _pickDuesBarangays() async {
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _BarangayPickerDialog(locations: _locations, selected: _duesBarangays),
    );
    if (picked != null) {
      setState(() => _duesBarangays
        ..clear()
        ..addAll(picked));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstname.dispose();
    _lastname.dispose();
    super.dispose();
  }

  void _applyPreset(String? name) {
    final preset = AppPermissions.presets[name];
    if (preset == null) return;
    setState(() {
      _permissions = {...preset};
      // Collectors only need their barangays' records on their phones.
      _syncAssignedOnly = name == 'Dues Collector';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_permissions.isEmpty) {
      showSettingsMessage(context, 'Grant at least one permission.', error: true);
      return;
    }
    if (widget.isSelf &&
        !(_permissions.contains(AppPermissions.systemAdmin) || _permissions.contains(AppPermissions.manageUsers))) {
      showSettingsMessage(context, 'You cannot remove your own Manage users permission.', error: true);
      return;
    }
    if (_picksDuesBarangays && _duesBarangays.isEmpty && !_permissions.contains(AppPermissions.manageUsers)) {
      showSettingsMessage(context, 'Choose at least one barangay this user collects dues for.', error: true);
      return;
    }

    setState(() => _saving = true);
    final service = ref.read(supabaseServiceProvider);
    final permissions = _isSystemAdmin ? [AppPermissions.systemAdmin] : _permissions.toList();
    final duesBarangays = _picksDuesBarangays ? _duesBarangays.toList() : <String>[];
    final syncAssignedOnly = _picksDuesBarangays && duesBarangays.isNotEmpty && _syncAssignedOnly;
    try {
      if (_isNew) {
        await service.createUserAccount(
          email: _email.text.trim(),
          password: _password.text,
          firstname: _firstname.text.trim(),
          lastname: _lastname.text.trim(),
          permissions: permissions,
          duesBarangays: duesBarangays,
          syncAssignedOnly: syncAssignedOnly,
        );
      } else {
        final u = widget.user!;
        await service.updateAppUser(AppUser(
          id: u.id,
          email: u.email,
          firstname: _firstname.text.trim(),
          lastname: _lastname.text.trim(),
          status: u.status,
          permissions: permissions,
          duesBarangays: duesBarangays,
          syncAssignedOnly: syncAssignedOnly,
          lastLogin: u.lastLogin,
          createdDate: u.createdDate,
          updatedDate: phNow(),
        ));
        if (widget.isSelf) await ref.read(currentAppUserProvider.notifier).refreshUser();
      }
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

    return AlertDialog(
      title: Text(_isNew ? 'Add Staff User' : 'Edit Access: ${widget.user!.fullName}'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isNew) ...[
                  LabeledField(
                    label: 'Email (sign-in username) *',
                    child: TextFormField(
                      controller: _email,
                      style: TropaStyles.fieldText(context),
                      decoration: TropaStyles.formField(context, hint: 'name@example.com'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Enter a valid email';
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: 'Initial password *',
                    child: TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      style: TropaStyles.fieldText(context),
                      decoration: TropaStyles.formField(
                        context,
                        helper: 'At least 8 characters. Share it with the user directly.',
                        suffix: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (v) => (v ?? '').length < 8 ? 'At least 8 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(widget.user!.email, style: p.meta),
                  const SizedBox(height: 12),
                ],
                ResponsiveFieldRow(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'First Name *',
                        child: TextFormField(
                          inputFormatters: const [UpperCaseFormatter()],
                          textCapitalization: TextCapitalization.characters,
                          controller: _firstname,
                          style: TropaStyles.fieldText(context),
                          decoration: TropaStyles.formField(context),
                          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(
                        label: 'Last Name *',
                        child: TextFormField(
                          inputFormatters: const [UpperCaseFormatter()],
                          textCapitalization: TextCapitalization.characters,
                          controller: _lastname,
                          style: TropaStyles.fieldText(context),
                          decoration: TropaStyles.formField(context),
                          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Start from preset',
                  child: DropdownButtonFormField<String>(
                    // Keyed on the match so ticking boxes below updates the shown preset.
                    key: ValueKey(AppPermissions.matchingPreset(_permissions)),
                    initialValue: AppPermissions.matchingPreset(_permissions),
                    hint: const Text('Custom'),
                    style: TropaStyles.fieldText(context),
                    decoration:
                        TropaStyles.formField(context, helper: 'Choosing a preset resets the permissions below'),
                    items: [
                      for (final name in AppPermissions.presets.keys) DropdownMenuItem(value: name, child: Text(name))
                    ],
                    onChanged: _applyPreset,
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader('Permissions'),
                const SizedBox(height: 4),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _isSystemAdmin,
                  title: Text('System Admin (all permissions)', style: p.body),
                  subtitle: Text('Every screen, including future ones', style: p.caption),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _permissions = {AppPermissions.systemAdmin};
                    } else {
                      _permissions = {...AppPermissions.presets['Admin']!};
                    }
                  }),
                ),
                for (final group in AppPermissions.groups.entries) ...[
                  const Divider(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(group.key.toUpperCase(), style: p.label),
                  ),
                  for (final entry in group.value.entries)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _isSystemAdmin || _permissions.contains(entry.key),
                      title: Text(entry.value, style: p.body),
                      subtitle: Text(entry.key, style: p.meta),
                      onChanged: _isSystemAdmin
                          ? null
                          : (v) =>
                              setState(() => v == true ? _permissions.add(entry.key) : _permissions.remove(entry.key)),
                    ),
                ],
                if (_picksDuesBarangays) ...[
                  const SizedBox(height: 16),
                  const SectionHeader('Dues barangays'),
                  const SizedBox(height: 4),
                  Text(
                    _permissions.contains(AppPermissions.manageUsers)
                        ? 'Barangays this user records dues for. Leave empty for all barangays.'
                        : 'Barangays this user records dues for. They only see members and households there on the Dues page.',
                    style: p.caption,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final l in _locations.where((l) => _duesBarangays.contains(l.id)))
                        InputChip(
                          label: Text('${l.barangay}, ${l.lgu}', style: p.body),
                          onDeleted: () => setState(() => _duesBarangays.remove(l.id)),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add_location_alt_outlined, size: 16),
                        label: Text(_duesBarangays.isEmpty ? 'Choose barangays' : 'Change'),
                        onPressed: _locations.isEmpty ? null : _pickDuesBarangays,
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _syncAssignedOnly && _duesBarangays.isNotEmpty,
                    title: Text('Sync only assigned barangays', style: p.body),
                    subtitle: Text(
                      'Their devices download only these barangays\' households, members and dues. '
                      'Members, Households and Reports then show only these barangays.',
                      style: p.caption,
                    ),
                    onChanged: _duesBarangays.isEmpty ? null : (v) => setState(() => _syncAssignedOnly = v == true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_isNew ? Icons.person_add : Icons.save, size: 16),
          label: Text(_isNew ? 'Create Account' : 'Save Changes'),
        ),
      ],
    );
  }
}

/// Multi-select of barangays with a search box; returns the chosen `locations.id`s.
class _BarangayPickerDialog extends StatefulWidget {
  final List<LocationOption> locations;
  final Set<String> selected;

  const _BarangayPickerDialog({required this.locations, required this.selected});

  @override
  State<_BarangayPickerDialog> createState() => _BarangayPickerDialogState();
}

class _BarangayPickerDialogState extends State<_BarangayPickerDialog> {
  late final Set<String> _selected = {...widget.selected};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final q = _query.trim().toUpperCase();
    final shown = widget.locations.where((l) => q.isEmpty || l.barangay.contains(q) || l.lgu.contains(q)).toList();

    return AlertDialog(
      title: const Text('Dues barangays'),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          children: [
            TextField(
              inputFormatters: const [UpperCaseFormatter()],
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
              style: TropaStyles.fieldText(context),
              decoration: TropaStyles.filterField(context, hint: 'Search barangay or LGU…', search: true),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final l = shown[i];
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(l.id),
                    title: Text(l.barangay, style: p.body),
                    subtitle: Text(l.lgu, style: p.meta),
                    onChanged: (v) => setState(() => v == true ? _selected.add(l.id) : _selected.remove(l.id)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _selected), child: Text('Done (${_selected.length})')),
      ],
    );
  }
}
