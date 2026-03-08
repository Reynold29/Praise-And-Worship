import 'package:flutter/foundation.dart';
import '../services/app_config_service.dart';
import '../utils/app_logger.dart';

/// Holds remote app configuration fetched from the `app_config` Supabase table.
/// Provides reactive flag access for the widget tree via Provider.
class AppConfigProvider extends ChangeNotifier {
  bool _loaded = false;
  bool _socialLoginEnabled =
      true; // show by default until server says otherwise
  String _appMinVersion = '1.0.0';
  List<String> _masterEmails = [];

  /// Whether the config has been fetched at least once.
  bool get loaded => _loaded;

  /// True  → show all login / sign-up UI normally.
  /// False → hide every login button, form, and auth screen entry point.
  bool get socialLoginEnabled => _socialLoginEnabled;

  /// Minimum app version required (for future use).
  String get appMinVersion => _appMinVersion;

  /// Check if the given email is in the master emails list.
  bool isMasterUser(String? email) {
    if (email == null || email.isEmpty) return false;
    return _masterEmails.contains(email.trim().toLowerCase());
  }

  /// Fetch config from Supabase and notify listeners.
  /// Safe to call multiple times (e.g. on app resume).
  Future<void> load() async {
    final config = await AppConfigService.instance.fetchAll();

    final rawFlag = config['social_login_enabled'] ?? '1';
    final enabled = rawFlag.trim() == '1';

    _socialLoginEnabled = enabled;
    _appMinVersion = config['app_version_min'] ?? '1.0.0';

    final masterEmailsRaw = config['master_emails'] ?? '';
    _masterEmails = masterEmailsRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    _loaded = true;

    notifyListeners();
    AppLogger.d(
        'AppConfig', 'Loaded — socialLoginEnabled=$_socialLoginEnabled');
  }
}
