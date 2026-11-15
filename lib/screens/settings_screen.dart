import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';
import 'dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    AppSettings.syncFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettings.themeMode,
          builder: (context, currentThemeMode, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark ? const Color(0xFF1E2822) : Colors.white;
            final borderColor = isDark ? const Color(0xFF2C3E33) : const Color(0xFFE5E7EB);
            final textColor = isDark ? Colors.white : const Color(0xFF1B2E1C);
            final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

            return Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context, s),
                      const SizedBox(height: 12),
                      _buildHeader(s, textColor, subtextColor),
                      const SizedBox(height: 24),

                      // 1. Language Section
                      _buildSectionTitle(
                        icon: Icons.language_rounded,
                        title: s.kLanguageSectionTitle,
                        subtitle: s.kLanguageSectionSubtitle,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageSelector(s, cardBg, borderColor, textColor),
                      const SizedBox(height: 24),

                      // 2. Theme Section (Light / Dark / System)
                      _buildSectionTitle(
                        icon: Icons.palette_outlined,
                        title: s.kThemeSectionTitle,
                        subtitle: s.kThemeSectionSubtitle,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      const SizedBox(height: 12),
                      _buildThemeSelector(s, currentThemeMode, cardBg, borderColor, textColor),
                      const SizedBox(height: 24),

                      // 3. Measurement Units (Same units shown on new_edit_plot.dart & temperature)
                      _buildSectionTitle(
                        icon: Icons.straighten_rounded,
                        title: s.kUnitsSectionTitle,
                        subtitle: s.kUnitsSectionSubtitle,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      const SizedBox(height: 12),
                      _buildUnitsSelector(s, cardBg, borderColor, textColor, subtextColor),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (_) => const DashboardScreen(),
                ),
              );
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2822) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF2C3E33) : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.chevron_back,
              color: Color(0xFF0F5A37),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppStrings s, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.kSettingsTitle,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F5A37),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.kSettingsSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF0F5A37), size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(
    AppStrings s,
    Color cardBg,
    Color borderColor,
    Color textColor,
  ) {
    final isSpanish = AppLanguage.isSpanish;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          _buildOptionTile(
            title: s.kSpanish,
            subtitle: 'ES',
            isSelected: isSpanish,
            onTap: () => AppSettings.setLanguage(AppLanguageType.spanish),
            textColor: textColor,
          ),
          Divider(height: 1, color: borderColor),
          _buildOptionTile(
            title: s.kEnglish,
            subtitle: 'EN',
            isSelected: !isSpanish,
            onTap: () => AppSettings.setLanguage(AppLanguageType.english),
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
    AppStrings s,
    ThemeMode currentThemeMode,
    Color cardBg,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _buildThemeOption(
              label: s.kThemeSystem,
              icon: Icons.brightness_auto_rounded,
              isSelected: currentThemeMode == ThemeMode.system,
              onTap: () => AppSettings.setThemeMode(ThemeMode.system),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildThemeOption(
              label: s.kThemeLight,
              icon: Icons.light_mode_rounded,
              isSelected: currentThemeMode == ThemeMode.light,
              onTap: () => AppSettings.setThemeMode(ThemeMode.light),
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildThemeOption(
              label: s.kThemeDark,
              icon: Icons.dark_mode_rounded,
              isSelected: currentThemeMode == ThemeMode.dark,
              onTap: () => AppSettings.setThemeMode(ThemeMode.dark),
              textColor: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF5EC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F5A37) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0F5A37) : Colors.grey.shade500,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F5A37) : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsSelector(
    AppStrings s,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Surface Area Unit (matching unit of measurement shown on new_edit_plot.dart)
          ValueListenableBuilder<AppSurfaceUnit>(
            valueListenable: AppSettings.surfaceUnit,
            builder: (context, currentUnit, _) {
              final activeUnitShort = AppSettings.getSurfaceUnitShort(currentUnit);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.square_foot_rounded, color: Color(0xFF0F5A37), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            s.kSurfaceUnitsTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      // Current unit badge as shown on new_edit_plot.dart
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          activeUnitShort,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F5A37),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${s.kLotSurfaceLabel} ($activeUnitShort)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPillOption(
                          label: s.kUnitHectares,
                          isSelected: currentUnit == AppSurfaceUnit.hectares,
                          onTap: () => AppSettings.setSurfaceUnit(AppSurfaceUnit.hectares),
                        ),
                        const SizedBox(width: 8),
                        _buildPillOption(
                          label: s.kUnitAcres,
                          isSelected: currentUnit == AppSurfaceUnit.acres,
                          onTap: () => AppSettings.setSurfaceUnit(AppSurfaceUnit.acres),
                        ),
                        const SizedBox(width: 8),
                        _buildPillOption(
                          label: s.kUnitManzanas,
                          isSelected: currentUnit == AppSurfaceUnit.manzanas,
                          onTap: () => AppSettings.setSurfaceUnit(AppSurfaceUnit.manzanas),
                        ),
                        const SizedBox(width: 8),
                        _buildPillOption(
                          label: s.kUnitSquareMeters,
                          isSelected: currentUnit == AppSurfaceUnit.squareMeters,
                          onTap: () => AppSettings.setSurfaceUnit(AppSurfaceUnit.squareMeters),
                        ),
                        const SizedBox(width: 8),
                        _buildPillOption(
                          label: s.kUnitTareas,
                          isSelected: currentUnit == AppSurfaceUnit.tareas,
                          onTap: () => AppSettings.setSurfaceUnit(AppSurfaceUnit.tareas),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 20),

          // Temperature Unit
          Row(
            children: [
              const Icon(Icons.thermostat_rounded, color: Color(0xFF0F5A37), size: 20),
              const SizedBox(width: 8),
              Text(
                s.kTemperatureUnitsTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<AppTemperatureUnit>(
            valueListenable: AppSettings.temperatureUnit,
            builder: (context, currentTempUnit, _) {
              return Row(
                children: [
                  Expanded(
                    child: _buildPillOption(
                      label: s.kUnitCelsius,
                      isSelected: currentTempUnit == AppTemperatureUnit.celsius,
                      onTap: () => AppSettings.setTemperatureUnit(AppTemperatureUnit.celsius),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPillOption(
                      label: s.kUnitFahrenheit,
                      isSelected: currentTempUnit == AppTemperatureUnit.fahrenheit,
                      onTap: () => AppSettings.setTemperatureUnit(AppTemperatureUnit.fahrenheit),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F5A37).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF4A5568),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F5A37),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
