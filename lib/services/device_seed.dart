import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'device_seed_stub.dart' if (dart.library.io) 'device_seed_io.dart';

/// Starter database ("pre-seeded SQLite", see docs.powersync.com/client-sdks/advanced/pre-seeded-sqlite).
///
/// An admin's fully synced desktop publishes a compact copy of its local database to Supabase
/// Storage. New devices download it on first sign-in instead of pulling every member and household
/// through PowerSync, then PowerSync only sends the changes made since the copy was taken. The
/// download counts against Supabase egress, not the PowerSync "data synced" allowance.
///
/// The file handling lives in device_seed_io.dart (desktop); web keeps the normal full sync.

const deviceSeedBucket = 'device-seeds';
const deviceSeedManifestPath = 'manifest.json';

/// Progress text shown while a starter database is downloaded or installed, null when idle.
final deviceSeedProgress = ValueNotifier<String?>(null);

/// The published manifest, or null if offline or nothing has been published yet.
Future<Map<String, dynamic>?> fetchDeviceSeedManifest(SupabaseClient client) async {
  try {
    final bytes = await client.storage.from(deviceSeedBucket).download(deviceSeedManifestPath);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Byte ranges for splitting a file of [length] bytes into parts of at most [partSize].
List<({int start, int end})> seedPartRanges(int length, int partSize) => [
      for (var start = 0; start < length; start += partSize)
        (start: start, end: start + partSize < length ? start + partSize : length),
    ];
