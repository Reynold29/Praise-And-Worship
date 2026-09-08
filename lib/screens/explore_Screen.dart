import 'package:material_ui/material_ui.dart';

class _GuideItem {
  const _GuideItem({
    required this.section,
    required this.title,
    required this.howTo,
    required this.icon,
    this.image,
  });

  final String section;
  final String title;
  final String howTo;
  final IconData icon;
  final String? image;
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const _guides = <_GuideItem>[
    _GuideItem(
      section: 'Get started',
      title: 'Welcome & your name',
      howTo:
          'On first launch, type what we should call you and tap Get Started. You can skip and change this later from your profile.',
      icon: Icons.waving_hand_rounded,
      image: 'onboarding.png',
    ),
    _GuideItem(
      section: 'Get started',
      title: 'Home at a glance',
      howTo:
          'Your greeting, How to use, language cards, search, and More Options (Favorites, Playlists, Scanner, Settings) all live here.',
      icon: Icons.home_rounded,
      image: 'homescreen.png',
    ),
    _GuideItem(
      section: 'Songs',
      title: 'Open a language card',
      howTo:
          'Swipe the Discover Melodies cards, then tap English, Kannada, or Other Languages. The card morphs into that list’s header.',
      icon: Icons.album_rounded,
      image: 'categories.png',
    ),
    _GuideItem(
      section: 'Songs',
      title: 'Find a song fast',
      howTo:
          'Use Search, jump with the A–Z letters, or tap Sync Songs after a cloud update. Heart a row to save it to Favorites.',
      icon: Icons.search_rounded,
      image: 'english-songs.png',
    ),
    _GuideItem(
      section: 'Lyrics',
      title: 'Read, share, favorite',
      howTo:
          'Open a song for lyrics. Share Song shows a QR others can scan. Favorite saves it. Playlist / Chords / Audio sit in the card.',
      icon: Icons.lyrics_rounded,
      image: 'detail-song.png',
    ),
    _GuideItem(
      section: 'Lyrics',
      title: 'Chords & transpose',
      howTo:
          'Tap Chords to show them above the words. Transpose stays greyed out until Chords is on, then use − / + to change key.',
      icon: Icons.music_note_rounded,
      image: 'chords.png',
    ),
    _GuideItem(
      section: 'Worship tools',
      title: 'Playlists',
      howTo:
          'More Options → Playlists. Create a list, add songs from any lyrics card, then share the playlist with a QR so others can import it.',
      icon: Icons.queue_music_rounded,
      image: 'playlists.png',
    ),
    _GuideItem(
      section: 'You',
      title: 'Theme & dark mode',
      howTo:
          'Settings lets you pick Material Expressive or system colors, light/dark, AMOLED black, and a custom seed color.',
      icon: Icons.palette_rounded,
      image: 'settings.png',
    ),
    _GuideItem(
      section: 'You',
      title: 'Custom colors',
      howTo:
          'In Settings, tap the color preview. Pick a seed, then OK — the whole app restyles around that color.',
      icon: Icons.color_lens_rounded,
      image: 'custom_theme.png',
    ),
    _GuideItem(
      section: 'You',
      title: 'Your profile',
      howTo:
          'Tap your avatar on Home. Change your name or photo. Profile stays on this device only.',
      icon: Icons.account_circle_rounded,
      image: 'user.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sections = <String>[];
    for (final item in _guides) {
      if (!sections.contains(item.section)) sections.add(item.section);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('How to use'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Worship Companion',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A short tour of the screens you will use most — tap a language card, open lyrics, share a QR, or build a playlist.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final section in sections) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Text(
                  section.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (final item
                      in _guides.where((g) => g.section == section))
                    _GuideCard(item: item),
                ]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.item});

  final _GuideItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.howTo,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (item.image != null) ...[
                const SizedBox(height: 14),
                _PhoneShot(asset: 'assets/screenshots/${item.image}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneShot extends StatelessWidget {
  const _PhoneShot({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                asset,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                cacheWidth: (320 * dpr).round().clamp(360, 900),
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (context, error, stack) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.outline,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
