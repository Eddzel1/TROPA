import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // In case .env file is not found or fails to load, fallback safely
    }
  }

  static String get supabaseUrl {
    final val = _get('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL'));
    if (val.isNotEmpty) return val;
    return 'https://ytrpijnooxglkpgwxlpo.supabase.co';
  }

  static String get supabaseAnonKey {
    final val = _get('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY'));
    if (val.isNotEmpty) return val;
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl0cnBpam5vb3hnbGtwZ3d4bHBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1ODA4NTMsImV4cCI6MjA3MzE1Njg1M30.jmqKAtlJCr_Wdq8eO50jkZ8H-x2QnBUeeuUt70Z6DQk';
  }

  /// PowerSync instance endpoint, e.g. https://<id>.powersync.journeyapps.com.
  /// Empty means the app runs on its local database only and does not sync.
  static String get powersyncUrl => _get('POWERSYNC_URL', const String.fromEnvironment('POWERSYNC_URL'));

  /// Prefers the bundled .env asset, then the value compiled in with --dart-define-from-file=.env.
  /// The compiled-in value matters on web hosts that don't serve dot-files (e.g. Netlify).
  static String _get(String key, String compiled) {
    final val = dotenv.maybeGet(key);
    return (val != null && val.isNotEmpty) ? val : compiled;
  }
}
