# Graph Report - TROPAV2  (2026-11-26)

## Corpus Check
- 152 files · ~173,259 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 7 file(s) not represented in the graph (top: (none) 3, .ttf 3, .toml 1)

## Summary
- 2963 nodes · 4189 edges · 156 communities (102 shown, 54 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bc5bf5e6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- models.dart
- member_form_dialog.dart
- design_system.dart
- supabase_service.dart
- household_view_dialog.dart
- tropa_finder_view.dart
- settings_common.dart
- member_provider.dart
- db.dart
- 20261022000000_barangay_sync.sql
- duesScopeProvider
- tropa_map_widget.dart
- members_view.dart
- dues_provider.dart
- desktop_scaffold.dart
- form_tracking_provider.dart
- household_provider.dart
- user_form_dialog.dart
- form_tracking_dialog.dart
- member_id_view.dart
- officer_form_dialog.dart
- dues_view.dart
- locations_tab.dart
- motion.dart
- voter_snapshot.dart
- package:flutter_riverpod/flutter_riverpod.dart
- env.dart
- device_seed.dart
- TROPA Design System
- tropa_v2
- package:flutter/material.dart
- member_id_view.dart
- users_tab.dart
- supabaseServiceProvider
- device_seed_card.dart
- device_seed_io.dart
- fallback_sync.dart
- dues_math.dart
- package:flutter/material.dart
- supabase_connector.dart
- ph_time.dart
- 20261016000000_fallback_sync.sql
- tropa_id_export.dart
- form_tracking_view.dart
- login_view.dart
- offline_auth.dart
- officers_tab.dart
- review_view.dart
- index.ts
- voter_provider.dart
- dues_report_print.dart
- deno.d.ts
- 20261014000000_voter_snapshot.sql
- tropa_animated_logo.dart
- ConsumerWidget
- TextInputFormatter
- dues_rate_tab.dart
- gen_sw.mjs
- router.dart
- package:flutter/material.dart
- tropa_id_card.dart
- Cross-Platform Flutter Desktop & Web Application Architecture
- form_tracking_status_changed_at
- vercel.json
- public.has_any_tropa_permission
- device_seed_web.dart
- sw.template.js
- build_web.sh
- form_fields.dart
- StatelessWidget
- membership_date_dialog.dart
- public.public_household_members
- public_search_view.dart
- 20261019000000_dues_ledger.sql
- 20261112000000_dues_allocations.sql
- compilerOptions
- 20261018010000_system_admin_and_delete.sql
- bool get
- review_flags.dart
- tropa_member.dart
- TropaScreen
- 20261018030000_match_profile_by_email.sql
- activity_log_provider.dart
- public.can_collect_dues_for
- State
- voter_list_print.dart
- package:supabase_flutter/supabase_flutter.dart
- transfer_member_dialog.dart
- package:flutter_test/flutter_test.dart
- 20261021000000_member_id_number.sql
- settings_view.dart
- theme_palettes.dart
- auth_provider.dart
- household_compare_dialog.dart
- public.can_manage_members
- ../core/design_system.dart
- public.public_household_members
- Widget
- static const
- currentAppUserProvider
- review_provider.dart
- 20261023000000_barangay_start_month.sql
- geo.dart
- reports_view.dart
- build
- public.public_household_members
- package:intl/intl.dart
- public.public_member_search
- sync_status_pill.dart
- _ReviewViewState
- audit_logs_view.dart
- canPermissionProvider
- image_compress.dart
- public.update_household_member_counts
- StateNotifier
- 20261108000000_review_dismissals.sql
- GEMINI.md
- CustomPainter
- big_household_audit.sql
- package:flutter/material.dart
- 20261015000000_admin_settings.sql
- _CollectTabState
- activity_logs_search_text_trgm
- TropaBrand
- _PromptDialog
- DashboardView
- _BarangayPickerDialog
- PowerSyncDatabase

## God Nodes (most connected - your core abstractions)
1. `_` - 148 edges
2. `supabaseServiceProvider` - 80 edges
3. `build` - 23 edges
4. `canPermissionProvider` - 17 edges
5. `locationsProvider` - 17 edges
6. `householdListNotifierProvider` - 15 edges
7. `puroksProvider` - 15 edges
8. `memberListNotifierProvider` - 14 edges
9. `duesRatesProvider` - 13 edges
10. `localDbProvider` - 11 edges

## Surprising Connections (you probably didn't know these)
- `_` --references--> `DuesBalance`  [EXTRACTED]
  lib/views/dues_view.dart → lib/core/dues_math.dart
- `build` --references--> `pendingUploadsProvider`  [EXTRACTED]
  lib/views/settings/device_seed_card.dart → lib/data/db.dart
- `createBatches` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `deleteBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart
- `updateBatch` --references--> `supabaseServiceProvider`  [EXTRACTED]
  lib/providers/form_tracking_provider.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (156 total, 54 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.01
Nodes (189): action, activeMembers, ActivityLog, age, all, amount, AppPermissions, asBool (+181 more)

### Community 1 - "member_form_dialog.dart"
Cohesion: 0.01
Nodes (216): _addDependentRow, _addDependentRowFromShortcut, _ageOn, _applyDependentSeniorRule, _applySeniorRule, _avatarBytes, _avatarName, _backToSearch (+208 more)

### Community 2 - "design_system.dart"
Cohesion: 0.02
Nodes (76): action, backgroundOf, badge, body, bodyStrong, borderOf, _build, _cache (+68 more)

### Community 3 - "supabase_service.dart"
Cohesion: 0.02
Nodes (126): _adminUsers, _checkUniqueLocation, _checkUniquePurok, clearReview, client, countAllMembers, countDuesReceipts, countHouseholdMembers (+118 more)

### Community 5 - "household_view_dialog.dart"
Cohesion: 0.06
Nodes (40): householdListNotifierProvider, memberListNotifierProvider, _confirmDelete, _delete, _move, _canSeePayments, confirm, confirmAndDeleteHousehold (+32 more)

### Community 6 - "tropa_finder_view.dart"
Cohesion: 0.07
Nodes (29): voterFilterProvider, voterNotifierProvider, _actionWidth, _applyFilter, _applyNames, build, _cell, _columns (+21 more)

### Community 7 - "settings_common.dart"
Cohesion: 0.04
Nodes (42): action, actions, body, bodyStrong, border, build, caption, card (+34 more)

### Community 8 - "member_provider.dart"
Cohesion: 0.06
Nodes (30): addMember, addMembersBulk, archived, barangay, _changes, copyWith, deleteMember, dispose (+22 more)

### Community 9 - "db.dart"
Cohesion: 0.06
Nodes (26): auth, backup, backupPhase, _connect, db, dbGeneration, _ensureVoterListFor, ensureVoterSnapshot (+18 more)

### Community 10 - "20261022000000_barangay_sync.sql"
Cohesion: 0.16
Nodes (12): dues_payments_sync_key_idx, family_members_sync_key_idx, households_sync_key_idx, move_payments_sync_key, public.can_collect_dues_in(), public.move_member_payments_sync_key(), public.refresh_user_sync_scopes(), public.set_payment_sync_key() (+4 more)

### Community 11 - "duesScopeProvider"
Cohesion: 0.29
Nodes (7): duesPanelProvider, duesScopeProvider, DuesCollectionView, _PaymentPanel, _PaymentPanelState, _record, _fetchPayments

### Community 12 - "tropa_map_widget.dart"
Cohesion: 0.07
Nodes (21): build, _buildCircles, _circles, createState, didChangeDependencies, didUpdateWidget, dispose, _hitNotifier (+13 more)

### Community 13 - "members_view.dart"
Cohesion: 0.10
Nodes (17): createState, dispose, _filterDropdown, _firstNameCtrl, _householdFilter, _isPrinting, _lastNameCtrl, _middleNameCtrl (+9 more)

### Community 14 - "dues_provider.dart"
Cohesion: 0.05
Nodes (35): DuesLedgerFilter, DuesScope, 0, allocations, barangay, barangays, copyWith, DuesFundsRow (+27 more)

### Community 15 - "desktop_scaffold.dart"
Cohesion: 0.13
Nodes (15): build, child, _collapseToggle, collapsible, currentPath, DesktopScaffold, inDrawer, _loadPreference (+7 more)

### Community 16 - "form_tracking_provider.dart"
Cohesion: 0.10
Nodes (17): barangay, _changes, copyWith, createBatches, deleteBatch, dispose, FormTrackingFilter, lgu (+9 more)

### Community 17 - "household_provider.dart"
Cohesion: 0.10
Nodes (20): addHousehold, archived, barangay, _changes, copyWith, dispose, filter, getHouseholds (+12 more)

### Community 18 - "user_form_dialog.dart"
Cohesion: 0.07
Nodes (25): _applyPreset, build, createState, dispose, _duesBarangays, _email, _firstname, _formKey (+17 more)

### Community 19 - "form_tracking_dialog.dart"
Cohesion: 0.08
Nodes (23): FormTracking, count, createState, dispose, _encodedBy, _entries, existing, _formKey (+15 more)

### Community 20 - "member_id_view.dart"
Cohesion: 0.06
Nodes (33): _actionBarHeight, blocks, bold, border, build, buildDuesSheet, cell, columnHeader (+25 more)

### Community 21 - "officer_form_dialog.dart"
Cohesion: 0.08
Nodes (23): Officer, build, createState, current, _debounce, dispose, initialPosition, initState (+15 more)

### Community 22 - "dues_view.dart"
Cohesion: 0.03
Nodes (77): DuesMember, DuesReceipt, _, allPuroks, amount, anyLabels, balance, barangay (+69 more)

### Community 23 - "locations_tab.dart"
Cohesion: 0.08
Nodes (26): adminLocationsProvider, _barangay, build, _clearStartMonth, _coordValidator, createState, _deleteLocation, _deletePurok (+18 more)

### Community 24 - "motion.dart"
Cohesion: 0.07
Nodes (27): barrierDismissible, build, child, _controller, createState, _curved, didChangeDependencies, didUpdateWidget (+19 more)

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

### Community 33 - "TROPA Design System"
Cohesion: 0.12
Nodes (16): Badges, lists and tables, Buttons, Colour, Components, Default theme (TROPA, light), Dropdowns, Feedback, Filters and search (+8 more)

### Community 35 - "package:flutter/material.dart"
Cohesion: 0.18
Nodes (9): build, _count, noun, onPage, page, pageSize, shown, total (+1 more)

### Community 37 - "member_id_view.dart"
Cohesion: 0.10
Nodes (19): FamilyMember, _backKey, build, createState, ext, _frontKey, idNumber, member (+11 more)

### Community 38 - "users_tab.dart"
Cohesion: 0.08
Nodes (24): AppUser, SettingsPalette, barangayNames, createState, _delete, _HeaderRow, _initials, isSelf (+16 more)

### Community 39 - "supabaseServiceProvider"
Cohesion: 0.09
Nodes (33): supabaseServiceProvider, _delete, _editDate, _PrintSheetDialog, _PrintSheetDialogState, _void, HouseholdsView, MembersView (+25 more)

### Community 40 - "device_seed_card.dart"
Cohesion: 0.07
Nodes (26): localDbProvider, voterSnapshotStatusProvider, build, createState, DeviceSeedCard, _DeviceSeedCardState, _download, initState (+18 more)

### Community 41 - "device_seed_io.dart"
Cohesion: 0.13
Nodes (11): bytes, copy, deviceSeedSupported, gz, installDeviceSeed, _installing, outcome, _partSize (+3 more)

### Community 42 - "fallback_sync.dart"
Cohesion: 0.04
Nodes (51): _activateAfter, _applyDeletions, _areaTables, bools, client, column, cursor, _cursorsCleared (+43 more)

### Community 43 - "dues_math.dart"
Cohesion: 0.04
Nodes (51): afterPaying, allocate, allocationChanges, allocationForMonth, allocationRowForMonth, amountDue, amountFor, amountForMonths (+43 more)

### Community 46 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (8): _backKey, build, createState, _export, _frontKey, member, MyIdPage, _MyIdPageState

### Community 47 - "supabase_connector.dart"
Cohesion: 0.12
Nodes (11): _batchable, _batchSize, _checkApplied, _client, _fatalPostgresCodes, fetchCredentials, invalidateCredentials, _recordRejection (+3 more)

### Community 48 - "ph_time.dart"
Cohesion: 0.15
Nodes (12): formatPh, _hasOffset, _hasTime, p, parsePh, phNow, phOffset, phToday (+4 more)

### Community 49 - "20261016000000_fallback_sync.sql"
Cohesion: 0.15
Nodes (13): deleted_records_deleted_at_idx, dues_payments_updated_date_idx, family_members_updated_date_idx, form_tracking_updated_at_idx, households_updated_date_idx, log_deleted_record, officers_updated_at_idx, public.deleted_records (+5 more)

### Community 50 - "tropa_id_export.dart"
Cohesion: 0.13
Nodes (9): boundary, build, captureKey, captureTropaIdPng, child, data, image, ratio (+1 more)

### Community 51 - "form_tracking_view.dart"
Cohesion: 0.07
Nodes (27): _agePill, assignedTo, batch, _body, _cardDateFmt, _cardDateYearFmt, cardWidth, _columnGap (+19 more)

### Community 52 - "login_view.dart"
Cohesion: 0.12
Nodes (12): build, createState, dispose, _emailCtrl, _errorMessage, _handleLogin, initState, _isLoading (+4 more)

### Community 53 - "offline_auth.dart"
Cohesion: 0.14
Nodes (12): _credentialKey, isLocked, _iterations, localDbOwner, _lockedKey, OfflineAuth, _ownerKey, _pbkdf2 (+4 more)

### Community 54 - "officers_tab.dart"
Cohesion: 0.14
Nodes (11): Location, createState, location, _locationId, _OfficerSlate, OfficersTab, _OfficersTabState, _open (+3 more)

### Community 55 - "review_view.dart"
Cohesion: 0.10
Nodes (16): ReviewItem, _count, createState, _dateFmt, dispose, _dropdown, _editMember, _flagColor (+8 more)

### Community 57 - "voter_provider.dart"
Cohesion: 0.07
Nodes (27): barangay, _changes, copyWith, dispose, filter, firstName, flaggedOnly, flagVoter (+19 more)

### Community 58 - "dues_report_print.dart"
Cohesion: 0.10
Nodes (15): bold, buildDuesAllocationReport, cell, doc, fonts, format, fundHeading, name (+7 more)

### Community 59 - "deno.d.ts"
Cohesion: 0.08
Nodes (9): AdminAuthClient, Deno, env, GoTrueClient, npm:@supabase/supabase-js@2.45.4, PostgrestFilterBuilder, SupabaseClient, SupabaseClientOptions (+1 more)

### Community 60 - "20261014000000_voter_snapshot.sql"
Cohesion: 0.36
Nodes (5): public.apply_voter_flag(), public.is_tropa_admin(), public.voter_flags, voter_flags_apply, voter_flags_voter_id_idx

### Community 61 - "tropa_animated_logo.dart"
Cohesion: 0.06
Nodes (27): _brandGreen, build, createState, _ctrl, _cycleMs, didChangeDependencies, dispose, dx (+19 more)

### Community 63 - "ConsumerWidget"
Cohesion: 0.19
Nodes (12): officersProvider, puroksProvider, _LocationPickers, _ReceiptRow, _openHouseholdDialog, _LocationDetail, _BarangayOfficers, build (+4 more)

### Community 64 - "TextInputFormatter"
Cohesion: 0.40
Nodes (4): UpperCaseFormatter, _DateSlashFormatter, _PhicFormatter, _PhMobileFormatter

### Community 66 - "dues_rate_tab.dart"
Cohesion: 0.12
Nodes (14): _amount, createState, _delete, dispose, _fields, _month, _percents, _percentText (+6 more)

### Community 67 - "gen_sw.mjs"
Cohesion: 0.13
Nodes (10): CANVASKIT, files, hash, indexPath, output, precache, SKIP_NAMES, templatePath (+2 more)

### Community 69 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (11): actions, below, build, subtitle, title, titleTrailing, TropaPageHeader, build (+3 more)

### Community 70 - "tropa_id_card.dart"
Cohesion: 0.04
Nodes (51): _bar, blue, body, bodyDark, build, _c, child, children (+43 more)

### Community 71 - "Cross-Platform Flutter Desktop & Web Application Architecture"
Cohesion: 0.25
Nodes (7): 1. `pubspec.yaml`, 2. Design System & Theme Provider (`theme_provider.dart`), 3. Data Models (`models.dart`), 4. Supabase Service with Auto-Activity Logging & Storage, 5. `go_router` Role-Based Route Guarding, Cross-Platform Flutter Desktop & Web Application Architecture, TROPA v2 (Tabang Respeto Og Panalipud)

### Community 73 - "vercel.json"
Cohesion: 0.25
Nodes (7): buildCommand, framework, headers, installCommand, outputDirectory, rewrites, $schema

### Community 76 - "device_seed_web.dart"
Cohesion: 0.11
Nodes (15): buffer, candidates, decompressor, deviceSeedSupported, downloadBytes, existing, features, _gunzip (+7 more)

### Community 79 - "form_fields.dart"
Cohesion: 0.11
Nodes (15): build, child, children, color, crossAxisAlignment, formatEditUpdate, icon, label (+7 more)

### Community 80 - "StatelessWidget"
Cohesion: 0.08
Nodes (23): _CardFrame, _Divided, _Field, _MicroText, _PhotoPlaceholder, TropaIdCardBack, TropaIdCardFront, _DuesTabs (+15 more)

### Community 81 - "membership_date_dialog.dart"
Cohesion: 0.08
Nodes (24): build, _countRequest, createState, _current, _firstYear, initState, location, members (+16 more)

### Community 84 - "public_search_view.dart"
Cohesion: 0.04
Nodes (45): _barangay, birthDate, build, contact, createState, dispose, _error, _filterDropdown (+37 more)

### Community 85 - "20261019000000_dues_ledger.sql"
Cohesion: 0.27
Nodes (7): check_dues_payment_update, dues_payments_member_status_idx, dues_payments_receipt_idx, dues_rates_updated_at_idx, log_deleted_record, public.dues_rates, touch_updated

### Community 87 - "20261112000000_dues_allocations.sql"
Cohesion: 0.70
Nodes (4): dues_allocations_updated_at_idx, log_deleted_record, public.dues_allocations, touch_updated

### Community 88 - "compilerOptions"
Cohesion: 0.22
Nodes (8): compilerOptions, lib, module, moduleResolution, skipLibCheck, strict, target, include

### Community 90 - "bool get"
Cohesion: 0.18
Nodes (7): keyboardDebugRequested, VisibleArea, host, keyboardDebugRequested, rect, VisibleArea, vv

### Community 94 - "review_flags.dart"
Cohesion: 0.03
Nodes (69): a, barangay, _birthKeys, byBirth, byHousehold, cleared, _closeBirth, _closeFirstName (+61 more)

### Community 95 - "tropa_member.dart"
Cohesion: 0.07
Nodes (27): address, authorizedSignature, birthDate, dateIssued, firstName, formatIdDate, fullName, hotline (+19 more)

### Community 98 - "activity_log_provider.dart"
Cohesion: 0.07
Nodes (24): LedgerPeriod, action, actions, ActivityLogFilter, activityLogPageSize, copyWith, days, entity (+16 more)

### Community 100 - "State"
Cohesion: 0.16
Nodes (16): TropaStaggerIn, _TropaStaggerInState, TropaSuccessPulse, _TropaSuccessPulseState, TropaIdFlipCard, _TropaIdFlipCardState, DuesSheetPreview, _DuesSheetPreviewState (+8 more)

### Community 101 - "voter_list_print.dart"
Cohesion: 0.09
Nodes (20): bold, border, buildVoterList, cell, columnHeader, columns, columnWidths, doc (+12 more)

### Community 102 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.12
Nodes (10): booleanColumns, jsonColumns, schema, snapshotVoterLgus, deviceSeedSupported, false, installDeviceSeed, publishDeviceSeed (+2 more)

### Community 103 - "transfer_member_dialog.dart"
Cohesion: 0.12
Nodes (15): Household, build, createState, _currentHousehold, _householdPicker, initState, _isSaving, _leavesEmpty (+7 more)

### Community 106 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.06
Nodes (21): main, main, months, main, main, today, main, member (+13 more)

### Community 107 - "20261021000000_member_id_number.sql"
Cohesion: 0.47
Nodes (3): family_members_id_number, family_members_id_number_key, public.family_members_assign_id_number()

### Community 110 - "settings_view.dart"
Cohesion: 0.07
Nodes (18): TropaPalette, appThemeProvider, build, createState, main, _ready, _start, TropaApp (+10 more)

### Community 114 - "theme_palettes.dart"
Cohesion: 0.09
Nodes (18): accentText, background, border, brand, brightness, defaultId, id, muted (+10 more)

### Community 115 - "auth_provider.dart"
Cohesion: 0.10
Nodes (17): authStateStreamProvider, _blockedReason, contains, _deactivatedMessage, _endSession, _logLogin, _noAccessMessage, permissions (+9 more)

### Community 116 - "household_compare_dialog.dart"
Cohesion: 0.10
Nodes (18): _Column, createState, _dateFmt, _draggable, _Dragged, _groups, HouseholdCompareDialog, _HouseholdCompareDialogState (+10 more)

### Community 119 - "../core/design_system.dart"
Cohesion: 0.10
Nodes (7): _kpiCard, _confirmDelete, createState, dispose, _filterDropdown, _searchCtrl, _toggleArchived

### Community 121 - "Widget"
Cohesion: 0.14
Nodes (8): build, child, KeyboardSafeBody, minHeight, padding, build, child, WebKeyboardInset

### Community 122 - "static const"
Cohesion: 0.20
Nodes (4): _loadPreference, _prefKey, setTheme, main

### Community 123 - "currentAppUserProvider"
Cohesion: 0.16
Nodes (18): adminUsersProvider, currentAppUserProvider, formBatchNotifierProvider, formTrackingFilterProvider, _applyFilter, build, _confirmDelete, FormTrackingView (+10 more)

### Community 125 - "review_provider.dart"
Cohesion: 0.10
Nodes (17): barangay, _changes, clear, copyWith, _debounce, dispose, flag, kind (+9 more)

### Community 127 - "geo.dart"
Cohesion: 0.17
Nodes (11): b, barangayCenter, jitterAround, l, LatLngPoint, LocationOption, metersPerDegree, null (+3 more)

### Community 128 - "reports_view.dart"
Cohesion: 0.12
Nodes (14): barangayReportProvider, reportLguFilterProvider, _breakdownTable, build, createState, _dec1, _dec2, _int (+6 more)

### Community 129 - "build"
Cohesion: 0.13
Nodes (25): duesAllocationsProvider, duesFundsByPurokProvider, duesFundsFilterProvider, duesHouseholdResultsProvider, duesLedgerCountProvider, duesLedgerFilterProvider, duesLedgerPageProvider, duesLedgerTotalsProvider (+17 more)

### Community 133 - "sync_status_pill.dart"
Cohesion: 0.18
Nodes (15): PendingUpload, pendingUploadEntriesProvider, pendingUploadsProvider, syncStateProvider, syncStatusProvider, uploadRejectionsProvider, fallbackSyncStateProvider, build (+7 more)

### Community 134 - "_ReviewViewState"
Cohesion: 0.28
Nodes (9): userPermissionsProvider, reviewFilterProvider, reviewItemsProvider, build, _clear, initState, _restore, ReviewView (+1 more)

### Community 135 - "audit_logs_view.dart"
Cohesion: 0.12
Nodes (17): activityLogFilterProvider, activityLogsAsyncProvider, LogActionGroup, ActivityLogsView, _ActivityLogsViewState, _applyFilter, build, _clearFilters (+9 more)

### Community 136 - "canPermissionProvider"
Cohesion: 0.18
Nodes (18): canPermissionProvider, barangayStartMonthsProvider, householdMatchCountProvider, memberCountsProvider, memberFilterProvider, MemberListNotifier, locationsProvider, purokNamesProvider (+10 more)

### Community 137 - "image_compress.dart"
Cohesion: 0.13
Nodes (13): buffer, codec, compressPhoto, descriptor, encodeJpg, flat, frame, h (+5 more)

### Community 139 - "StateNotifier"
Cohesion: 0.23
Nodes (10): AppThemeNotifier, AppUserNotifier, FormBatchNotifier, householdFilterProvider, HouseholdListNotifier, ReviewItemsNotifier, VoterNotifier, _applyFilter (+2 more)

### Community 140 - "20261108000000_review_dismissals.sql"
Cohesion: 0.70
Nodes (4): log_deleted_record, public.review_dismissals, review_dismissals_created_at_idx, review_dismissals_entity_idx

### Community 141 - "GEMINI.md"
Cohesion: 0.50
Nodes (3): Design system, Formatting, graphify

### Community 145 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (3): main, page, scrolls

### Community 146 - "20261015000000_admin_settings.sql"
Cohesion: 0.33
Nodes (3): officers, officers_touch_updated_at, public.is_tropa_admin()

### Community 147 - "_CollectTabState"
Cohesion: 0.33
Nodes (6): duesPurokProvider, duesSearchProvider, duesSelectionProvider, _CollectTab, _CollectTabState, _search

### Community 151 - "DashboardView"
Cohesion: 0.67
Nodes (4): dashboardMetricsProvider, householdCoordinatesProvider, build, DashboardView

## Knowledge Gaps
- **1973 isolated node(s):** `TropaColors`, `TropaTheme`, `TropaText`, `TropaStyles`, `TropaBreakpoints` (+1968 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2257 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **54 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `dues_view.dart` to `build`, `package:intl/intl.dart`, `audit_logs_view.dart`, `duesScopeProvider`, `dues_provider.dart`, `package:flutter/material.dart`, `_CollectTabState`, `locations_tab.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `package:flutter/material.dart`, `supabaseServiceProvider`, `device_seed_card.dart`, `dues_math.dart`, `login_view.dart`, `officers_tab.dart`, `dues_report_print.dart`, `ConsumerWidget`, `dues_rate_tab.dart`, `package:flutter/material.dart`, `form_fields.dart`, `StatelessWidget`, `settings_view.dart`, `theme_palettes.dart`, `../core/design_system.dart`, `Widget`, `static const`, `review_provider.dart`?**
  _High betweenness centrality (0.097) - this node is a cross-community bridge._
- **What connects `TropaColors`, `TropaTheme`, `TropaText` to the rest of the system?**
  _1973 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.010526315789473684 - nodes in this community are weakly interconnected._
- **Why does `supabaseServiceProvider` connect `supabaseServiceProvider` to `build`, `household_view_dialog.dart`, `_ReviewViewState`, `tropa_finder_view.dart`, `member_provider.dart`, `canPermissionProvider`, `StateNotifier`, `duesScopeProvider`, `members_view.dart`, `tropa_map_widget.dart`, `form_tracking_provider.dart`, `household_provider.dart`, `user_form_dialog.dart`, `locations_tab.dart`, `users_tab.dart`, `officers_tab.dart`, `review_view.dart`, `voter_provider.dart`, `ConsumerWidget`, `dues_rate_tab.dart`, `transfer_member_dialog.dart`, `auth_provider.dart`, `household_compare_dialog.dart`, `currentAppUserProvider`, `review_provider.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Should `member_form_dialog.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.008849557522123894 - nodes in this community are weakly interconnected._
- **Why does `Household` connect `transfer_member_dialog.dart` to `models.dart`, `member_form_dialog.dart`, `household_view_dialog.dart`, `tropa_map_widget.dart`, `members_view.dart`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Should `design_system.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.024691358024691357 - nodes in this community are weakly interconnected._