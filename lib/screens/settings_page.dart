import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'package:worshipcompanion/widgets/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Import the package
import 'package:flutter/services.dart'; // For Clipboard
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:vibration/vibration.dart';

enum AppThemeMode {
  materialExpressive,
  youTheming, // Dynamic color / system theme
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Keys for SharedPreferences
  static const String _themeModeKey = 'app_theme_mode';
  static const String _amoledBlackKeySP = 'amoled_black_on_sp'; // Differentiated from ThemeProvider key for clarity
  static const String _customColorKeySP = 'custom_color_sp'; // Differentiated

  AppThemeMode _selectedTheme = AppThemeMode.youTheming;
  bool _isAmoledBlackEnabled = false;
  Color _customColor = Colors.blue; // Default custom color

  bool _isLoading = true; // To show a loader while preferences are loading

  // Placeholder primary colors - replace with your desired list
  final List<Color> _primaryPickerColors = [
    Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.orange, Colors.teal,
    Colors.blueGrey, Colors.indigo, Colors.pink, Colors.amber, Colors.cyan, Colors.lime,
  ];

  // Placeholder accent colors - replace with your desired list
  final List<Color> _accentPickerColors = [
    Colors.lightBlueAccent, Colors.greenAccent, Colors.redAccent, Colors.purpleAccent,
    Colors.orangeAccent, Colors.tealAccent, Colors.indigoAccent, Colors.pinkAccent,
    Colors.amberAccent, Colors.cyanAccent, Colors.limeAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = Provider.of<ThemeProvider>(this.context, listen: false);

    _selectedTheme = AppThemeMode.values[prefs.getInt(_themeModeKey) ?? AppThemeMode.youTheming.index];
    _isAmoledBlackEnabled = prefs.getBool(_amoledBlackKeySP) ?? false;
    _customColor = Color(prefs.getInt(_customColorKeySP) ?? Colors.blue.value);

    // Apply loaded settings to ThemeProvider to ensure consistency on startup
    // This is important if the user had custom settings saved
    if (_selectedTheme == AppThemeMode.materialExpressive) {
       // If youTheming is off, apply the custom/default color as the seed
      themeProvider.setCustomSeedColor(_customColor);
    } else {
      // If youTheming is on, clear any custom seed color to allow dynamic colors to take effect
      // Assuming ThemeProvider's _generateColorSchemes() handles dynamic colors if _customSeedColor is null
      themeProvider.setCustomSeedColor(Colors.transparent); // Passing a transparent color as a signal, to be handled in ThemeProvider
    }
    themeProvider.setAmoledBlack(_isAmoledBlackEnabled);
    // Note: toggleTheme in ThemeProvider is for dark/light mode, which is separate from these style settings

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _selectedTheme.index);
    await prefs.setBool(_amoledBlackKeySP, _isAmoledBlackEnabled);
    await prefs.setInt(_customColorKeySP, _customColor.value);
  }

  void _performVibration() async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: 18, amplitude: 60);
    }
  }

  void _openColorPicker() async {
    final themeProvider = Provider.of<ThemeProvider>(this.context, listen: false);
    
    final Color? result = await showDialog<Color>(
      context: this.context,
      barrierDismissible: false, // User must use buttons to close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          // The AlertDialog will be styled further, but its content is our custom widget
          content: _ColorPickerDialogContent(
            initialColor: _customColor,
            primaryColors: _primaryPickerColors,
            accentColors: _accentPickerColors,
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _customColor = result;
      });
      if (_selectedTheme == AppThemeMode.materialExpressive) {
        themeProvider.setCustomSeedColor(_customColor);
      }
      await _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider for theme changes to rebuild SettingsPage
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('App Settings')),
        backgroundColor: Theme.of(context).colorScheme.background, // Ensure background updates
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        // backgroundColor: Theme.of(context).colorScheme.surface, // Optional: theme app bar too
      ),
      backgroundColor: Theme.of(context).colorScheme.background, // Explicitly set background
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Theme Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground, // Ensure text is visible
                  ),
            ),
          ),
          Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: Theme.of(context).colorScheme.surface, // Ensure card color matches theme
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<AppThemeMode>(
                    title: Text('Material 3 Expressive (Custom Seed)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    value: AppThemeMode.materialExpressive,
                    groupValue: _selectedTheme,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (AppThemeMode? value) async {
                      _performVibration();
                      if (value != null) {
                        setState(() {
                          _selectedTheme = value;
                        });
                        themeProvider.setCustomSeedColor(_customColor);
                        await _savePreferences();
                      }
                    },
                    subtitle:
                        Text('Uses a custom seed color for the theme.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ),
                  RadioListTile<AppThemeMode>(
                    title: Text('System Theme (Material You)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    value: AppThemeMode.youTheming,
                    groupValue: _selectedTheme,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (AppThemeMode? value) async {
                      _performVibration();
                      if (value != null) {
                        setState(() {
                          _selectedTheme = value;
                        });
                        // For You Theming, we need to tell ThemeProvider to use dynamic colors.
                        // This might mean passing null or a specific signal to setCustomSeedColor
                        // or having a dedicated method like themeProvider.enableDynamicColors(true).
                        // The current themeProvider.setCustomSeedColor(themeProvider.customSeedColor!) won't switch to dynamic.
                        // Let's modify this to pass null, assuming ThemeProvider is updated to handle it.
                        // TODO: Ensure ThemeProvider.setCustomSeedColor(null) correctly enables dynamic theme.
                        themeProvider.setCustomSeedColor(Colors.transparent); // Passing a transparent color as a signal, to be handled in ThemeProvider

                        await _savePreferences();
                      }
                    },
                    subtitle: Text(
                        'Adapts to your system\'s color scheme (Android 12+).', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Dark Mode', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    value: themeProvider.isDarkMode,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool value) {
                      _performVibration();
                      themeProvider.toggleTheme(value);
                    },
                    subtitle: Text('Enable or disable dark theme.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ),
                  SwitchListTile(
                    title: Text('AMOLED Black Theme', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    value: _isAmoledBlackEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool value) async {
                      _performVibration();
                      setState(() {
                        _isAmoledBlackEnabled = value;
                      });
                      themeProvider.setAmoledBlack(value);
                      await _savePreferences();
                    },
                    subtitle:
                        Text('Uses true black backgrounds for OLED screens.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Custom Theme Color', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    subtitle:
                        Text('Current: #${_customColor.value.toRadixString(16).substring(2)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _customColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    onTap: () {
                      _performVibration();
                      _openColorPicker();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Miscellaneous',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
          ),
          Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: Theme.of(context).colorScheme.surface,
            child: ListTile(
              leading: const Icon(Icons.developer_mode_rounded),
              title: const Text('Developer Options'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () async {
                _performVibration();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeveloperOptionsPage()),
                );
              },
            ),
          ),
          // TODO: Add more settings sections here as Cards or similar groupings
          // Example:
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 8.0),
          //   child: Text(
          //     'Notification Settings',
          //     style: Theme.of(context).textTheme.titleLarge,
          //   ),
          // ),
          // Card(
          //   child: Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: Column(
          //       children: [
          //         // ... notification settings widgets ...
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

// New StatefulWidget for the Color Picker Dialog Content
enum _ColorPickerType { primary, accent, wheel }

class _ColorPickerDialogContent extends StatefulWidget {
  final Color initialColor;
  final List<Color> primaryColors;
  final List<Color> accentColors;

  const _ColorPickerDialogContent({
    Key? key,
    required this.initialColor,
    required this.primaryColors,
    required this.accentColors,
  }) : super(key: key);

  @override
  _ColorPickerDialogContentState createState() => _ColorPickerDialogContentState();
}

class _ColorPickerDialogContentState extends State<_ColorPickerDialogContent> {
  late Color _currentColor;
  _ColorPickerType _selectedPickerType = _ColorPickerType.primary;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  void _performVibration() async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: 18, amplitude: 60);
    }
  }

  // Helper function to generate shades for the BlockPicker
  List<Color> _generateShades(Color color) {
    final List<Color> shades = [];
    for (int i = 1; i <= 6; i++) { // Generate 6 shades
      final double factor = i / 7.0; // Adjust factor for desired lightness/darkness
      shades.add(HSLColor.fromColor(color).withLightness(factor).toColor());
    }
    // Add some darker shades too for more variety, similar to the image
    for (int i = 1; i <= 6; i++) {
        final double factor = 1.0 - (i / 10.0); // Lighter to darker
        final Color baseShade = HSLColor.fromColor(color).withSaturation(0.8).withLightness(factor * 0.8 + 0.1).toColor(); // Ensure not too dark
        shades.add(baseShade);
    }
    // Ensure unique colors and sort by lightness (optional, but can make it look more organized)
    return shades.toSet().toList()..sort((a, b) => HSLColor.fromColor(a).lightness.compareTo(HSLColor.fromColor(b).lightness));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color dialogBackgroundColor = theme.brightness == Brightness.dark 
        ? colorScheme.surfaceVariant.withOpacity(0.95) 
        : colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: dialogBackgroundColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      clipBehavior: Clip.antiAlias,
      width: MediaQuery.of(context).size.width * 0.9, 
      height: 600, 
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Choose Theme Color', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: colorScheme.primary),
                      onPressed: () {
                        _performVibration();
                        Navigator.of(context).pop(_currentColor);
                      },
                      style: IconButton.styleFrom(splashFactory: InkSparkle.splashFactory),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                      onPressed: () {
                        _performVibration();
                        Navigator.of(context).pop();
                      },
                      style: IconButton.styleFrom(splashFactory: InkSparkle.splashFactory),
                    ),
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                // border: Border.all(color: colorScheme.outline.withOpacity(0.7), width: 1.0), // Keep or remove based on visual preference later
                borderRadius: BorderRadius.circular(12.0), // This will round the group
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0), // Add extra space above the ToggleButtons
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: ToggleButtons(
                    isSelected: [
                      _selectedPickerType == _ColorPickerType.primary,
                      _selectedPickerType == _ColorPickerType.accent,
                      _selectedPickerType == _ColorPickerType.wheel,
                    ],
                    onPressed: (index) {
                      _performVibration();
                      setState(() {
                        _selectedPickerType = _ColorPickerType.values[index];
                      });
                    },
                    borderRadius: BorderRadius.circular(11.0), // Rounds each button
                    fillColor: colorScheme.primary.withOpacity(0.2), // Lighter fill for selected
                    selectedColor: colorScheme.primary, // Text color for selected
                    color: colorScheme.onSurfaceVariant, // Text color for unselected
                    borderColor: colorScheme.outline.withOpacity(0.5), // Border for unselected
                    selectedBorderColor: colorScheme.primary, // Border for selected (matches text)
                    borderWidth: 1.5, // Make borders visible
                    constraints: const BoxConstraints(minHeight: 38.0, minWidth: 70.0), // Adjust minWidth if needed to fill
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Primary')), // Adjusted padding
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Accent')),  // Adjusted padding
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Spectrum')),   // Adjusted padding
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildCurrentPicker(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _currentColor, shape: BoxShape.circle, border: Border.all(color: colorScheme.outline)),
                ),
                Text('#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                IconButton(
                  icon: Icon(Icons.copy, size: 20, color: colorScheme.primary),
                  onPressed: () {
                    _performVibration();
                    Clipboard.setData(ClipboardData(text: '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Color code copied!', style: TextStyle(color: colorScheme.onInverseSurface)),
                        backgroundColor: colorScheme.inverseSurface,
                        duration: const Duration(seconds: 1)
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _performVibration();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(splashFactory: InkSparkle.splashFactory),
                  child: Text('CANCEL', style: TextStyle(color: colorScheme.primary)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _performVibration();
                    Navigator.of(context).pop(_currentColor);
                  },
                  style: TextButton.styleFrom(splashFactory: InkSparkle.splashFactory),
                  child: Text('OK', style: TextStyle(color: colorScheme.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPicker() {
    switch (_selectedPickerType) {
      case _ColorPickerType.primary:
        return SizedBox(
          height: 200,
          child: BlockPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) => setState(() => _currentColor = color),
            availableColors: widget.primaryColors,
            itemBuilder: (color, isCurrentColor, changeColor) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _performVibration();
                      changeColor();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 210),
                      opacity: isCurrentColor ? 1 : 0,
                      child: Icon(Icons.done, color: useWhiteForeground(color) ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              );
            },
            layoutBuilder: (BuildContext context, List<Color> colors, PickerItem child) {
              return GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                children: colors.map((Color color) => child(color)).toList(),
              );
            },
          ),
        );
      case _ColorPickerType.accent:
        return SizedBox(
          height: 200,
          child: BlockPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) => setState(() => _currentColor = color),
            availableColors: widget.accentColors,
            itemBuilder: (color, isCurrentColor, changeColor) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _performVibration();
                      changeColor();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 210),
                      opacity: isCurrentColor ? 1 : 0,
                      child: Icon(Icons.done, color: useWhiteForeground(color) ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              );
            },
            layoutBuilder: (BuildContext context, List<Color> colors, PickerItem child) {
              return GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                children: colors.map((Color color) => child(color)).toList(),
              );
            },
          ),
        );
      case _ColorPickerType.wheel:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220, // Adjust width as needed
                  height: 280, // Adjust height as needed
                  child: ColorPicker(
                    pickerColor: _currentColor,
                    onColorChanged: (color) {
                      _performVibration();
                      setState(() => _currentColor = color);
                    },
                    colorPickerWidth: 220, // Adjust as needed
                    pickerAreaHeightPercent: 0.6, // Adjusted from 0.7 to 0.6
                    enableAlpha: false, // Alpha is not in the target UI
                    displayThumbColor: true,
                    paletteType: PaletteType.hsvWithSaturation, // For the square saturation/value picker
                    pickerAreaBorderRadius: BorderRadius.circular(20.0), // Rounded corners for the picker area
                    labelTypes: const [], // No labels like "R", "G", "B"
                  ),
                ),
                const SizedBox(height: 16), // Small space below the color selector
                Text("Shades", style: Theme.of(this.context).textTheme.titleMedium),
                SizedBox(
                  height: 100, // Adjust as needed
                  child: BlockPicker(
                    pickerColor: _currentColor, // This will highlight the selected color if it's in the swatches
                    onColorChanged: (color) {
                      _performVibration();
                      setState(() => _currentColor = color);
                    },
                    availableColors: _generateShades(_currentColor), // Dynamically generate shades
                    layoutBuilder: (builderContext, colors, child) {
                      return GridView.count(
                        crossAxisCount: 6, // Number of swatches per row
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: colors.map((color) => child(color)).toList(),
                      );
                    },
                    itemBuilder: (color, isCurrentColor, changeColor) {
                      return Builder(
                        builder: (builderContext) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: Theme.of(builderContext).dividerColor,
                                width: isCurrentColor ? 2.0 : 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _performVibration();
                                  changeColor();
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 210),
                                  opacity: isCurrentColor ? 1 : 0,
                                  child: Icon(
                                    Icons.done,
                                    color: useWhiteForeground(color) ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Options')),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danger Zone', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Clear Local DB'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 4.0,
                    splashFactory: InkSparkle.splashFactory,
                  ),
                  onPressed: () async {
                    final bool? hasVibration = await Vibration.hasVibrator();
                    if (hasVibration == true) {
                      Vibration.vibrate(duration: 18, amplitude: 60);
                    }
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm'),
                        content: const Text('Are you sure you want to delete the local encrypted DB? This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              final bool? hasVibration = await Vibration.hasVibrator();
                              if (hasVibration == true) {
                                Vibration.vibrate(duration: 18, amplitude: 60);
                              }
                              Navigator.of(context).pop(false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final bool? hasVibration = await Vibration.hasVibrator();
                              if (hasVibration == true) {
                                Vibration.vibrate(duration: 18, amplitude: 60);
                              }
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final dbPath = await getDatabasesPath();
                      final pathEnglish = join(dbPath, 'songs_encrypted.db');
                      final pathKannada = join(dbPath, 'kannada_songs_encrypted.db');
                      await deleteDatabase(pathEnglish);
                      await deleteDatabase(pathKannada);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Local encrypted DBs deleted! Restart the app to re-sync.')),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will delete all locally stored songs from the encrypted DB. Connect to the internet to re-download the songs and go offline again.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 