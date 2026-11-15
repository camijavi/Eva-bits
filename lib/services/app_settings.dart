import 'package:flutter/material.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';

enum AppSurfaceUnit {
  hectares,
  acres,
  manzanas,
  squareMeters,
  tareas,
}

enum AppTemperatureUnit {
  celsius,
  fahrenheit,
}

class AppSettings {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static final ValueNotifier<AppSurfaceUnit> surfaceUnit =
      ValueNotifier<AppSurfaceUnit>(AppSurfaceUnit.hectares);

  static final ValueNotifier<AppTemperatureUnit> temperatureUnit =
      ValueNotifier<AppTemperatureUnit>(AppTemperatureUnit.celsius);

  // Theme helpers
  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }

  // Language helpers
  static AppLanguageType get currentLanguage => AppLanguage.current.value;

  static void setLanguage(AppLanguageType lang) {
    AppLanguage.setLanguage(lang);
  }

  // Surface Unit helpers
  static Future<void> setSurfaceUnit(AppSurfaceUnit unit) async {
    surfaceUnit.value = unit;
    try {
      final unitStr = getSurfaceUnitShort(unit);
      await DatabaseManager().updateFarmSurfaceUnit(unitStr);
    } catch (_) {}
  }

  static AppSurfaceUnit parseSurfaceUnit(String? unitStr) {
    if (unitStr == null) return AppSurfaceUnit.hectares;
    final lower = unitStr.toLowerCase().trim();
    if (lower == 'ac' || lower == 'acres') return AppSurfaceUnit.acres;
    if (lower == 'mz' || lower == 'manzanas') return AppSurfaceUnit.manzanas;
    if (lower == 'm2' || lower == 'm²' || lower.contains('metro')) {
      return AppSurfaceUnit.squareMeters;
    }
    if (lower == 'tareas') return AppSurfaceUnit.tareas;
    return AppSurfaceUnit.hectares;
  }

  static Future<void> syncFromDatabase() async {
    try {
      final latestFarm = await DatabaseManager().getLatestFarm();
      if (latestFarm != null && latestFarm['surface_unit'] != null) {
        final parsed = parseSurfaceUnit(latestFarm['surface_unit'].toString());
        surfaceUnit.value = parsed;
      }
    } catch (_) {}
  }

  static String getSurfaceUnitShort([AppSurfaceUnit? unit]) {
    final target = unit ?? surfaceUnit.value;
    switch (target) {
      case AppSurfaceUnit.hectares:
        return 'ha';
      case AppSurfaceUnit.acres:
        return 'ac';
      case AppSurfaceUnit.manzanas:
        return 'mz';
      case AppSurfaceUnit.squareMeters:
        return 'm²';
      case AppSurfaceUnit.tareas:
        return 'tareas';
    }
  }

  static String getSurfaceUnitLabel(AppStrings s, [AppSurfaceUnit? unit]) {
    final target = unit ?? surfaceUnit.value;
    switch (target) {
      case AppSurfaceUnit.hectares:
        return s.kUnitHectares;
      case AppSurfaceUnit.acres:
        return s.kUnitAcres;
      case AppSurfaceUnit.manzanas:
        return s.kUnitManzanas;
      case AppSurfaceUnit.squareMeters:
        return s.kUnitSquareMeters;
      case AppSurfaceUnit.tareas:
        return s.kUnitTareas;
    }
  }

  // Temperature Unit helpers
  static void setTemperatureUnit(AppTemperatureUnit unit) {
    temperatureUnit.value = unit;
  }

  static String getTemperatureUnitShort([AppTemperatureUnit? unit]) {
    final target = unit ?? temperatureUnit.value;
    switch (target) {
      case AppTemperatureUnit.celsius:
        return '°C';
      case AppTemperatureUnit.fahrenheit:
        return '°F';
    }
  }

  static String getTemperatureUnitLabel(AppStrings s, [AppTemperatureUnit? unit]) {
    final target = unit ?? temperatureUnit.value;
    switch (target) {
      case AppTemperatureUnit.celsius:
        return s.kUnitCelsius;
      case AppTemperatureUnit.fahrenheit:
        return s.kUnitFahrenheit;
    }
  }

  /// Converts Celsius temperature to current chosen temperature unit
  static double convertTemperature(double celsius, [AppTemperatureUnit? unit]) {
    final target = unit ?? temperatureUnit.value;
    if (target == AppTemperatureUnit.fahrenheit) {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }
}
