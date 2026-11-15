import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/screens/dashboard_screen.dart';
import 'package:flutter_eva_bits/screens/farm_info.dart';
import 'package:flutter_eva_bits/screens/settings_screen.dart';
import 'package:flutter_eva_bits/services/app_settings.dart';
import 'package:flutter_eva_bits/languages/app_strings.dart';

void main() {
  setUp(() {
    AppSettings.setLanguage(AppLanguageType.spanish);
    AppSettings.setThemeMode(ThemeMode.system);
    AppSettings.setSurfaceUnit(AppSurfaceUnit.hectares);
    AppSettings.setTemperatureUnit(AppTemperatureUnit.celsius);
  });

  testWidgets('SettingsScreen renders sections and options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // 1. Header
    expect(find.text(s.kSettingsTitle), findsOneWidget);
    expect(find.text(s.kSettingsSubtitle), findsOneWidget);

    // 2. Language section
    expect(find.text(s.kLanguageSectionTitle), findsOneWidget);
    expect(find.text(s.kSpanish), findsOneWidget);
    expect(find.text(s.kEnglish), findsOneWidget);

    // 3. Theme section
    expect(find.text(s.kThemeSectionTitle), findsOneWidget);
    expect(find.text(s.kThemeSystem), findsOneWidget);
    expect(find.text(s.kThemeLight), findsOneWidget);
    expect(find.text(s.kThemeDark), findsOneWidget);

    // 4. Units section
    expect(find.text(s.kUnitsSectionTitle), findsOneWidget);
    expect(find.text(s.kSurfaceUnitsTitle), findsOneWidget);
    expect(find.text(s.kUnitHectares), findsOneWidget);
    expect(find.text(s.kUnitAcres), findsOneWidget);
    expect(find.text(s.kUnitManzanas), findsOneWidget);

    expect(find.text(s.kTemperatureUnitsTitle), findsOneWidget);
    expect(find.text(s.kUnitCelsius), findsOneWidget);
    expect(find.text(s.kUnitFahrenheit), findsOneWidget);
  });

  testWidgets('SettingsScreen changes language when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(AppLanguage.isSpanish, isTrue);

    // Tap English option
    await tester.tap(find.text('Inglés'));
    await tester.pumpAndSettle();

    expect(AppLanguage.isSpanish, isFalse);

    // Tap Spanish option
    await tester.tap(find.text('Spanish'));
    await tester.pumpAndSettle();

    expect(AppLanguage.isSpanish, isTrue);
  });

  testWidgets('SettingsScreen changes theme mode when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // Tap Dark theme
    await tester.tap(find.text(s.kThemeDark));
    await tester.pumpAndSettle();
    expect(AppSettings.themeMode.value, ThemeMode.dark);

    // Tap Light theme
    await tester.tap(find.text(s.kThemeLight));
    await tester.pumpAndSettle();
    expect(AppSettings.themeMode.value, ThemeMode.light);

    // Tap System theme
    await tester.tap(find.text(s.kThemeSystem));
    await tester.pumpAndSettle();
    expect(AppSettings.themeMode.value, ThemeMode.system);
  });

  testWidgets('SettingsScreen changes surface unit when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // Ensure visible then tap Acres
    await tester.ensureVisible(find.text(s.kUnitAcres));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.kUnitAcres));
    await tester.pumpAndSettle();
    expect(AppSettings.surfaceUnit.value, AppSurfaceUnit.acres);
    expect(AppSettings.getSurfaceUnitShort(), 'ac');

    // Ensure visible then tap Manzanas
    await tester.ensureVisible(find.text(s.kUnitManzanas));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.kUnitManzanas));
    await tester.pumpAndSettle();
    expect(AppSettings.surfaceUnit.value, AppSurfaceUnit.manzanas);
    expect(AppSettings.getSurfaceUnitShort(), 'mz');

    // Ensure visible then tap Hectares
    await tester.ensureVisible(find.text(s.kUnitHectares));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.kUnitHectares));
    await tester.pumpAndSettle();
    expect(AppSettings.surfaceUnit.value, AppSurfaceUnit.hectares);
    expect(AppSettings.getSurfaceUnitShort(), 'ha');
  });

  testWidgets('SettingsScreen changes temperature unit when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // Ensure visible then tap Fahrenheit
    await tester.ensureVisible(find.text(s.kUnitFahrenheit));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.kUnitFahrenheit));
    await tester.pumpAndSettle();
    expect(AppSettings.temperatureUnit.value, AppTemperatureUnit.fahrenheit);
    expect(AppSettings.getTemperatureUnitShort(), '°F');

    // Ensure visible then tap Celsius
    await tester.ensureVisible(find.text(s.kUnitCelsius));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.kUnitCelsius));
    await tester.pumpAndSettle();
    expect(AppSettings.temperatureUnit.value, AppTemperatureUnit.celsius);
    expect(AppSettings.getTemperatureUnitShort(), '°C');
  });

  testWidgets('Dashboard settings icon navigates to SettingsScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('CustomBottomNavBar index 4 ("Más") navigates to SettingsScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    expect(find.text(s.kNavMore), findsOneWidget);

    await tester.tap(find.text(s.kNavMore));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Language switcher is removed from FarmInfoDetailScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FarmInfoDetailScreen(),
      ),
    );

    await tester.pump();

    // Verify language switcher button ('ES' / 'EN') is NOT in FarmInfoDetailScreen
    expect(find.text('ES'), findsNothing);
    expect(find.text('EN'), findsNothing);
  });
}
