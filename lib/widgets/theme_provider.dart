import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _darkModeKey = 'dark_mode_on';
  static const String _customSeedColorKey = 'custom_seed_color';
  static const String _amoledBlackKey = 'amoled_black_on';

  bool _isDarkMode = false;
  Color? _customSeedColor;
  bool _isAmoledBlack = false;

  ColorScheme? _lightColorScheme;
  ColorScheme? _darkColorScheme;

  final Color _defaultSeedColor = Colors.blue;

  Color get defaultSeedColor => _defaultSeedColor;

  /// True when the user picked Material Expressive (custom seed) instead of You.
  bool get isExpressive =>
      _customSeedColor != null && _customSeedColor != Colors.transparent;

  Future<void> initialize() async {
    await _loadPreferencesAndInitialize();
  }

  Future<void> _loadPreferencesAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _isAmoledBlack = prefs.getBool(_amoledBlackKey) ?? false;
    final int? savedColorValue = prefs.getInt(_customSeedColorKey);
    if (savedColorValue != null) {
      _customSeedColor = Color(savedColorValue);
    }

    await _generateColorSchemes();
    notifyListeners();
  }

  ColorScheme _schemeFromSeed(Color seed, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: isExpressive
          ? DynamicSchemeVariant.expressive
          : DynamicSchemeVariant.tonalSpot,
    );
  }

  Future<void> _generateColorSchemes() async {
    final Color seed = _customSeedColor ?? _defaultSeedColor;

    _lightColorScheme = _schemeFromSeed(seed, Brightness.light);
    _darkColorScheme = _schemeFromSeed(seed, Brightness.dark);

    if (_isDarkMode && _isAmoledBlack) {
      _darkColorScheme = _darkColorScheme?.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
      );
    }
  }

  bool get isDarkMode => _isDarkMode;
  Color? get customSeedColor => _customSeedColor;
  bool get isAmoledBlack => _isAmoledBlack;

  ColorScheme get lightColorScheme =>
      _lightColorScheme ?? _schemeFromSeed(_defaultSeedColor, Brightness.light);
  ColorScheme get darkColorScheme =>
      _darkColorScheme ?? _schemeFromSeed(_defaultSeedColor, Brightness.dark);

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    await prefs.setBool(_amoledBlackKey, _isAmoledBlack);
    if (_customSeedColor != null) {
      await prefs.setInt(_customSeedColorKey, _customSeedColor!.toARGB32());
    } else {
      await prefs.remove(_customSeedColorKey);
    }
  }

  void toggleTheme(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    await _generateColorSchemes();
    await _savePreferences();
    notifyListeners();
  }

  void setCustomSeedColor(Color color) async {
    if (color == Colors.transparent) {
      _customSeedColor = null;
    } else {
      _customSeedColor = color;
    }
    await _generateColorSchemes();
    await _savePreferences();
    notifyListeners();
  }

  void setAmoledBlack(bool isEnabled) async {
    _isAmoledBlack = isEnabled;
    if (_isDarkMode) {
      await _generateColorSchemes();
    }
    await _savePreferences();
    notifyListeners();
  }
}
