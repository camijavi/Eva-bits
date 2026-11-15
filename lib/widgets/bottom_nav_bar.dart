import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';
import '../languages/app_strings.dart';
import '../screens/dashboard_screen.dart';
import '../screens/lots_screen.dart';
import '../screens/predictions_screen.dart';
import '../screens/settings_screen.dart';

/// Available animation styles for bottom navigation transitions.
enum NavAnimationType {
  /// Standard instant tab switch used by common bottom navigation bars.
  standard,

  /// Subtle horizontal slide with smooth opacity cross-fade (legacy/custom).
  fadeSlide,

  /// Pure opacity cross-fade without horizontal motion (legacy/custom).
  fade,

  /// Subtle scale-up with opacity fade (legacy/custom).
  scaleFade,

  /// Gentle slide-up with opacity fade (legacy/custom).
  slideUp,
}

/// Creates a standard page route for bottom navigation bar switches without custom animations.
Route<T> createBottomNavPageRoute<T>(
  Widget page, {
  bool fromLeft = false,
  NavAnimationType animationType = NavAnimationType.standard,
  Duration duration = Duration.zero,
}) {
  if (animationType == NavAnimationType.standard) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  // Backwards-compatible support for legacy animation types if explicitly requested
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      switch (animationType) {
        case NavAnimationType.fade:
          return FadeTransition(
            opacity: curvedAnimation,
            child: child,
          );
        case NavAnimationType.scaleFade:
          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation),
              child: child,
            ),
          );
        case NavAnimationType.slideUp:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.06),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          );
        case NavAnimationType.fadeSlide:
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(fromLeft ? -0.05 : 0.05, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        case NavAnimationType.standard:
          return child;
      }
    },
  );
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final NavAnimationType animationType;

  const CustomBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.animationType = NavAnimationType.standard,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;

        return CupertinoTabBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (onTap != null) {
              onTap!(index);
              return;
            }
            if (index == currentIndex) return;

            if (index == 0) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  createBottomNavPageRoute(
                    const DashboardScreen(),
                    fromLeft: true,
                    animationType: animationType,
                  ),
                );
              }
            } else if (index == 1) {
              Navigator.of(context).push(
                createBottomNavPageRoute(
                  const LotsScreen(),
                  fromLeft: false,
                  animationType: animationType,
                ),
              );
            } else if (index == 2) {
              Navigator.of(context).push(
                createBottomNavPageRoute(
                  const PredictionsScreen(),
                  fromLeft: false,
                  animationType: animationType,
                ),
              );
            } else if (index == 4) {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            }
          },
          backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
          activeColor: AppColors.primary,
          inactiveColor: CupertinoColors.systemGrey,
          iconSize: 24,
          border: const Border(
            top: BorderSide(
              color: Color(0x33000000),
              width: 0.5,
            ),
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.house),
              activeIcon: const Icon(CupertinoIcons.house_fill),
              label: s.kNavHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.layers),
              activeIcon: const Icon(CupertinoIcons.layers_fill),
              label: s.kNavLots,
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.leaf_arrow_circlepath),
              label: s.kNavRotations,
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.person_2),
              activeIcon: const Icon(CupertinoIcons.person_2_fill),
              label: s.kNavCommunity,
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.ellipsis),
              label: s.kNavMore,
            ),
          ],
        );
      },
    );
  }
}
