import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:worshipcompanion/screens/settings_page.dart';
import 'card_model.dart';
import 'package:flutter/services.dart';
import 'package:worshipcompanion/screens/song_list_screen.dart';
import 'package:worshipcompanion/screens/add_song_options_screen.dart';
import 'package:worshipcompanion/screens/about_developer.dart';
import 'package:worshipcompanion/screens/kannada_song_list_screen.dart';
import 'package:worshipcompanion/screens/other_song_list_screen.dart';
import 'package:worshipcompanion/screens/home_page.dart';
import 'package:worshipcompanion/screens/qr_scanner_screen.dart';
import 'package:worshipcompanion/screens/playlist_list_screen.dart';
import 'package:worshipcompanion/screens/admin_panel_screen.dart';
import 'package:worshipcompanion/widgets/snappy_transitions.dart';
import 'package:worshipcompanion/widgets/language_card_hero.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/auth_provider.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';
import 'package:worshipcompanion/widgets/favorite_provider.dart';
import 'package:worshipcompanion/widgets/sync_dialog.dart';

class SlidingCardsView extends StatefulWidget {
  final VoidCallback? onFavoriteToggled;
  const SlidingCardsView({super.key, this.onFavoriteToggled});

  @override
  State<SlidingCardsView> createState() => _SlidingCardsViewState();
}

class _SlidingCardsViewState extends State<SlidingCardsView> {
  static const double _cardGap = 12;
  static const double _viewportFraction = LanguageCardHero.viewportFraction;

