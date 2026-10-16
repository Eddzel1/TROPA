import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../models/models.dart';
import 'auth_provider.dart';

/// All staff accounts from the `users` table.
final adminUsersProvider = FutureProvider<List<AppUser>>((ref) {
  ref.watch(tableChangesProvider('users'));
  return ref.watch(supabaseServiceProvider).getUsers();
});

/// Barangays with household, member and purok counts.
final adminLocationsProvider = FutureProvider<List<Location>>((ref) {
  ref.watch(tableChangesProvider('locations,puroks,households,family_members'));
  return ref.watch(supabaseServiceProvider).getLocationsAdmin();
});

/// Federation and purok officers of one barangay (keyed by `locations.id`).
final officersProvider = FutureProvider.family<List<Officer>, String>((ref, locationId) {
  ref.watch(tableChangesProvider('officers,family_members,puroks'));
  return ref.watch(supabaseServiceProvider).getOfficers(locationId);
});
