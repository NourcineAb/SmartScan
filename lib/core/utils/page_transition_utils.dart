import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Custom page transitions using Material motion specifications
class PageTransitionUtils {
  /// Shared axis transition with horizontal axis (default)
  static PageRoute<T> sharedAxisTransition<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    required String routeName,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      settings: RouteSettings(name: routeName),
    );
  }

  /// Fade transition
  static PageRoute<T> fadeTransition<T>({
    required Widget Function(BuildContext) builder,
    required String routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      settings: RouteSettings(name: routeName),
    );
  }

  /// Slide up transition
  static PageRoute<T> slideUpTransition<T>({
    required Widget Function(BuildContext) builder,
    required String routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      settings: RouteSettings(name: routeName),
    );
  }

  /// Shared axis transition with vertical axis
  static PageRoute<T> verticalSharedAxisTransition<T>({
    required Widget Function(BuildContext) builder,
    required String routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      settings: RouteSettings(name: routeName),
    );
  }

  /// Shared axis transition with scaled axis
  static PageRoute<T> scaledSharedAxisTransition<T>({
    required Widget Function(BuildContext) builder,
    required String routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      settings: RouteSettings(name: routeName),
    );
  }
}

/// Extension on BuildContext for easier navigation
extension NavigationExtension on BuildContext {
  /// Navigate with horizontal shared axis transition
  Future<T?> navigateWithTransition<T>(
    Widget Function(BuildContext) builder,
    String routeName,
  ) {
    return Navigator.of(this).push<T>(
      PageTransitionUtils.sharedAxisTransition<T>(
        context: this,
        builder: builder,
        routeName: routeName,
      ),
    );
  }

  /// Navigate and replace with transition
  Future<T?> navigateAndReplaceWithTransition<T, TO>(
    Widget Function(BuildContext) builder,
    String routeName,
  ) {
    return Navigator.of(this).pushReplacement<T, TO>(
      PageTransitionUtils.sharedAxisTransition<T>(
        context: this,
        builder: builder,
        routeName: routeName,
      ),
    );
  }

  /// Navigate with fade transition
  Future<T?> navigateWithFadeTransition<T>(
    Widget Function(BuildContext) builder,
    String routeName,
  ) {
    return Navigator.of(this).push<T>(
      PageTransitionUtils.fadeTransition<T>(
        builder: builder,
        routeName: routeName,
      ),
    );
  }

  /// Navigate with slide up transition
  Future<T?> navigateWithSlideUpTransition<T>(
    Widget Function(BuildContext) builder,
    String routeName,
  ) {
    return Navigator.of(this).push<T>(
      PageTransitionUtils.slideUpTransition<T>(
        builder: builder,
        routeName: routeName,
      ),
    );
  }
}
