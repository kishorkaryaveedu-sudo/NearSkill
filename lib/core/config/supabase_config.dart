import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  static bool _initialized = false;

  // Supabase project credentials
  static const String supabaseUrl = 'https://lxhrwomqozwhcokbpfvk.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4aHJ3b21xb3p3aGNva2JwZnZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzNjI0MjIsImV4cCI6MjA4MzkzODQyMn0.VBrmpc_BcAwZUYV6RcpHZ1Te7OsVDn74N-7_jqoX5Rc';

  /// Initialize Supabase
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      _initialized = true;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Check if Supabase is initialized
  static bool get isInitialized => _initialized;
}
