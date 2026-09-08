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

  /// Whether the config has been fetched at least once from the network.
  bool get loaded => _loaded;

  /// True  → show all login / sign-up UI normally.
  bool get socialLoginEnabled => _socialLoginEnabled;

  /// Minimum app version required (for future use).
  String get appMinVersion => _appMinVersion;

  /// Base URL used for generated QR codes.
  String get qrBaseUrl => _qrBaseUrl;

  /// List of domains allowed for scanning within the app.
  List<String> get whitelistedQrDomains => _whitelistedQrDomains;

  /// Parsed master emails (lowercased).
  List<String> get masterEmails => List.unmodifiable(_masterEmails);

  static List<String> _parseEmails(String raw) {
    return raw
        .split(RegExp(r'[,;\s]+'))
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.contains('@'))
        .toList();
  }

  /// Check if the given email is in the master emails list.
  bool isMasterUser(String? email) {
    if (email == null || email.isEmpty) return false;
    if (_masterEmails.isEmpty) return false;
    final cleanEmail = email.trim().toLowerCase();
    final isMaster = _masterEmails.contains(cleanEmail);
    AppLogger.d('AppConfig',
        'Checking master for $cleanEmail: $isMaster (list=${_masterEmails.length})');
    return isMaster;
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _socialLoginEnabled = prefs.getBool('config_social_login') ?? true;
      _appMinVersion = prefs.getString('config_min_version') ?? '1.0.0';
      final masterEmailsRaw = prefs.getString('config_master_emails') ?? '';
      _masterEmails = _parseEmails(masterEmailsRaw);

      _qrBaseUrl = prefs.getString('config_qr_base_url') ??
          'https://projects.reyziehomelab.com/worshipcompanion';
      final domainsRaw = prefs.getString('config_qr_whitelist') ?? '';
      _whitelistedQrDomains = domainsRaw
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (_whitelistedQrDomains.isEmpty) {
        _whitelistedQrDomains = ['projects.reyziehomelab.com'];
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

    // Never wipe a known master list if the network response omitted it
    // (defaults / partial failure). Only replace when we actually got emails.
    final masterEmailsRaw = config['master_emails'];
    if (masterEmailsRaw != null && masterEmailsRaw.trim().isNotEmpty) {
      _masterEmails = _parseEmails(masterEmailsRaw);
    } else {
      AppLogger.w('AppConfig',
          'Remote config missing master_emails — keeping cached list (${_masterEmails.length})');
    }

    _qrBaseUrl = config['qr_base_url'] ??
        'https://projects.reyziehomelab.com/worshipcompanion';
    final domainsRaw = config['whitelisted_qr_domains'] ?? '';
    _whitelistedQrDomains = domainsRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (_whitelistedQrDomains.isEmpty) {
      _whitelistedQrDomains = ['projects.reyziehomelab.com'];
    }

    _loaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('config_social_login', _socialLoginEnabled);
      await prefs.setString('config_min_version', _appMinVersion);
      if (_masterEmails.isNotEmpty) {
        await prefs.setString(
            'config_master_emails', _masterEmails.join(','));
      }
      await prefs.setString('config_qr_base_url', _qrBaseUrl);
      await prefs.setString('config_qr_whitelist', domainsRaw);
    } catch (e) {
      AppLogger.e('AppConfig', 'Fail to persist cache', e);
    }

    notifyListeners();
    AppLogger.d('AppConfig',
        'Loaded — socialLoginEnabled=$_socialLoginEnabled, masterEmailsCount=${_masterEmails.length}, qrBaseUrl=$_qrBaseUrl');
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('config_social_login', _socialLoginEnabled);
    await prefs.setString('config_min_version', _appMinVersion);
    if (_masterEmails.isNotEmpty) {
      await prefs.setString('config_master_emails', _masterEmails.join(','));
    }
    await prefs.setString('config_qr_base_url', _qrBaseUrl);
    await prefs.setString(
        'config_qr_whitelist', _whitelistedQrDomains.join(','));
  }

  /// Master-only remote toggle for social login.
  Future<void> setSocialLoginEnabled(bool enabled) async {
    await AppConfigService.instance
        .upsert('social_login_enabled', enabled ? '1' : '0');
    _socialLoginEnabled = enabled;
    await _persistLocal();
    notifyListeners();
  }

  Future<void> setQrBaseUrl(String url) async {
    final trimmed = url.trim();
    await AppConfigService.instance.upsert('qr_base_url', trimmed);
    _qrBaseUrl = trimmed;
    await _persistLocal();
    notifyListeners();
  }

  Future<void> setWhitelistedQrDomains(List<String> domains) async {
    final cleaned = domains
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final raw = cleaned.join(',');
    await AppConfigService.instance.upsert('whitelisted_qr_domains', raw);
    _whitelistedQrDomains = cleaned;
    await _persistLocal();
    notifyListeners();
  }

  Future<void> setAppMinVersion(String version) async {
    final trimmed = version.trim();
    await AppConfigService.instance.upsert('app_version_min', trimmed);
    _appMinVersion = trimmed;
    await _persistLocal();
    notifyListeners();
  }

  Future<void> setMasterEmails(List<String> emails) async {
    final cleaned = _parseEmails(emails.join(','));
    await AppConfigService.instance
        .upsert('master_emails', cleaned.join(','));
    _masterEmails = cleaned;
    await _persistLocal();
    notifyListeners();
  }
}
