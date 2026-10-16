# Graph Report - TROPAV2  (2026-10-15)

## Corpus Check
- 73 files · ~95,952 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 3 file(s) not represented in the graph (top: (none) 3)

## Summary
- 1474 nodes · 2087 edges · 73 communities (54 shown, 19 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- models.dart
- member_form_dialog.dart
- design_system.dart
- supabase_service.dart
- user_form_dialog.dart
- bulk_add_member_dialog.dart
- tropa_finder_view.dart
- settings_common.dart
- member_provider.dart
- db.dart
- members_view.dart
- form_fields.dart
- tropa_map_widget.dart
- login_view.dart
- dues_provider.dart
- offline_auth.dart
- form_tracking_provider.dart
- household_provider.dart
- auth_provider.dart
- form_tracking_dialog.dart
- households_view.dart
- officer_form_dialog.dart
- supabaseServiceProvider
- locations_tab.dart
- voter_snapshot.dart
- ../providers/auth_provider.dart
- package:flutter_riverpod/flutter_riverpod.dart
- env.dart
- dart:convert
- DESIGN.md
- tropa_v2
- CLAUDE.md
- ConsumerState
- _TropaAnimatedLogoState
- users_tab.dart
- widget_test.dart
- device_seed_io.dart
- router.dart
- dashboard_view.dart
- supabase_connector.dart
- officers_tab.dart
- package:flutter/material.dart
- reports_view.dart
- form_tracking_view.dart
- package:supabase_flutter/supabase_flutter.dart
- device_seed_card.dart
- appThemeProvider
- 20261015000000_admin_settings.sql
- index.ts
- voter_provider.dart
- household_view_dialog.dart
- StatelessWidget
- 20261014000000_voter_snapshot.sql
- tropa_animated_logo.dart
- package:shared_preferences/shared_preferences.dart
- _DateSlashFormatter
- package:flutter_test/flutter_test.dart
- ConsumerWidget
- TropaBrand
- pendingUploadsProvider
- Cross-Platform Flutter Desktop & Web Application Architecture
- static const

## God Nodes (most connected - your core abstractions)
1. `supabaseServiceProvider` - 51 edges
2. `localDbProvider` - 12 edges
3. `locationsProvider` - 11 edges
4. `memberListNotifierProvider` - 10 edges
5. `currentAppUserProvider` - 9 edges
6. `householdListNotifierProvider` - 9 edges
7. `puroksProvider` - 9 edges
8. `_FormTrackingDialogState` - 8 edges
9. `adminUsersProvider` - 7 edges
10. `formBatchNotifierProvider` - 7 edges

## Surprising Connections (you probably didn't know these)
- `deletePayment` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/dues_provider.dart → lib/providers/auth_provider.dart
- `recordPayment` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/dues_provider.dart → lib/providers/auth_provider.dart
- `createBatches` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `deleteBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `updateBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (73 total, 19 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.02
Nodes (129): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+121 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.01
Nodes (149): _addDependentRow, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch, _barangay (+141 more)

### Community 2 - "design_system.dart"
Cohesion: 0.02
Nodes (102): action, backgroundOf, badge, body, bodyStrong, borderOf, caption, copyWith (+94 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.03
Nodes (74): _adminUsers, _checkUniqueLocation, _checkUniquePurok, client, countAllMembers, createDuesPayment, createFamilyMembersBulk, createFormBatches (+66 more)

### Community 4 - "user_form_dialog.dart"
Cohesion: 0.09
Nodes (17): _applyRole, build, createState, dispose, _email, _firstname, _formKey, _isNew (+9 more)

### Community 5 - "bulk_add_member_dialog.dart"
Cohesion: 0.07
Nodes (27): _addRow, ageCtrl, build, BulkAddMemberDialog, _BulkAddMemberDialogState, BulkMemberRowData, createState, dispose (+19 more)

### Community 6 - "tropa_finder_view.dart"
Cohesion: 0.11
Nodes (16): _actionWidth, _applyNames, _cell, _columns, createState, dispose, _filterDropdown, _firstNameCtrl (+8 more)

### Community 7 - "settings_common.dart"
Cohesion: 0.04
Nodes (41): action, actions, body, bodyStrong, border, build, caption, card (+33 more)

### Community 8 - "member_provider.dart"
Cohesion: 0.09
Nodes (22): barangay, _changes, copyWith, dispose, filter, firstName, getMembers, householdId (+14 more)

### Community 9 - "db.dart"
Cohesion: 0.07
Nodes (22): auth, _connect, db, dbGeneration, false, initialize, installDeviceSeed, isOnline (+14 more)

### Community 10 - "members_view.dart"
Cohesion: 0.09
Nodes (22): memberCountsProvider, memberFilterProvider, _applyFilter, _barangays, build, createState, dispose, _filterDropdown (+14 more)

### Community 11 - "form_fields.dart"
Cohesion: 0.15
Nodes (9): build, child, color, icon, label, text, title, trailing (+1 more)

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.07
Nodes (22): build, _buildCircles, _circles, createState, didChangeDependencies, didUpdateWidget, dispose, _hitNotifier (+14 more)

### Community 13 - "login_view.dart"
Cohesion: 0.15
Nodes (10): build, createState, dispose, _emailCtrl, _errorMessage, _handleLogin, _isLoading, LoginView (+2 more)

### Community 14 - "dues_provider.dart"
Cohesion: 0.11
Nodes (16): _changes, copyWith, deletePayment, dispose, duesAsyncProvider, DuesFilter, filter, householdId (+8 more)

### Community 15 - "offline_auth.dart"
Cohesion: 0.13
Nodes (12): _credentialKey, isLocked, _iterations, localDbOwner, _lockedKey, OfflineAuth, _ownerKey, _pbkdf2 (+4 more)

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.10
Nodes (18): barangay, _changes, copyWith, createBatches, deleteBatch, dispose, FormTrackingFilter, formTrackingFilterProvider (+10 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.10
Nodes (18): addHousehold, barangay, _changes, copyWith, deleteHousehold, dispose, filter, getHouseholds (+10 more)

### Community 18 - "auth_provider.dart"
Cohesion: 0.10
Nodes (16): authStateStreamProvider, _blockedReason, canPermissionProvider, contains, _deactivatedMessage, _endSession, _logLogin, permissions (+8 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (22): count, createState, dispose, _encodedBy, _entries, existing, _formKey, initState (+14 more)

### Community 20 - "households_view.dart"
Cohesion: 0.10
Nodes (14): duesListNotifierProvider, build, createState, currencyFormat, dateFormat, dispose, DuesCollectionView, _DuesCollectionViewState (+6 more)

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.08
Nodes (25): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+17 more)

### Community 22 - "supabaseServiceProvider"
Cohesion: 0.14
Nodes (19): AppUserNotifier, supabaseServiceProvider, duesFilterProvider, DuesListNotifier, FormBatchNotifier, HouseholdListNotifier, addMember, addMembersBulk (+11 more)

### Community 23 - "locations_tab.dart"
Cohesion: 0.09
Nodes (23): _addPurok, _barangay, _coordValidator, createState, _deleteLocation, _deletePurok, dispose, _editLocation (+15 more)

### Community 25 - "voter_snapshot.dart"
Cohesion: 0.06
Nodes (32): bytes, clean, count, decodeVoterSnapshot, encodeVoterSnapshot, ensureVoterSnapshot, error, _fetchManifest (+24 more)

### Community 26 - "../providers/auth_provider.dart"
Cohesion: 0.18
Nodes (6): userPermissionsProvider, build, child, DesktopScaffold, _navItem, _pageTitle

### Community 28 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.17
Nodes (9): items, service, watch, getDashboardMetrics, service, db, onChange, _reportSourceChangesProvider (+1 more)

### Community 29 - "env.dart"
Cohesion: 0.33
Nodes (3): Env, init, powersyncUrl

### Community 30 - "dart:convert"
Cohesion: 0.22
Nodes (4): deviceSeedBucket, deviceSeedManifestPath, deviceSeedProgress, fetchDeviceSeedManifest

### Community 33 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Form Fields & Checkboxes, Geospatial Control Overlays (+5 more)

### Community 36 - "ConsumerState"
Cohesion: 0.15
Nodes (23): adminUsersProvider, currentAppUserProvider, formBatchNotifierProvider, locationsProvider, build, FormTrackingView, _FormTrackingViewState, HouseholdsView (+15 more)

### Community 37 - "_TropaAnimatedLogoState"
Cohesion: 0.28
Nodes (6): _PromptDialog, _PromptDialogState, _TypeableDateField, _TypeableDateFieldState, TropaAnimatedLogo, _TropaAnimatedLogoState

### Community 38 - "users_tab.dart"
Cohesion: 0.11
Nodes (16): AppUser, SettingsPalette, createState, _initials, isSelf, _lastSession, onEdit, onResetPassword (+8 more)

### Community 39 - "widget_test.dart"
Cohesion: 0.29
Nodes (3): main, noSuchMethod, _UnopenedDb

### Community 41 - "device_seed_io.dart"
Cohesion: 0.11
Nodes (13): copy, _coreVersion, deviceSeedSupported, gz, installDeviceSeed, _installing, _isFreshLocalDb, _mb (+5 more)

### Community 46 - "dashboard_view.dart"
Cohesion: 0.28
Nodes (5): dashboardMetricsProvider, householdCoordinatesProvider, build, DashboardView, _kpiCard

### Community 47 - "supabase_connector.dart"
Cohesion: 0.17
Nodes (7): _client, _fatalPostgresCodes, fetchCredentials, invalidateCredentials, SupabaseConnector, _toRemote, uploadData

### Community 48 - "officers_tab.dart"
Cohesion: 0.18
Nodes (9): Location, createState, location, _locationId, OfficersTab, _OfficersTabState, _open, purok (+1 more)

### Community 49 - "package:flutter/material.dart"
Cohesion: 0.11
Nodes (13): PendingUpload, init, main, openLocalDatabase, activityLogsAsyncProvider, voterSnapshotStatusProvider, ActivityLogsView, build (+5 more)

### Community 50 - "reports_view.dart"
Cohesion: 0.12
Nodes (14): barangayReportProvider, reportLguFilterProvider, _breakdownTable, build, createState, _dec1, _dec2, _int (+6 more)

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.09
Nodes (20): FormTracking, assignedTo, batch, borderCol, cardBg, _collapsed, _confirmDelete, createState (+12 more)

### Community 52 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.15
Nodes (8): booleanColumns, jsonColumns, schema, snapshotVoterLgus, deviceSeedSupported, false, installDeviceSeed, publishDeviceSeed

### Community 53 - "device_seed_card.dart"
Cohesion: 0.09
Nodes (22): localDbProvider, createState, DeviceSeedCard, _DeviceSeedCardState, _download, initState, _load, _loading (+14 more)

### Community 54 - "appThemeProvider"
Cohesion: 0.40
Nodes (6): appThemeProvider, build, TropaApp, routerProvider, _AppearanceTab, build

### Community 55 - "20261015000000_admin_settings.sql"
Cohesion: 0.33
Nodes (3): officers, officers_touch_updated_at, public.is_tropa_admin()

### Community 57 - "voter_provider.dart"
Cohesion: 0.08
Nodes (24): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, flagVoter (+16 more)

### Community 58 - "household_view_dialog.dart"
Cohesion: 0.11
Nodes (20): FamilyMember, Household, householdListNotifierProvider, memberListNotifierProvider, _openHouseholdDialog, _saveBulkBatch, build, createState (+12 more)

### Community 59 - "StatelessWidget"
Cohesion: 0.18
Nodes (10): _LocationCard, _StatusChip, _SubmissionTile, _PurokOfficers, SettingsCard, SettingsChip, _HeaderRow, _UserRow (+2 more)

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "tropa_animated_logo.dart"
Cohesion: 0.04
Nodes (38): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+30 more)

### Community 67 - "ConsumerWidget"
Cohesion: 0.21
Nodes (11): adminLocationsProvider, officersProvider, puroksProvider, build, _LocationDetail, _LocationsTabState, _BarangayOfficers, build (+3 more)

### Community 69 - "pendingUploadsProvider"
Cohesion: 0.39
Nodes (8): pendingUploadEntriesProvider, pendingUploadsProvider, syncStateProvider, syncStatusProvider, build, build, SyncQueueDialog, SyncStatusPill

### Community 71 - "Cross-Platform Flutter Desktop & Web Application Architecture"
Cohesion: 0.25
Nodes (7): 1. `pubspec.yaml`, 2. Design System & Theme Provider (`theme_provider.dart`), 3. Data Models (`models.dart`), 4. Supabase Service with Auto-Activity Logging & Storage, 5. `go_router` Role-Based Route Guarding, Cross-Platform Flutter Desktop & Web Application Architecture, TROPA v2 (Tabang Respeto Og Panalipud)

### Community 72 - "static const"
Cohesion: 0.33
Nodes (5): AppTheme, AppThemeNotifier, _loadPreference, _prefKey, setTheme

## Knowledge Gaps
- **995 isolated node(s):** `TropaColors`, `TropaTheme`, `TropaText`, `TropaStyles`, `primaryLight` (+990 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1133 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **19 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `ConsumerWidget`, `ConsumerState`, `bulk_add_member_dialog.dart`, `users_tab.dart`, `members_view.dart`, `tropa_map_widget.dart`, `dues_provider.dart`, `form_tracking_provider.dart`, `household_provider.dart`, `auth_provider.dart`, `officers_tab.dart`, `officer_form_dialog.dart`, `locations_tab.dart`, `voter_provider.dart`, `household_view_dialog.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `TropaText` to the rest of the system?**
  _995 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015037593984962405 - nodes in this community are weakly interconnected._
- **Why does `Household` connect `household_view_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `bulk_add_member_dialog.dart`, `members_view.dart`, `tropa_map_widget.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012578616352201259 - nodes in this community are weakly interconnected._
- **Why does `FamilyMember` connect `household_view_dialog.dart` to `models.dart`, `member_form_dialog.dart`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.018867924528301886 - nodes in this community are weakly interconnected._