import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'languages/app_strings.dart';
import 'screens/farm_info_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppLanguage.strings.kFarmInfoTitle,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
            useMaterial3: true,
          ),
          home: const FarmInfoScreen(),
        );
      },
    );
  }
}
