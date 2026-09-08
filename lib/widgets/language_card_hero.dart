import 'package:material_ui/material_ui.dart';

/// Shared Hero settings for home language cards ↔ language list headers.
class LanguageCardHero {
  static const double viewportFraction = 0.80;

  static int cacheWidthFor(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width * viewportFraction;
    return (width * dpr).round().clamp(480, 1400);
  }

  static RectTween createRectTween(Rect? begin, Rect? end) {
    return MaterialRectArcTween(begin: begin, end: end);
  }

  static Widget placeholderBuilder(
    BuildContext context,
    Size heroSize,
    Widget child,
  ) {
    return child;
  }

  static Widget flightShuttle({
    required Animation<double> animation,
    required HeroFlightDirection direction,
    required String imageName,
    required int cacheWidth,
  }) {
    const fromRadius = BorderRadius.all(Radius.circular(32));
    const toRadius = BorderRadius.vertical(bottom: Radius.circular(32));
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.fastOutSlowIn.transform(animation.value);
        final radius = BorderRadius.lerp(
              direction == HeroFlightDirection.push ? fromRadius : toRadius,
              direction == HeroFlightDirection.push ? toRadius : fromRadius,
              t,
            ) ??
            fromRadius;
        return ClipRRect(
          borderRadius: radius,
          child: Image.asset(
            'assets/cards/$imageName',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        );
      },
    );
  }
}
