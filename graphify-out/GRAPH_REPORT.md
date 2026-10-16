# Graph Report - TROPAV2  (2026-10-16)

## Corpus Check
- 79 files · ~97,940 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 3 file(s) not represented in the graph (top: (none) 3)

## Summary
- 1528 nodes · 2159 edges · 80 communities (60 shown, 20 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- models.dart
- member_form_dialog.dart
- design_system.dart
- supabase_service.dart
- bulk_add_member_dialog.dart
- tropa_finder_view.dart
- settings_common.dart
- member_provider.dart
- db.dart
- members_view.dart
- ConsumerState
- tropa_map_widget.dart
- auth_provider.dart
- dues_provider.dart
- offline_auth.dart
- form_tracking_provider.dart
- household_provider.dart
- user_form_dialog.dart
- form_tracking_dialog.dart
- dues_view.dart
- officer_form_dialog.dart
- formBatchNotifierProvider
- locations_tab.dart
- settings_view.dart
- voter_snapshot.dart
- package:flutter_riverpod/flutter_riverpod.dart
- env.dart
- dart:convert
- DESIGN.md
- tropa_v2
- CLAUDE.md
- supabaseServiceProvider
- users_tab.dart
- StateNotifier
- sync_status_pill.dart
- device_seed_io.dart
- login_view.dart
- ../core/design_system.dart
- supabase_connector.dart
- officers_tab.dart
- package:flutter/material.dart
- reports_view.dart
- form_tracking_view.dart
- package:supabase_flutter/supabase_flutter.dart
- device_seed_card.dart
- main.dart
- 20261015000000_admin_settings.sql
- index.ts
- voter_provider.dart
- household_view_dialog.dart
- voter_registry_tab.dart
- 20261014000000_voter_snapshot.sql
- tropa_animated_logo.dart
- memberListNotifierProvider
- _DateSlashFormatter
- ../core/ph_time.dart
- gen_sw.mjs
- package:powersync/powersync.dart
- package:intl/intl.dart
- Cross-Platform Flutter Desktop & Web Application Architecture
- _OfficerFormDialogState
- households_view.dart
- ph_time.dart
- sw.template.js
- build_web.sh
- form_fields.dart
- StatelessWidget
- puroksProvider

## God Nodes (most connected - your core abstractions)
1. `supabaseServiceProvider` - 51 edges
2. `localDbProvider` - 12 edges
3. `locationsProvider` - 11 edges
4. `memberListNotifierProvider` - 10 edges
5. `currentAppUserProvider` - 9 edges
6. `householdListNotifierProvider` - 9 edges
7. `puroksProvider` - 9 edges
8. `formBatchNotifierProvider` - 8 edges
9. `_FormTrackingDialogState` - 8 edges
10. `adminUsersProvider` - 7 edges

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

## Communities (80 total, 20 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.01
Nodes (130): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+122 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.01
Nodes (153): _addDependentRow, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch, _barangay (+145 more)

### Community 2 - "design_system.dart"
Cohesion: 0.02
Nodes (102): action, backgroundOf, badge, body, bodyStrong, borderOf, caption, copyWith (+94 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.03
Nodes (74): _adminUsers, _checkUniqueLocation, _checkUniquePurok, client, countAllMembers, createDuesPayment, createFamilyMembersBulk, createFormBatches (+66 more)

### Community 5 - "bulk_add_member_dialog.dart"
Cohesion: 0.07
Nodes (27): _addRow, ageCtrl, build, BulkAddMemberDialog, _BulkAddMemberDialogState, BulkMemberRowData, createState, dispose (+19 more)

### Community 6 - "tropa_finder_view.dart"
Cohesion: 0.09
Nodes (22): voterFilterProvider, voterNotifierProvider, _actionWidth, _applyFilter, _applyNames, build, _cell, _columns (+14 more)

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
Cohesion: 0.10
Nodes (16): _barangays, createState, dispose, _filterDropdown, _firstNameCtrl, _isPrinting, _lastNameCtrl, _lgus (+8 more)

### Community 11 - "ConsumerState"
Cohesion: 0.15
Nodes (22): adminUsersProvider, currentAppUserProvider, formTrackingFilterProvider, locationsProvider, build, FormTrackingView, _FormTrackingViewState, HouseholdsView (+14 more)

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.07
Nodes (22): build, _buildCircles, _circles, createState, didChangeDependencies, didUpdateWidget, dispose, _hitNotifier (+14 more)

### Community 13 - "auth_provider.dart"
Cohesion: 0.08
Nodes (21): AppTheme, AppThemeNotifier, _loadPreference, _prefKey, setTheme, authStateStreamProvider, _blockedReason, canPermissionProvider (+13 more)

### Community 14 - "dues_provider.dart"
Cohesion: 0.11
Nodes (16): _changes, copyWith, deletePayment, dispose, duesAsyncProvider, DuesFilter, filter, householdId (+8 more)

### Community 15 - "offline_auth.dart"
Cohesion: 0.04
Nodes (29): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+21 more)

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.11
Nodes (17): barangay, _changes, copyWith, createBatches, deleteBatch, dispose, FormTrackingFilter, lgu (+9 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.11
Nodes (16): addHousehold, barangay, _changes, copyWith, deleteHousehold, dispose, filter, getHouseholds (+8 more)

### Community 18 - "user_form_dialog.dart"
Cohesion: 0.09
Nodes (17): _applyRole, build, createState, dispose, _email, _firstname, _formKey, _isNew (+9 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (23): FormTracking, count, createState, dispose, _encodedBy, _entries, existing, _formKey (+15 more)

### Community 20 - "dues_view.dart"
Cohesion: 0.19
Nodes (11): duesFilterProvider, duesListNotifierProvider, build, createState, currencyFormat, dateFormat, dispose, DuesCollectionView (+3 more)

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.08
Nodes (23): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+15 more)

### Community 22 - "formBatchNotifierProvider"
Cohesion: 0.40
Nodes (5): formBatchNotifierProvider, _applyFilter, _confirmDelete, _move, _save

### Community 23 - "locations_tab.dart"
Cohesion: 0.08
Nodes (25): _addPurok, _barangay, _coordValidator, createState, _deleteLocation, _deletePurok, dispose, _editLocation (+17 more)

### Community 24 - "settings_view.dart"
Cohesion: 0.16
Nodes (6): appThemeProvider, _LocationDetail, _OfficerSlate, _AppearanceTab, build, SettingsAdminView

### Community 25 - "voter_snapshot.dart"
Cohesion: 0.06
Nodes (32): bytes, clean, count, decodeVoterSnapshot, encodeVoterSnapshot, ensureVoterSnapshot, error, _fetchManifest (+24 more)

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

### Community 37 - "supabaseServiceProvider"
Cohesion: 0.17
Nodes (12): supabaseServiceProvider, addMember, addMembersBulk, deleteMember, updateMember, _householdFilter, _loadHouseholds, _checkDependentMatches (+4 more)

### Community 38 - "users_tab.dart"
Cohesion: 0.11
Nodes (16): AppUser, SettingsPalette, createState, _initials, isSelf, _lastSession, onEdit, onResetPassword (+8 more)

### Community 39 - "StateNotifier"
Cohesion: 0.33
Nodes (7): AppUserNotifier, DuesListNotifier, FormBatchNotifier, householdFilterProvider, HouseholdListNotifier, VoterNotifier, build

### Community 40 - "sync_status_pill.dart"
Cohesion: 0.23
Nodes (11): PendingUpload, pendingUploadEntriesProvider, pendingUploadsProvider, syncStateProvider, syncStatusProvider, build, build, entry (+3 more)

### Community 41 - "device_seed_io.dart"
Cohesion: 0.11
Nodes (13): copy, _coreVersion, deviceSeedSupported, gz, installDeviceSeed, _installing, _isFreshLocalDb, _mb (+5 more)

### Community 42 - "login_view.dart"
Cohesion: 0.05
Nodes (19): TropaBrand, userPermissionsProvider, permissions, userAsync, build, createState, dispose, _emailCtrl (+11 more)

### Community 46 - "../core/design_system.dart"
Cohesion: 0.24
Nodes (5): dashboardMetricsProvider, householdCoordinatesProvider, build, DashboardView, _kpiCard

### Community 47 - "supabase_connector.dart"
Cohesion: 0.18
Nodes (7): _client, _fatalPostgresCodes, fetchCredentials, invalidateCredentials, SupabaseConnector, _toRemote, uploadData

### Community 48 - "officers_tab.dart"
Cohesion: 0.17
Nodes (9): Location, createState, location, _locationId, OfficersTab, _OfficersTabState, _open, purok (+1 more)

### Community 49 - "package:flutter/material.dart"
Cohesion: 0.33
Nodes (3): activityLogsAsyncProvider, ActivityLogsView, build

### Community 50 - "reports_view.dart"
Cohesion: 0.12
Nodes (14): barangayReportProvider, reportLguFilterProvider, _breakdownTable, build, createState, _dec1, _dec2, _int (+6 more)

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.07
Nodes (24): assignedTo, batch, _body, _cardDateFmt, _cardDateYearFmt, cardWidth, _columnGap, createState (+16 more)

### Community 52 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.29
Nodes (4): deviceSeedSupported, false, installDeviceSeed, publishDeviceSeed

### Community 53 - "device_seed_card.dart"
Cohesion: 0.15
Nodes (13): localDbProvider, createState, DeviceSeedCard, _DeviceSeedCardState, _download, initState, _load, _loading (+5 more)

### Community 54 - "main.dart"
Cohesion: 0.22
Nodes (6): build, init, main, openLocalDatabase, TropaApp, routerProvider

### Community 55 - "20261015000000_admin_settings.sql"
Cohesion: 0.33
Nodes (3): officers, officers_touch_updated_at, public.is_tropa_admin()

### Community 57 - "voter_provider.dart"
Cohesion: 0.10
Nodes (18): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, flagVoter (+10 more)

### Community 58 - "household_view_dialog.dart"
Cohesion: 0.12
Nodes (16): FamilyMember, Household, householdListNotifierProvider, _openHouseholdDialog, createState, _currentHousehold, _fetchRoster, household (+8 more)

### Community 59 - "voter_registry_tab.dart"
Cohesion: 0.17
Nodes (9): build, createState, initState, _loadingManifest, _loadManifest, _manifest, _progress, VoterRegistryTab (+1 more)

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "tropa_animated_logo.dart"
Cohesion: 0.05
Nodes (33): _PromptDialog, _PromptDialogState, _TypeableDateField, _TypeableDateFieldState, _brandGreen, build, createState, _ctrl (+25 more)

### Community 63 - "memberListNotifierProvider"
Cohesion: 0.25
Nodes (11): memberCountsProvider, memberFilterProvider, MemberListNotifier, memberListNotifierProvider, _applyFilter, build, MembersView, _MembersViewState (+3 more)

### Community 66 - "../core/ph_time.dart"
Cohesion: 0.40
Nodes (3): voterSnapshotStatusProvider, build, VoterSnapshotStatusLine

### Community 67 - "gen_sw.mjs"
Cohesion: 0.15
Nodes (8): files, hash, output, precache, SKIP_NAMES, templatePath, version, walk()

### Community 68 - "package:powersync/powersync.dart"
Cohesion: 0.33
Nodes (4): booleanColumns, jsonColumns, schema, snapshotVoterLgus

### Community 71 - "Cross-Platform Flutter Desktop & Web Application Architecture"
Cohesion: 0.25
Nodes (7): 1. `pubspec.yaml`, 2. Design System & Theme Provider (`theme_provider.dart`), 3. Data Models (`models.dart`), 4. Supabase Service with Auto-Activity Logging & Storage, 5. `go_router` Role-Based Route Guarding, Cross-Platform Flutter Desktop & Web Application Architecture, TROPA v2 (Tabang Respeto Og Panalipud)

### Community 74 - "households_view.dart"
Cohesion: 0.20
Nodes (4): _barangays, createState, dispose, _searchCtrl

### Community 75 - "ph_time.dart"
Cohesion: 0.15
Nodes (12): formatPh, _hasOffset, _hasTime, p, parsePh, phNow, phOffset, phToday (+4 more)

### Community 79 - "form_fields.dart"
Cohesion: 0.17
Nodes (8): build, child, color, icon, label, text, title, trailing

### Community 80 - "StatelessWidget"
Cohesion: 0.17
Nodes (11): _StageColumn, _SubmissionCard, _PurokOfficers, SettingsCard, SettingsChip, _HeaderRow, _UserRow, LabeledField (+3 more)

### Community 81 - "puroksProvider"
Cohesion: 0.38
Nodes (7): adminLocationsProvider, officersProvider, puroksProvider, build, _BarangayOfficers, build, _buildPurokDropdown

## Knowledge Gaps
- **1022 isolated node(s):** `TropaColors`, `TropaTheme`, `TropaText`, `TropaStyles`, `primaryLight` (+1017 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1180 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **20 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `bulk_add_member_dialog.dart`, `users_tab.dart`, `StateNotifier`, `tropa_finder_view.dart`, `_OfficerFormDialogState`, `ConsumerState`, `tropa_map_widget.dart`, `auth_provider.dart`, `dues_provider.dart`, `form_tracking_provider.dart`, `household_provider.dart`, `officers_tab.dart`, `locations_tab.dart`, `settings_view.dart`, `voter_provider.dart`, `household_view_dialog.dart`, `memberListNotifierProvider`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `TropaText` to the rest of the system?**
  _1022 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.014925373134328358 - nodes in this community are weakly interconnected._
- **Why does `Household` connect `household_view_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `bulk_add_member_dialog.dart`, `members_view.dart`, `tropa_map_widget.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012269938650306749 - nodes in this community are weakly interconnected._
- **Why does `_TypeableDateField` connect `tropa_animated_logo.dart` to `member_form_dialog.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.018867924528301886 - nodes in this community are weakly interconnected._