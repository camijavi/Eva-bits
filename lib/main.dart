import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'languages/app_strings.dart';
import 'screens/new_farm_info_screen.dart';
import 'services/app_settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, currentThemeMode, _) {
        return ValueListenableBuilder<AppLanguageType>(
          valueListenable: AppLanguage.current,
          builder: (context, currentLang, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: AppLanguage.strings.kFarmInfoTitle,
              themeMode: currentThemeMode,
              theme: ThemeData(
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  primary: AppColors.primary,
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: const Color(0xFFF9FBF8),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  primary: AppColors.primary,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF121814),
                useMaterial3: true,
              ),
              home: const FarmInfoScreen(),
            );
          },
        );
      },
    );
  }
}
