# Graph Report - TROPAV2  (2026-10-27)

## Corpus Check
- 131 files · ~140,679 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 7 file(s) not represented in the graph (top: (none) 3, .ttf 3, .toml 1)

## Summary
- 2434 nodes · 3419 edges · 134 communities (91 shown, 43 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6b0f1b6f`
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
- ConsumerWidget
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
- locationsProvider
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
- memberListNotifierProvider
- form_tracking_view.dart
- login_view.dart
- household_view_dialog.dart
- officers_tab.dart
- package:flutter_test/flutter_test.dart
- index.ts
- voter_provider.dart
- households_view.dart
- deno.d.ts
- 20261014000000_voter_snapshot.sql
- tropa_animated_logo.dart
- package:flutter/material.dart
- TextInputFormatter
- dues_rate_tab.dart
- gen_sw.mjs
- image_compress.dart
- auth_provider.dart
- tropa_id_card.dart
- Cross-Platform Flutter Desktop & Web Application Architecture
- sync_status_pill.dart
- vercel.json
- main.dart
- device_seed_web.dart
- sw.template.js
- build_web.sh
- form_fields.dart
- StatelessWidget
- membership_date_dialog.dart
- public.public_household_members
- public_search_view.dart
- 20261019000000_dues_ledger.sql
- reports_view.dart
- compilerOptions
- 20261018010000_system_admin_and_delete.sql
- _PromptDialog
- voter_registry_tab.dart
- tropa_member.dart
- TropaScreen
- 20261018030000_match_profile_by_email.sql
- geo.dart
- public.can_collect_dues_for
- State
- ../core/ph_time.dart
- package:supabase_flutter/supabase_flutter.dart
- package:google_fonts/google_fonts.dart
- supabaseServiceProvider
- 20261021000000_member_id_number.sql
- CustomPainter
- tropa_id_export.dart
- theme_palettes.dart
- String?
- 20261015000000_admin_settings.sql
- public.can_manage_members
- login_view.dart
- appThemeProvider
- keyboard_safe_body.dart
- ../providers/auth_provider.dart
- offline_auth.dart
- ConsumerState
- 20261023000000_barangay_start_month.sql
- settings_view.dart
- package:flutter/foundation.dart
- static const
- public.public_household_members
- ../core/design_system.dart
- public.public_member_search
- PowerSyncDatabase

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

## Communities (134 total, 43 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.01
Nodes (166): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+158 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.01
Nodes (186): _addDependentRow, _addDependentRowFromShortcut, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch (+178 more)

### Community 2 - "design_system.dart"
Cohesion: 0.03
Nodes (75): action, backgroundOf, badge, body, bodyStrong, borderOf, _build, _cache (+67 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.02
Nodes (104): _adminUsers, _checkUniqueLocation, _checkUniquePurok, client, countAllMembers, countHouseholdMembers, createFamilyMembersBulk, createFormBatches (+96 more)

### Community 5 - "bulk_add_member_dialog.dart"
Cohesion: 0.07
Nodes (27): _addRow, ageCtrl, build, BulkMemberRowData, createState, dispose, firstnameCtrl, _householdOptions (+19 more)

### Community 6 - "tropa_finder_view.dart"
Cohesion: 0.08
Nodes (21): _actionWidth, _applyNames, _cell, _columns, createState, dispose, _filterDropdown, _firstNameCtrl (+13 more)

### Community 7 - "settings_common.dart"
Cohesion: 0.04
Nodes (42): action, actions, body, bodyStrong, border, build, caption, card (+34 more)

### Community 8 - "member_provider.dart"
Cohesion: 0.07
Nodes (29): addMember, addMembersBulk, archived, barangay, _changes, copyWith, deleteMember, dispose (+21 more)

### Community 9 - "db.dart"
Cohesion: 0.06
Nodes (25): auth, backup, backupPhase, _connect, db, dbGeneration, _ensureVoterListFor, ensureVoterSnapshot (+17 more)

### Community 10 - "20261022000000_barangay_sync.sql"
Cohesion: 0.16
Nodes (12): dues_payments_sync_key_idx, family_members_sync_key_idx, households_sync_key_idx, move_payments_sync_key, public.can_collect_dues_in(), public.move_member_payments_sync_key(), public.refresh_user_sync_scopes(), public.set_payment_sync_key() (+4 more)

### Community 11 - "ConsumerWidget"
Cohesion: 0.09
Nodes (27): adminUsersProvider, canPermissionProvider, currentAppUserProvider, userPermissionsProvider, duesScopeProvider, formTrackingFilterProvider, DuesCollectionView, _PaymentPanel (+19 more)

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.07
Nodes (21): build, _buildCircles, _circles, createState, didChangeDependencies, didUpdateWidget, dispose, _hitNotifier (+13 more)

### Community 13 - "members_view.dart"
Cohesion: 0.09
Nodes (17): _confirmDelete, createState, dispose, _filterDropdown, _firstNameCtrl, _householdFilter, _isPrinting, _lastNameCtrl (+9 more)

### Community 14 - "dues_provider.dart"
Cohesion: 0.08
Nodes (35): DuesScope, 0, copyWith, duesHouseholdResultsProvider, duesLedgerPageProvider, duesLedgerQueryProvider, duesLedgerTotalsProvider, duesMemberResultsProvider (+27 more)

### Community 15 - "bool get"
Cohesion: 0.18
Nodes (7): keyboardDebugRequested, VisibleArea, host, keyboardDebugRequested, rect, VisibleArea, vv

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.10
Nodes (17): barangay, _changes, copyWith, createBatches, deleteBatch, dispose, FormTrackingFilter, lgu (+9 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.08
Nodes (23): dashboardMetricsProvider, addHousehold, archived, barangay, _changes, copyWith, deleteHousehold, dispose (+15 more)

### Community 18 - "user_form_dialog.dart"
Cohesion: 0.07
Nodes (24): _applyPreset, build, createState, dispose, _duesBarangays, _email, _firstname, _formKey (+16 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (23): FormTracking, count, createState, dispose, _encodedBy, _entries, existing, _formKey (+15 more)

### Community 20 - "member_id_view.dart"
Cohesion: 0.06
Nodes (31): _actionBarHeight, blocks, bold, border, build, buildDuesSheet, cell, columnHeader (+23 more)

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.08
Nodes (23): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+15 more)

### Community 22 - "dues_view.dart"
Cohesion: 0.04
Nodes (49): DuesMember, DuesReceipt, amount, balance, caption, child, color, createState (+41 more)

### Community 23 - "locations_tab.dart"
Cohesion: 0.08
Nodes (27): _addPurok, _barangay, _clearStartMonth, _coordValidator, createState, _deleteLocation, _deletePurok, dispose (+19 more)

### Community 24 - "locationsProvider"
Cohesion: 0.14
Nodes (21): adminLocationsProvider, officersProvider, barangayStartMonthsProvider, householdFilterProvider, householdListNotifierProvider, locationsProvider, puroksProvider, _applyFilter (+13 more)

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
Cohesion: 0.04
Nodes (40): client, coreVersionAccepts, d, details, device, deviceSeedBucket, deviceSeedManifestPath, deviceSeedProgress (+32 more)

### Community 33 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Colors, Components, Data Tables, Elevation & Depth, Form Fields & Checkboxes, Geospatial Control Overlays (+5 more)

### Community 37 - "member_id_view.dart"
Cohesion: 0.10
Nodes (18): _backKey, build, createState, ext, _frontKey, idNumber, member, MemberIdPanel (+10 more)

### Community 38 - "users_tab.dart"
Cohesion: 0.08
Nodes (24): AppUser, SettingsPalette, barangayNames, createState, _delete, _HeaderRow, _initials, isSelf (+16 more)

### Community 39 - "transfer_member_dialog.dart"
Cohesion: 0.13
Nodes (14): FamilyMember, Household, build, createState, _currentHousehold, _householdPicker, initState, _isSaving (+6 more)

### Community 40 - "device_seed_card.dart"
Cohesion: 0.14
Nodes (15): localDbProvider, pendingUploadsProvider, build, createState, DeviceSeedCard, _DeviceSeedCardState, _download, initState (+7 more)

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

### Community 50 - "memberListNotifierProvider"
Cohesion: 0.27
Nodes (10): memberCountsProvider, memberFilterProvider, memberListNotifierProvider, _applyFilter, build, MembersView, _MembersViewState, _confirmRemove (+2 more)

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.07
Nodes (29): formBatchNotifierProvider, _applyFilter, assignedTo, batch, _body, _cardDateFmt, _cardDateYearFmt, cardWidth (+21 more)

### Community 53 - "household_view_dialog.dart"
Cohesion: 0.14
Nodes (10): createState, _currentHousehold, _fetchRoster, household, HouseholdViewDialog, _HouseholdViewDialogState, initState, _isLoadingRoster (+2 more)

### Community 54 - "officers_tab.dart"
Cohesion: 0.15
Nodes (10): Location, createState, location, _locationId, OfficersTab, _OfficersTabState, _open, purok (+2 more)

### Community 55 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (11): main, main, months, main, main, member, oct2026, rate (+3 more)

### Community 57 - "voter_provider.dart"
Cohesion: 0.10
Nodes (18): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, flagVoter (+10 more)

### Community 58 - "households_view.dart"
Cohesion: 0.13
Nodes (6): createState, dispose, _filterDropdown, HouseholdsView, _searchCtrl, _toggleArchived

### Community 59 - "deno.d.ts"
Cohesion: 0.08
Nodes (9): AdminAuthClient, Deno, env, GoTrueClient, npm:@supabase/supabase-js@2.45.4, PostgrestFilterBuilder, SupabaseClient, SupabaseClientOptions (+1 more)

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "tropa_animated_logo.dart"
Cohesion: 0.06
Nodes (27): _brandGreen, build, createState, _ctrl, _cycleMs, didChangeDependencies, dispose, dx (+19 more)

### Community 63 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (3): main, page, scrolls

### Community 64 - "TextInputFormatter"
Cohesion: 0.40
Nodes (4): UpperCaseFormatter, _DateSlashFormatter, _PhicFormatter, _PhMobileFormatter

### Community 66 - "dues_rate_tab.dart"
Cohesion: 0.13
Nodes (13): duesRatesProvider, _print, _amount, build, createState, _delete, dispose, DuesRateTab (+5 more)

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

### Community 72 - "sync_status_pill.dart"
Cohesion: 0.21
Nodes (12): PendingUpload, pendingUploadEntriesProvider, syncStateProvider, syncStatusProvider, fallbackSyncStateProvider, build, compact, entry (+4 more)

### Community 73 - "vercel.json"
Cohesion: 0.25
Nodes (7): buildCommand, framework, headers, installCommand, outputDirectory, rewrites, $schema

### Community 74 - "main.dart"
Cohesion: 0.20
Nodes (4): createState, main, _ready, _start

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
Nodes (22): build, _countRequest, createState, _current, _firstYear, initState, location, members (+14 more)

### Community 84 - "public_search_view.dart"
Cohesion: 0.05
Nodes (43): _barangay, birthDate, build, contact, createState, dispose, _error, _filterDropdown (+35 more)

### Community 85 - "20261019000000_dues_ledger.sql"
Cohesion: 0.27
Nodes (7): check_dues_payment_update, dues_payments_member_status_idx, dues_payments_receipt_idx, dues_rates_updated_at_idx, log_deleted_record, public.dues_rates, touch_updated

### Community 87 - "reports_view.dart"
Cohesion: 0.13
Nodes (14): barangayReportProvider, reportLguFilterProvider, _breakdownTable, build, createState, _dec1, _dec2, _int (+6 more)

### Community 88 - "compilerOptions"
Cohesion: 0.22
Nodes (8): compilerOptions, lib, module, moduleResolution, skipLibCheck, strict, target, include

### Community 94 - "voter_registry_tab.dart"
Cohesion: 0.17
Nodes (9): build, createState, initState, _loadingManifest, _loadManifest, _manifest, _progress, VoterRegistryTab (+1 more)

### Community 95 - "tropa_member.dart"
Cohesion: 0.06
Nodes (27): address, authorizedSignature, birthDate, dateIssued, firstName, formatIdDate, fullName, hotline (+19 more)

### Community 98 - "geo.dart"
Cohesion: 0.17
Nodes (11): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+3 more)

### Community 100 - "State"
Cohesion: 0.17
Nodes (14): TropaStartup, _TropaStartupState, TropaIdFlipCard, _TropaIdFlipCardState, DuesSheetPreview, _DuesSheetPreviewState, _TypeableDateField, _TypeableDateFieldState (+6 more)

### Community 101 - "../core/ph_time.dart"
Cohesion: 0.12
Nodes (8): activityLogsAsyncProvider, voterSnapshotStatusProvider, ActivityLogsView, build, build, VoterSnapshotStatusLine, instant, main

### Community 102 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.12
Nodes (10): booleanColumns, jsonColumns, schema, snapshotVoterLgus, deviceSeedSupported, false, installDeviceSeed, publishDeviceSeed (+2 more)

### Community 103 - "package:google_fonts/google_fonts.dart"
Cohesion: 0.25
Nodes (4): build, error, onRetry, StartupScreen

### Community 106 - "supabaseServiceProvider"
Cohesion: 0.24
Nodes (13): AppUserNotifier, supabaseServiceProvider, FormBatchNotifier, HouseholdListNotifier, MemberListNotifier, voterFilterProvider, VoterNotifier, voterNotifierProvider (+5 more)

### Community 107 - "20261021000000_member_id_number.sql"
Cohesion: 0.47
Nodes (3): family_members_id_number, family_members_id_number_key, public.family_members_assign_id_number()

### Community 110 - "tropa_id_export.dart"
Cohesion: 0.13
Nodes (9): boundary, build, captureKey, captureTropaIdPng, child, data, image, ratio (+1 more)

### Community 114 - "theme_palettes.dart"
Cohesion: 0.09
Nodes (18): accentText, background, border, brand, brightness, defaultId, id, muted (+10 more)

### Community 115 - "String?"
Cohesion: 0.22
Nodes (7): actions, below, build, subtitle, title, titleTrailing, TropaPageHeader

### Community 116 - "20261015000000_admin_settings.sql"
Cohesion: 0.33
Nodes (3): officers, officers_touch_updated_at, public.is_tropa_admin()

### Community 119 - "login_view.dart"
Cohesion: 0.13
Nodes (12): build, createState, dispose, _emailCtrl, _errorMessage, _handleLogin, initState, _isLoading (+4 more)

### Community 120 - "appThemeProvider"
Cohesion: 0.40
Nodes (6): appThemeProvider, build, TropaApp, routerProvider, _AppearanceTab, build

### Community 121 - "keyboard_safe_body.dart"
Cohesion: 0.25
Nodes (5): build, child, KeyboardSafeBody, minHeight, padding

### Community 122 - "../providers/auth_provider.dart"
Cohesion: 0.17
Nodes (7): TropaBrand, child, currentPath, inDrawer, _navItem, _pageTitle, rail

### Community 123 - "offline_auth.dart"
Cohesion: 0.14
Nodes (12): _credentialKey, isLocked, _iterations, localDbOwner, _lockedKey, OfflineAuth, _ownerKey, _pbkdf2 (+4 more)

### Community 125 - "ConsumerState"
Cohesion: 0.17
Nodes (14): _PrintSheetDialog, _PrintSheetDialogState, BulkAddMemberDialog, _BulkAddMemberDialogState, FormTrackingDialog, _FormTrackingDialogState, _BarangayStartMonthDialog, _BarangayStartMonthDialogState (+6 more)

### Community 127 - "settings_view.dart"
Cohesion: 0.13
Nodes (6): TropaPalette, onTap, palette, _SectionPicker, selected, _ThemeSwatch

### Community 128 - "package:flutter/foundation.dart"
Cohesion: 0.29
Nodes (3): build, child, WebKeyboardInset

### Community 129 - "static const"
Cohesion: 0.29
Nodes (4): AppThemeNotifier, _loadPreference, _prefKey, setTheme

## Knowledge Gaps
- **1579 isolated node(s):** `TropaColors`, `TropaTheme`, `TropaText`, `TropaStyles`, `TropaBreakpoints` (+1574 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1841 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **43 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `member_form_dialog.dart`, `bulk_add_member_dialog.dart`, `member_provider.dart`, `ConsumerWidget`, `tropa_map_widget.dart`, `members_view.dart`, `form_tracking_provider.dart`, `household_provider.dart`, `user_form_dialog.dart`, `dues_view.dart`, `locations_tab.dart`, `locationsProvider`, `users_tab.dart`, `transfer_member_dialog.dart`, `memberListNotifierProvider`, `household_view_dialog.dart`, `officers_tab.dart`, `voter_provider.dart`, `dues_rate_tab.dart`, `auth_provider.dart`, `ConsumerState`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `TropaText` to the rest of the system?**
  _1579 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.011976047904191617 - nodes in this community are weakly interconnected._
- **Why does `Household` connect `transfer_member_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `bulk_add_member_dialog.dart`, `tropa_map_widget.dart`, `members_view.dart`, `household_view_dialog.dart`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01020408163265306 - nodes in this community are weakly interconnected._
- **Why does `FamilyMember` connect `transfer_member_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `household_view_dialog.dart`, `member_id_view.dart`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.025 - nodes in this community are weakly interconnected._