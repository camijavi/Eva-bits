import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/eve_animated_avatar.dart';
import '../services/app_settings.dart';
import '../services/nasa_power_service.dart';
import '../services/agro_prediction_engine.dart';
import '../services/subplot_graph_service.dart';
import 'farm_info.dart';
import 'lots_screen.dart';
import 'predictions_screen.dart';
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
  Map<String, dynamic>? _nasaData;
  bool _isLoadingNasa = false;
  SubplotGraph? _farmGraph;
  List<Map<String, dynamic>> _farmSubplots = [];
  FarmPredictionsReport? _cachedReport;

  @override
  void initState() {
    super.initState();
    _loadLatestFarm();
  }

  Future<void> _loadLatestFarm() async {
    try {
      final farm = await DatabaseManager().getLatestFarm();
      if (mounted) {
        setState(() {
          _dbFarm = farm;
          _cachedReport = null;
        });
      }

      if (farm != null && farm['id'] != null) {
        final farmId = farm['id'] as int;
        try {
          final graph = await SubplotGraphService.getGraphForFarm(farmId);
          final lotsWithSubplots =
              await DatabaseManager().getAllLotsWithSubplots(farmId: farmId);
          final List<Map<String, dynamic>> flatSubplots = [];
          for (final lot in lotsWithSubplots) {
            final lotCrop = lot['crop']?.toString();
            final spList = lot['subplots'] as List<dynamic>? ?? [];
            if (spList.isEmpty && lotCrop != null && lotCrop.isNotEmpty) {
              flatSubplots.add({
                'name': lot['name'] ?? 'Lote',
                'crop': lotCrop,
                'soil_type': 'Franco',
              });
            }
            for (final sp in spList) {
              if (sp is Map<String, dynamic>) {
                final copy = Map<String, dynamic>.from(sp);
                if ((copy['crop'] == null ||
                        copy['crop'].toString().trim().isEmpty) &&
                    lotCrop != null &&
                    lotCrop.isNotEmpty) {
                  copy['crop'] = lotCrop;
                }
                flatSubplots.add(copy);
              }
            }
          }
          if (mounted) {
            setState(() {
              _farmGraph = graph;
              _farmSubplots = flatSubplots;
              _cachedReport = null;
            });
          }
        } catch (_) {}
      }
      _loadNasaData();
    } catch (_) {
      _loadNasaData();
    }
  }

  FarmPredictionsReport _getPredictionsReport() {
    if (_cachedReport != null) return _cachedReport!;
    final report = AgroPredictionEngine.generateReport(
      farmData: _dbFarm ?? {
        'name': widget.farmName ?? 'Mi Finca',
        'zone': widget.location ?? 'Nicaragua',
        'total_surface': 2.5,
        'unit': 'ha',
      },
      nasaData: _nasaData ?? NasaPowerService.getFallbackData(),
      graph: _farmGraph,
      subplots: _farmSubplots.isNotEmpty ? _farmSubplots : null,
    );
    _cachedReport = report;
    return report;
  }

  Future<void> _loadNasaData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNasa = true;
      _cachedReport = null;
    });

    try {
      double lat = 13.0910;
      double lon = -86.3538;

      if (_dbFarm != null) {
        if (_dbFarm!['latitude'] != null && _dbFarm!['longitude'] != null) {
          final pLat = (_dbFarm!['latitude'] as num).toDouble();
          final pLon = (_dbFarm!['longitude'] as num).toDouble();
          if (pLat != 0.0 || pLon != 0.0) {
            lat = pLat;
            lon = pLon;
          }
        } else {
          final zone = _dbFarm!['country']?.toString() ?? '';
          for (final entry in NasaPowerService.knownRegions.entries) {
            if (zone.toLowerCase().contains(entry.key.toLowerCase())) {
              lat = entry.value['lat']!;
              lon = entry.value['lon']!;
              break;
            }
          }
        }
      }

      final data = await NasaPowerService.fetchClimateData(
        latitude: lat,
        longitude: lon,
      );

      if (mounted) {
        setState(() {
          _nasaData = data;
          _isLoadingNasa = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingNasa = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;
        final isDark = AppColors.isDark(context);
        final textColor = AppColors.getTextPrimary(context);
        final scaffoldBg = AppColors.getBackground(context);

        final displayLocation = widget.location ??
            (_dbFarm?['country']?.toString() ?? 'Estelí, Nicaragua');
        final displayFarmName = widget.farmName ??
            (_dbFarm?['name']?.toString() ?? s.kDashboardYourFarm);
        final displaySurface = widget.surface ??
            (_dbFarm != null
                ? '${_dbFarm!['total_surface']} ${_dbFarm!['surface_unit'] ?? 'ha'}'
                : '2.5 ha');

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: RefreshIndicator(
            onRefresh: _loadLatestFarm,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, s, displayFarmName, displayLocation),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        _buildHeroWeatherCard(context, s),
                        const SizedBox(height: 12),
                        _buildEnvironmentalStatusBanner(context, s),
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C3E33)
                                  : const Color(0xFFDCDFD8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.kDashboardWhatToDo == '¿Qué quieres hacer hoy?'
                              ? 'Gestiona tu campo'
                              : 'Manage your fields',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildFieldsGrid(context, s, displaySurface),
                        const SizedBox(height: 24),
                        Text(
                          s.kDashboardWhatToDo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context: context,
                          backgroundColor: const Color(0xFFEAF5EC),
                          iconBoxColor: const Color(0xFF2E7D32),
                          icon: Icons.eco_rounded,
                          iconColor: Colors.white,
                          title: s.kDashboardAction1,
                          chevronColor: const Color(0xFF4A7C59),
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              createBottomNavPageRoute(
                                const PredictionsScreen(initialTab: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildActionCard(
                          context: context,
                          backgroundColor: const Color(0xFFEBF3FB),
                          iconBoxColor: const Color(0xFFD4E7F7),
                          icon: Icons.cloud_outlined,
                          iconColor: const Color(0xFF1976D2),
                          title: s.kDashboardAction2,
                          chevronColor: const Color(0xFF5B8FB9),
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              createBottomNavPageRoute(
                                const PredictionsScreen(initialTab: 0),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildActionCard(
                          context: context,
                          backgroundColor: const Color(0xFFFEF8E7),
                          iconBoxColor: const Color(0xFFFEEBC2),
                          icon: Icons.lightbulb_outline_rounded,
                          iconColor: const Color(0xFFF57F17),
                          title: s.kDashboardAction3,
                          chevronColor: const Color(0xFFBCA05A),
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              createBottomNavPageRoute(
                                const PredictionsScreen(initialTab: 5),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: EveFloatingLauncherButton(
            tooltip: s.kAskIvyTooltip,
            farmData: _dbFarm ??
                {
                  'name': widget.farmName ?? 'Mi Finca',
                  'zone': widget.location ?? 'Nicaragua',
                  'total_surface': 2.5,
                  'unit': 'ha',
                },
            nasaData: _nasaData ?? NasaPowerService.getFallbackData(),
            report: _getPredictionsReport(),
            graph: _farmGraph,
            subplots: _farmSubplots,
          ),
          bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppStrings s,
    String farmNameText,
    String locationText,
  ) {
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextMuted(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 18,
          right: 18,
          top: 10,
          bottom: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C1E20)
                    : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF5C2B2F)
                      : const Color(0xFFFFCDD2),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFE53935),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    farmNameText,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationText,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: textColor,
                size: 24,
              ),
              tooltip: s.kSettingsTitle,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            CircleAvatar(
              radius: 19,
              backgroundColor: isDark
                  ? const Color(0xFF1E2822)
                  : const Color(0xFFE8F5E9),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: isDark
                      ? AppColors.primaryLight
                      : const Color(0xFF2E7D32),
                  size: 22,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const FarmInfoDetailScreen(),
                    ),
                  );
                  _loadLatestFarm();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroWeatherCard(BuildContext context, AppStrings s) {
    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;
    final isLive = _nasaData?['source']?.toString().contains('Live') == true;

    final moistureLabel = soilMoisture < 0.40
        ? 'Baja'
        : (soilMoisture > 0.75 ? 'Alta' : 'Óptima');
    final rainLabel = rainMm < 1.0
        ? 'Baja'
        : (rainMm > 15.0 ? 'Alta' : '${rainMm.toStringAsFixed(1)} mm');

    return Container(
      width: double.infinity,
      height: 185,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFEDBA8),
            Color(0xFFFDC27D),
            Color(0xFFF9A84D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF9A84D).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WeatherCardLandscapePainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<AppTemperatureUnit>(
                            valueListenable: AppSettings.temperatureUnit,
                            builder: (context, tempUnit, _) {
                              final isC =
                                  tempUnit == AppTemperatureUnit.celsius;
                              final tVal = isC
                                  ? '${tempC.toStringAsFixed(1)}°C'
                                  : '${((tempC * 9 / 5) + 32).toStringAsFixed(1)}°F';
                              return Text(
                                tVal,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E1C0C),
                                  letterSpacing: -0.5,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _isLoadingNasa
                                    ? 'Sincronizando...'
                                    : (isLive
                                        ? 'NASA Live'
                                        : 'Parcialmente soleado'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4E342E)
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _isLoadingNasa ? null : _loadNasaData,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: const Color(0xFF4E342E)
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildSunCloudGraphic(),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWeatherPill(
                          label: 'Humedad',
                          value: '${(soilMoisture * 100).toInt()}%',
                          valueColor: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWeatherPill(
                          label: 'Humedad Radicular',
                          value: moistureLabel,
                          valueColor: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWeatherPill(
                          label: 'Precipitación',
                          value: rainLabel,
                          valueColor: const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherPill({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3E2723).withValues(alpha: 0.85),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSunCloudGraphic() {
    return SizedBox(
      width: 86,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 2,
            right: 22,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFEE58), Color(0xFFFFA000)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_rounded,
                    color: Color(0xFFECEFF1),
                    size: 22,
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFFFFB300),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalStatusBanner(BuildContext context, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final Color statusBg;
    final Color statusColor;
    final IconData statusIcon;
    final String statusTitle;
    final String statusMsg;

    if (soilMoisture < 0.40) {
      statusBg = isDark ? const Color(0xFF2E2014) : const Color(0xFFFFF3E0);
      statusColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'Déficit hídrico detectado';
      statusMsg =
          'Humedad radicular baja (${(soilMoisture * 100).toInt()}%). Planificar riego o cultivos tolerantes a sequía.';
    } else if (soilMoisture > 0.75) {
      statusBg = isDark ? const Color(0xFF14222E) : const Color(0xFFE3F2FD);
      statusColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
      statusIcon = Icons.water_drop_outlined;
      statusTitle = 'Saturación hídrica alta';
      statusMsg =
          'Humedad radicular en ${(soilMoisture * 100).toInt()}%. Monitorear drenaje en zonas bajas.';
    } else {
      statusBg = isDark ? const Color(0xFF18261D) : const Color(0xFFE8F5E9);
      statusColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_outline_rounded;
      statusTitle = 'Condiciones agroclimáticas óptimas';
      statusMsg =
          'Humedad radicular equilibrada (${(soilMoisture * 100).toInt()}%) y radiación favorable.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusMsg,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsGrid(
    BuildContext context,
    AppStrings s,
    String surfaceText,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _buildGridCard(
          context: context,
          title: s.kDashboardYourFarm,
          subtitle: surfaceText,
          icon: Icons.landscape_rounded,
          iconColor: const Color(0xFF2E7D32),
          iconBgColor: const Color(0xFFE8F5E9),
          onTap: () async {
            await Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => const FarmInfoDetailScreen(),
              ),
            );
            _loadLatestFarm();
          },
        ),
        _buildGridCard(
          context: context,
          title: 'Cultivos',
          subtitle: 'Lotes y Parcelas',
          icon: Icons.spa_rounded,
          iconColor: const Color(0xFF00796B),
          iconBgColor: const Color(0xFFE0F2F1),
          onTap: () {
            Navigator.of(context).pushReplacement(
              createBottomNavPageRoute(const LotsScreen()),
            );
          },
        ),
        _buildGridCard(
          context: context,
          title: 'Predicciones',
          subtitle: 'Fenología & Rotación',
          icon: Icons.assignment_turned_in_rounded,
          iconColor: const Color(0xFFE65100),
          iconBgColor: const Color(0xFFFFF3E0),
          onTap: () {
            Navigator.of(context).pushReplacement(
              createBottomNavPageRoute(
                const PredictionsScreen(initialTab: 1),
              ),
            );
          },
        ),
        _buildGridCard(
          context: context,
          title: 'Balance',
          subtitle: 'Riego y Nutrición',
          icon: Icons.monetization_on_rounded,
          iconColor: const Color(0xFFF57F17),
          iconBgColor: const Color(0xFFFFF8E1),
          onTap: () {
            Navigator.of(context).pushReplacement(
              createBottomNavPageRoute(
                const PredictionsScreen(initialTab: 0),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.getCardBg(context);
    final borderColor = AppColors.getBorder(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextMuted(context);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(22),
      elevation: isDark ? 2 : 1.5,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? iconBgColor.withValues(alpha: 0.22)
                      : iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isDark ? AppColors.primaryLight : iconColor,
                    size: 26,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required Color backgroundColor,
    required Color iconBoxColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color chevronColor,
    VoidCallback? onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final cardColor = isDark ? const Color(0xFF1E2822) : backgroundColor;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF1B2E1C);
    final borderCol = isDark ? AppColors.borderDark : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: borderCol) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? iconBoxColor.withValues(alpha: 0.25)
                        : iconBoxColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isDark ? AppColors.primaryLight : iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.25,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.primaryLight : chevronColor,
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

class _WeatherCardLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backHillPaint = Paint()
      ..color = const Color(0xFF43A047).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final backHillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.72,
        size.width * 0.80,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.92,
        size.width,
        size.height * 0.94,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(backHillPath, backHillPaint);

    final frontHillPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final frontHillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.96,
        size.width * 0.62,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.76,
        size.width,
        size.height * 0.82,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(frontHillPath, frontHillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
