import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

/// Fetches key-value config from the `app_config` Supabase table.
/// Falls back to safe defaults if the network is unavailable.
class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  static const Map<String, String> _defaults = {
    'social_login_enabled': '1',
    'app_version_min': '1.0.0',
    'qr_base_url': 'https://projects.reyziehomelab.com/worshipcompanion',
    'whitelisted_qr_domains': 'projects.reyziehomelab.com',
  };

  Future<Map<String, String>> fetchAll() async {
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('app_config')
          .select('key, value')
          .timeout(const Duration(seconds: 6));

      final result = Map<String, String>.from(_defaults);
      for (final row in rows as List<dynamic>) {
        final key = row['key'] as String?;
        final value = row['value'] as String?;
        if (key != null && value != null) {
          result[key] = value;
        }
      }
      return result;
    } catch (e) {
      AppLogger.e('AppConfig', 'Failed to fetch config, using defaults', e);
      return Map<String, String>.from(_defaults);
    }
  }

  /// Upsert a single config key (master-only via RLS).
  Future<void> upsert(String key, String value) async {
    final client = Supabase.instance.client;
    await client.from('app_config').upsert(
      {'key': key, 'value': value},
      onConflict: 'key',
    );
  }
}
