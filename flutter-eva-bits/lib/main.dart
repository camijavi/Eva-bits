import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart';
import 'languages/app_strings.dart';
import 'screens/welcome_screen.dart';
import 'services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
              title: 'Eva Bits',
              themeMode: currentThemeMode,
              theme: AppColors.lightTheme,
              darkTheme: AppColors.darkTheme,
              home: const WelcomeScreen(),
            );
          },
        );
      },
    );
  }
}
