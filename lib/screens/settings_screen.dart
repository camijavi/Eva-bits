import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';
import '../widgets/eve_animated_avatar.dart';
import 'dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  EveEmote _previewEmote = EveEmote.greeting;

  @override
  void initState() {
    super.initState();
    AppSettings.syncFromDatabase();
    final isDark = AppSettings.themeMode.value == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
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

            final overlayStyle = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            );

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: Scaffold(
                backgroundColor: isDark ? const Color(0xFF121A15) : const Color(0xFFF8FAF8),
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
                      const SizedBox(height: 24),

                      // 4. Eve Virtual Assistant Visibility (Show Eve / Hide Eve) & Emote Preview
                      _buildSectionTitle(
                        icon: Icons.auto_awesome_rounded,
                        title: s.kEveVisibilitySectionTitle,
                        subtitle: s.kEveVisibilitySectionSubtitle,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      const SizedBox(height: 12),
                      _buildEveVisibilitySelector(s, cardBg, borderColor, textColor, subtextColor),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  Widget _buildEveVisibilitySelector(
    AppStrings s,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.showEve,
      builder: (context, isEveVisible, _) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptionTile(
                title: s.kShowEveOption,
                subtitle: s.kShowEveSubtitle,
                isSelected: isEveVisible,
                onTap: () => AppSettings.setShowEve(true),
                textColor: textColor,
              ),
              Divider(height: 1, color: borderColor),
              _buildOptionTile(
                title: s.kHideEveOption,
                subtitle: s.kHideEveSubtitle,
                isSelected: !isEveVisible,
                onTap: () => AppSettings.setShowEve(false),
                textColor: textColor,
              ),
              if (isEveVisible) ...[
                Divider(height: 1, color: borderColor),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2F23) : const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF2E4E39) : const Color(0xFFC8E6C9)),
                            ),
                            child: EveAnimatedAvatar(
                              emote: _previewEmote,
                              size: 74,
                              onTap: () {
                                final nextIdx = (_previewEmote.index + 1) %
                                    EveEmote.values.length;
                                setState(() {
                                  _previewEmote = EveEmote.values[nextIdx];
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.kEvePreviewEmoteLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                EveEmotePreviewSelector(
                                  selectedEmote: _previewEmote,
                                  s: s,
                                  onEmoteSelected: (emote) {
                                    setState(() => _previewEmote = emote);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
              color: isDark ? const Color(0xFF1E2B20) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF2E7D32) : const Color(0xFFA5D6A7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.chevron_back,
              color: isDark ? Colors.white : const Color(0xFF1B5E20),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppStrings s, Color textColor, Color subtextColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.kSettingsTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF81C784) : const Color(0xFF0F5A37),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3024) : const Color(0xFFEAF5EC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, color: isDark ? const Color(0xFF81C784) : const Color(0xFF0F5A37), size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3827) : const Color(0xFFEAF5EC))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF0F5A37))
                : (isDark ? const Color(0xFF2C3E33) : Colors.transparent),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? const Color(0xFF81C784) : const Color(0xFF0F5A37))
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
              size: 26,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? const Color(0xFF81C784) : const Color(0xFF0F5A37))
                      : textColor,
                ),
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
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final activeUnitShort = AppSettings.getSurfaceUnitShort(currentUnit);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.square_foot_rounded, color: isDark ? const Color(0xFF81C784) : const Color(0xFF0F5A37), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                s.kSurfaceUnitsTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Current unit badge as shown on new_edit_plot.dart
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3024) : const Color(0xFFEAF5EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF2E4E39) : const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          activeUnitShort,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF0F5A37),
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
              Icon(Icons.thermostat_rounded, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : const Color(0xFF0F5A37), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.kTemperatureUnitsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2E7D32) : const Color(0xFF0F5A37))
              : (isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF0F5A37))
                : (isDark ? const Color(0xFF2C3E33) : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF2E7D32) : const Color(0xFF0F5A37)).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : const Color(0xFF4A5568)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E7D32) : const Color(0xFF0F5A37),
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
                    border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, width: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
