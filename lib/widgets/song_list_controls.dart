import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Shared search + font + sync chrome for language song lists (English style).
class SongListControlsBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String searchHint;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback? onSync;
  final bool syncing;
  final String syncLabel;
  final Widget? trailing;

  const SongListControlsBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.searchHint,
    required this.fontSize,
    required this.onFontSizeChanged,
    this.onSync,
    this.syncing = false,
    this.syncLabel = 'Sync',
    this.trailing,
  });

  static final _stepperSize = M3EButtonSize.custom(height: 40, hPadding: 4);

  void _vibrate() => HapticFeedback.lightImpact();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: searchHint,
                    prefixIcon: Icon(Icons.search_rounded,
                        color: colorScheme.primary),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _vibrate();
                              searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor:
                        colorScheme.surfaceContainerHighest.withAlpha(180),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 128,
                child: M3EButtonGroup(
                  type: M3EButtonGroupType.connected,
                  shape: M3EButtonShape.round,
                  size: _stepperSize,
                  style: M3EButtonStyle.tonal,
                  density: M3EButtonGroupDensity.compact,
                  neighborSquish: false,
                  overflow: M3EButtonGroupOverflow.none,
                  haptic: M3EHapticFeedback.light,
                  onSelectedIndicesChanged: (indices) {
                    if (indices.contains(0) && fontSize > 12) {
                      onFontSizeChanged(fontSize - 2);
                    } else if (indices.contains(2) && fontSize < 28) {
                      onFontSizeChanged(fontSize + 2);
                    }
                  },
                  actions: [
                    const M3EButtonGroupAction(
                      icon: Icon(Icons.remove_rounded, size: 18),
                      width: 36,
                    ),
                    M3EButtonGroupAction(
                      label: Text(
                        fontSize.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      width: 44,
                    ),
                    const M3EButtonGroupAction(
                      icon: Icon(Icons.add_rounded, size: 18),
                      width: 36,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onSync != null || trailing != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                if (onSync != null)
                  FilledButton.tonalIcon(
                    onPressed: syncing ? null : onSync,
                    icon: syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(syncLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Alphabet / letter chip row matching English list styling.
class SongListAlphabetBar extends StatelessWidget {
  final List<String> letters;
  final Set<String> availableLetters;
  final String? selectedLetter;
  final ValueChanged<String?> onSelected;
  final bool fadeUnavailable;

  const SongListAlphabetBar({
    super.key,
    required this.letters,
    required this.availableLetters,
    required this.selectedLetter,
    required this.onSelected,
    this.fadeUnavailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          ...letters.map((letter) {
            final has = !fadeUnavailable || availableLetters.contains(letter);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: has ? 1 : 0.3,
                child: ChoiceChip(
                  label: Text(letter),
                  selected: selectedLetter == letter,
                  onSelected: has
                      ? (_) {
                          HapticFeedback.lightImpact();
                          onSelected(
                              selectedLetter == letter ? null : letter);
                        }
                      : null,
                  selectedColor: colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
            );
          }),
          if (selectedLetter != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ActionChip(
                label: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onSelected(null);
                },
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }
}
