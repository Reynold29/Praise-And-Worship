import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database_service.dart';

class RealtimeSyncService {
  static final RealtimeSyncService instance = RealtimeSyncService._();
  RealtimeChannel? _channel;
  bool _isSubscribed = false;

  RealtimeSyncService._();

  /// Call this once (e.g., on app start) to begin listening for changes
  void startListening() {
    if (_isSubscribed) return;
    
    try {
      final supabase = Supabase.instance.client;
      if (supabase == null) {
        print('Supabase client is null, skipping realtime sync setup');
        return;
      }
      
      _channel = supabase.channel('public:english_data')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'english_data',
          callback: (payload) async {
            try {
              await LocalDatabaseService.instance.syncFromSupabase();
            } catch (e) {
              print('Realtime sync insert callback failed: $e');
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'english_data',
          callback: (payload) async {
            try {
              await LocalDatabaseService.instance.syncFromSupabase();
            } catch (e) {
              print('Realtime sync update callback failed: $e');
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'english_data',
          callback: (payload) async {
            try {
              await LocalDatabaseService.instance.syncFromSupabase();
            } catch (e) {
              print('Realtime sync delete callback failed: $e');
            }
          },
        )
        ..subscribe();
      _isSubscribed = true;
      print('Realtime sync started successfully');
    } catch (e) {
      print('Failed to start realtime sync: $e');
      // Don't rethrow - app should continue working without realtime sync
    }
  }

  void stopListening() {
    if (_channel != null) {
      try {
        _channel!.unsubscribe();
        _channel = null;
        _isSubscribed = false;
        print('Realtime sync stopped');
      } catch (e) {
        print('Error stopping realtime sync: $e');
      }
    }
  }
} 