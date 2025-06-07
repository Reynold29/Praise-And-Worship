import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:worshipcompanion/widgets/theme_provider.dart';
import 'package:worshipcompanion/screens/settings_page.dart';
import 'card_model.dart';
import 'package:vibration/vibration.dart';
import 'package:worshipcompanion/screens/song_list_screen.dart';
import 'package:worshipcompanion/screens/add_song_options_screen.dart';
import 'package:worshipcompanion/screens/about_developer.dart';
import 'package:worshipcompanion/screens/kannada_song_list_screen.dart';
import 'package:worshipcompanion/screens/home_page.dart';

class SlidingCardsView extends StatefulWidget {
  final VoidCallback? onFavoriteToggled;
  const SlidingCardsView({super.key, this.onFavoriteToggled});

  @override
  State<SlidingCardsView> createState() => _SlidingCardsViewState();
}

class _SlidingCardsViewState extends State<SlidingCardsView> {
  late PageController pageController;
  int _currentPage = 0;

  bool _isLeftArrowTapped = false;
  bool _isRightArrowTapped = false;

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
        setState(() {
          _currentPage = currentPage;
        });

        final bool? hasCustomSupport = await Vibration.hasCustomVibrationsSupport();
        if (hasCustomSupport == true) {
          Vibration.vibrate(
            duration: 6,
            amplitude: 30,
          );
        } else {
          Vibration.vibrate(duration: 6);
        }
      }
    } catch (e) {
      print('Vibration error: $e');
    }
  }

  void _onArrowTap(bool isNext) {
    int nextPage = isNext ? _currentPage + 1 : _currentPage - 1;

    if (nextPage >= 0 && nextPage < demoCardData.length) {
      pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onArrowTapDown(bool isNext) {
    setState(() {
      if (isNext) {
        _isRightArrowTapped = true;
      } else {
        _isLeftArrowTapped = true;
      }
    });
  }

  void _onArrowTapUp(bool isNext) {
    setState(() {
      if (isNext) {
        _isRightArrowTapped = false;
      } else {
        _isLeftArrowTapped = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: PageView.builder(
                clipBehavior: Clip.none,
                controller: pageController,
                itemCount: demoCardData.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: pageController,
                    builder: (context, child) {
                      double pageOffset = 0;
                      if (pageController.position.haveDimensions) {
                        pageOffset = pageController.page! - index;
                      }
                      double gauss = math.exp(
                          -(math.pow((pageOffset.abs() - 0.5), 2) / 0.08));
                      bool isCreatePlaylistCard = demoCardData[index].icon != null;

                      return Transform.translate(
                        offset: Offset(
                            -32 * gauss * pageOffset.sign - (isCreatePlaylistCard ? 40 : 60), 0),
                        child: GestureDetector(
                          onTap: () async {
                            final card = demoCardData[index];
                            if (card.onTap != null) {
                              card.onTap!();
                            } else if (card.name == "Kannada Songs") {
                              print('Card tapped: Kannada Songs, navigating to KannadaSongListScreen');
                              await Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => KannadaSongListScreen(heroTag: card.heroTag, cardImage: card.image, onFavoriteToggled: widget.onFavoriteToggled),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 450),
                                  reverseTransitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            } else {
                              print('Card tapped: English Songs, navigating to SongListScreen');
                              await Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => SongListScreen(heroTag: card.heroTag, cardImage: card.image, onFavoriteToggled: widget.onFavoriteToggled),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 450),
                                  reverseTransitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            }
                          },
                          child: Hero(
                            tag: demoCardData[index].heroTag,
                            child: Container(
                              margin: const EdgeInsets.only(
                                  left: 10, right: 10, bottom: 14),
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
                                  alignment: Alignment(-pageOffset.abs(), 0),
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
            const SizedBox(height: 8),
            Row(
              children: [
                if (_currentPage > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton.filledTonal(
                      onPressed: () async {
                        final bool? hasVibration = await Vibration.hasVibrator();
                        if (hasVibration == true) {
                          Vibration.vibrate(duration: 18, amplitude: 60);
                        }
                        _onArrowTap(false);
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onPrimaryContainer),
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
                      onPressed: () async {
                        final bool? hasVibration = await Vibration.hasVibrator();
                        if (hasVibration == true) {
                          Vibration.vibrate(duration: 18, amplitude: 60);
                        }
                        _onArrowTap(true);
                      },
                      icon: Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onPrimaryContainer),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    "More Options",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: colorScheme.primaryContainer,
                            child: IconButton(
                              icon: Icon(Icons.favorite, color: colorScheme.onPrimaryContainer),
                              onPressed: () async {
                                final bool? hasVibration = await Vibration.hasVibrator();
                                if (hasVibration == true) {
                                  Vibration.vibrate(duration: 18, amplitude: 60);
                                }
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const FavoritesScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 450),
                                    reverseTransitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Favorites',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: colorScheme.primaryContainer,
                            child: IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, color: colorScheme.onPrimaryContainer),
                              onPressed: () async {
                                final bool? hasVibration = await Vibration.hasVibrator();
                                if (hasVibration == true) {
                                  Vibration.vibrate(duration: 18, amplitude: 60);
                                }
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const AddSongOptionsScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 450),
                                    reverseTransitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Add Song',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: colorScheme.primaryContainer,
                            child: IconButton(
                              icon: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
                              onPressed: () async {
                                final bool? hasVibration = await Vibration.hasVibrator();
                                if (hasVibration == true) {
                                  Vibration.vibrate(duration: 18, amplitude: 60);
                                }
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 450),
                                    reverseTransitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Settings',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: colorScheme.primaryContainer,
                            child: IconButton(
                              icon: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
                              onPressed: () async {
                                final bool? hasVibration = await Vibration.hasVibrator();
                                if (hasVibration == true) {
                                  Vibration.vibrate(duration: 18, amplitude: 60);
                                }
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const AboutDeveloper(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 450),
                                    reverseTransitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'About Dev',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
