# Graph Report - TROPAV2  (2026-10-21)

## Corpus Check
- 116 files · ~131,056 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 3, .toml 1)

## Summary
- 2232 nodes · 3136 edges · 119 communities (83 shown, 36 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4ef8739f`
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
- member_id_view.dart
- offline_auth.dart
- tropa_map_widget.dart
- ../core/design_system.dart
- dues_provider.dart
- geo.dart
- form_tracking_provider.dart
- household_provider.dart
- user_form_dialog.dart
- form_tracking_dialog.dart
- settings_view.dart
- officer_form_dialog.dart
- dues_view.dart
- locations_tab.dart
- ../providers/auth_provider.dart
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
- dues_math.dart
- package:flutter/material.dart
- supabase_connector.dart
- officers_tab.dart
- 20261016000000_fallback_sync.sql
- reports_view.dart
- form_tracking_view.dart
- package:supabase_flutter/supabase_flutter.dart
- household_view_dialog.dart
- members_view.dart
- ph_time.dart
- index.ts
- voter_provider.dart
- households_view.dart
- deno.d.ts
- 20261014000000_voter_snapshot.sql
- tropa_animated_logo.dart
- _MembersViewState
- TextInputFormatter
- dues_rate_tab.dart
- gen_sw.mjs
- image_compress.dart
- auth_provider.dart
- tropa_id_card.dart
- Cross-Platform Flutter Desktop & Web Application Architecture
- ConsumerWidget
- vercel.json
- main.dart
- ConsumerState
- device_seed_web.dart
- sw.template.js
- build_web.sh
- form_fields.dart
- StatelessWidget
- membership_date_dialog.dart
- voter_registry_tab.dart
- ../core/ph_time.dart
- 20261019000000_dues_ledger.sql
- _PaymentPanelState
- compilerOptions
- 20261018010000_system_admin_and_delete.sql
- package:intl/intl.dart
- build
- tropa_member.dart
- TropaScreen
- 20261018030000_match_profile_by_email.sql
- _SlideGradient
- public.can_collect_dues_for
- State
- List
- ../core/design_system.dart
- String?
- 20261021000000_member_id_number.sql
- CustomPainter
- tropa_id_export.dart
- theme_palettes.dart
- public.can_manage_members
- static const
- puroksProvider

## God Nodes (most connected - your core abstractions)
1. `supabaseServiceProvider` - 67 edges
2. `locationsProvider` - 14 edges
3. `canPermissionProvider` - 13 edges
4. `memberListNotifierProvider` - 13 edges
5. `build` - 13 edges
6. `puroksProvider` - 12 edges
7. `currentAppUserProvider` - 11 edges
8. `householdListNotifierProvider` - 11 edges
9. `log_deleted_record` - 11 edges
10. `localDbProvider` - 9 edges

## Surprising Connections (you probably didn't know these)
- `createBatches` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `deleteBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `updateBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `addHousehold` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/household_provider.dart → lib/providers/auth_provider.dart
- `deleteHousehold` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/household_provider.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (119 total, 36 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.01
Nodes (162): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+154 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.01
Nodes (181): _addDependentRow, _addDependentRowFromShortcut, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch (+173 more)

### Community 2 - "design_system.dart"
Cohesion: 0.03
Nodes (75): action, backgroundOf, badge, body, bodyStrong, borderOf, _build, _cache (+67 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.02
Nodes (100): _adminUsers, _checkUniqueLocation, _checkUniquePurok, client, countAllMembers, countHouseholdMembers, createFamilyMembersBulk, createFormBatches (+92 more)

### Community 5 - "bulk_add_member_dialog.dart"
Cohesion: 0.07
Nodes (28): _addRow, ageCtrl, build, BulkAddMemberDialog, _BulkAddMemberDialogState, BulkMemberRowData, createState, dispose (+20 more)

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
Cohesion: 0.05
Nodes (37): auth, backup, backupPhase, _connect, db, dbGeneration, false, initialize (+29 more)

### Community 10 - "member_id_view.dart"
Cohesion: 0.11
Nodes (16): _backKey, build, createState, ext, _frontKey, idNumber, member, MemberIdView (+8 more)

### Community 11 - "offline_auth.dart"
Cohesion: 0.14
Nodes (12): _credentialKey, isLocked, _iterations, localDbOwner, _lockedKey, OfflineAuth, _ownerKey, _pbkdf2 (+4 more)

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.07
Nodes (23): build, _buildCircles, _circles, createState, didChangeDependencies, didUpdateWidget, dispose, _hitNotifier (+15 more)

### Community 13 - "../core/design_system.dart"
Cohesion: 0.28
Nodes (5): dashboardMetricsProvider, householdCoordinatesProvider, build, DashboardView, _kpiCard

### Community 14 - "dues_provider.dart"
Cohesion: 0.11
Nodes (17): DuesScope, 0, copyWith, DuesSearch, DuesSearchMode, DuesSelection, _duesTables, _duesUserIdProvider (+9 more)

### Community 15 - "geo.dart"
Cohesion: 0.14
Nodes (11): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+3 more)

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.10
Nodes (17): barangay, _changes, copyWith, createBatches, deleteBatch, dispose, FormTrackingFilter, lgu (+9 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.10
Nodes (19): addHousehold, archived, barangay, _changes, copyWith, deleteHousehold, dispose, filter (+11 more)

### Community 18 - "user_form_dialog.dart"
Cohesion: 0.07
Nodes (27): _applyPreset, _BarangayPickerDialog, _BarangayPickerDialogState, build, createState, dispose, _duesBarangays, _email (+19 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (23): FormTracking, count, createState, dispose, _encodedBy, _entries, existing, _formKey (+15 more)

### Community 20 - "settings_view.dart"
Cohesion: 0.13
Nodes (6): TropaPalette, onTap, palette, _SectionPicker, selected, _ThemeSwatch

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.07
Nodes (25): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+17 more)

### Community 22 - "dues_view.dart"
Cohesion: 0.05
Nodes (38): DuesMember, DuesReceipt, amount, balance, caption, child, color, createState (+30 more)

### Community 23 - "locations_tab.dart"
Cohesion: 0.09
Nodes (21): _addPurok, _barangay, _coordValidator, createState, _deleteLocation, _deletePurok, dispose, _editLocation (+13 more)

### Community 24 - "../providers/auth_provider.dart"
Cohesion: 0.05
Nodes (20): TropaBrand, userPermissionsProvider, permissions, userAsync, build, createState, dispose, _emailCtrl (+12 more)

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
Nodes (39): client, coreVersionAccepts, d, details, device, deviceSeedBucket, deviceSeedManifestPath, deviceSeedProgress (+31 more)

### Community 33 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Form Fields & Checkboxes, Geospatial Control Overlays (+5 more)

### Community 37 - "supabaseServiceProvider"
Cohesion: 0.11
Nodes (22): AppThemeNotifier, AppUserNotifier, supabaseServiceProvider, FormBatchNotifier, HouseholdListNotifier, addMember, addMembersBulk, deleteMember (+14 more)

### Community 38 - "users_tab.dart"
Cohesion: 0.08
Nodes (28): AppUser, currentAppUserProvider, SettingsPalette, barangayNames, _barangayNamesProvider, build, createState, _HeaderRow (+20 more)

### Community 39 - "transfer_member_dialog.dart"
Cohesion: 0.13
Nodes (14): FamilyMember, Household, build, createState, _currentHousehold, _householdPicker, initState, _isSaving (+6 more)

### Community 40 - "device_seed_card.dart"
Cohesion: 0.15
Nodes (13): localDbProvider, createState, DeviceSeedCard, _DeviceSeedCardState, _download, initState, _load, _loading (+5 more)

### Community 41 - "device_seed_io.dart"
Cohesion: 0.13
Nodes (11): bytes, copy, deviceSeedSupported, gz, installDeviceSeed, _installing, outcome, _partSize (+3 more)

### Community 42 - "fallback_sync.dart"
Cohesion: 0.04
Nodes (45): _activateAfter, _applyDeletions, bools, client, column, cursor, _cursorsCleared, _deactivate (+37 more)

### Community 43 - "dues_math.dart"
Cohesion: 0.05
Nodes (34): afterPaying, amountDue, amountFor, amountForMonths, balanceFor, best, bestMonth, currentMonth (+26 more)

### Community 46 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (8): _backKey, build, createState, _export, _frontKey, member, MyIdPage, _MyIdPageState

### Community 47 - "supabase_connector.dart"
Cohesion: 0.14
Nodes (9): _batchable, _batchSize, _client, _fatalPostgresCodes, fetchCredentials, invalidateCredentials, SupabaseConnector, _toRemote (+1 more)

### Community 48 - "officers_tab.dart"
Cohesion: 0.11
Nodes (11): Location, createState, location, _locationId, officers, _open, purok, _PurokOfficers (+3 more)

### Community 49 - "20261016000000_fallback_sync.sql"
Cohesion: 0.15
Nodes (13): deleted_records_deleted_at_idx, dues_payments_updated_date_idx, family_members_updated_date_idx, form_tracking_updated_at_idx, households_updated_date_idx, log_deleted_record, officers_updated_at_idx, public.deleted_records (+5 more)

### Community 50 - "reports_view.dart"
Cohesion: 0.13
Nodes (14): barangayReportProvider, reportLguFilterProvider, _breakdownTable, build, createState, _dec1, _dec2, _int (+6 more)

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.07
Nodes (31): formBatchNotifierProvider, formTrackingFilterProvider, _applyFilter, assignedTo, batch, _body, build, _cardDateFmt (+23 more)

### Community 52 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.12
Nodes (10): booleanColumns, jsonColumns, schema, snapshotVoterLgus, deviceSeedSupported, false, installDeviceSeed, publishDeviceSeed (+2 more)

### Community 53 - "household_view_dialog.dart"
Cohesion: 0.11
Nodes (16): householdListNotifierProvider, _confirmDelete, _confirmRemove, createState, _currentHousehold, _fetchRoster, household, HouseholdViewDialog (+8 more)

### Community 54 - "members_view.dart"
Cohesion: 0.10
Nodes (16): createState, dispose, _filterDropdown, _firstNameCtrl, _householdFilter, _isPrinting, _lastNameCtrl, _middleNameCtrl (+8 more)

### Community 55 - "ph_time.dart"
Cohesion: 0.06
Nodes (19): formatPh, _hasOffset, _hasTime, p, parsePh, phNow, phOffset, phToday (+11 more)

### Community 57 - "voter_provider.dart"
Cohesion: 0.10
Nodes (18): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, flagVoter (+10 more)

### Community 58 - "households_view.dart"
Cohesion: 0.13
Nodes (10): householdFilterProvider, _applyFilter, build, createState, dispose, _filterDropdown, HouseholdsView, _HouseholdsViewState (+2 more)

### Community 59 - "deno.d.ts"
Cohesion: 0.08
Nodes (9): AdminAuthClient, Deno, env, GoTrueClient, npm:@supabase/supabase-js@2.45.4, PostgrestFilterBuilder, SupabaseClient, SupabaseClientOptions (+1 more)

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "tropa_animated_logo.dart"
Cohesion: 0.07
Nodes (26): _brandGreen, build, createState, _ctrl, _cycleMs, didChangeDependencies, dispose, dx (+18 more)

### Community 63 - "_MembersViewState"
Cohesion: 0.24
Nodes (9): memberFilterProvider, memberListNotifierProvider, _applyFilter, build, _confirmDelete, MembersView, _MembersViewState, _saveBulkBatch (+1 more)

### Community 64 - "TextInputFormatter"
Cohesion: 0.40
Nodes (4): UpperCaseFormatter, _DateSlashFormatter, _PhicFormatter, _PhMobileFormatter

### Community 66 - "dues_rate_tab.dart"
Cohesion: 0.17
Nodes (10): _amount, createState, _delete, dispose, DuesRateTab, _DuesRateTabState, _month, _peso (+2 more)

### Community 67 - "gen_sw.mjs"
Cohesion: 0.14
Nodes (9): CANVASKIT, files, hash, output, precache, SKIP_NAMES, templatePath, version (+1 more)

### Community 68 - "image_compress.dart"
Cohesion: 0.12
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

### Community 72 - "ConsumerWidget"
Cohesion: 0.18
Nodes (13): canPermissionProvider, duesHouseholdResultsProvider, duesMemberResultsProvider, duesRatesProvider, DuesCollectionView, _HouseholdResults, _MemberResults, _ReceiptTile (+5 more)

### Community 73 - "vercel.json"
Cohesion: 0.25
Nodes (7): buildCommand, framework, headers, installCommand, outputDirectory, rewrites, $schema

### Community 74 - "main.dart"
Cohesion: 0.14
Nodes (10): appThemeProvider, build, createState, main, _ready, _start, TropaApp, routerProvider (+2 more)

### Community 75 - "ConsumerState"
Cohesion: 0.14
Nodes (19): adminUsersProvider, locationsProvider, FormTrackingView, _FormTrackingViewState, _openHouseholdDialog, LoginView, _LoginViewState, _LocationFormDialog (+11 more)

### Community 76 - "device_seed_web.dart"
Cohesion: 0.11
Nodes (15): buffer, candidates, decompressor, deviceSeedSupported, downloadBytes, existing, features, _gunzip (+7 more)

### Community 79 - "form_fields.dart"
Cohesion: 0.11
Nodes (15): build, child, children, color, crossAxisAlignment, formatEditUpdate, icon, label (+7 more)

### Community 80 - "StatelessWidget"
Cohesion: 0.10
Nodes (20): _CardFrame, _Divided, _Field, _MicroText, _PhotoPlaceholder, TropaIdCardBack, TropaIdCardFront, _DuesTabs (+12 more)

### Community 81 - "membership_date_dialog.dart"
Cohesion: 0.08
Nodes (22): _barangay, _BarangayMembershipDialog, _BarangayMembershipDialogState, barangays, build, _countRequest, createState, _current (+14 more)

### Community 83 - "voter_registry_tab.dart"
Cohesion: 0.18
Nodes (9): build, createState, initState, _loadingManifest, _loadManifest, _manifest, _progress, VoterRegistryTab (+1 more)

### Community 84 - "../core/ph_time.dart"
Cohesion: 0.20
Nodes (5): activityLogsAsyncProvider, items, service, ActivityLogsView, build

### Community 85 - "20261019000000_dues_ledger.sql"
Cohesion: 0.27
Nodes (7): check_dues_payment_update, dues_payments_member_status_idx, dues_payments_receipt_idx, dues_rates_updated_at_idx, log_deleted_record, public.dues_rates, touch_updated

### Community 87 - "_PaymentPanelState"
Cohesion: 0.33
Nodes (6): duesPanelProvider, duesScopeProvider, _PaymentPanel, _PaymentPanelState, _record, _setBarangayMonth

### Community 88 - "compilerOptions"
Cohesion: 0.22
Nodes (8): compilerOptions, lib, module, moduleResolution, skipLibCheck, strict, target, include

### Community 94 - "build"
Cohesion: 0.26
Nodes (12): duesLedgerPageProvider, duesLedgerQueryProvider, duesLedgerTotalsProvider, duesReceiptsProvider, duesSearchProvider, duesSelectionProvider, build, _CollectTab (+4 more)

### Community 95 - "tropa_member.dart"
Cohesion: 0.06
Nodes (27): address, authorizedSignature, birthDate, dateIssued, firstName, formatIdDate, fullName, hotline (+19 more)

### Community 100 - "State"
Cohesion: 0.17
Nodes (14): TropaStartup, _TropaStartupState, TropaIdFlipCard, _TropaIdFlipCardState, _PromptDialog, _PromptDialogState, _TypeableDateField, _TypeableDateFieldState (+6 more)

### Community 101 - "List"
Cohesion: 0.22
Nodes (7): actions, below, build, subtitle, title, titleTrailing, TropaPageHeader

### Community 102 - "../core/design_system.dart"
Cohesion: 0.40
Nodes (3): voterSnapshotStatusProvider, build, VoterSnapshotStatusLine

### Community 106 - "String?"
Cohesion: 0.25
Nodes (4): build, error, onRetry, StartupScreen

### Community 107 - "20261021000000_member_id_number.sql"
Cohesion: 0.47
Nodes (3): family_members_id_number, family_members_id_number_key, public.family_members_assign_id_number()

### Community 110 - "tropa_id_export.dart"
Cohesion: 0.13
Nodes (9): boundary, build, captureKey, captureTropaIdPng, child, data, image, ratio (+1 more)

### Community 114 - "theme_palettes.dart"
Cohesion: 0.09
Nodes (18): accentText, background, border, brand, brightness, defaultId, id, muted (+10 more)

### Community 120 - "static const"
Cohesion: 0.20
Nodes (4): _loadPreference, _prefKey, setTheme, main

### Community 125 - "puroksProvider"
Cohesion: 0.28
Nodes (9): adminLocationsProvider, officersProvider, puroksProvider, build, _LocationDetail, _BarangayOfficers, build, _buildPurokDropdown (+1 more)

## Knowledge Gaps
- **1455 isolated node(s):** `TropaColors`, `TropaTheme`, `TropaText`, `TropaStyles`, `TropaBreakpoints` (+1450 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1699 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **36 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `bulk_add_member_dialog.dart`, `tropa_finder_view.dart`, `tropa_map_widget.dart`, `form_tracking_provider.dart`, `household_provider.dart`, `user_form_dialog.dart`, `officer_form_dialog.dart`, `locations_tab.dart`, `users_tab.dart`, `transfer_member_dialog.dart`, `officers_tab.dart`, `household_view_dialog.dart`, `members_view.dart`, `voter_provider.dart`, `households_view.dart`, `_MembersViewState`, `dues_rate_tab.dart`, `auth_provider.dart`, `ConsumerWidget`, `ConsumerState`, `_PaymentPanelState`, `build`, `puroksProvider`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `TropaText` to the rest of the system?**
  _1455 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012269938650306749 - nodes in this community are weakly interconnected._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.010471204188481676 - nodes in this community are weakly interconnected._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.025 - nodes in this community are weakly interconnected._
- **Should `supabase_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01904761904761905 - nodes in this community are weakly interconnected._
- **Should `bulk_add_member_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._