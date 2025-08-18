import 'package:flutter/material.dart';

/// Shared micro-animation for page/screen transitions: quick slide + subtle scale.
Widget snappyTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeOutCubic,
  );

  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(0.06, 0.0), end: Offset.zero).animate(curved),
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
      child: child,
    ),
  );
}

/// Convenience helper to build a PageRoute with the snappy transition.
PageRouteBuilder<T> snappyPageRoute<T>({
  required Widget page,
  Duration duration = const Duration(milliseconds: 400),
  Duration reverseDuration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: snappyTransition,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
  );
}

/// AnimatedSwitcher-friendly variant (no secondary animation available)
Widget snappySwitcherTransition(Animation<double> animation, Widget child) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeOutCubic,
  );

  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(0.05, 0.0), end: Offset.zero).animate(curved),
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.992, end: 1.0).animate(curved),
      child: child,
    ),
  );
}


