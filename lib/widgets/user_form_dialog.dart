import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'form_fields.dart';
import '../views/settings/settings_common.dart';
import '../core/ph_time.dart';

/// Creates a staff account (with [user] null) or edits an existing user's role and permissions.
class UserFormDialog extends ConsumerStatefulWidget {
  final AppUser? user;

  /// Editing your own account: keeps 'all'/'user_management' so you can't lock yourself out.
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
  late String _role = widget.user?.role ?? 'Field Encoder';
  late Set<String> _permissions = {...(widget.user?.permissions ?? AppPermissions.rolePresets['Field Encoder']!)};
  bool _saving = false;
  bool _showPassword = false;

  bool get _isNew => widget.user == null;
  bool get _isSuperAdmin => _permissions.contains(AppPermissions.all);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstname.dispose();
    _lastname.dispose();
    super.dispose();
  }

  void _applyRole(String? role) {
    if (role == null) return;
    setState(() {
      _role = role;
      final preset = AppPermissions.rolePresets[role];
      if (preset != null) _permissions = {...preset};
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_permissions.isEmpty) {
      showSettingsMessage(context, 'Grant at least one permission.', error: true);
      return;
    }
    if (widget.isSelf && !(_permissions.contains(AppPermissions.all) || _permissions.contains(AppPermissions.userManagement))) {
      showSettingsMessage(context, 'You cannot remove your own access to Settings.', error: true);
      return;
    }

    setState(() => _saving = true);
    final service = ref.read(supabaseServiceProvider);
    final permissions = _isSuperAdmin ? [AppPermissions.all] : _permissions.toList();
    try {
      if (_isNew) {
        await service.createUserAccount(
          email: _email.text.trim(),
          password: _password.text,
          firstname: _firstname.text.trim(),
          lastname: _lastname.text.trim(),
          role: _role,
          permissions: permissions,
        );
      } else {
        final u = widget.user!;
        await service.updateAppUser(AppUser(
          id: u.id,
          email: u.email,
          firstname: _firstname.text.trim(),
          lastname: _lastname.text.trim(),
          role: _role,
          status: u.status,
          permissions: permissions,
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
    final roles = {...AppPermissions.rolePresets.keys, _role}.toList();

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
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'First Name *',
                        child: TextFormField(
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
                  label: 'Role *',
                  child: DropdownButtonFormField<String>(
                    initialValue: _role,
                    style: TropaStyles.fieldText(context),
                    decoration: TropaStyles.formField(context, helper: 'Choosing a role resets the permissions below'),
                    items: [for (final r in roles) DropdownMenuItem(value: r, child: Text(r))],
                    onChanged: _applyRole,
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader('Permissions'),
                const SizedBox(height: 4),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _isSuperAdmin,
                  title: Text('Full access (all)', style: p.body),
                  subtitle: Text('Every screen, including future ones', style: p.caption),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _permissions = {AppPermissions.all};
                    } else {
                      _permissions = {...AppPermissions.rolePresets['Admin']!};
                    }
                  }),
                ),
                const Divider(height: 8),
                for (final entry in AppPermissions.labels.entries)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _isSuperAdmin || _permissions.contains(entry.key),
                    title: Text(entry.value, style: p.body),
                    subtitle: Text(entry.key, style: p.meta),
                    onChanged: _isSuperAdmin
                        ? null
                        : (v) => setState(() => v == true ? _permissions.add(entry.key) : _permissions.remove(entry.key)),
                  ),
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
