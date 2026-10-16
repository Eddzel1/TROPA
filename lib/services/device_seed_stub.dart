import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Web: starter databases need file access, so the web app keeps the normal full sync.
const deviceSeedSupported = false;

Future<int> publishDeviceSeed(PowerSyncDatabase db, SupabaseClient client, {void Function(String)? onProgress}) =>
    throw UnsupportedError('Publishing the starter database needs the desktop app.');

Future<bool> installDeviceSeed({required bool force}) async {
  if (force) throw UnsupportedError('Downloading the starter database needs the desktop app.');
  return false;
}
