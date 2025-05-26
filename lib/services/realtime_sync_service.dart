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
    final supabase = Supabase.instance.client;
    _channel = supabase.channel('public:english_data')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'english_data',
        callback: (payload) async {
          await LocalDatabaseService.instance.syncFromSupabase();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'english_data',
        callback: (payload) async {
          await LocalDatabaseService.instance.syncFromSupabase();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'english_data',
        callback: (payload) async {
          await LocalDatabaseService.instance.syncFromSupabase();
        },
      )
      ..subscribe();
    _isSubscribed = true;
  }

  void stopListening() {
    if (_channel != null) {
      _channel!.unsubscribe();
      _channel = null;
      _isSubscribed = false;
    }
  }
} 