  late final PageController pageController;
  int _currentPage = 0;
  bool _openingCard = false;
  bool _didPrecache = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
      for (final card in demoCardData) {
        final provider = ResizeImage(
          AssetImage('assets/cards/${card.image}'),
          width: LanguageCardHero.cacheWidthFor(context),
        );
        precacheImage(provider, context);
      }
  }

  void _onPageChanged(int index) {
    if (_currentPage == index) return;
    setState(() => _currentPage = index);
    HapticFeedback.selectionClick();
  }

  void _onArrowTap(bool isNext) {
    final nextPage = isNext ? _currentPage + 1 : _currentPage - 1;
    if (nextPage >= 0 && nextPage < demoCardData.length) {
      pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _vibrate() {
    HapticFeedback.lightImpact();
  }

  Future<void> _openCard(CardModel card) async {
    if (card.onTap != null) {
      card.onTap!();
      return;
    }
    if (!mounted || _openingCard) return;
    _openingCard = true;
    try {
      if (card.name == 'Kannada Songs') {
        await Navigator.of(context).push(
          snappyFadeRoute(
            page: KannadaSongListScreen(
              heroTag: card.heroTag,
              cardImage: card.image,
              onFavoriteToggled: widget.onFavoriteToggled,
            ),
          ),
        );
      } else if (card.name == 'Other Languages') {
        await Navigator.of(context).push(
          snappyFadeRoute(
            page: OtherSongListScreen(
              heroTag: card.heroTag,
              cardImage: card.image,
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          snappyFadeRoute(
            page: SongListScreen(
              heroTag: card.heroTag,
              cardImage: card.image,
              onFavoriteToggled: widget.onFavoriteToggled,
            ),
          ),
        );
      }
    } finally {
      _openingCard = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.36,
          child: PageView.builder(
            controller: pageController,
            itemCount: demoCardData.length,
            padEnds: true,
            clipBehavior: Clip.none,
            allowImplicitScrolling: true,
            physics: const BouncingScrollPhysics(
              parent: PageScrollPhysics(),
            ),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final card = demoCardData[index];
              return _DiscoverCard(
                card: card,
                index: index,
                pageController: pageController,
                gap: _cardGap,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
                onTap: () => _openCard(card),
              );
            },
          ),
        ),

            // ── Page indicator + arrows ───────────────────────────────────
            const SizedBox(height: 4),
            Row(
              children: [
                if (_currentPage > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton.filledTonal(
                      onPressed: () {
                        _vibrate();
                        _onArrowTap(false);
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.onPrimaryContainer, size: 16),
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: colorScheme.primaryContainer,
                        fixedSize: const Size(40, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashFactory: InkSparkle.splashFactory,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),
                Expanded(
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: pageController,
                      count: demoCardData.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 16,
                        dotHeight: 4,
                        spacing: 6,
                        activeDotColor: colorScheme.primary,
                        dotColor: colorScheme.outline,
                        expansionFactor: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_currentPage < demoCardData.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton.filledTonal(
                      onPressed: () {
                        _vibrate();
                        _onArrowTap(true);
                      },
                      icon: Icon(Icons.arrow_forward_ios_rounded,
                          color: colorScheme.onPrimaryContainer, size: 16),
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: colorScheme.primaryContainer,
                        fixedSize: const Size(40, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashFactory: InkSparkle.splashFactory,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),

            // ── More Options section ──────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'More Options',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Horizontal scroll → never overflows regardless of screen width
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _NavItem(
                          icon: Icons.favorite_rounded,
                          label: 'Favorites',
                          color: colorScheme.primaryContainer,
                          iconColor: colorScheme.onPrimaryContainer,
                          onTap: () {
                            _vibrate();
                            if (context.mounted) {
                              Navigator.push(
                                  context,
                                  snappyPageRoute(
                                      page: const FavoritesScreen()));
                            }
                          },
                        ),
                        Consumer2<AuthProvider, AppConfigProvider>(
                          builder: (ctx, auth, config, _) {
                            if (!auth.isLoggedIn ||
                                !config.isMasterUser(auth.email)) {
                              return const SizedBox.shrink();
                            }
                            return _NavItem(
                              icon: Icons.admin_panel_settings_rounded,
                              label: 'Admin',
                              color: colorScheme.tertiaryContainer,
                              iconColor: colorScheme.onTertiaryContainer,
                              onTap: () async {
                                _vibrate();
                                if (!await ConnectivityGuard.ensureOnline(
                                    context,
                                    message:
                                        'Admin controls need an internet connection.',
                                    useDialog: true)) {
                                  return;
                                }
                                if (!context.mounted) return;
                                Navigator.push(
                                    context,
                                    snappyPageRoute(
                                        page: const AdminPanelScreen()));
                              },
                            );
                          },
                        ),
                        _NavItem(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Add Song',
                          color: colorScheme.primaryContainer,
                          iconColor: colorScheme.onPrimaryContainer,
                          onTap: () {
                            _vibrate();
                            if (context.mounted) {
                              Navigator.push(
                                  context,
                                  snappyPageRoute(
                                      page: const AddSongOptionsScreen()));
                            }
                          },
                        ),
                        _NavItem(
                          icon: Icons.playlist_play_rounded,
                          label: 'Playlists',
                          color: colorScheme.primaryContainer,
                          iconColor: colorScheme.onPrimaryContainer,
                          onTap: () {
                            _vibrate();
                            if (context.mounted) {
                              Navigator.push(
                                  context,
                                  snappyPageRoute(
                                      page: const PlaylistListScreen()));
                            }
                          },
                        ),
                        _NavItem(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Scanner',
                          color: colorScheme.primaryContainer,
                          iconColor: colorScheme.onPrimaryContainer,
                          onTap: () {
                            _vibrate();
                            if (context.mounted) {
                              Navigator.push(
                                  context,
                                  snappyPageRoute(
                                      page: const QRScannerScreen()));
                            }
                          },
                        ),
                        _NavItem(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          color: colorScheme.primaryContainer,
                          iconColor: colorScheme.onPrimaryContainer,
                          onTap: () {
                            _vibrate();
                            if (context.mounted) {
                              Navigator.push(context,
                                  snappyPageRoute(page: const SettingsPage()));
                            }
                          },
                        ),
                        _NavItem(
                          icon: Icons.info_outline_rounded,
                          label: 'About Dev',
                          color: colorScheme.primaryContainer,
                          iconColor: colorScheme.onPrimaryContainer,
                          onTap: () {
                            _vibrate();
                            if (context.mounted) {
                              Navigator.push(
                                  context,
                                  snappyPageRoute(
                                      page: const AboutDeveloper()));
                            }
                          },
                        ),
                        // Login — only visible when not signed in AND login is enabled
                        Consumer2<AuthProvider, AppConfigProvider>(
                          builder: (ctx, auth, config, _) {
                            // Hide if already logged in OR if login is disabled
                            if (auth.isLoggedIn || !config.socialLoginEnabled) {
                              return const SizedBox.shrink();
                            }
                            return _LoginNavItem(
                              onTap: () async {
                                _vibrate();
                                final favProv = Provider.of<FavoriteProvider>(
                                    context,
                                    listen: false);
                                final localKeys = favProv.favoriteSongKeys
                                    .where((k) => k.isNotEmpty)
                                    .toList();
                                final result = await Navigator.of(context)
                                    .push<bool>(snappyPageRoute(
                                        page: const UserProfilePage()));
                                if (!context.mounted) return;
                                final updatedAuth = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                if ((result == true ||
                                        updatedAuth.isLoggedIn) &&
                                    updatedAuth.isLoggedIn &&
                                    localKeys.isNotEmpty) {
                                  await showSyncDialog(context);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ), // closes Align
              ],
            ),
          ],
        );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.card,
    required this.index,
    required this.pageController,
    required this.gap,
    required this.shadowColor,
    required this.onTap,
  });

  final CardModel card;
  final int index;
  final PageController pageController;
  final double gap;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, _) {
        var pageOffset = 0.0;
        if (pageController.hasClients &&
            pageController.position.haveDimensions) {
          pageOffset = (pageController.page ?? index.toDouble()) - index;
        }
        // Gaussian curve — peaks when the adjacent card is halfway into
        // view, creating the push-away parallax between cards.
        final gauss =
            math.exp(-(math.pow((pageOffset.abs() - 0.5), 2) / 0.08));

        return Transform.translate(
          offset: Offset(-32 * gauss * pageOffset.sign, 0),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gap / 2, 4, gap / 2, 16),
            child: GestureDetector(
              onTap: onTap,
              child: Hero(
                tag: card.heroTag,
                transitionOnUserGestures: true,
                createRectTween: LanguageCardHero.createRectTween,
                placeholderBuilder: LanguageCardHero.placeholderBuilder,
                flightShuttleBuilder:
                    (context, animation, direction, fromHero, toHero) {
                  return LanguageCardHero.flightShuttle(
                    animation: animation,
                    direction: direction,
                    imageName: card.image,
                    cacheWidth: LanguageCardHero.cacheWidthFor(context),
                  );
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          offset: const Offset(8, 20),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/cards/${card.image}',
                        fit: BoxFit.cover,
                        alignment: Alignment(
                          pageOffset.clamp(-1.0, 1.0) * -0.5,
                          0,
                        ),
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: LanguageCardHero.cacheWidthFor(context),
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Reusable nav item ─────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface)),
        ],
      ),
    );
  }
}

// ── Pulsing login nav item ────────────────────────────────────────────────────

class _LoginNavItem extends StatefulWidget {
  final VoidCallback onTap;
  const _LoginNavItem({required this.onTap});

  @override
  State<_LoginNavItem> createState() => _LoginNavItemState();
}

class _LoginNavItemState extends State<_LoginNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (_, child) => Transform.scale(
              scale: _scale.value,
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing outer ring
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primary
                            .withOpacity(0.3 * (1 - _controller.value)),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: cs.primary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onTap,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(Icons.login_rounded,
                          color: cs.onPrimary, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Login',
            style: TextStyle(
                fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
