import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../languages/app_strings.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (_) {
            // Mockup: No button must have functionality as requested
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
              icon: const Icon(Icons.home),
              label: s.kNavHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.eco_outlined),
              label: s.kNavRotations,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
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
