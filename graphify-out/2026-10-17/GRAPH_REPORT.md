# Graph Report - TROPAV2  (2026-10-17)

## Corpus Check
- 86 files · ~103,082 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 3, .toml 1)

## Summary
- 1680 nodes · 2374 edges · 91 communities (66 shown, 25 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c93c91e3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- String?
- dues_provider.dart
- offline_auth.dart
- form_tracking_provider.dart
- household_provider.dart
- user_form_dialog.dart
- form_tracking_dialog.dart
- dues_view.dart
- officer_form_dialog.dart
- households_view.dart
- locations_tab.dart
- ConsumerWidget
- voter_snapshot.dart
- package:flutter_riverpod/flutter_riverpod.dart
- env.dart
- device_seed.dart
- DESIGN.md
- tropa_v2
- CLAUDE.md
- supabaseServiceProvider
- users_tab.dart
- transfer_member_dialog.dart
- device_seed_card.dart
- device_seed_io.dart
- fallback_sync.dart
- package:flutter/material.dart
- supabase_connector.dart
- officers_tab.dart
- 20261016000000_fallback_sync.sql
- reports_view.dart
- form_tracking_view.dart
- package:powersync/powersync.dart
- login_view.dart
- ../core/design_system.dart
- 20261015000000_admin_settings.sql
- index.ts
- voter_provider.dart
- household_view_dialog.dart
- geo.dart
- 20261014000000_voter_snapshot.sql
- tropa_animated_logo.dart
- memberListNotifierProvider
- _DateSlashFormatter
- ../core/ph_time.dart
- gen_sw.mjs
- package:intl/intl.dart
- auth_provider.dart
- Cross-Platform Flutter Desktop & Web Application Architecture
- main.dart
- vercel.json
- build
- ph_time.dart
- device_seed_web.dart
- sw.template.js
- build_web.sh
- form_fields.dart
- StatelessWidget
- static const
- package:flutter_test/flutter_test.dart
- _TropaAnimatedLogoState
- device_seed_stub.dart
- package:supabase_flutter/supabase_flutter.dart
- package:shared_preferences/shared_preferences.dart
- _OfficerFormDialogState
- _SlideGradient
- PowerSyncDatabase

## God Nodes (most connected - your core abstractions)
1. `supabaseServiceProvider` - 55 edges
2. `localDbProvider` - 12 edges
3. `memberListNotifierProvider` - 12 edges
4. `locationsProvider` - 12 edges
5. `log_deleted_record` - 11 edges
6. `householdListNotifierProvider` - 10 edges
7. `currentAppUserProvider` - 9 edges
8. `puroksProvider` - 9 edges
9. `formBatchNotifierProvider` - 8 edges
10. `_FormTrackingDialogState` - 8 edges

## Surprising Connections (you probably didn't know these)
- `_load` --references--> `localDbProvider`  [EXTRACTED]
  lib/views/settings/device_seed_card.dart → lib/data/db.dart
- `_publish` --references--> `localDbProvider`  [EXTRACTED]
  lib/views/settings/device_seed_card.dart → lib/data/db.dart
- `_publish` --references--> `localDbProvider`  [EXTRACTED]
  lib/views/settings/voter_registry_tab.dart → lib/data/db.dart
- `deletePayment` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/dues_provider.dart → lib/providers/auth_provider.dart
- `recordPayment` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/dues_provider.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (91 total, 25 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.02
Nodes (130): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+122 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.01
Nodes (154): _addDependentRow, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch, _barangay (+146 more)

### Community 2 - "design_system.dart"
Cohesion: 0.02
Nodes (102): action, backgroundOf, badge, body, bodyStrong, borderOf, caption, copyWith (+94 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.02
Nodes (76): _adminUsers, _checkUniqueLocation, _checkUniquePurok, client, countAllMembers, countHouseholdMembers, createDuesPayment, createFamilyMembersBulk (+68 more)

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
Nodes (22): auth, backup, backupPhase, _connect, db, dbGeneration, false, initialize (+14 more)

### Community 10 - "members_view.dart"
Cohesion: 0.09
Nodes (17): _barangays, createState, dispose, _filterDropdown, _firstNameCtrl, _householdFilter, _isPrinting, _lastNameCtrl (+9 more)

### Community 11 - "ConsumerState"
Cohesion: 0.15
Nodes (22): adminUsersProvider, currentAppUserProvider, formTrackingFilterProvider, locationsProvider, build, FormTrackingView, _FormTrackingViewState, HouseholdsView (+14 more)

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.07
Nodes (22): build, _buildCircles, _circles, createState, didChangeDependencies, didUpdateWidget, dispose, _hitNotifier (+14 more)

### Community 13 - "String?"
Cohesion: 0.29
Nodes (3): build, error, onRetry

### Community 14 - "dues_provider.dart"
Cohesion: 0.11
Nodes (16): _changes, copyWith, deletePayment, dispose, duesAsyncProvider, DuesFilter, filter, householdId (+8 more)

### Community 15 - "offline_auth.dart"
Cohesion: 0.13
Nodes (12): _credentialKey, isLocked, _iterations, localDbOwner, _lockedKey, OfflineAuth, _ownerKey, _pbkdf2 (+4 more)

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.12
Nodes (15): barangay, _changes, copyWith, createBatches, dispose, FormTrackingFilter, lgu, moveBatch (+7 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.11
Nodes (16): addHousehold, barangay, _changes, copyWith, dispose, filter, getHouseholds, HouseholdFilter (+8 more)

### Community 18 - "user_form_dialog.dart"
Cohesion: 0.08
Nodes (18): _applyRole, build, createState, dispose, _email, _firstname, _formKey, _isNew (+10 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (23): FormTracking, count, createState, dispose, _encodedBy, _entries, existing, _formKey (+15 more)

### Community 20 - "dues_view.dart"
Cohesion: 0.16
Nodes (11): duesFilterProvider, duesListNotifierProvider, build, createState, currencyFormat, dateFormat, dispose, DuesCollectionView (+3 more)

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.08
Nodes (23): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+15 more)

### Community 22 - "households_view.dart"
Cohesion: 0.17
Nodes (8): householdFilterProvider, _applyFilter, _barangays, build, createState, dispose, _filterDropdown, _searchCtrl

### Community 23 - "locations_tab.dart"
Cohesion: 0.08
Nodes (25): _addPurok, _barangay, _coordValidator, createState, _deleteLocation, _deletePurok, dispose, _editLocation (+17 more)

### Community 24 - "ConsumerWidget"
Cohesion: 0.24
Nodes (9): appThemeProvider, build, TropaApp, routerProvider, _LocationDetail, _OfficerSlate, _AppearanceTab, build (+1 more)

### Community 25 - "voter_snapshot.dart"
Cohesion: 0.06
Nodes (32): bytes, clean, count, decodeVoterSnapshot, encodeVoterSnapshot, ensureVoterSnapshot, error, _fetchManifest (+24 more)

### Community 28 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.17
Nodes (9): items, service, watch, getDashboardMetrics, service, db, onChange, _reportSourceChangesProvider (+1 more)

### Community 29 - "env.dart"
Cohesion: 0.29
Nodes (4): Env, _get, init, powersyncUrl

### Community 30 - "device_seed.dart"
Cohesion: 0.07
Nodes (23): client, coreVersionAccepts, d, device, deviceSeedBucket, deviceSeedManifestPath, deviceSeedProgress, downloadSeedParts (+15 more)

### Community 33 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Form Fields & Checkboxes, Geospatial Control Overlays (+5 more)

### Community 37 - "supabaseServiceProvider"
Cohesion: 0.13
Nodes (22): localDbProvider, AppUserNotifier, supabaseServiceProvider, DuesListNotifier, deleteBatch, FormBatchNotifier, updateBatch, deleteHousehold (+14 more)

### Community 38 - "users_tab.dart"
Cohesion: 0.11
Nodes (16): AppUser, SettingsPalette, createState, _initials, isSelf, _lastSession, onEdit, onResetPassword (+8 more)

### Community 39 - "transfer_member_dialog.dart"
Cohesion: 0.14
Nodes (13): Household, build, createState, _currentHousehold, _householdPicker, initState, _isSaving, _leavesEmpty (+5 more)

### Community 40 - "device_seed_card.dart"
Cohesion: 0.08
Nodes (21): createState, DeviceSeedCard, _DeviceSeedCardState, _download, initState, _load, _loading, _localBuckets (+13 more)

### Community 41 - "device_seed_io.dart"
Cohesion: 0.17
Nodes (9): copy, deviceSeedSupported, gz, installDeviceSeed, _installing, _partSize, publishDeviceSeed, seed (+1 more)

### Community 42 - "fallback_sync.dart"
Cohesion: 0.04
Nodes (45): _activateAfter, _applyDeletions, bools, client, column, cursor, _cursorsCleared, _deactivate (+37 more)

### Community 46 - "package:flutter/material.dart"
Cohesion: 0.24
Nodes (5): dashboardMetricsProvider, householdCoordinatesProvider, build, DashboardView, _kpiCard

### Community 47 - "supabase_connector.dart"
Cohesion: 0.15
Nodes (7): _client, _fatalPostgresCodes, fetchCredentials, invalidateCredentials, SupabaseConnector, _toRemote, uploadData

### Community 48 - "officers_tab.dart"
Cohesion: 0.13
Nodes (16): Location, adminLocationsProvider, officersProvider, puroksProvider, build, _BarangayOfficers, build, createState (+8 more)

### Community 49 - "20261016000000_fallback_sync.sql"
Cohesion: 0.15
Nodes (13): deleted_records_deleted_at_idx, dues_payments_updated_date_idx, family_members_updated_date_idx, form_tracking_updated_at_idx, households_updated_date_idx, log_deleted_record, officers_updated_at_idx, public.deleted_records (+5 more)

### Community 50 - "reports_view.dart"
Cohesion: 0.12
Nodes (14): barangayReportProvider, reportLguFilterProvider, _breakdownTable, build, createState, _dec1, _dec2, _int (+6 more)

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.07
Nodes (29): formBatchNotifierProvider, _applyFilter, assignedTo, batch, _body, _cardDateFmt, _cardDateYearFmt, cardWidth (+21 more)

### Community 52 - "package:powersync/powersync.dart"
Cohesion: 0.33
Nodes (4): booleanColumns, jsonColumns, schema, snapshotVoterLgus

### Community 53 - "login_view.dart"
Cohesion: 0.05
Nodes (19): TropaBrand, userPermissionsProvider, permissions, userAsync, build, createState, dispose, _emailCtrl (+11 more)

### Community 54 - "../core/design_system.dart"
Cohesion: 0.22
Nodes (6): PendingUpload, voterSnapshotStatusProvider, entry, isDark, build, VoterSnapshotStatusLine

### Community 55 - "20261015000000_admin_settings.sql"
Cohesion: 0.33
Nodes (3): officers, officers_touch_updated_at, public.is_tropa_admin()

### Community 57 - "voter_provider.dart"
Cohesion: 0.11
Nodes (17): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, items (+9 more)

### Community 58 - "household_view_dialog.dart"
Cohesion: 0.12
Nodes (17): FamilyMember, householdListNotifierProvider, _openHouseholdDialog, build, createState, _currentHousehold, _fetchRoster, household (+9 more)

### Community 59 - "geo.dart"
Cohesion: 0.14
Nodes (11): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+3 more)

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "tropa_animated_logo.dart"
Cohesion: 0.07
Nodes (26): _brandGreen, build, createState, _ctrl, _cycleMs, didChangeDependencies, dispose, dx (+18 more)

### Community 63 - "memberListNotifierProvider"
Cohesion: 0.27
Nodes (10): memberCountsProvider, memberFilterProvider, memberListNotifierProvider, _applyFilter, build, MembersView, _MembersViewState, _saveBulkBatch (+2 more)

### Community 66 - "../core/ph_time.dart"
Cohesion: 0.33
Nodes (3): activityLogsAsyncProvider, ActivityLogsView, build

### Community 67 - "gen_sw.mjs"
Cohesion: 0.14
Nodes (9): CANVASKIT, files, hash, output, precache, SKIP_NAMES, templatePath, version (+1 more)

### Community 69 - "auth_provider.dart"
Cohesion: 0.10
Nodes (16): authStateStreamProvider, _blockedReason, canPermissionProvider, contains, _deactivatedMessage, _endSession, _logLogin, permissions (+8 more)

### Community 71 - "Cross-Platform Flutter Desktop & Web Application Architecture"
Cohesion: 0.25
Nodes (7): 1. `pubspec.yaml`, 2. Design System & Theme Provider (`theme_provider.dart`), 3. Data Models (`models.dart`), 4. Supabase Service with Auto-Activity Logging & Storage, 5. `go_router` Role-Based Route Guarding, Cross-Platform Flutter Desktop & Web Application Architecture, TROPA v2 (Tabang Respeto Og Panalipud)

### Community 72 - "main.dart"
Cohesion: 0.20
Nodes (6): createState, main, _ready, _start, TropaStartup, _TropaStartupState

### Community 73 - "vercel.json"
Cohesion: 0.25
Nodes (7): buildCommand, framework, headers, installCommand, outputDirectory, rewrites, $schema

### Community 74 - "build"
Cohesion: 0.36
Nodes (9): pendingUploadEntriesProvider, pendingUploadsProvider, syncStateProvider, syncStatusProvider, fallbackSyncStateProvider, build, build, SyncQueueDialog (+1 more)

### Community 75 - "ph_time.dart"
Cohesion: 0.15
Nodes (12): formatPh, _hasOffset, _hasTime, p, parsePh, phNow, phOffset, phToday (+4 more)

### Community 76 - "device_seed_web.dart"
Cohesion: 0.12
Nodes (13): buffer, candidates, decompressor, deviceSeedSupported, existing, features, _gunzip, installDeviceSeed (+5 more)

### Community 79 - "form_fields.dart"
Cohesion: 0.15
Nodes (9): build, child, color, icon, label, SectionHeader, text, title (+1 more)

### Community 80 - "StatelessWidget"
Cohesion: 0.17
Nodes (11): _StageColumn, _SubmissionCard, _PurokOfficers, SettingsCard, SettingsChip, _HeaderRow, _UserRow, LabeledField (+3 more)

### Community 82 - "static const"
Cohesion: 0.33
Nodes (5): AppTheme, AppThemeNotifier, _loadPreference, _prefKey, setTheme

### Community 83 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.20
Nodes (3): main, main, main

### Community 84 - "_TropaAnimatedLogoState"
Cohesion: 0.28
Nodes (6): _PromptDialog, _PromptDialogState, _TypeableDateField, _TypeableDateFieldState, TropaAnimatedLogo, _TropaAnimatedLogoState

### Community 85 - "device_seed_stub.dart"
Cohesion: 0.33
Nodes (4): deviceSeedSupported, false, installDeviceSeed, publishDeviceSeed

## Knowledge Gaps
- **1115 isolated node(s):** `TropaColors`, `TropaTheme`, `TropaText`, `TropaStyles`, `primaryLight` (+1110 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1292 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `auth_provider.dart`, `users_tab.dart`, `tropa_finder_view.dart`, `bulk_add_member_dialog.dart`, `transfer_member_dialog.dart`, `members_view.dart`, `ConsumerState`, `tropa_map_widget.dart`, `dues_provider.dart`, `form_tracking_provider.dart`, `household_provider.dart`, `officers_tab.dart`, `user_form_dialog.dart`, `locations_tab.dart`, `ConsumerWidget`, `household_view_dialog.dart`, `_OfficerFormDialogState`, `memberListNotifierProvider`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `TropaText` to the rest of the system?**
  _1115 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.015037593984962405 - nodes in this community are weakly interconnected._
- **Why does `Household` connect `transfer_member_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `bulk_add_member_dialog.dart`, `members_view.dart`, `tropa_map_widget.dart`, `household_view_dialog.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012195121951219513 - nodes in this community are weakly interconnected._
- **Why does `FamilyMember` connect `household_view_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `transfer_member_dialog.dart`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.018867924528301886 - nodes in this community are weakly interconnected._