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
          body: RefreshIndicator(
            onRefresh: _loadLatestFarm,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                          const SizedBox(height: 16),
                          _buildNasaEnvironmentalCard(context, s),
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
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              createBottomNavPageRoute(
                                const PredictionsScreen(initialTab: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
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
                        const SizedBox(height: 12),
                        _buildActionCard(
                          backgroundColor: const Color(0xFFFEF8E7),
                          iconBoxColor: const Color(0xFFFEEBC2),
                          icon: Icons.lightbulb_outline,
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
                        const SizedBox(height: 16),
                      ],
                    ),
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
                    CupertinoPageRoute(
                      builder: (_) => const SettingsScreen(),
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
                            final summary = _nasaData?['summary'] as Map<String, dynamic>?;
                            final tempC = (summary?['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
                            final isCelsius = tempUnit == AppTemperatureUnit.celsius;
                            final tempVal = isCelsius
                                ? '${tempC.toStringAsFixed(1)} °C'
                                : '${((tempC * 9 / 5) + 32).toStringAsFixed(1)} °F';
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
                          _isLoadingNasa
                              ? 'Sincronizando...'
                              : (_nasaData?['source']?.toString().contains('Live') == true
                                  ? 'NASA Live'
                                  : s.kDashboardWeatherSummary),
                          style: TextStyle(
                            fontSize: 10,
                            color: _nasaData?['source']?.toString().contains('Live') == true
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade600,
                            fontWeight: _nasaData?['source']?.toString().contains('Live') == true
                                ? FontWeight.bold
                                : FontWeight.normal,
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
                    CupertinoPageRoute(
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
    VoidCallback? onTap,
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
          onTap: onTap,
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

  Widget _buildNasaEnvironmentalCard(BuildContext context, AppStrings s) {
    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final solarMj =
        (summary['avg_solar_radiation_mj'] as num?)?.toDouble() ?? 18.5;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final isLive = _nasaData?['source']?.toString().contains('Live') == true;

    // Environmental diagnosis for status banner
    final Color statusBg;
    final Color statusColor;
    final IconData statusIcon;
    final String statusTitle;
    final String statusMsg;

    if (soilMoisture < 0.40) {
      statusBg = const Color(0xFFFFF3E0);
      statusColor = const Color(0xFFE65100);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'Déficit hídrico detectado';
      statusMsg =
          'Humedad radicular baja (${(soilMoisture * 100).toInt()}%). Se recomienda planificar riego o seleccionar cultivos tolerantes a sequía.';
    } else if (soilMoisture > 0.75) {
      statusBg = const Color(0xFFE3F2FD);
      statusColor = const Color(0xFF1565C0);
      statusIcon = Icons.water_drop_outlined;
      statusTitle = 'Saturación hídrica alta';
      statusMsg =
          'Humedad radicular en ${(soilMoisture * 100).toInt()}%. Monitorear drenaje para prevenir asfixia radicular en zonas bajas.';
    } else {
      statusBg = const Color(0xFFE8F5E9);
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_outline_rounded;
      statusTitle = 'Condiciones agroclimáticas óptimas';
      statusMsg =
          'Humedad radicular equilibrada (${(soilMoisture * 100).toInt()}%) y radiación solar favorable para fotosíntesis activa.';
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isLive ? const Color(0xFFC8E6C9) : const Color(0xFFE0E0E0),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with satellite badge and refresh button
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.satellite_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.kNasaDataReady,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2E1C),
                        ),
                      ),
                      Text(
                        'POWER & SMAP Earth Observations',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live / Cached Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLive
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFFFFE082),
                      width: 1,
                    ),
                  ),
                  child: _isLoadingNasa
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLive
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFF57F17),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isLive ? 'NASA Live' : 'Caché',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLive
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFF57F17),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isLoadingNasa ? null : _loadNasaData,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Metrics Grid
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<AppTemperatureUnit>(
                    valueListenable: AppSettings.temperatureUnit,
                    builder: (context, tempUnit, _) {
                      final isC = tempUnit == AppTemperatureUnit.celsius;
                      final tVal = isC
                          ? '${tempC.toStringAsFixed(1)} °C'
                          : '${((tempC * 9 / 5) + 32).toStringAsFixed(1)} °F';
                      return _buildNasaMetricTile(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFFF57F17),
                        bgColor: const Color(0xFFFFF9E6),
                        title: s.kTemperature,
                        value: tVal,
                        subtext: 'NASA POWER 2m',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNasaMetricTile(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF1976D2),
                    bgColor: const Color(0xFFE3F2FD),
                    title: s.kPrecipitation,
                    value: '${rainMm.toStringAsFixed(1)} mm',
                    subtext: 'Acumulada 7d',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNasaMetricTile(
                    icon: Icons.flare_rounded,
                    iconColor: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                    title: s.kSolarRadiation,
                    value: '${solarMj.toStringAsFixed(1)} MJ',
                    subtext: 'm² / día',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNasaMetricTile(
                    icon: Icons.grass_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    title: s.kSoilMoisture,
                    value: '${(soilMoisture * 100).toInt()}%',
                    subtext: 'SMAP Radicular',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Agroclimatic Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(statusIcon, size: 18, color: statusColor),
                  const SizedBox(width: 8),
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
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNasaMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2D24),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
