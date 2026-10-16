# Graph Report - TROPAV2  (2026-10-14)

## Corpus Check
- 62 files · ~88,389 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 3 file(s) not represented in the graph (top: (none) 3)

## Summary
- 1233 nodes · 1792 edges · 64 communities (52 shown, 12 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- models.dart
- member_form_dialog.dart
- design_system.dart
- supabase_service.dart
- auth_provider.dart
- bulk_add_member_dialog.dart
- tropa_finder_view.dart
- settings_common.dart
- member_provider.dart
- db.dart
- members_view.dart
- DESIGN.md
- tropa_map_widget.dart
- ../core/design_system.dart
- dues_provider.dart
- ../providers/auth_provider.dart
- form_tracking_provider.dart
- household_provider.dart
- offline_auth.dart
- form_tracking_dialog.dart
- dues_view.dart
- officer_form_dialog.dart
- supabaseServiceProvider
- login_view.dart
- voter_registry_tab.dart
- voter_snapshot.dart
- router.dart
- package:flutter_riverpod/flutter_riverpod.dart
- env.dart
- locations_tab.dart
- Cross-Platform Flutter Desktop & Web Application Architecture
- tropa_v2
- CLAUDE.md
- widget_test.dart
- main.dart
- users_tab.dart
- package:powersync/powersync.dart
- ConsumerState
- user_form_dialog.dart
- ConsumerWidget
- supabase_connector.dart
- officers_tab.dart
- currentAppUserProvider
- puroksProvider
- form_tracking_view.dart
- package:google_fonts/google_fonts.dart
- package:flutter/material.dart
- StatelessWidget
- 20261015000000_admin_settings.sql
- index.ts
- voter_provider.dart
- household_view_dialog.dart
- households_view.dart
- 20261014000000_voter_snapshot.sql
- voter_snapshot_status.dart
- _OfficerFormDialogState
- memberListNotifierProvider

## God Nodes (most connected - your core abstractions)
1. `supabaseServiceProvider` - 51 edges
2. `locationsProvider` - 11 edges
3. `memberListNotifierProvider` - 10 edges
4. `localDbProvider` - 9 edges
5. `currentAppUserProvider` - 9 edges
6. `householdListNotifierProvider` - 9 edges
7. `puroksProvider` - 9 edges
8. `_FormTrackingDialogState` - 8 edges
9. `themeModeProvider` - 7 edges
10. `adminUsersProvider` - 7 edges

## Surprising Connections (you probably didn't know these)
- `recordPayment` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/dues_provider.dart → lib/providers/auth_provider.dart
- `createBatches` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `deleteBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `updateBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `updateHousehold` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/household_provider.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (64 total, 12 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.02
Nodes (120): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+112 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.02
Nodes (98): VoterSearchResult, _addDependentRow, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch (+90 more)

### Community 2 - "design_system.dart"
Cohesion: 0.03
Nodes (63): backgroundOf, borderOf, darkBackground, darkOnSurface, darkOnSurfaceVariant, darkOutline, darkOutlineVariant, darkSurface (+55 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.03
Nodes (73): _adminUsers, _checkUniqueLocation, _checkUniquePurok, client, countAllMembers, createDuesPayment, createFamilyMembersBulk, createFormBatches (+65 more)

### Community 4 - "auth_provider.dart"
Cohesion: 0.10
Nodes (16): authStateStreamProvider, _blockedReason, canPermissionProvider, contains, _deactivatedMessage, _endSession, _logLogin, permissions (+8 more)

### Community 5 - "bulk_add_member_dialog.dart"
Cohesion: 0.07
Nodes (26): _addRow, ageCtrl, build, BulkMemberRowData, createState, dispose, firstnameCtrl, _householdOptions (+18 more)

### Community 6 - "tropa_finder_view.dart"
Cohesion: 0.09
Nodes (23): voterFilterProvider, voterNotifierProvider, _actionWidth, _applyFilter, _applyNames, build, _cell, _columns (+15 more)

### Community 7 - "settings_common.dart"
Cohesion: 0.04
Nodes (39): actions, body, border, build, caption, card, cardBg, child (+31 more)

### Community 8 - "member_provider.dart"
Cohesion: 0.09
Nodes (22): barangay, _changes, copyWith, dispose, filter, firstName, getMembers, householdId (+14 more)

### Community 9 - "db.dart"
Cohesion: 0.07
Nodes (30): auth, _connect, db, initialize, isOnline, localDb, onChange, openLocalDatabase (+22 more)

### Community 10 - "members_view.dart"
Cohesion: 0.09
Nodes (18): _barangays, createState, dispose, _filterDecoration, _filterDropdown, _firstNameCtrl, _householdFilter, _isPrinting (+10 more)

### Community 11 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Form Fields & Checkboxes, Geospatial Control Overlays (+5 more)

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.08
Nodes (20): build, _buildCircles, _circles, createState, didUpdateWidget, dispose, _hitNotifier, households (+12 more)

### Community 13 - "../core/design_system.dart"
Cohesion: 0.16
Nodes (9): dashboardMetricsProvider, householdCoordinatesProvider, build, DashboardView, _kpiCard, build, _metricBox, _progressBarItem (+1 more)

### Community 14 - "dues_provider.dart"
Cohesion: 0.12
Nodes (15): _changes, copyWith, dispose, duesAsyncProvider, DuesFilter, filter, householdId, items (+7 more)

### Community 15 - "../providers/auth_provider.dart"
Cohesion: 0.18
Nodes (6): userPermissionsProvider, build, child, DesktopScaffold, _navItem, _pageTitle

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.13
Nodes (13): barangay, _changes, copyWith, createBatches, deleteBatch, dispose, FormTrackingFilter, lgu (+5 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.11
Nodes (17): barangay, _changes, copyWith, dispose, filter, getHouseholds, HouseholdFilter, householdFilterProvider (+9 more)

### Community 18 - "offline_auth.dart"
Cohesion: 0.05
Nodes (25): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+17 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (22): count, createState, dispose, _encodedBy, _entries, existing, _formKey, initState (+14 more)

### Community 20 - "dues_view.dart"
Cohesion: 0.16
Nodes (11): duesFilterProvider, duesListNotifierProvider, build, createState, currencyFormat, dateFormat, dispose, DuesCollectionView (+3 more)

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.08
Nodes (23): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+15 more)

### Community 22 - "supabaseServiceProvider"
Cohesion: 0.12
Nodes (22): AppUserNotifier, supabaseServiceProvider, deletePayment, DuesListNotifier, FormBatchNotifier, addHousehold, deleteHousehold, addMember (+14 more)

### Community 23 - "login_view.dart"
Cohesion: 0.17
Nodes (10): build, createState, dispose, _emailCtrl, _errorMessage, _handleLogin, _isLoading, LoginView (+2 more)

### Community 24 - "voter_registry_tab.dart"
Cohesion: 0.15
Nodes (9): build, createState, initState, _loadingManifest, _loadManifest, _manifest, _progress, VoterRegistryTab (+1 more)

### Community 25 - "voter_snapshot.dart"
Cohesion: 0.06
Nodes (32): bytes, clean, count, decodeVoterSnapshot, encodeVoterSnapshot, ensureVoterSnapshot, error, _fetchManifest (+24 more)

### Community 28 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.23
Nodes (5): items, service, watch, getDashboardMetrics, service

### Community 29 - "env.dart"
Cohesion: 0.33
Nodes (3): Env, init, powersyncUrl

### Community 30 - "locations_tab.dart"
Cohesion: 0.09
Nodes (23): _addPurok, _barangay, _coordValidator, createState, _deleteLocation, _deletePurok, dispose, _editLocation (+15 more)

### Community 33 - "Cross-Platform Flutter Desktop & Web Application Architecture"
Cohesion: 0.25
Nodes (7): 1. `pubspec.yaml`, 2. Design System & Theme Provider (`theme_provider.dart`), 3. Data Models (`models.dart`), 4. Supabase Service with Auto-Activity Logging & Storage, 5. `go_router` Role-Based Route Guarding, Cross-Platform Flutter Desktop & Web Application Architecture, TROPA v2 (Tabang Respeto Og Panalipud)

### Community 36 - "widget_test.dart"
Cohesion: 0.25
Nodes (3): main, noSuchMethod, _UnopenedDb

### Community 37 - "main.dart"
Cohesion: 0.29
Nodes (3): init, main, openLocalDatabase

### Community 38 - "users_tab.dart"
Cohesion: 0.11
Nodes (16): AppUser, SettingsPalette, createState, _initials, isSelf, _lastSession, onEdit, onResetPassword (+8 more)

### Community 39 - "package:powersync/powersync.dart"
Cohesion: 0.33
Nodes (4): booleanColumns, jsonColumns, schema, snapshotVoterLgus

### Community 41 - "ConsumerState"
Cohesion: 0.19
Nodes (13): locationsProvider, HouseholdsView, _HouseholdsViewState, MembersView, LocationsTab, _LocationsTabState, TropaFinderView, _TropaFinderViewState (+5 more)

### Community 42 - "user_form_dialog.dart"
Cohesion: 0.09
Nodes (18): _applyRole, build, createState, dispose, _email, _firstname, _formKey, _isNew (+10 more)

### Community 46 - "ConsumerWidget"
Cohesion: 0.16
Nodes (9): themeModeProvider, build, TropaApp, routerProvider, _LocationDetail, _OfficerSlate, _AppearanceTab, build (+1 more)

### Community 47 - "supabase_connector.dart"
Cohesion: 0.17
Nodes (7): _client, _fatalPostgresCodes, fetchCredentials, invalidateCredentials, SupabaseConnector, _toRemote, uploadData

### Community 48 - "officers_tab.dart"
Cohesion: 0.17
Nodes (9): Location, createState, location, _locationId, OfficersTab, _OfficersTabState, _open, purok (+1 more)

### Community 49 - "currentAppUserProvider"
Cohesion: 0.22
Nodes (14): adminUsersProvider, currentAppUserProvider, formBatchNotifierProvider, formTrackingFilterProvider, _applyFilter, build, FormTrackingView, _FormTrackingViewState (+6 more)

### Community 50 - "puroksProvider"
Cohesion: 0.38
Nodes (7): adminLocationsProvider, officersProvider, puroksProvider, build, _BarangayOfficers, build, _buildPurokDropdown

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.09
Nodes (21): FormTracking, assignedTo, batch, borderCol, cardBg, _collapsed, _confirmDelete, createState (+13 more)

### Community 52 - "package:google_fonts/google_fonts.dart"
Cohesion: 0.33
Nodes (3): activityLogsAsyncProvider, ActivityLogsView, build

### Community 53 - "package:flutter/material.dart"
Cohesion: 0.25
Nodes (5): _loadPreference, _prefKey, setTheme, ThemeModeNotifier, toggleTheme

### Community 54 - "StatelessWidget"
Cohesion: 0.22
Nodes (8): _LocationCard, _StatusChip, _SubmissionTile, _PurokOfficers, SettingsCard, SettingsChip, _HeaderRow, _UserRow

### Community 55 - "20261015000000_admin_settings.sql"
Cohesion: 0.33
Nodes (3): officers, officers_touch_updated_at, public.is_tropa_admin()

### Community 57 - "voter_provider.dart"
Cohesion: 0.11
Nodes (17): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, items (+9 more)

### Community 58 - "household_view_dialog.dart"
Cohesion: 0.12
Nodes (16): FamilyMember, Household, householdListNotifierProvider, _openHouseholdDialog, createState, _currentHousehold, _fetchRoster, household (+8 more)

### Community 59 - "households_view.dart"
Cohesion: 0.18
Nodes (4): _barangays, createState, dispose, _searchCtrl

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "voter_snapshot_status.dart"
Cohesion: 0.38
Nodes (5): localDbProvider, voterSnapshotStatusProvider, _publish, build, VoterSnapshotStatusLine

### Community 63 - "memberListNotifierProvider"
Cohesion: 0.29
Nodes (7): memberListNotifierProvider, _applyFilter, BulkAddMemberDialog, _BulkAddMemberDialogState, _saveBulkBatch, build, _saveMemberRecord

## Knowledge Gaps
- **813 isolated node(s):** `TropaColors`, `TropaTheme`, `primaryLight`, `primaryDark`, `primaryVariant` (+808 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 925 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `auth_provider.dart`, `bulk_add_member_dialog.dart`, `users_tab.dart`, `tropa_finder_view.dart`, `ConsumerState`, `members_view.dart`, `user_form_dialog.dart`, `tropa_map_widget.dart`, `dues_provider.dart`, `ConsumerWidget`, `form_tracking_provider.dart`, `household_provider.dart`, `officers_tab.dart`, `currentAppUserProvider`, `_OfficerFormDialogState`, `household_view_dialog.dart`, `locations_tab.dart`, `memberListNotifierProvider`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `primaryLight` to the rest of the system?**
  _813 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01639344262295082 - nodes in this community are weakly interconnected._
- **Why does `Household` connect `household_view_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `bulk_add_member_dialog.dart`, `members_view.dart`, `tropa_map_widget.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.019417475728155338 - nodes in this community are weakly interconnected._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03125 - nodes in this community are weakly interconnected._
- **Should `supabase_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02564102564102564 - nodes in this community are weakly interconnected._