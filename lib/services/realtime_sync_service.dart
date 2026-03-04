import '../utils/app_logger.dart';
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
        AppLogger.d('App', 'Supabase client is null, skipping realtime sync setup');
        return;
      }

      _channel = supabase.channel('public:all_data');

      void _registerTableSync(
          String tableName, Future<void> Function() syncMethod) {
        _channel!
          ..onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: tableName,
            callback: (payload) async {
              try {
                await syncMethod();
              } catch (e) {
                AppLogger.d('App', 'Realtime sync insert error ($tableName): $e');
              }
            },
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: tableName,
            callback: (payload) async {
              try {
                await syncMethod();
              } catch (e) {
                AppLogger.d('App', 'Realtime sync update error ($tableName): $e');
              }
            },
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: tableName,
            callback: (payload) async {
              try {
                await syncMethod();
              } catch (e) {
                AppLogger.d('App', 'Realtime sync delete error ($tableName): $e');
              }
            },
          );
      }

      _registerTableSync(
          'english_data', LocalDatabaseService.instance.syncFromSupabase);
      _registerTableSync('kannada_data',
          LocalDatabaseService.instance.syncKannadaFromSupabase);
      _registerTableSync(
          'other_data', LocalDatabaseService.instance.syncOtherFromSupabase);

      _channel!.subscribe();
      _isSubscribed = true;
      AppLogger.d('App', 'Realtime sync started successfully');
    } catch (e) {
      AppLogger.d('App', 'Failed to start realtime sync: $e');
      // Don't rethrow - app should continue working without realtime sync
    }
  }

  void stopListening() {
    if (_channel != null) {
      try {
        _channel!.unsubscribe();
        _channel = null;
        _isSubscribed = false;
        AppLogger.d('App', 'Realtime sync stopped');
      } catch (e) {
        AppLogger.d('App', 'Error stopping realtime sync: $e');
      }
    }
  }
}
