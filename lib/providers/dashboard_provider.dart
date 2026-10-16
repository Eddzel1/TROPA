import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import 'auth_provider.dart';

final dashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(tableChangesProvider('households,family_members,dues_payments'));
  final service = ref.watch(supabaseServiceProvider);
  return service.getDashboardMetrics();
});
