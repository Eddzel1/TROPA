import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powersync/powersync.dart';
import 'package:tropa_v2/data/db.dart';
import 'package:tropa_v2/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Start locked (signed out) so booting never queries the local database.
    SharedPreferences.setMockInitialValues({'offline_auth.locked': true});
    try {
      await Supabase.initialize(
        url: 'https://ytrpijnooxglkpgwxlpo.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl0cnBpam5vb3hnbGtwZ3d4bHBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1ODA4NTMsImV4cCI6MjA3MzE1Njg1M30.jmqKAtlJCr_Wdq8eO50jkZ8H-x2QnBUeeuUt70Z6DQk',
      );
    } catch (_) {}
  });

  testWidgets('TROPA App boots successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localDbProvider.overrideWithValue(_UnopenedDb())],
        child: const TropaApp(),
      ),
    );
    expect(find.byType(TropaApp), findsOneWidget);
  });
}

/// The PowerSync native library isn't available under `flutter test`. The app boots locked, so the
/// local database is never queried; any unexpected call fails loudly via noSuchMethod.
class _UnopenedDb implements PowerSyncDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
