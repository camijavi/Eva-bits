import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/app_settings.dart';
import 'farm_info.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String? farmName;
  final String? location;
  final String? surface;
  final String? crops;

  const DashboardScreen({
    super.key,
    this.farmName,
    this.location,
    this.surface,
    this.crops,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dbFarm;

  @override
  void initState() {
    super.initState();
    _loadLatestFarm();
  }

  Future<void> _loadLatestFarm() async {
    try {
      final farm = await DatabaseManager().getLatestFarm();
      if (mounted && farm != null) {
        setState(() {
          _dbFarm = farm;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;

        final displayLocation = widget.location ??
            (_dbFarm?['country']?.toString() ?? 'Estelí, Nicaragua');
        final displayFarmName = widget.farmName ??
            (_dbFarm?['name']?.toString() ?? s.kDashboardYourFarm);
        final displaySurface = widget.surface ??
            (_dbFarm != null
                ? '${_dbFarm!['total_surface']} ${_dbFarm!['surface_unit'] ?? 'ha'}'
                : '2.5 ha');

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF8),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, s),
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFarmSummaryCard(
                          context,
                          s,
                          displayLocation,
                          displayFarmName,
                          displaySurface,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          s.kDashboardWhatToDo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF223127),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildActionCard(
                          backgroundColor: const Color(0xFFEAF5EC),
                          iconBoxColor: const Color(0xFF2E7D32),
                          icon: Icons.eco,
                          iconColor: Colors.white,
                          title: s.kDashboardAction1,
                          chevronColor: const Color(0xFF4A7C59),
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          backgroundColor: const Color(0xFFEBF3FB),
                          iconBoxColor: const Color(0xFFD4E7F7),
                          icon: Icons.cloud_outlined,
                          iconColor: const Color(0xFF1976D2),
                          title: s.kDashboardAction2,
                          chevronColor: const Color(0xFF5B8FB9),
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          backgroundColor: const Color(0xFFFEF8E7),
                          iconBoxColor: const Color(0xFFFEEBC2),
                          icon: Icons.lightbulb_outline,
                          iconColor: const Color(0xFFF57F17),
                          title: s.kDashboardAction3,
                          chevronColor: const Color(0xFFBCA05A),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 54,
        bottom: 50,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F5A37),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.kDashboardGreeting,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.kDashboardSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: s.kSettingsTitle,
                onPressed: () {
                  Navigator.of(context).push(
                    createBottomNavPageRoute(
                      const SettingsScreen(),
                      fromLeft: false,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF0F5A37),
                    size: 24,
                  ),
                  onPressed: () {
                    // Mockup: No functionality
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmSummaryCard(
    BuildContext context,
    AppStrings s,
    String locationText,
    String farmNameText,
    String surfaceText,
  ) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A6572),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFFFFB300),
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<AppTemperatureUnit>(
                          valueListenable: AppSettings.temperatureUnit,
                          builder: (context, tempUnit, _) {
                            final tempVal = tempUnit == AppTemperatureUnit.celsius ? '28 °C' : '82 °F';
                            return Text(
                              tempVal,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            );
                          },
                        ),
                        Text(
                          s.kDashboardWeatherSummary,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.forest_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmNameText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2D24),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${s.kDashboardFarmSize}: $surfaceText',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.kDashboardCurrentCrops,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F6F2),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FarmInfoDetailScreen(),
                    ),
                  );
                  _loadLatestFarm();
                },
                child: Text(
                  s.kDashboardViewDetails,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required Color backgroundColor,
    required Color iconBoxColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color chevronColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Mockup: No functionality
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBoxColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2E1C),
                      height: 1.25,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: chevronColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
