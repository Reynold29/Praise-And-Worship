import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_config_service.dart';
import '../utils/app_logger.dart';

/// Holds remote app configuration fetched from the `app_config` Supabase table.
/// Provides reactive flag access for the widget tree via Provider.
class AppConfigProvider extends ChangeNotifier {
  bool _loaded = false;
  bool _socialLoginEnabled = true;
  String _appMinVersion = '1.0.0';
  List<String> _masterEmails = [];
  String _qrBaseUrl = 'https://projects.reyziehomelab.com/worshipcompanion';
  List<String> _whitelistedQrDomains = ['projects.reyziehomelab.com'];

  AppConfigProvider() {
    _loadFromCache();
  }

  /// Whether the config has been fetched at least once.
  bool get loaded => _loaded;

  /// True  → show all login / sign-up UI normally.
  bool get socialLoginEnabled => _socialLoginEnabled;

  /// Minimum app version required (for future use).
  String get appMinVersion => _appMinVersion;

  /// Base URL used for generated QR codes.
  String get qrBaseUrl => _qrBaseUrl;

  /// List of domains allowed for scanning within the app.
  List<String> get whitelistedQrDomains => _whitelistedQrDomains;

  /// Check if the given email is in the master emails list.
  bool isMasterUser(String? email) {
    if (email == null || email.isEmpty) return false;
    final cleanEmail = email.trim().toLowerCase();
    final isMaster = _masterEmails.contains(cleanEmail);
    AppLogger.d('AppConfig', 'Checking master for $cleanEmail: $isMaster');
    return isMaster;
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _socialLoginEnabled = prefs.getBool('config_social_login') ?? true;
      _appMinVersion = prefs.getString('config_min_version') ?? '1.0.0';
      final masterEmailsRaw = prefs.getString('config_master_emails') ?? '';
      _masterEmails = masterEmailsRaw
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      _qrBaseUrl = prefs.getString('config_qr_base_url') ??
          'https://projects.reyziehomelab.com/worshipcompanion';
      final domainsRaw = prefs.getString('config_qr_whitelist') ?? '';
      _whitelistedQrDomains = domainsRaw
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (_whitelistedQrDomains.isEmpty) {
        _whitelistedQrDomains = ['worshipcompanion.app'];
      }

      notifyListeners();
    } catch (e) {
      AppLogger.e('AppConfig', 'Fail to load from cache', e);
    }
  }

  /// Fetch config from Supabase and notify listeners.
  Future<void> load() async {
    final config = await AppConfigService.instance.fetchAll();

    final rawFlag = config['social_login_enabled'] ?? '1';
    _socialLoginEnabled = rawFlag.trim() == '1';
    _appMinVersion = config['app_version_min'] ?? '1.0.0';

    final masterEmailsRaw = config['master_emails'] ?? '';
    _masterEmails = masterEmailsRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    _qrBaseUrl = config['qr_base_url'] ?? 'https://worshipcompanion.app';
    final domainsRaw = config['whitelisted_qr_domains'] ?? '';
    _whitelistedQrDomains = domainsRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (_whitelistedQrDomains.isEmpty) {
      _whitelistedQrDomains = ['worshipcompanion.app'];
    }

    _loaded = true;

    // Persist to cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('config_social_login', _socialLoginEnabled);
      await prefs.setString('config_min_version', _appMinVersion);
      await prefs.setString('config_master_emails', masterEmailsRaw);
      await prefs.setString('config_qr_base_url', _qrBaseUrl);
      await prefs.setString('config_qr_whitelist', domainsRaw);
    } catch (e) {
      AppLogger.e('AppConfig', 'Fail to persist cache', e);
    }

    notifyListeners();
    AppLogger.d('AppConfig',
        'Loaded — socialLoginEnabled=$_socialLoginEnabled, masterEmailsCount=${_masterEmails.length}, qrBaseUrl=$_qrBaseUrl');
  }
}
