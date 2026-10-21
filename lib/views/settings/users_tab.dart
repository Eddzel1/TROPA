import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_form_dialog.dart';
import '../../core/ph_time.dart';
import 'settings_common.dart';
import '../../widgets/form_fields.dart';

/// Barangay names by `locations.id`, for showing each user's dues barangays.
final _barangayNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final locations = await ref.watch(supabaseServiceProvider).getLocations();
  return {for (final l in locations) l.id: l.barangay};
});

/// User Management: staff accounts and their permission scopes.
class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  String _query = '';
  String _status = 'All';

  static bool _isSelf(AppUser? me, AppUser u) =>
      me != null && (me.id == u.id || me.email.toLowerCase() == u.email.toLowerCase());

  Future<void> _openForm({AppUser? user, bool isSelf = false}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(user: user, isSelf: isSelf),
    );
    if (saved == true && mounted) {
      showSettingsMessage(
          context, user == null ? 'Account created. Share the sign-in details with the user.' : 'Access updated.');
    }
  }

  Future<void> _resetPassword(AppUser user) async {
    final password = await promptText(
      context,
      title: 'Reset password for ${user.fullName}',
      label: 'New password (at least 8 characters)',
      confirmLabel: 'Set Password',
    );
    if (password == null || !mounted) return;
    if (password.length < 8) {
      showSettingsMessage(context, 'Password must be at least 8 characters.', error: true);
      return;
    }
    try {
      await ref.read(supabaseServiceProvider).setUserPassword(user.id, password);
      if (mounted) showSettingsMessage(context, 'Password updated for ${user.email}.');
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  Future<void> _delete(AppUser user) async {
    final ok = await confirmAction(
      context,
      title: 'Delete ${user.fullName}?',
      message: 'This permanently removes ${user.email} and their sign-in. It cannot be undone. '
          'To only block sign-in and keep the account, deactivate it instead.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(supabaseServiceProvider).deleteUserAccount(user);
      if (mounted) showSettingsMessage(context, 'User deleted.');
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  Future<void> _toggleStatus(AppUser user) async {
    final activate = user.status != 'active';
    final ok = await confirmAction(
      context,
      title: activate ? 'Reactivate ${user.fullName}?' : 'Deactivate ${user.fullName}?',
      message: activate
          ? 'They will be able to sign in again with their existing password.'
          : 'They will be signed out on their next token refresh and cannot sign in, online or offline. '
              'Their records and audit history are kept.',
      confirmLabel: activate ? 'Reactivate' : 'Deactivate',
      destructive: !activate,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(supabaseServiceProvider).setUserStatus(user.id, activate ? 'active' : 'inactive');
      if (mounted) showSettingsMessage(context, activate ? 'User reactivated.' : 'User deactivated.');
    } catch (e) {
      if (mounted) showSettingsMessage(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final usersAsync = ref.watch(adminUsersProvider);
    final me = ref.watch(currentAppUserProvider).value;
    final barangayNames = ref.watch(_barangayNamesProvider).value ?? const <String, String>{};

    final searchField = TextField(
      inputFormatters: const [UpperCaseFormatter()],
      textCapitalization: TextCapitalization.characters,
      style: TropaStyles.fieldText(context),
      decoration: TropaStyles.filterField(context, hint: 'Filter operators...', search: true),
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
    );
    final statusFilter = SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 'All', label: Text('All')),
        ButtonSegment(value: 'active', label: Text('Active')),
        ButtonSegment(value: 'inactive', label: Text('Inactive')),
      ],
      selected: {_status},
      onSelectionChanged: (s) => setState(() => _status = s.first),
    );
    final addButton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.onPrimary),
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('Add User'),
      onPressed: () => _openForm(),
    );
    // Phones and tablets: search + Add User on one line, the status filter full width under it.
    final narrow = context.screenWidth < 900;

    return SettingsCard(
      title: 'Active System Operators & Access Control',
      subtitle: 'Create staff accounts and grant the screens each one may use',
      actions: narrow
          ? const []
          : [
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: searchField),
              statusFilter,
              addButton,
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (narrow) ...[
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 10),
                addButton,
              ],
            ),
            const SizedBox(height: 10),
            statusFilter,
            const SizedBox(height: 16),
          ],
          _usersList(context, p, usersAsync, me, barangayNames),
        ],
      ),
    );
  }

  Widget _usersList(BuildContext context, SettingsPalette p, AsyncValue<List<AppUser>> usersAsync, AppUser? me,
      Map<String, String> barangayNames) {
    return usersAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Could not load users: $e', style: p.body),
        data: (users) {
          final filtered = users.where((u) {
            if (_status != 'All' && (u.status == 'active') != (_status == 'active')) return false;
            if (_query.isEmpty) return true;
            return '${u.fullName} ${u.email}'.toLowerCase().contains(_query);
          }).toList();

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child:
                      Text(users.isEmpty ? 'No users have synced yet.' : 'No users match the filter.', style: p.body)),
            );
          }

          final table = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(p: p),
              Divider(height: 1, color: p.border),
              for (final u in filtered) ...[
                _UserRow(
                  user: u,
                  isSelf: _isSelf(me, u),
                  barangayNames: barangayNames,
                  onEdit: () => _openForm(user: u, isSelf: _isSelf(me, u)),
                  onResetPassword: () => _resetPassword(u),
                  onToggleStatus: () => _toggleStatus(u),
                  onDelete: () => _delete(u),
                ),
                Divider(height: 1, color: p.border),
              ],
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Six columns need ~900px; narrower screens stack each operator's details.
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 900
                    ? table
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Divider(height: 1, color: p.border),
                          for (final u in filtered) ...[
                            _UserRow(
                              user: u,
                              isSelf: _isSelf(me, u),
                              barangayNames: barangayNames,
                              stacked: true,
                              onEdit: () => _openForm(user: u, isSelf: _isSelf(me, u)),
                              onResetPassword: () => _resetPassword(u),
                              onToggleStatus: () => _toggleStatus(u),
                              onDelete: () => _delete(u),
                            ),
                            Divider(height: 1, color: p.border),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Text('Displaying ${filtered.length} of ${users.length} registered system operators', style: p.meta),
            ],
          );
        },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final SettingsPalette p;
  const _HeaderRow({required this.p});

  @override
  Widget build(BuildContext context) {
    final style = p.label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('OPERATOR IDENTITY', style: style)),
          Expanded(flex: 2, child: Text('ACCESS', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(flex: 2, child: Text('LAST SESSION', style: style)),
          Expanded(flex: 4, child: Text('ASSIGNED SCOPES', style: style)),
          SizedBox(width: 150, child: Text('ACTIONS', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  final bool isSelf;
  final Map<String, String> barangayNames;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  /// Phones and tablets: details stacked under the name instead of table columns.
  final bool stacked;

  const _UserRow({
    required this.user,
    required this.isSelf,
    required this.barangayNames,
    this.stacked = false,
    required this.onEdit,
    required this.onResetPassword,
    required this.onToggleStatus,
    required this.onDelete,
  });

  String _initials() {
    final f = user.firstname.trim();
    final l = user.lastname.trim();
    final s = '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}';
    return s.isNotEmpty ? s.toUpperCase() : (user.email.isNotEmpty ? user.email[0].toUpperCase() : '?');
  }

  String _lastSession() {
    final last = user.lastLogin;
    if (last == null) return 'Never';
    final diff = phNow().difference(last);
    final t = toPh(last);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    final active = user.status == 'active';
    final scopes = user.permissions;
    const maxScopes = 3;

    Widget menu() => PopupMenuButton<String>(
      tooltip: 'More actions',
      icon: Icon(Icons.more_vert, size: 18, color: p.subtext),
      onSelected: (v) => switch (v) {
        'edit' => onEdit(),
        'password' => onResetPassword(),
        'status' => onToggleStatus(),
        _ => onDelete(),
      },
      itemBuilder: (_) => [
        if (stacked)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
                dense: true,
                leading: Icon(Icons.admin_panel_settings_outlined, size: 18),
                title: Text('Edit access')),
          ),
        const PopupMenuItem(
          value: 'password',
          child: ListTile(dense: true, leading: Icon(Icons.key, size: 18), title: Text('Reset password')),
        ),
        if (!isSelf)
          PopupMenuItem(
            value: 'status',
            child: ListTile(
              dense: true,
              leading: Icon(active ? Icons.person_off : Icons.person,
                  size: 18, color: active ? p.error : p.success),
              title: Text(active ? 'Deactivate' : 'Reactivate'),
            ),
          ),
        if (!isSelf)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline, size: 18, color: p.error),
              title: Text('Delete user', style: TextStyle(color: p.error)),
            ),
          ),
      ],
    );

    final scopeChips = [
      for (final s in scopes.take(maxScopes))
        SettingsChip(s == AppPermissions.systemAdmin ? 'System Admin' : AppPermissions.labels[s] ?? s, color: p.subtext),
      if (scopes.length > maxScopes)
        Tooltip(
          message: scopes.skip(maxScopes).map((s) => AppPermissions.labels[s] ?? s).join('\n'),
          child: SettingsChip('+${scopes.length - maxScopes}', color: p.subtext),
        ),
    ];

    if (stacked) {
      return Opacity(
        opacity: active ? 1 : 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: p.chipBg,
                child: Text(_initials(), style: TropaText.bodyStrong(p.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(user.fullName, overflow: TextOverflow.ellipsis, style: p.bodyStrong)),
                        if (isSelf) ...[const SizedBox(width: 6), const SettingsChip('You')],
                      ],
                    ),
                    Text(user.email, style: p.meta, overflow: TextOverflow.ellipsis),
                    if (user.permissions.contains(AppPermissions.duesCollection) && user.duesBarangays.isNotEmpty)
                      Text(
                        'Dues: ${user.duesBarangays.map((id) => barangayNames[id] ?? '?').join(', ')}',
                        style: p.caption,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SettingsChip(AppPermissions.summary(user.permissions)),
                        SettingsChip(active ? '● Active' : '● Inactive', color: active ? p.success : p.error),
                        Text('Last session: ${_lastSession()}', style: p.meta),
                      ],
                    ),
                    if (scopeChips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 4, runSpacing: 4, children: scopeChips),
                    ],
                  ],
                ),
              ),
              menu(),
            ],
          ),
        ),
      );
    }

    return Opacity(
      opacity: active ? 1 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: p.chipBg,
                    child: Text(_initials(), style: TropaText.bodyStrong(p.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(user.fullName, overflow: TextOverflow.ellipsis, style: p.bodyStrong),
                            ),
                            if (isSelf) ...[const SizedBox(width: 6), const SettingsChip('You')],
                          ],
                        ),
                        Text(user.email, style: p.meta, overflow: TextOverflow.ellipsis),
                        if (user.permissions.contains(AppPermissions.duesCollection) && user.duesBarangays.isNotEmpty)
                          Text(
                            'Dues: ${user.duesBarangays.map((id) => barangayNames[id] ?? '?').join(', ')}'
                            '${user.syncAssignedOnly ? ' · syncs only these' : ''}',
                            style: p.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                flex: 2,
                child: Align(
                    alignment: Alignment.centerLeft, child: SettingsChip(AppPermissions.summary(user.permissions)))),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SettingsChip(active ? '● Active' : '● Inactive', color: active ? p.success : p.error),
              ),
            ),
            Expanded(flex: 2, child: Text(_lastSession(), style: p.meta)),
            Expanded(
              flex: 4,
              child: Wrap(spacing: 4, runSpacing: 4, children: scopeChips),
            ),
            SizedBox(
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextButton(
                        onPressed: onEdit,
                        child: Text('Edit Access', style: p.action, overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ),
                  menu(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
