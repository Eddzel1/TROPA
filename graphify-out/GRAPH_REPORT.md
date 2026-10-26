# Graph Report - TROPAV2  (2026-10-26)

## Corpus Check
- 127 files · ~137,471 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 7 file(s) not represented in the graph (top: (none) 3, .ttf 3, .toml 1)

## Summary
- 2370 nodes · 3334 edges · 132 communities (92 shown, 40 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `daf4d918`
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
- 20261022000000_barangay_sync.sql
- offline_auth.dart
- tropa_map_widget.dart
- members_view.dart
- dues_provider.dart
- bool get
- form_tracking_provider.dart
- household_provider.dart
- user_form_dialog.dart
- form_tracking_dialog.dart
- member_id_view.dart
- officer_form_dialog.dart
- dues_view.dart
- locations_tab.dart
- reports_view.dart
- voter_snapshot.dart
- package:flutter_riverpod/flutter_riverpod.dart
- env.dart
- device_seed.dart
- DESIGN.md
- tropa_v2
- CLAUDE.md
- member_id_view.dart
- users_tab.dart
- transfer_member_dialog.dart
- device_seed_card.dart
- device_seed_io.dart
- fallback_sync.dart
- dues_math.dart
- package:flutter/material.dart
- supabase_connector.dart
- ph_time.dart
- 20261016000000_fallback_sync.sql
- ConsumerWidget
- form_tracking_view.dart
- router.dart
- household_view_dialog.dart
- locationsProvider
- package:flutter_test/flutter_test.dart
- index.ts
- voter_provider.dart
- households_view.dart
- deno.d.ts
- 20261014000000_voter_snapshot.sql
- tropa_animated_logo.dart
- settings_view.dart
- TextInputFormatter
- dues_rate_tab.dart
- gen_sw.mjs
- image_compress.dart
- auth_provider.dart
- tropa_id_card.dart
- Cross-Platform Flutter Desktop & Web Application Architecture
- ../core/ph_time.dart
- vercel.json
- geo.dart
- device_seed_web.dart
- sw.template.js
- build_web.sh
- form_fields.dart
- StatelessWidget
- membership_date_dialog.dart
- supabaseServiceProvider
- login_view.dart
- 20261019000000_dues_ledger.sql
- ConsumerWidget
- compilerOptions
- 20261018010000_system_admin_and_delete.sql
- package:flutter/material.dart
- build
- tropa_member.dart
- TropaScreen
- 20261018030000_match_profile_by_email.sql
- String?
- public.can_collect_dues_for
- State
- memberListNotifierProvider
- package:supabase_flutter/supabase_flutter.dart
- officers_tab.dart
- StateNotifier
- 20261021000000_member_id_number.sql
- CustomPainter
- tropa_id_export.dart
- theme_palettes.dart
- List
- 20261015000000_admin_settings.sql
- public.can_manage_members
- package:flutter/foundation.dart
- static const
- keyboard_safe_body.dart
- ../providers/auth_provider.dart
- ../core/design_system.dart
- ConsumerState
- 20261023000000_barangay_start_month.sql
- main.dart
- build
- TropaBrand
- DuesSheetPreview
- _PromptDialog

## God Nodes (most connected - your core abstractions)
1. `supabaseServiceProvider` - 69 edges
2. `locationsProvider` - 16 edges
3. `build` - 15 edges
4. `puroksProvider` - 14 edges
5. `canPermissionProvider` - 13 edges
6. `memberListNotifierProvider` - 13 edges
7. `currentAppUserProvider` - 11 edges
8. `householdListNotifierProvider` - 11 edges
9. `log_deleted_record` - 11 edges
10. `duesRatesProvider` - 10 edges

## Surprising Connections (you probably didn't know these)
- `createBatches` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `updateBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `addHousehold` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/household_provider.dart → lib/providers/auth_provider.dart
- `setHouseholdArchived` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/household_provider.dart → lib/providers/auth_provider.dart
- `updateHousehold` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/household_provider.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (132 total, 40 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.01
Nodes (166): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+158 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.01
Nodes (181): _addDependentRow, _addDependentRowFromShortcut, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch (+173 more)

### Community 2 - "design_system.dart"
Cohesion: 0.03
Nodes (75): action, backgroundOf, badge, body, bodyStrong, borderOf, _build, _cache (+67 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.02
Nodes (104): _adminUsers, _checkUniqueLocation, _checkUniquePurok, client, countAllMembers, countHouseholdMembers, createFamilyMembersBulk, createFormBatches (+96 more)

### Community 5 - "bulk_add_member_dialog.dart"
Cohesion: 0.07
Nodes (26): _addRow, ageCtrl, build, BulkMemberRowData, createState, dispose, firstnameCtrl, _householdOptions (+18 more)

### Community 6 - "tropa_finder_view.dart"
Cohesion: 0.08
Nodes (28): voterFilterProvider, voterNotifierProvider, _actionWidth, _applyFilter, _applyNames, build, _cell, _columns (+20 more)

### Community 7 - "settings_common.dart"
Cohesion: 0.04
Nodes (42): action, actions, body, bodyStrong, border, build, caption, card (+34 more)

### Community 8 - "member_provider.dart"
Cohesion: 0.08
Nodes (23): archived, barangay, _changes, copyWith, dispose, filter, firstName, getMembers (+15 more)

### Community 9 - "db.dart"
Cohesion: 0.06
Nodes (25): auth, backup, backupPhase, _connect, db, dbGeneration, _ensureVoterListFor, ensureVoterSnapshot (+17 more)

### Community 10 - "20261022000000_barangay_sync.sql"
Cohesion: 0.16
Nodes (12): dues_payments_sync_key_idx, family_members_sync_key_idx, households_sync_key_idx, move_payments_sync_key, public.can_collect_dues_in(), public.move_member_payments_sync_key(), public.refresh_user_sync_scopes(), public.set_payment_sync_key() (+4 more)

### Community 11 - "offline_auth.dart"
Cohesion: 0.14
Nodes (12): _credentialKey, isLocked, _iterations, localDbOwner, _lockedKey, OfflineAuth, _ownerKey, _pbkdf2 (+4 more)

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.07
Nodes (23): build, _buildCircles, _circles, createState, didChangeDependencies, didUpdateWidget, dispose, _hitNotifier (+15 more)

### Community 13 - "members_view.dart"
Cohesion: 0.08
Nodes (23): memberCountsProvider, memberFilterProvider, MemberListNotifier, _applyFilter, build, createState, dispose, _filterDropdown (+15 more)

### Community 14 - "dues_provider.dart"
Cohesion: 0.11
Nodes (18): DuesScope, 0, copyWith, DuesSearch, DuesSearchMode, DuesSelection, _duesTables, _duesUserIdProvider (+10 more)

### Community 15 - "bool get"
Cohesion: 0.18
Nodes (7): keyboardDebugRequested, VisibleArea, host, keyboardDebugRequested, rect, VisibleArea, vv

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.11
Nodes (16): barangay, _changes, copyWith, createBatches, dispose, FormTrackingFilter, lgu, moveBatch (+8 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.10
Nodes (18): addHousehold, archived, barangay, _changes, copyWith, dispose, filter, getHouseholds (+10 more)

### Community 18 - "user_form_dialog.dart"
Cohesion: 0.07
Nodes (26): _applyPreset, build, createState, dispose, _duesBarangays, _email, _firstname, _formKey (+18 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (23): FormTracking, count, createState, dispose, _encodedBy, _entries, existing, _formKey (+15 more)

### Community 20 - "member_id_view.dart"
Cohesion: 0.06
Nodes (31): _actionBarHeight, blocks, bold, border, build, buildDuesSheet, cell, columnHeader (+23 more)

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.07
Nodes (25): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+17 more)

### Community 22 - "dues_view.dart"
Cohesion: 0.04
Nodes (46): DuesMember, DuesReceipt, amount, balance, caption, child, color, createState (+38 more)

### Community 23 - "locations_tab.dart"
Cohesion: 0.08
Nodes (23): _addPurok, _barangay, _clearStartMonth, _coordValidator, createState, _deleteLocation, _deletePurok, dispose (+15 more)

### Community 24 - "reports_view.dart"
Cohesion: 0.13
Nodes (14): barangayReportProvider, reportLguFilterProvider, _breakdownTable, build, createState, _dec1, _dec2, _int (+6 more)

### Community 25 - "voter_snapshot.dart"
Cohesion: 0.06
Nodes (32): bytes, clean, count, decodeVoterSnapshot, encodeVoterSnapshot, ensureVoterSnapshot, error, _fetchManifest (+24 more)

### Community 28 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.20
Nodes (7): watch, getDashboardMetrics, service, db, onChange, _reportSourceChangesProvider, watch

### Community 29 - "env.dart"
Cohesion: 0.29
Nodes (4): Env, _get, init, powersyncUrl

### Community 30 - "device_seed.dart"
Cohesion: 0.04
Nodes (40): client, coreVersionAccepts, d, details, device, deviceSeedBucket, deviceSeedManifestPath, deviceSeedProgress (+32 more)

### Community 33 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Form Fields & Checkboxes, Geospatial Control Overlays (+5 more)

### Community 37 - "member_id_view.dart"
Cohesion: 0.11
Nodes (16): _backKey, build, createState, ext, _frontKey, idNumber, member, MemberIdView (+8 more)

### Community 38 - "users_tab.dart"
Cohesion: 0.07
Nodes (28): AppUser, SettingsPalette, barangayNames, _barangayNamesProvider, build, createState, _delete, _HeaderRow (+20 more)

### Community 39 - "transfer_member_dialog.dart"
Cohesion: 0.14
Nodes (12): build, createState, _currentHousehold, _householdPicker, initState, _isSaving, _leavesEmpty, _loadCurrent (+4 more)

### Community 40 - "device_seed_card.dart"
Cohesion: 0.09
Nodes (22): localDbProvider, createState, DeviceSeedCard, _DeviceSeedCardState, _download, initState, _load, _loading (+14 more)

### Community 41 - "device_seed_io.dart"
Cohesion: 0.13
Nodes (11): bytes, copy, deviceSeedSupported, gz, installDeviceSeed, _installing, outcome, _partSize (+3 more)

### Community 42 - "fallback_sync.dart"
Cohesion: 0.04
Nodes (51): _activateAfter, _applyDeletions, _areaTables, bools, client, column, cursor, _cursorsCleared (+43 more)

### Community 43 - "dues_math.dart"
Cohesion: 0.05
Nodes (34): afterPaying, amountDue, amountFor, amountForMonths, balanceFor, best, bestMonth, currentMonth (+26 more)

### Community 46 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (8): _backKey, build, createState, _export, _frontKey, member, MyIdPage, _MyIdPageState

### Community 47 - "supabase_connector.dart"
Cohesion: 0.14
Nodes (9): _batchable, _batchSize, _client, _fatalPostgresCodes, fetchCredentials, invalidateCredentials, SupabaseConnector, _toRemote (+1 more)

### Community 48 - "ph_time.dart"
Cohesion: 0.15
Nodes (12): formatPh, _hasOffset, _hasTime, p, parsePh, phNow, phOffset, phToday (+4 more)

### Community 49 - "20261016000000_fallback_sync.sql"
Cohesion: 0.15
Nodes (13): deleted_records_deleted_at_idx, dues_payments_updated_date_idx, family_members_updated_date_idx, form_tracking_updated_at_idx, households_updated_date_idx, log_deleted_record, officers_updated_at_idx, public.deleted_records (+5 more)

### Community 50 - "ConsumerWidget"
Cohesion: 0.21
Nodes (12): appThemeProvider, build, TropaApp, canPermissionProvider, routerProvider, _ReceiptTile, _OfficerSlate, _AppearanceTab (+4 more)

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.07
Nodes (35): adminUsersProvider, FormBatchNotifier, formBatchNotifierProvider, formTrackingFilterProvider, _applyFilter, assignedTo, batch, _body (+27 more)

### Community 53 - "household_view_dialog.dart"
Cohesion: 0.13
Nodes (12): FamilyMember, Household, createState, _currentHousehold, _fetchRoster, household, HouseholdViewDialog, _HouseholdViewDialogState (+4 more)

### Community 54 - "locationsProvider"
Cohesion: 0.20
Nodes (14): adminLocationsProvider, officersProvider, barangayStartMonthsProvider, locationsProvider, puroksProvider, _openHouseholdDialog, build, _LocationDetail (+6 more)

### Community 55 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (11): main, main, months, main, main, member, oct2026, rate (+3 more)

### Community 57 - "voter_provider.dart"
Cohesion: 0.10
Nodes (18): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, flagVoter (+10 more)

### Community 58 - "households_view.dart"
Cohesion: 0.11
Nodes (15): householdFilterProvider, householdListNotifierProvider, _applyFilter, build, _confirmDelete, createState, dispose, _filterDropdown (+7 more)

### Community 59 - "deno.d.ts"
Cohesion: 0.08
Nodes (9): AdminAuthClient, Deno, env, GoTrueClient, npm:@supabase/supabase-js@2.45.4, PostgrestFilterBuilder, SupabaseClient, SupabaseClientOptions (+1 more)

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "tropa_animated_logo.dart"
Cohesion: 0.06
Nodes (27): _brandGreen, build, createState, _ctrl, _cycleMs, didChangeDependencies, dispose, dx (+19 more)

### Community 63 - "settings_view.dart"
Cohesion: 0.13
Nodes (6): TropaPalette, onTap, palette, _SectionPicker, selected, _ThemeSwatch

### Community 64 - "TextInputFormatter"
Cohesion: 0.40
Nodes (4): UpperCaseFormatter, _DateSlashFormatter, _PhicFormatter, _PhMobileFormatter

### Community 66 - "dues_rate_tab.dart"
Cohesion: 0.17
Nodes (10): _amount, createState, _delete, dispose, DuesRateTab, _DuesRateTabState, _month, _peso (+2 more)

### Community 67 - "gen_sw.mjs"
Cohesion: 0.13
Nodes (10): CANVASKIT, files, hash, indexPath, output, precache, SKIP_NAMES, templatePath (+2 more)

### Community 68 - "image_compress.dart"
Cohesion: 0.13
Nodes (13): buffer, codec, compressPhoto, descriptor, encodeJpg, flat, frame, h (+5 more)

### Community 69 - "auth_provider.dart"
Cohesion: 0.10
Nodes (17): authStateStreamProvider, _blockedReason, contains, _deactivatedMessage, _endSession, _logLogin, _noAccessMessage, permissions (+9 more)

### Community 70 - "tropa_id_card.dart"
Cohesion: 0.04
Nodes (51): _bar, blue, body, bodyDark, build, _c, child, children (+43 more)

### Community 71 - "Cross-Platform Flutter Desktop & Web Application Architecture"
Cohesion: 0.25
Nodes (7): 1. `pubspec.yaml`, 2. Design System & Theme Provider (`theme_provider.dart`), 3. Data Models (`models.dart`), 4. Supabase Service with Auto-Activity Logging & Storage, 5. `go_router` Role-Based Route Guarding, Cross-Platform Flutter Desktop & Web Application Architecture, TROPA v2 (Tabang Respeto Og Panalipud)

### Community 72 - "../core/ph_time.dart"
Cohesion: 0.11
Nodes (10): activityLogsAsyncProvider, items, service, voterSnapshotStatusProvider, ActivityLogsView, build, build, VoterSnapshotStatusLine (+2 more)

### Community 73 - "vercel.json"
Cohesion: 0.25
Nodes (7): buildCommand, framework, headers, installCommand, outputDirectory, rewrites, $schema

### Community 74 - "geo.dart"
Cohesion: 0.17
Nodes (11): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+3 more)

### Community 76 - "device_seed_web.dart"
Cohesion: 0.11
Nodes (15): buffer, candidates, decompressor, deviceSeedSupported, downloadBytes, existing, features, _gunzip (+7 more)

### Community 79 - "form_fields.dart"
Cohesion: 0.11
Nodes (15): build, child, children, color, crossAxisAlignment, formatEditUpdate, icon, label (+7 more)

### Community 80 - "StatelessWidget"
Cohesion: 0.10
Nodes (19): _CardFrame, _Divided, _Field, _MicroText, _PhotoPlaceholder, TropaIdCardBack, TropaIdCardFront, _DuesTabs (+11 more)

### Community 81 - "membership_date_dialog.dart"
Cohesion: 0.08
Nodes (22): _BarangayStartMonthDialog, _BarangayStartMonthDialogState, build, _countRequest, createState, _current, _firstYear, initState (+14 more)

### Community 83 - "supabaseServiceProvider"
Cohesion: 0.11
Nodes (17): supabaseServiceProvider, deleteBatch, deleteHousehold, addMember, addMembersBulk, deleteMember, setMemberArchived, transferMember (+9 more)

### Community 84 - "login_view.dart"
Cohesion: 0.13
Nodes (10): build, createState, dispose, _emailCtrl, _errorMessage, _handleLogin, initState, _isLoading (+2 more)

### Community 85 - "20261019000000_dues_ledger.sql"
Cohesion: 0.27
Nodes (7): check_dues_payment_update, dues_payments_member_status_idx, dues_payments_receipt_idx, dues_rates_updated_at_idx, log_deleted_record, public.dues_rates, touch_updated

### Community 87 - "ConsumerWidget"
Cohesion: 0.15
Nodes (14): duesHouseholdResultsProvider, duesMemberResultsProvider, duesPanelProvider, duesRatesProvider, duesScopeProvider, DuesCollectionView, _HouseholdResults, _MemberResults (+6 more)

### Community 88 - "compilerOptions"
Cohesion: 0.22
Nodes (8): compilerOptions, lib, module, moduleResolution, skipLibCheck, strict, target, include

### Community 90 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (3): main, page, scrolls

### Community 94 - "build"
Cohesion: 0.26
Nodes (12): duesLedgerPageProvider, duesLedgerQueryProvider, duesLedgerTotalsProvider, duesReceiptsProvider, duesSearchProvider, duesSelectionProvider, build, _CollectTab (+4 more)

### Community 95 - "tropa_member.dart"
Cohesion: 0.06
Nodes (27): address, authorizedSignature, birthDate, dateIssued, firstName, formatIdDate, fullName, hotline (+19 more)

### Community 98 - "String?"
Cohesion: 0.25
Nodes (4): build, error, onRetry, StartupScreen

### Community 100 - "State"
Cohesion: 0.17
Nodes (14): TropaStartup, _TropaStartupState, TropaIdFlipCard, _TropaIdFlipCardState, _TypeableDateField, _TypeableDateFieldState, _MembershipDateDialog, _MembershipDateDialogState (+6 more)

### Community 101 - "memberListNotifierProvider"
Cohesion: 0.25
Nodes (8): memberListNotifierProvider, _confirmDelete, BulkAddMemberDialog, _BulkAddMemberDialogState, _saveBulkBatch, _confirmRemove, _saveMemberRecord, _save

### Community 102 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.11
Nodes (11): booleanColumns, jsonColumns, schema, snapshotVoterLgus, deviceSeedSupported, false, installDeviceSeed, publishDeviceSeed (+3 more)

### Community 103 - "officers_tab.dart"
Cohesion: 0.15
Nodes (10): Location, createState, location, _locationId, OfficersTab, _OfficersTabState, _open, purok (+2 more)

### Community 106 - "StateNotifier"
Cohesion: 0.47
Nodes (4): AppThemeNotifier, AppUserNotifier, HouseholdListNotifier, VoterNotifier

### Community 107 - "20261021000000_member_id_number.sql"
Cohesion: 0.47
Nodes (3): family_members_id_number, family_members_id_number_key, public.family_members_assign_id_number()

### Community 110 - "tropa_id_export.dart"
Cohesion: 0.13
Nodes (9): boundary, build, captureKey, captureTropaIdPng, child, data, image, ratio (+1 more)

### Community 114 - "theme_palettes.dart"
Cohesion: 0.09
Nodes (18): accentText, background, border, brand, brightness, defaultId, id, muted (+10 more)

### Community 115 - "List"
Cohesion: 0.22
Nodes (7): actions, below, build, subtitle, title, titleTrailing, TropaPageHeader

### Community 116 - "20261015000000_admin_settings.sql"
Cohesion: 0.33
Nodes (3): officers, officers_touch_updated_at, public.is_tropa_admin()

### Community 119 - "package:flutter/foundation.dart"
Cohesion: 0.29
Nodes (3): build, child, WebKeyboardInset

### Community 120 - "static const"
Cohesion: 0.33
Nodes (3): _loadPreference, _prefKey, setTheme

### Community 121 - "keyboard_safe_body.dart"
Cohesion: 0.25
Nodes (5): build, child, KeyboardSafeBody, minHeight, padding

### Community 122 - "../providers/auth_provider.dart"
Cohesion: 0.14
Nodes (11): currentAppUserProvider, userPermissionsProvider, build, child, currentPath, inDrawer, _navItem, _pageTitle (+3 more)

### Community 123 - "../core/design_system.dart"
Cohesion: 0.24
Nodes (5): dashboardMetricsProvider, householdCoordinatesProvider, build, DashboardView, _kpiCard

### Community 125 - "ConsumerState"
Cohesion: 0.24
Nodes (9): LoginView, _LoginViewState, _LocationFormDialog, _LocationFormDialogState, LocationsTab, _LocationsTabState, FormTrackingDialog, _FormTrackingDialogState (+1 more)

### Community 127 - "main.dart"
Cohesion: 0.20
Nodes (4): createState, main, _ready, _start

### Community 128 - "build"
Cohesion: 0.17
Nodes (14): PendingUpload, pendingUploadEntriesProvider, pendingUploadsProvider, syncStateProvider, syncStatusProvider, fallbackSyncStateProvider, build, build (+6 more)

## Knowledge Gaps
- **1537 isolated node(s):** `TropaColors`, `TropaTheme`, `TropaText`, `TropaStyles`, `TropaBreakpoints` (+1532 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1796 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **40 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `officers` connect `20261015000000_admin_settings.sql` to `officers_tab.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `TropaText` to the rest of the system?**
  _1537 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.011976047904191617 - nodes in this community are weakly interconnected._
- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `bulk_add_member_dialog.dart`, `tropa_finder_view.dart`, `tropa_map_widget.dart`, `members_view.dart`, `form_tracking_provider.dart`, `household_provider.dart`, `user_form_dialog.dart`, `officer_form_dialog.dart`, `locations_tab.dart`, `users_tab.dart`, `transfer_member_dialog.dart`, `ConsumerWidget`, `form_tracking_view.dart`, `household_view_dialog.dart`, `locationsProvider`, `voter_provider.dart`, `households_view.dart`, `dues_rate_tab.dart`, `auth_provider.dart`, `membership_date_dialog.dart`, `ConsumerWidget`, `memberListNotifierProvider`, `officers_tab.dart`, `StateNotifier`, `../providers/auth_provider.dart`, `ConsumerState`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.010471204188481676 - nodes in this community are weakly interconnected._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.025 - nodes in this community are weakly interconnected._
- **Should `supabase_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01834862385321101 - nodes in this community are weakly interconnected._