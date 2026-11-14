import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../languages/app_strings.dart';
import '../screens/dashboard_screen.dart';
import '../screens/lots_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;

        return BottomNavigationBar(
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
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              }
            } else if (index == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LotsScreen()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: s.kNavHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.layers_outlined),
              activeIcon: const Icon(Icons.layers),
              label: s.kNavLots,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.eco_outlined),
              activeIcon: const Icon(Icons.eco),
              label: s.kNavRotations,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: s.kNavCommunity,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu),
              label: s.kNavMore,
            ),
          ],
        );
      },
    );
  }
}
