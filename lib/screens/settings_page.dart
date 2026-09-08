import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/widgets/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import '../services/local_database_service.dart';

// ─── Theme mode enum ──────────────────────────────────────────────────────────
enum AppThemeMode {
  materialExpressive, // Custom seed color
  youTheming, // Dynamic / system color
}

// ─── Dark mode preference stored as int ──────────────────────────────────────
enum AppDarkMode { system, light, dark }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _darkModeKey = 'app_dark_mode';
  static const String _amoledBlackKeySP = 'amoled_black_on_sp';
  static const String _customColorKeySP = 'custom_color_sp';

  AppThemeMode _selectedTheme = AppThemeMode.youTheming;
  AppDarkMode _darkMode = AppDarkMode.system;
  bool _isAmoledBlack = false;
  Color _customColor = Colors.blue;
  bool _isLoading = true;

  // Recent colors (stored as int list)
  static const String _recentColorsKey = 'recent_colors';
  List<Color> _recentColors = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Capture ThemeProvider BEFORE the first await so the BuildContext
    // is not used across an async gap (Dart SDK >= 3.7 enforcement).
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final themeModeIdx =
        prefs.getInt(_themeModeKey) ?? AppThemeMode.youTheming.index;
    final darkModeIdx = prefs.getInt(_darkModeKey) ?? AppDarkMode.system.index;

    _selectedTheme = AppThemeMode.values[themeModeIdx];
    _darkMode =
        AppDarkMode.values.elementAtOrNull(darkModeIdx) ?? AppDarkMode.system;
    _isAmoledBlack =
        prefs.getBool(_amoledBlackKeySP) ?? themeProvider.isAmoledBlack;
    _customColor = Color(prefs.getInt(_customColorKeySP) ??
        (themeProvider.customSeedColor?.value ?? Colors.blue.value));

    // Recent colors
    final raw = prefs.getStringList(_recentColorsKey) ?? [];
    _recentColors = raw
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .map(Color.new)
        .toList();

    _applyThemeMode(themeProvider);
    themeProvider.setAmoledBlack(_isAmoledBlack);
    _applyDarkMode(themeProvider);

    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _selectedTheme.index);
    await prefs.setInt(_darkModeKey, _darkMode.index);
    await prefs.setBool(_amoledBlackKeySP, _isAmoledBlack);
    await prefs.setInt(_customColorKeySP, _customColor.value);
    await prefs.setStringList(_recentColorsKey,
        _recentColors.map((c) => c.value.toString()).toList());
  }

  void _applyThemeMode(ThemeProvider tp) {
    if (_selectedTheme == AppThemeMode.materialExpressive) {
      tp.setCustomSeedColor(_customColor);
    } else {
      tp.setCustomSeedColor(Colors.transparent);
    }
  }

  void _applyDarkMode(ThemeProvider tp) {
    switch (_darkMode) {
      case AppDarkMode.light:
        tp.toggleTheme(false);
      case AppDarkMode.dark:
        tp.toggleTheme(true);
      case AppDarkMode.system:
        // Honour system brightness
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        tp.toggleTheme(brightness == Brightness.dark);
    }
  }

  void _vibrate() {
    HapticFeedback.lightImpact();
  }

  Future<void> _openColorPicker() async {
    // Capture context and provider before any await.
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (!mounted) return;
    final Color? result = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 500),
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModernColorPicker(
        initialColor: _customColor,
        recentColors: _recentColors,
      ),
    );

    if (result != null) {
      setState(() => _customColor = result);
      // Save to recent
      _recentColors.removeWhere((c) => c.value == result.value);
      _recentColors.insert(0, result);
      if (_recentColors.length > 8) _recentColors = _recentColors.sublist(0, 8);

      if (_selectedTheme == AppThemeMode.materialExpressive) {
        themeProvider.setCustomSeedColor(_customColor);
      }
      await _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Appearance Preview Card ────────────────────────────────────
          _SectionLabel(label: 'Appearance Preview'),
          _AppearancePreviewCard(
            seedColor: _selectedTheme == AppThemeMode.materialExpressive
                ? _customColor
                : colorScheme.primary,
            isDark: themeProvider.isDarkMode,
          ),
          const SizedBox(height: 20),

          // ── Color Scheme ───────────────────────────────────────────────
          _SectionLabel(label: 'Color Scheme'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.auto_awesome_rounded,
              iconColor: colorScheme.primary,
              title: 'System Theme (Material You)',
              subtitle: 'Adapts to your wallpaper (Android 12+)',
              trailing: Radio<AppThemeMode>(
                value: AppThemeMode.youTheming,
                groupValue: _selectedTheme,
                activeColor: colorScheme.primary,
                onChanged: (v) async {
                  _vibrate();
                  setState(() => _selectedTheme = v!);
                  _applyThemeMode(themeProvider);
                  await _savePreferences();
                },
              ),
              onTap: () async {
                _vibrate();
                setState(() => _selectedTheme = AppThemeMode.youTheming);
                _applyThemeMode(themeProvider);
                await _savePreferences();
              },
            ),
            const Divider(indent: 56, endIndent: 16, height: 1),
            _SettingsTile(
              icon: Icons.palette_outlined,
              iconColor: colorScheme.tertiary,
              title: 'Material Expressive',
              subtitle: 'Custom seed with Material 3 Expressive palettes',
              trailing: Radio<AppThemeMode>(
                value: AppThemeMode.materialExpressive,
                groupValue: _selectedTheme,
                activeColor: colorScheme.primary,
                onChanged: (v) async {
                  _vibrate();
                  setState(() => _selectedTheme = v!);
                  _applyThemeMode(themeProvider);
                  await _savePreferences();
                },
              ),
              onTap: () async {
                _vibrate();
                setState(
                    () => _selectedTheme = AppThemeMode.materialExpressive);
                _applyThemeMode(themeProvider);
                await _savePreferences();
              },
            ),
            // Color swatch row — only tappable when custom mode is active
            AnimatedOpacity(
              opacity:
                  _selectedTheme == AppThemeMode.materialExpressive ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selectedTheme == AppThemeMode.materialExpressive
                    ? () {
                        _vibrate();
                        _openColorPicker();
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(56, 12, 16, 12),
                  child: Row(
                    children: [
                      // Large color circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _customColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colorScheme.outline.withOpacity(0.5),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: _customColor.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Custom Color',
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500)),
                            Text(
                                '#${_customColor.value.toRadixString(16).substring(2).toUpperCase()}',
                                style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Brightness ─────────────────────────────────────────────────
          _SectionLabel(label: 'Brightness'),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.brightness_6_rounded,
                          color: colorScheme.primary, size: 22),
                      const SizedBox(width: 14),
                      Text('App Appearance',
                          style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AppDarkMode>(
                    segments: const [
                      ButtonSegment(
                          value: AppDarkMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System')),
                      ButtonSegment(
                          value: AppDarkMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light')),
                      ButtonSegment(
                          value: AppDarkMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark')),
                    ],
                    selected: {_darkMode},
                    onSelectionChanged: (s) async {
                      _vibrate();
                      setState(() => _darkMode = s.first);
                      _applyDarkMode(themeProvider);
                      await _savePreferences();
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: colorScheme.primaryContainer,
                      selectedForegroundColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(indent: 16, endIndent: 16, height: 1),
            SwitchListTile(
              secondary: Icon(
                Icons.contrast_rounded,
                color: _isAmoledBlack
                    ? Colors.white
                    : colorScheme.onSurfaceVariant,
              ),
              title: Row(
                children: [
                  Text('AMOLED Black',
                      style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  if (_isAmoledBlack)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text('ON',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ),
                ],
              ),
              subtitle: Text('True black backgrounds for OLED screens',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              value: _isAmoledBlack,
              activeColor: colorScheme.primary,
              onChanged: (v) async {
                _vibrate();
                setState(() => _isAmoledBlack = v);
                themeProvider.setAmoledBlack(v);
                await _savePreferences();
              },
              tileColor: _isAmoledBlack ? Colors.black87 : null,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Developer Options ──────────────────────────────────────────
          _SectionLabel(label: 'Advanced'),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.error.withOpacity(0.2)),
            ),
            child: ListTile(
              leading:
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              title: Text('Developer Options',
                  style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error, fontWeight: FontWeight.w600)),
              subtitle: Text('Danger zone — clear local data',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: colorScheme.error.withOpacity(0.7)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onTap: () {
                _vibrate();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const DeveloperOptionsPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Appearance Preview Card ──────────────────────────────────────────────────
class _AppearancePreviewCard extends StatelessWidget {
  final Color seedColor;
  final bool isDark;
  const _AppearancePreviewCard({required this.seedColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: isDark ? Brightness.dark : Brightness.light);
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Color swatches
          _Swatch(color: scheme.primary, label: 'Primary'),
          const SizedBox(width: 8),
          _Swatch(color: scheme.secondary, label: 'Secondary'),
          const SizedBox(width: 8),
          _Swatch(color: scheme.tertiary, label: 'Tertiary'),
          const SizedBox(width: 16),
          // Mini text preview
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amazing Grace',
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text('How sweet the sound',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('♪ Favorites',
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  const _Swatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)
              ]),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 9)),
      ],
    );
  }
}

// ─── Reusable layout helpers ──────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ─── Modern Color Picker (Bottom Sheet) ───────────────────────────────────────
enum _PickerTab { primary, accent, spectrum }

class _ModernColorPicker extends StatefulWidget {
  final Color initialColor;
  final List<Color> recentColors;
  const _ModernColorPicker(
      {required this.initialColor, required this.recentColors});

  @override
  State<_ModernColorPicker> createState() => _ModernColorPickerState();
}

class _ModernColorPickerState extends State<_ModernColorPicker> {
  late Color _current;
  _PickerTab _tab = _PickerTab.primary;
  late TextEditingController _hexController;

  static const _primaryColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.blueGrey,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
  ];
  static const _accentColors = [
    Colors.lightBlueAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.indigoAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
    Colors.cyanAccent,
    Colors.limeAccent,
  ];

  void _vibrate() {
    HapticFeedback.lightImpact();
  }

  @override
  void initState() {
    super.initState();
    _current = widget.initialColor;
    _hexController = TextEditingController(text: _toHex(_current));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _toHex(Color c) =>
      c.value.toRadixString(16).substring(2).toUpperCase();

  void _updateColor(Color c) {
    setState(() {
      _current = c;
      _hexController.text = _toHex(c);
    });
  }

  void _applyHex(String text) {
    final clean = text.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) _updateColor(Color(val));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                )),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Choose Color',
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _vibrate();
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () {
                      _vibrate();
                      Navigator.of(context).pop(_current);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Large color preview swatch
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _current,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _current.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ],
                  border:
                      Border.all(color: colorScheme.outlineVariant, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Hex input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: TextField(
                controller: _hexController,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5),
                decoration: InputDecoration(
                  prefixText: '#',
                  prefixStyle: TextStyle(
                      color: colorScheme.primary, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.copy_rounded,
                        size: 18, color: colorScheme.primary),
                    onPressed: () {
                      _vibrate();
                      Clipboard.setData(
                          ClipboardData(text: '#${_toHex(_current)}'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Color copied!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6)
                ],
                onSubmitted: _applyHex,
                onChanged: _applyHex,
              ),
            ),
            const SizedBox(height: 18),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<_PickerTab>(
                segments: const [
                  ButtonSegment(
                      value: _PickerTab.primary,
                      icon: Icon(Icons.palette_rounded),
                      label: Text('Palette')),
                  ButtonSegment(
                      value: _PickerTab.accent,
                      icon: Icon(Icons.brightness_7_rounded),
                      label: Text('Accent')),
                  ButtonSegment(
                      value: _PickerTab.spectrum,
                      icon: Icon(Icons.colorize_rounded),
                      label: Text('Wheel')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) {
                  _vibrate();
                  setState(() => _tab = s.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorScheme.primaryContainer,
                  selectedForegroundColor: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Picker body
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tab == _PickerTab.primary || _tab == _PickerTab.accent)
                      _ColorGrid(
                        colors: _tab == _PickerTab.primary
                            ? _primaryColors
                            : _accentColors,
                        selected: _current,
                        onSelect: (c) {
                          _vibrate();
                          _updateColor(c);
                        },
                      )
                    else
                      Center(
                        child: ColorPicker(
                          pickerColor: _current,
                          onColorChanged: (c) {
                            _vibrate();
                            _updateColor(c);
                          },
                          colorPickerWidth:
                              MediaQuery.of(context).size.width - 80,
                          pickerAreaHeightPercent: 0.55,
                          enableAlpha: false,
                          displayThumbColor: true,
                          paletteType: PaletteType.hsvWithSaturation,
                          pickerAreaBorderRadius: BorderRadius.circular(16),
                          labelTypes: const [],
                        ),
                      ),

                    // Recent colors
                    if (widget.recentColors.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Recently Used',
                          style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.recentColors
                            .map((c) => GestureDetector(
                                  onTap: () {
                                    _vibrate();
                                    _updateColor(c);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: c.value == _current.value
                                            ? colorScheme.primary
                                            : colorScheme.outlineVariant,
                                        width:
                                            c.value == _current.value ? 3 : 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                            color: c.withOpacity(0.3),
                                            blurRadius: 4)
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;
  const _ColorGrid(
      {required this.colors, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: colors.length,
      itemBuilder: (_, i) {
        final c = colors[i];
        final isSelected = c.value == selected.value;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                    color: c.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: isSelected
                ? Icon(Icons.check_rounded,
                    color: useWhiteForeground(c) ? Colors.white : Colors.black,
                    size: 20)
                : null,
          ),
        );
      },
    );
  }
}

// ─── Developer Options (unchanged logic, restyled) ────────────────────────────
class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Options')),
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danger Zone',
                style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Actions here cannot be undone.',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.error.withOpacity(0.3)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Icon(Icons.delete_forever_rounded,
                    color: colorScheme.error),
                title: Text('Clear Local Database',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Deletes all locally cached songs. Connect to the internet to re-download.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: colorScheme.error.withOpacity(0.6)),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (!context.mounted) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      icon: Icon(Icons.warning_amber_rounded,
                          color: colorScheme.error, size: 36),
                      title: const Text('Delete Local Database?'),
                      content: const Text(
                          'This will remove all locally stored songs. The app will re-sync from the cloud when you reconnect to the internet.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.error),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await LocalDatabaseService.instance.clearAllSongs();
                    await LocalDatabaseService.instance.clearAllKannadaSongs();
                    await LocalDatabaseService.instance.clearAllOtherSongs();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Local databases cleared — restart to re-sync.'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
