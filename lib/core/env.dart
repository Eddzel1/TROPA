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
    final val = dotenv.maybeGet('SUPABASE_URL');
    if (val != null && val.isNotEmpty) return val;
    return 'https://ytrpijnooxglkpgwxlpo.supabase.co';
  }

  static String get supabaseAnonKey {
    final val = dotenv.maybeGet('SUPABASE_ANON_KEY');
    if (val != null && val.isNotEmpty) return val;
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl0cnBpam5vb3hnbGtwZ3d4bHBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1ODA4NTMsImV4cCI6MjA3MzE1Njg1M30.jmqKAtlJCr_Wdq8eO50jkZ8H-x2QnBUeeuUt70Z6DQk';
  }

  /// PowerSync instance endpoint, e.g. https://<id>.powersync.journeyapps.com.
  /// Empty means the app runs on its local database only and does not sync.
  static String get powersyncUrl => dotenv.maybeGet('POWERSYNC_URL') ?? '';
}
