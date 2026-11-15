import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (Agroecological Greens & Earth tones)
  static const Color primary = Color(0xFF2E7D32); // Forest Green
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent = Color(0xFF558B2F);
  static const Color accentDark = Color(0xFF81C784);
  static const Color secondary = Color(0xFF8D6E63); // Earth / Soil Brown
  static const Color warning = Color(0xFFE65100);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1976D2);

  // Light Palette
  static const Color backgroundLight = Color(0xFFF9FBF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBgLight = Color(0xFFFFFFFF);
  static const Color lotCardBgLight = Color(0xFFF1F8E9);
  static const Color subplotCardBgLight = Color(0xFFFFFFFF);
  static const Color treeLineLight = Color(0xFF81C784);
  static const Color textPrimaryLight = Color(0xFF1B2E1C);
  static const Color textSecondaryLight = Color(0xFF4A6572);
  static const Color textMutedLight = Color(0xFF757575);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color headerBgLight = Color(0xFF0F5A37);
  static const Color inputBgLight = Color(0xFFF9FBF8);
  static const Color chipBgLight = Color(0xFFF1F5F2);
  static const Color chipBorderLight = Color(0xFFE2E8F0);
  static const Color badgeBgLight = Color(0xFFE8F5E9);
  static const Color modalBgLight = Color(0xFFFFFFFF);
  static const Color navBarBgLight = Color(0xFFFFFFFF);

  // Dark Palette (Agro-Slate deep dark, comfortable for OLED/LCD)
  static const Color backgroundDark = Color(0xFF121814); // Deep agro dark
  static const Color surfaceDark = Color(0xFF1A231D); // Elevated surface
  static const Color cardBgDark = Color(0xFF1E2822); // Card surface
  static const Color lotCardBgDark = Color(0xFF18231C); // Lot card dark
  static const Color subplotCardBgDark = Color(0xFF1E2822);
  static const Color treeLineDark = Color(0xFF388E3C);
  static const Color textPrimaryDark = Color(0xFFF1F5F2);
  static const Color textSecondaryDark = Color(0xFFA5D6A7);
  static const Color textMutedDark = Color(0xFF9E9E9E);
  static const Color borderDark = Color(0xFF2C3E33);
  static const Color dividerDark = Color(0xFF25332A);
  static const Color headerBgDark = Color(0xFF152219);
  static const Color inputBgDark = Color(0xFF18221B);
  static const Color chipBgDark = Color(0xFF202E25);
  static const Color chipBorderDark = Color(0xFF2E4235);
  static const Color badgeBgDark = Color(0xFF1E3024);
  static const Color modalBgDark = Color(0xFF1A261F);
  static const Color navBarBgDark = Color(0xFF141C16);

  // Backward-compatible static constants for legacy calls
  static const Color background = backgroundLight;
  static const Color cardBg = cardBgLight;
  static const Color lotCardBg = lotCardBgLight;
  static const Color subplotCardBg = subplotCardBgLight;
  static const Color treeLine = treeLineLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textMuted = textMutedLight;

  // Dynamic context-aware helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackground(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color getSurface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color getCardBg(BuildContext context) =>
      isDark(context) ? cardBgDark : cardBgLight;

  static Color getLotCardBg(BuildContext context) =>
      isDark(context) ? lotCardBgDark : lotCardBgLight;

  static Color getSubplotCardBg(BuildContext context) =>
      isDark(context) ? subplotCardBgDark : subplotCardBgLight;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? textMutedDark : textMutedLight;

  static Color getBorder(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color getDivider(BuildContext context) =>
      isDark(context) ? dividerDark : dividerLight;

  static Color getHeaderBg(BuildContext context) =>
      isDark(context) ? headerBgDark : headerBgLight;

  static Color getInputBg(BuildContext context) =>
      isDark(context) ? inputBgDark : inputBgLight;

  static Color getModalBg(BuildContext context) =>
      isDark(context) ? modalBgDark : modalBgLight;

  static Color getNavBarBg(BuildContext context) =>
      isDark(context) ? navBarBgDark : navBarBgLight;

  static Color getBadgeBg(BuildContext context) =>
      isDark(context) ? badgeBgDark : badgeBgLight;

  static Color getChipBg(BuildContext context, {bool isSelected = false}) {
    if (isSelected) {
      return isDark(context) ? primary : const Color(0xFF0F5A37);
    }
    return isDark(context) ? chipBgDark : chipBgLight;
  }

  static Color getChipBorder(BuildContext context, {bool isSelected = false}) {
    if (isSelected) {
      return isDark(context) ? primaryLight : const Color(0xFF0F5A37);
    }
    return isDark(context) ? chipBorderDark : chipBorderLight;
  }

  static Color getIconContainerBg(BuildContext context, Color baseColor) {
    return isDark(context) ? baseColor.withValues(alpha: 0.22) : baseColor;
  }

  // Complete Material 3 Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardBgLight,
      dividerColor: dividerLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surfaceLight,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBgLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBgLight,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        modalBackgroundColor: surfaceLight,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
      ),
      useMaterial3: true,
    );
  }

  // Complete Material 3 Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: backgroundDark,
      canvasColor: backgroundDark,
      cardColor: cardBgDark,
      dividerColor: dividerDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primaryLight,
        secondary: accent,
        surface: surfaceDark,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBgDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBgDark,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardBgDark,
        modalBackgroundColor: cardBgDark,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navBarBgDark,
        selectedItemColor: primaryLight,
        unselectedItemColor: Colors.white60,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBgDark,
        hintStyle: const TextStyle(color: textMutedDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: primaryLight, width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }
}
