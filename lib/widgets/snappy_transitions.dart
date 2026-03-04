import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modern Slide Transitions
//
// Push (forward):  new page slides in from right + fades in (0→1) + tiny
//                  scale-up (0.96→1.0).  300ms  easeOutCubic.
// Pop  (back):     page slides out to right + fades out.  280ms  easeInOutCubic.
//
// Scale & fade only touch the INCOMING page — the underlying page is never
// transformed, so no border-clipping or "app looks smaller" artifacts.
// ─────────────────────────────────────────────────────────────────────────────

Widget snappyTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInOutCubic,
  );

  return FadeTransition(
    // Fade: 0.0 → 1.0 on push, 1.0 → 0.0 on pop
    opacity: curved,
    child: SlideTransition(
      // Slide: enter from right, exit to right
      position: Tween<Offset>(
        begin: const Offset(0.12, 0.0),
        end: Offset.zero,
      ).animate(curved),
      child: ScaleTransition(
        // Subtle scale only on the incoming/outgoing page itself
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
        child: child,
      ),
    ),
  );
}

/// Convenience helper — smooth modern slide page route.
PageRouteBuilder<T> snappyPageRoute<T>({
  required Widget page,
  Duration duration = const Duration(milliseconds: 300),
  Duration reverseDuration = const Duration(milliseconds: 280),
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: snappyTransition,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
  );
}

/// AnimatedSwitcher helper — simple fade + tiny slide.
Widget snappySwitcherTransition(Animation<double> animation, Widget child) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.02, 0.0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// Route for modal/dialog-style pages — fades in from centre, no slide.
PageRouteBuilder<T> snappyFadeRoute<T>({required Widget page}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
