import 'package:worshipcompanion/utils/app_logger.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
import 'package:worshipcompanion/widgets/snappy_transitions.dart';
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
  late PageController pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController(viewportFraction: 0.75);
    pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    pageController.removeListener(_onPageChanged);
    pageController.dispose();
    super.dispose();
  }

  int _lastPage = 0;

  void _onPageChanged() async {
    final page = pageController.page ?? 0.0;
    try {
      final int currentPage = page.round();
      if (_lastPage != currentPage) {
        _lastPage = currentPage;
        setState(() => _currentPage = currentPage);
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      AppLogger.d('App', 'Vibration error: $e');
    }
  }

  void _onArrowTap(bool isNext) {
    int nextPage = isNext ? _currentPage + 1 : _currentPage - 1;
    if (nextPage >= 0 && nextPage < demoCardData.length) {
      pageController.animateToPage(nextPage,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _vibrate() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            // ── Sliding cards ─────────────────────────────────────────────
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: PageView.builder(
                clipBehavior: Clip.none,
                controller: pageController,
                itemCount: demoCardData.length,
                padEnds: false,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: pageController,
                    builder: (context, child) {
                      double pageOffset = 0;
                      if (pageController.position.haveDimensions) {
                        pageOffset = pageController.page! - index;
                      }
                      // Gaussian curve — peaks when adjacent card is halfway
                      // into view, creating the sweet 'push-away' parallax.
                      final double gauss = math
                          .exp(-(math.pow((pageOffset.abs() - 0.5), 2) / 0.08));

                      return Transform.translate(
                        // Only the gauss part (no constant offset) so cards
                        // stay evenly spaced in the viewport.
                        offset: Offset(-32 * gauss * pageOffset.sign, 0),
                        child: GestureDetector(
                          onTap: () async {
                            final card = demoCardData[index];
                            if (card.onTap != null) {
                              card.onTap!();
                            } else if (card.name == "Kannada Songs") {
                              await Navigator.of(context).push(
                                snappyFadeRoute(
                                  page: KannadaSongListScreen(
                                      heroTag: card.heroTag,
                                      cardImage: card.image,
                                      onFavoriteToggled:
                                          widget.onFavoriteToggled),
                                ),
                              );
                            } else if (card.name == "Other Languages") {
                              await Navigator.of(context).push(
                                snappyFadeRoute(
                                  page: OtherSongListScreen(
                                      heroTag: card.heroTag,
                                      cardImage: card.image),
                                ),
                              );
                            } else {
                              await Navigator.of(context).push(
                                snappyFadeRoute(
                                  page: SongListScreen(
                                      heroTag: card.heroTag,
                                      cardImage: card.image,
                                      onFavoriteToggled:
                                          widget.onFavoriteToggled),
                                ),
                              );
                            }
                          },
                          child: Hero(
                            tag: demoCardData[index].heroTag,
                            child: Container(
                              margin: const EdgeInsets.only(
                                  left: 6, right: 6, bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.1),
                                    offset: const Offset(8, 20),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  'assets/cards/${demoCardData[index].image}',
                                  alignment: Alignment(
                                      pageOffset.clamp(-1.0, 1.0) * -0.5, 0),
                                  fit: BoxFit.cover,
                                ),
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

            // ── Page indicator + arrows ───────────────────────────────────
            const SizedBox(height: 8),
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
                          color: colorScheme.onPrimaryContainer),
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: colorScheme.primaryContainer,
                        fixedSize: const Size(48, 48),
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
                        dotWidth: 20,
                        dotHeight: 5,
                        spacing: 8,
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
                          color: colorScheme.onPrimaryContainer),
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: colorScheme.primaryContainer,
                        fixedSize: const Size(48, 48),
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    'More Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
                width: 50,
                height: 50,
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    width: 58,
                    height: 58,
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
                      width: 50,
                      height: 50,
                      child: Icon(Icons.login_rounded,
                          color: cs.onPrimary, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Login',
            style: TextStyle(
                fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
