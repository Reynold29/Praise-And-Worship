import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _darkModeKey = 'dark_mode_on';
  static const String _customSeedColorKey = 'custom_seed_color';
  static const String _amoledBlackKey = 'amoled_black_on';
  // static const String _themeStyleKey = 'theme_style'; // For AppThemeMode if managed here

  bool _isDarkMode = false;
  Color? _customSeedColor;
  bool _isAmoledBlack = false;
  // AppThemeMode _themeStyle = AppThemeMode.youTheming; // Default if managed here

  ColorScheme? _lightColorScheme;
  ColorScheme? _darkColorScheme;

  // Default fallback seed color if no dynamic or custom color is available
  final Color _defaultSeedColor = Colors.blue;

  ThemeProvider() {
    // _loadPreferencesAndInitialize(); // Will be called by initialize()
  }

  Color get defaultSeedColor => _defaultSeedColor; // Getter for default seed color

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
    // _themeStyle = AppThemeMode.values[prefs.getInt(_themeStyleKey) ?? AppThemeMode.youTheming.index];

    await _generateColorSchemes();
    notifyListeners();
  }

  Future<void> _generateColorSchemes() async { // Removed await from plugin
    // ColorScheme? lightDynamic;
    // ColorScheme? darkDynamic;

    // FINAL COREPALETTE REMOVED
    // final corePalette = await DynamicColorPlugin.getCorePalette(); 
    // if (corePalette != null) {
    //   lightDynamic = corePalette.toColorScheme();
    //   darkDynamic = corePalette.toColorScheme(brightness: Brightness.dark);
    // }

    // Use _customSeedColor if available, otherwise _defaultSeedColor.
    // Dynamic colors will be handled by DynamicColorBuilder in the UI.
    Color seed = _customSeedColor ?? _defaultSeedColor;
    
    _lightColorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    _darkColorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    if (_isDarkMode && _isAmoledBlack) {
      _darkColorScheme = _darkColorScheme?.copyWith(
        background: Colors.black,
        surface: Colors.black,
      );
    }
  }

  bool get isDarkMode => _isDarkMode;
  Color? get customSeedColor => _customSeedColor;
  bool get isAmoledBlack => _isAmoledBlack;
  // AppThemeMode get themeStyle => _themeStyle;

  ColorScheme get lightColorScheme => _lightColorScheme ?? ColorScheme.fromSeed(seedColor: _defaultSeedColor);
  ColorScheme get darkColorScheme => _darkColorScheme ?? ColorScheme.fromSeed(seedColor: _defaultSeedColor, brightness: Brightness.dark);

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    await prefs.setBool(_amoledBlackKey, _isAmoledBlack);
    if (_customSeedColor != null) {
      await prefs.setInt(_customSeedColorKey, _customSeedColor!.value);
    }
    // await prefs.setInt(_themeStyleKey, _themeStyle.index);
  }

  void toggleTheme(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    await _generateColorSchemes(); // Regenerate schemes in case AMOLED needs to be applied/removed
    await _savePreferences();
    notifyListeners();
  }

  void setCustomSeedColor(Color color) async {
    if (color == Colors.transparent) { // Check if the color is the transparent signal
      _customSeedColor = null; // Set to null to allow dynamic/default colors to take precedence
    } else {
      _customSeedColor = color;
    }
    await _generateColorSchemes();
    await _savePreferences();
    notifyListeners();
  }

  void setAmoledBlack(bool isEnabled) async {
    _isAmoledBlack = isEnabled;
    if (_isDarkMode) { // Only regenerate if in dark mode, as it only affects dark theme
      await _generateColorSchemes();
    }
    await _savePreferences();
    notifyListeners();
  }

  // void setThemeStyle(AppThemeMode style) async {
  //   _themeStyle = style;
  //   await _generateColorSchemes();
  //   await _savePreferences();
  //   notifyListeners();
  // }
}
