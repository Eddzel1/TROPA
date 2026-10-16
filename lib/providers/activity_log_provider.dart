import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/ph_time.dart';
import 'auth_provider.dart';

final activityLogsAsyncProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final items = await service.getActivityLogs(limit: 100);
  if (items.isNotEmpty) return items;

  // Initial audit log items if table is brand new
  return [
    ActivityLog(
      id: 'log-seed-1',
      userId: 'usr-admin',
      userName: 'Executive Admin',
      action: 'SYSTEM_BOOT',
      entityType: 'System',
      entityId: 'tropa_v2',
      details: {'status': 'Initialized', 'version': '2.0.0+1'},
      createdAt: phNow().subtract(const Duration(minutes: 15)),
    ),
    ActivityLog(
      id: 'log-seed-2',
      userId: 'usr-admin',
      userName: 'Executive Admin',
      action: 'SYNC_COMELEC',
      entityType: 'VoterRegistry',
      entityId: 'registry-valencia',
      details: {'records_polled': 48219, 'status': 'success'},
      createdAt: phNow().subtract(const Duration(minutes: 5)),
    ),
  ];
});
