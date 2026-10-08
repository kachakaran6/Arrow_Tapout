import 'package:arrowtapout/design/primitives.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds a custom fade-through transition page.
///
/// Outgoing fades out over the first 35% of travel, while incoming fades in
/// and rises 12dp with [Primitives.curveEnter].
CustomTransitionPage<T> buildFadeThroughPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  Duration duration = Primitives.durationPage,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 1.0, curve: Primitives.curveEnter),
      );

      final slideIn = Tween<Offset>(
        begin: const Offset(0.0, 12.0 / 600.0), // 12dp relative rise
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1.0, curve: Primitives.curveEnter),
        ),
      );

      final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.35, curve: Curves.linear),
        ),
      );

      return FadeTransition(
        opacity: fadeOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        ),
      );
    },
  );
}

/// Shorter 220ms fade transition for the game screen where the board draws itself in.
CustomTransitionPage<T> buildGamePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Primitives.curveEnter,
        ),
        child: child,
      );
    },
  );
}
