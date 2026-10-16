import 'package:powersync/powersync.dart';

// Local SQLite mirror of the Supabase tables. `id` is implicit on every table.
// Postgres booleans arrive as 0/1 integers; JSON/array columns are stored as JSON text.

const schema = Schema([
  Table('households', [
    Column.text('household_name'),
    Column.text('lgu'),
    Column.text('barangay'),
    Column.text('purok'),
    Column.text('purok_id'),
    Column.text('household_leader_id'),
    Column.integer('total_members'),
    Column.integer('active_members'),
    Column.text('status'),
    Column.text('house_picture_url'),
    Column.text('house_picture_path'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.text('created_date'),
    Column.text('updated_date'),
    Column.text('created_by'),
  ], indexes: [
    Index('barangay', [IndexedColumn('barangay')]),
    Index('lgu_brgy', [IndexedColumn('lgu'), IndexedColumn('barangay')]),
    Index('created', [IndexedColumn.descending('created_date')]),
  ]),
  Table('family_members', [
    Column.text('household_id'),
    Column.text('firstname'),
    Column.text('lastname'),
    Column.text('middlename'),
    Column.text('extension'),
    Column.text('lgu'),
    Column.text('barangay'),
    Column.text('purok'),
    Column.text('purok_id'),
    Column.text('sector'),
    Column.integer('is_voter'),
    Column.text('voter_barangay'),
    Column.integer('voter_id'),
    Column.text('contact_number'),
    Column.integer('is_household_leader'),
    Column.integer('is_cooperative_member'),
    Column.text('membership_date'),
    Column.text('birth_date'),
    Column.integer('age'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.text('religion'),
    Column.text('school'),
    Column.text('year_level'),
    Column.text('gender'),
    Column.text('listing_status'),
    Column.text('profile_picture_url'),
    Column.text('profile_picture_path'),
    Column.integer('phic_member'),
    Column.text('phic_no'),
    Column.integer('trucare_member'),
    Column.text('created_date'),
    Column.text('updated_date'),
    Column.text('created_by'),
  ], indexes: [
    Index('name', [IndexedColumn('lastname'), IndexedColumn('firstname')]),
    Index('barangay', [IndexedColumn('barangay')]),
    // Covers the Reports per-barangay member/voter counts.
    Index('lgu_brgy_voter', [IndexedColumn('lgu'), IndexedColumn('barangay'), IndexedColumn('is_voter')]),
    Index('household', [IndexedColumn('household_id')]),
  ]),
  Table('dues_payments', [
    Column.text('member_id'),
    Column.text('household_id'),
    Column.real('amount'),
    Column.text('payment_month'),
    Column.integer('months_covered'),
    Column.text('payment_date'),
    Column.text('payment_method'),
    Column.text('reference_number'),
    Column.text('notes'),
    Column.text('status'),
    Column.text('collected_by'),
    Column.text('created_by'),
    Column.text('created_date'),
    Column.text('updated_date'),
  ], indexes: [
    Index('member', [IndexedColumn('member_id')]),
    Index('household', [IndexedColumn('household_id')]),
    Index('paid', [IndexedColumn.descending('payment_date')]),
  ]),
  Table('form_tracking', [
    Column.text('barangay'),
    Column.text('purok'),
    Column.integer('number_of_forms'),
    Column.text('submitted_by'),
    Column.text('received_by'),
    Column.text('encoded_by'),
    Column.text('status'),
    Column.text('returned_released_by'),
    Column.text('returned_received_by'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  Table('locations', [
    Column.text('lgu'),
    Column.text('barangay'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.integer('household_count'),
    Column.integer('member_count'),
  ]),
  // Puroks belong to a location (puroks.location_id → locations.id).
  // Needs a matching entry in the PowerSync sync rules to be available offline.
  Table('puroks', [
    Column.text('location_id'),
    Column.text('name'),
  ]),
  // Officers of a barangay federation (level 'barangay', purok_id null) or of a purok
  // (level 'purok'). Supabase enforces one holder per position except 'Board Member'.
  Table('officers', [
    Column.text('level'),
    Column.text('location_id'),
    Column.text('purok_id'),
    Column.text('position'),
    Column.text('member_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ], indexes: [
    Index('location', [IndexedColumn('location_id')]),
    Index('purok', [IndexedColumn('purok_id')]),
  ]),
  Table('users', [
    Column.text('email'),
    Column.text('firstname'),
    Column.text('lastname'),
    Column.text('role'),
    Column.text('status'),
    Column.text('permissions'),
    Column.text('last_login'),
    Column.text('created_date'),
    Column.text('updated_date'),
  ]),
  // COMELEC voters for [snapshotVoterLgus]. Not synced: installed from a compressed snapshot file in
  // Supabase Storage (see lib/services/voter_snapshot.dart), so it costs no PowerSync data.
  Table.localOnly('voters', [
    Column.text('lastname'),
    Column.text('firstname'),
    Column.text('middlename'),
    Column.text('ext'),
    Column.text('purok'),
    Column.text('brgy'),
    Column.text('lgu'),
    Column.text('status'),
    Column.text('pc'),
    Column.text('hhl'),
    Column.text('precinct'),
  ], indexes: [
    Index('name', [IndexedColumn('lastname'), IndexedColumn('firstname')]),
    Index('brgy', [IndexedColumn('brgy')]),
    Index('lgu', [IndexedColumn('lgu')]),
  ]),
  // Which voter snapshot is installed (one row, id 'current'). Lives in the same database so a
  // user switch that clears the database also triggers a fresh install.
  Table.localOnly('voter_snapshot_info', [
    Column.text('version'),
    Column.integer('count'),
    Column.text('installed_at'),
  ]),
  // Voter flags are the only voter edits; they sync both ways like any other table.
  Table('voter_flags', [
    Column.text('voter_id'),
    Column.text('reason'),
    Column.text('flagged_by'),
    Column.text('created_at'),
  ], indexes: [
    Index('voter', [IndexedColumn('voter_id')]),
  ]),
  // Written locally and uploaded; never downloaded (the audit log view reads Supabase directly).
  Table.insertOnly('activity_logs', [
    Column.text('user_id'),
    Column.text('user_name'),
    Column.text('action'),
    Column.text('entity_type'),
    Column.text('entity_id'),
    Column.text('details'),
    Column.text('created_at'),
  ]),
]);

/// LGUs whose voters are installed on devices for offline search. Searches for other LGUs go online.
const snapshotVoterLgus = {'VALENCIA CITY', 'KALILANGAN', 'PANGANTUCAN'};

/// Columns that are Postgres booleans; stored locally as 0/1 and converted back on upload.
const booleanColumns = <String, Set<String>>{
  'family_members': {
    'is_voter',
    'is_household_leader',
    'is_cooperative_member',
    'phic_member',
    'trucare_member',
  },
};

/// Columns that are Postgres json/array types; stored locally as JSON text and decoded on upload.
const jsonColumns = <String, Set<String>>{
  'users': {'permissions'},
};
