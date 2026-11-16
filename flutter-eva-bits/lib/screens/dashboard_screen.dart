import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/responsive.dart';
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

enum DayPeriod {
  madrugada,
  manana,
  mediodia,
  tarde,
  noche,
}

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
  DayPeriod? _userSelectedPeriod;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadLatestFarm();
  }

  DayPeriod get _effectiveDayPeriod {
    if (_userSelectedPeriod != null) return _userSelectedPeriod!;
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 7) {
      return DayPeriod.madrugada;
    } else if (hour >= 7 && hour < 12) {
      return DayPeriod.manana;
    } else if (hour >= 12 && hour < 15) {
      return DayPeriod.mediodia;
    } else if (hour >= 15 && hour < 19) {
      return DayPeriod.tarde;
    } else {
      return DayPeriod.noche;
    }
  }

  void _cycleDayPeriod() {
    setState(() {
      if (_userSelectedPeriod == null) {
        final cur = _effectiveDayPeriod;
        final nextIdx = (cur.index + 1) % DayPeriod.values.length;
        _userSelectedPeriod = DayPeriod.values[nextIdx];
      } else {
        final nextIdx = (_userSelectedPeriod!.index + 1) % (DayPeriod.values.length + 1);
        if (nextIdx >= DayPeriod.values.length) {
          _userSelectedPeriod = null;
        } else {
          _userSelectedPeriod = DayPeriod.values[nextIdx];
        }
      }
    });
  }

  String _getDayPeriodName(DayPeriod period, AppStrings s) {
    final isEs = AppLanguage.current.value == AppLanguageType.spanish;
    switch (period) {
      case DayPeriod.madrugada:
        return isEs ? 'Madrugada' : 'Dawn';
      case DayPeriod.manana:
        return isEs ? 'Mañana' : 'Morning';
      case DayPeriod.mediodia:
        return isEs ? 'Medio día' : 'Midday';
      case DayPeriod.tarde:
        return isEs ? 'Tarde' : 'Afternoon';
      case DayPeriod.noche:
        return isEs ? 'Noche' : 'Night';
    }
  }

  IconData _getDayPeriodIcon(DayPeriod period) {
    switch (period) {
      case DayPeriod.madrugada:
        return Icons.nights_stay_outlined;
      case DayPeriod.manana:
        return Icons.wb_sunny_rounded;
      case DayPeriod.mediodia:
        return Icons.light_mode_rounded;
      case DayPeriod.tarde:
        return Icons.wb_twilight_rounded;
      case DayPeriod.noche:
        return Icons.bedtime_rounded;
    }
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

        final report = _getPredictionsReport();

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
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
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Responsive(context).maxContentWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroWeatherCard(context, s),
                                const SizedBox(height: 10),
                                _buildNasaClimateSection(context, s),
                                const SizedBox(height: 12),
                                Text(
                                  AppLanguage.current.value == AppLanguageType.spanish
                                      ? 'Gestiona tu campo'
                                      : 'Manage your fields',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildFieldsGrid(context, s, displaySurface),
                                const SizedBox(height: 12),
                                _buildPredictionsSection(context, s, report),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
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
              report: report,
              graph: _farmGraph,
              subplots: _farmSubplots,
            ),
            bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
          ),
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
    final cleanLocation = locationText
        .replaceAll(RegExp(r'[\u{10000}-\u{10FFFF}]', unicode: true), '')
        .trim();
    final headerBg = AppColors.getHeaderBg(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 18,
            right: 18,
            top: 12,
            bottom: 46,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.18,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cleanLocation,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: s.kDashboardYourFarm,
                  icon: const Icon(
                    Icons.cottage_rounded,
                    color: Colors.white,
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

    final effectivePeriod = _effectiveDayPeriod;

    final moistureLabel = soilMoisture < 0.40
        ? 'Baja'
        : (soilMoisture > 0.75 ? 'Alta' : 'Óptima');
    final rainLabel = rainMm < 1.0
        ? 'Baja'
        : (rainMm > 15.0 ? 'Alta' : '${rainMm.toStringAsFixed(1)} mm');

    final List<Color> gradientColors;
    final Color periodTextColor;
    final Color periodSubtextColor;
    final Color shadowColor;
    final String conditionText;
    final bool isPeriodDark;

    switch (effectivePeriod) {
      case DayPeriod.madrugada:
        gradientColors = const [
          Color(0xFF1E1B38),
          Color(0xFF38325C),
          Color(0xFF6B4B70),
          Color(0xFF986278),
        ];
        periodTextColor = Colors.white;
        periodSubtextColor = const Color(0xFFE2D9EB);
        shadowColor = const Color(0xFF38325C).withValues(alpha: 0.35);
        conditionText = isLive ? 'NASA Live - Alba' : 'Amanecer fresco';
        isPeriodDark = true;
        break;
      case DayPeriod.manana:
        gradientColors = const [
          Color(0xFFFFDF9E),
          Color(0xFFFED285),
          Color(0xFFF9A84D),
        ];
        periodTextColor = const Color(0xFF2E1C0C);
        periodSubtextColor = const Color(0xFF4E342E).withValues(alpha: 0.9);
        shadowColor = const Color(0xFFF9A84D).withValues(alpha: 0.32);
        conditionText = isLive ? 'NASA Live - Soleado' : 'Parcialmente soleado';
        isPeriodDark = false;
        break;
      case DayPeriod.mediodia:
        gradientColors = const [
          Color(0xFF64B5F6),
          Color(0xFF42A5F5),
          Color(0xFF1976D2),
        ];
        periodTextColor = Colors.white;
        periodSubtextColor = const Color(0xFFE3F2FD);
        shadowColor = const Color(0xFF1976D2).withValues(alpha: 0.35);
        conditionText = isLive ? 'NASA Live - Cenit' : 'Sol radiante';
        isPeriodDark = true;
        break;
      case DayPeriod.tarde:
        gradientColors = const [
          Color(0xFFFFB74D),
          Color(0xFFFF7043),
          Color(0xFFD84315),
        ];
        periodTextColor = Colors.white;
        periodSubtextColor = const Color(0xFFFFE082);
        shadowColor = const Color(0xFFD84315).withValues(alpha: 0.35);
        conditionText = isLive ? 'NASA Live - Ocaso' : 'Atardecer cálido';
        isPeriodDark = true;
        break;
      case DayPeriod.noche:
        gradientColors = const [
          Color(0xFF0F172A),
          Color(0xFF1E293B),
          Color(0xFF2C3E50),
        ];
        periodTextColor = Colors.white;
        periodSubtextColor = const Color(0xFFCBD5E1);
        shadowColor = const Color(0xFF0F172A).withValues(alpha: 0.45);
        conditionText = isLive ? 'NASA Live - Nocturno' : 'Cielo sereno';
        isPeriodDark = true;
        break;
    }

    final pillLabelColor = isPeriodDark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF3E2723).withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      height: 215,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
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
                painter: _WeatherCardLandscapePainter(period: effectivePeriod),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: periodTextColor,
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
                                    : conditionText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: periodSubtextColor,
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
                                    size: 15,
                                    color: periodSubtextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _cycleDayPeriod,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (isPeriodDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (isPeriodDark
                                          ? Colors.white
                                          : Colors.black)
                                      .withValues(alpha: 0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getDayPeriodIcon(effectivePeriod),
                                    size: 12,
                                    color: periodTextColor.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _userSelectedPeriod == null
                                        ? '${_getDayPeriodName(effectivePeriod, s)} (Auto)'
                                        : _getDayPeriodName(effectivePeriod, s),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: periodTextColor.withValues(alpha: 0.95),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.touch_app_outlined,
                                    size: 11,
                                    color: periodTextColor.withValues(alpha: 0.75),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      _WeatherSkyArtwork(period: effectivePeriod),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWeatherPill(
                          label: 'Humedad',
                          value: '${(soilMoisture * 100).toInt()}%',
                          valueColor: const Color(0xFF2E7D32),
                          labelColor: pillLabelColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWeatherPill(
                          label: 'Humedad Radicular',
                          value: moistureLabel,
                          valueColor: const Color(0xFF2E7D32),
                          labelColor: pillLabelColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWeatherPill(
                          label: 'Precipitación',
                          value: rainLabel,
                          valueColor: const Color(0xFF1565C0),
                          labelColor: pillLabelColor,
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
    required Color labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: -0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNasaClimateSection(BuildContext context, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextMuted(context);

    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final avgSolar =
        (summary['avg_solar_radiation_mj'] as num?)?.toDouble() ?? 18.5;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;
    final isLive = _nasaData?['source']?.toString().contains('Live') == true;

    final solarKwh = avgSolar / 3.6;

    final moistureLabel = soilMoisture < 0.40
        ? 'Déficit radicular'
        : (soilMoisture > 0.75 ? 'Saturación alta' : 'Nivel óptimo');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos NASA & Clima',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLive
                        ? 'Telemetría satelital en tiempo real'
                        : 'Observaciones agroclimáticas satelitales',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _isLoadingNasa ? null : _loadNasaData,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2B20)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFA5D6A7),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLoadingNasa
                          ? 'Sincronizando...'
                          : (isLive ? 'NASA Live' : 'Sincronizar'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.primaryLight
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.primaryLight
                          : const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildEnvironmentalStatusBanner(context, s),
        const SizedBox(height: 6),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.38,
          children: [
            _buildTelemetryCard(
              context: context,
              title: 'Radiación Solar',
              value: '${solarKwh.toStringAsFixed(1)} kWh/m²',
              subtitle: 'Fotosíntesis activa',
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFFFA000),
              iconBgColor: const Color(0xFFFFF8E1),
            ),
            _buildTelemetryCard(
              context: context,
              title: 'Humedad SMAP',
              value: '${(soilMoisture * 100).toInt()}%',
              subtitle: moistureLabel,
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF1976D2),
              iconBgColor: const Color(0xFFE3F2FD),
            ),
            _buildTelemetryCard(
              context: context,
              title: 'Rango Térmico',
              value: '${tempC.toStringAsFixed(1)} °C',
              subtitle: 'Sensor T2M NASA',
              icon: Icons.thermostat_rounded,
              iconColor: const Color(0xFFE64A19),
              iconBgColor: const Color(0xFFFBE9E7),
            ),
            _buildTelemetryCard(
              context: context,
              title: 'Precipitación',
              value: rainMm < 0.1
                  ? '0.0 mm/día'
                  : '${rainMm.toStringAsFixed(1)} mm/día',
              subtitle: rainMm < 1.0 ? 'Sin lluvia reciente' : 'Aporte hídrico pluvial',
              icon: Icons.grain_rounded,
              iconColor: const Color(0xFF00897B),
              iconBgColor: const Color(0xFFE0F2F1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.getCardBg(context);
    final borderColor = AppColors.getBorder(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextMuted(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? iconBgColor.withValues(alpha: 0.22)
                      : iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: isDark ? AppColors.primaryLight : iconColor,
                  ),
                ),
              ),
              Icon(
                Icons.trending_flat_rounded,
                size: 16,
                color: subtextColor.withValues(alpha: 0.5),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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

  Widget _buildPredictionsSection(
    BuildContext context,
    AppStrings s,
    FarmPredictionsReport report,
  ) {
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextMuted(context);
    final isTablet = Responsive(context).isTabletOrDesktop;

    final cardIrrigation = _buildPredictionCard(
      context: context,
      badgeText: report.irrigation.status == 'critical'
          ? 'Atención'
          : (report.irrigation.status == 'moderate' ? 'Moderado' : 'Óptimo'),
      badgeColor: report.irrigation.status == 'critical'
          ? const Color(0xFFC62828)
          : (report.irrigation.status == 'moderate'
              ? const Color(0xFFF57F17)
              : const Color(0xFF2E7D32)),
      badgeBgColor: report.irrigation.status == 'critical'
          ? (isDark ? const Color(0xFF3E1E1E) : const Color(0xFFFFEBEE))
          : (report.irrigation.status == 'moderate'
              ? (isDark ? const Color(0xFF3E321E) : const Color(0xFFFFF8E1))
              : (isDark ? const Color(0xFF1E3322) : const Color(0xFFE8F5E9))),
      icon: Icons.water_drop_rounded,
      title: 'Gestor de Riego a 7 Días',
      subtitle: report.irrigation.actionTitle,
      details: report.irrigation.actionRecommendation,
      metricPill1:
          'Déficit: ${report.irrigation.weeklyDeficitMm.toStringAsFixed(1)} mm',
      metricPill2:
          'Sin estrés: ${report.irrigation.daysUntilStress} días',
      onTap: () {
        Navigator.of(context).pushReplacement(
          createBottomNavPageRoute(
            const PredictionsScreen(initialTab: 0),
          ),
        );
      },
    );

    final cardRotation = _buildPredictionCard(
      context: context,
      badgeText: '${report.rotation.score}% Compatibilidad',
      badgeColor: const Color(0xFF2E7D32),
      badgeBgColor:
          isDark ? const Color(0xFF1E3322) : const Color(0xFFE8F5E9),
      icon: Icons.sync_alt_rounded,
      title: 'Rotación y Sucesión Botánica',
      subtitle: 'Sucesión recomendada: ${report.rotation.suggestedCrop}',
      details: report.rotation.explanation,
      metricPill1: 'Nivel: ${report.rotation.compatibilityLevel}',
      metricPill2: report.rotation.hasSpatialCorridorRisk
          ? 'Alerta plagas'
          : 'Bajo riesgo biológico',
      onTap: () {
        Navigator.of(context).pushReplacement(
          createBottomNavPageRoute(
            const PredictionsScreen(initialTab: 1),
          ),
        );
      },
    );

    final cardCalendar = _buildPredictionCard(
      context: context,
      badgeText: report.calendar.windowStatus,
      badgeColor: report.calendar.isWindowOpen
          ? const Color(0xFF2E7D32)
          : const Color(0xFFE65100),
      badgeBgColor: report.calendar.isWindowOpen
          ? (isDark ? const Color(0xFF1E3322) : const Color(0xFFE8F5E9))
          : (isDark ? const Color(0xFF3E281E) : const Color(0xFFFFF3E0)),
      icon: Icons.calendar_month_rounded,
      title: 'Ventana de Siembra & GDD',
      subtitle: 'Fechas ideales: ${report.calendar.recommendedDateRange}',
      details: report.calendar.thermalAdvice,
      metricPill1:
          'GDD 7d: ${report.calendar.accumulatedGdd7d.toInt()} °C',
      metricPill2:
          'Floración: ~${report.calendar.estimatedDaysToFlowering} d',
      onTap: () {
        Navigator.of(context).pushReplacement(
          createBottomNavPageRoute(
            const PredictionsScreen(initialTab: 2),
          ),
        );
      },
    );

    final cardNutrition = _buildPredictionCard(
      context: context,
      badgeText: '${report.nutrition.soilHealthScore}/100 Salud',
      badgeColor: const Color(0xFF00796B),
      badgeBgColor:
          isDark ? const Color(0xFF1B3330) : const Color(0xFFE0F2F1),
      icon: Icons.eco_rounded,
      title: 'Salud del Suelo & Fijación Biológica',
      subtitle: 'Vigor vegetal: ${report.health.vigorStatus}',
      details:
          'Fijación biológica estimada de nitrógeno: +${report.nutrition.projectedNitrogenGainKgPerHa.toStringAsFixed(1)} kg N/ha con cobertura vegetal.',
      metricPill1:
          '+${report.nutrition.projectedNitrogenGainKgPerHa.toStringAsFixed(1)} kg N/ha',
      metricPill2:
          'NDVI Proxy: ${(report.health.estimatedNdviProxy * 100).toInt()}%',
      onTap: () {
        Navigator.of(context).pushReplacement(
          createBottomNavPageRoute(
            const PredictionsScreen(initialTab: 5),
          ),
        );
      },
    );

    Widget predictionsLayout;
    if (isTablet) {
      predictionsLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                cardIrrigation,
                const SizedBox(height: 10),
                cardCalendar,
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                cardRotation,
                const SizedBox(height: 10),
                cardNutrition,
              ],
            ),
          ),
        ],
      );
    } else {
      predictionsLayout = Column(
        children: [
          cardIrrigation,
          const SizedBox(height: 6),
          cardRotation,
          const SizedBox(height: 6),
          cardCalendar,
          const SizedBox(height: 6),
          cardNutrition,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predicciones de Eve',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Modelos biofísicos y agroecológicos de tu finca',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  createBottomNavPageRoute(
                    const PredictionsScreen(initialTab: 0),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text(
                'Ver todas',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        predictionsLayout,
      ],
    );
  }

  Widget _buildPredictionCard({
    required BuildContext context,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required String metricPill1,
    required String metricPill2,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.getCardBg(context);
    final borderColor = AppColors.getBorder(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextMuted(context);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 1.5 : 1.0,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(icon, color: badgeColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                details,
                style: TextStyle(
                  fontSize: 12,
                  color: subtextColor,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF243329)
                                : const Color(0xFFF1F8F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            metricPill1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF243329)
                                : const Color(0xFFF1F8F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            metricPill2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: subtextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsGrid(
    BuildContext context,
    AppStrings s,
    String surfaceText,
  ) {
    final isTablet = Responsive(context).isTabletOrDesktop;

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: isTablet ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isTablet ? 12 : 8,
      mainAxisSpacing: isTablet ? 12 : 8,
      childAspectRatio: isTablet ? 1.35 : 1.25,
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
}

class _WeatherSkyArtwork extends StatelessWidget {
  final DayPeriod period;

  const _WeatherSkyArtwork({required this.period});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 64,
      child: CustomPaint(
        painter: _WeatherSkyPainter(period: period),
      ),
    );
  }
}

class _WeatherSkyPainter extends CustomPainter {
  final DayPeriod period;

  const _WeatherSkyPainter({required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    switch (period) {
      case DayPeriod.madrugada:
        _drawDawn(canvas, size);
        break;
      case DayPeriod.manana:
        _drawMorning(canvas, size);
        break;
      case DayPeriod.mediodia:
        _drawMidday(canvas, size);
        break;
      case DayPeriod.tarde:
        _drawSunset(canvas, size);
        break;
      case DayPeriod.noche:
        _drawNight(canvas, size);
        break;
    }
  }

  void _drawMorning(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.65, size.height * 0.36);
    const sunRadius = 13.0;

    final rayPaint = Paint()
      ..color = const Color(0xFFFFA000).withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = i * (2 * math.pi / 8);
      final start = Offset(
        sunCenter.dx + (sunRadius + 3) * math.cos(angle),
        sunCenter.dy + (sunRadius + 3) * math.sin(angle),
      );
      final end = Offset(
        sunCenter.dx + (sunRadius + 9) * math.cos(angle),
        sunCenter.dy + (sunRadius + 9) * math.sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFEE58), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;

    final cloudRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.44, 58, 17),
      const Radius.circular(10),
    );
    canvas.drawRRect(cloudRect, cloudPaint);
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.41),
      12,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.45),
      9,
      cloudPaint,
    );

    final smallCloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final smallRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.28, 36, 11),
      const Radius.circular(6),
    );
    canvas.drawRRect(smallRect, smallCloudPaint);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.26),
      7,
      smallCloudPaint,
    );
  }

  void _drawMidday(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.62, size.height * 0.30);
    const sunRadius = 14.5;

    final coronaPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(sunCenter, sunRadius + 10, coronaPaint);

    final rayPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 10; i++) {
      final angle = i * (2 * math.pi / 10);
      final start = Offset(
        sunCenter.dx + (sunRadius + 3) * math.cos(angle),
        sunCenter.dy + (sunRadius + 3) * math.sin(angle),
      );
      final end = Offset(
        sunCenter.dx + (sunRadius + 11) * math.cos(angle),
        sunCenter.dy + (sunRadius + 11) * math.sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFFFEE58), Color(0xFFFFB300)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    final cloudRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.46, 62, 16),
      const Radius.circular(9),
    );
    canvas.drawRRect(cloudRect, cloudPaint);
    canvas.drawCircle(
      Offset(size.width * 0.46, size.height * 0.43),
      11,
      cloudPaint,
    );
  }

  void _drawSunset(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.66, size.height * 0.46);
    const sunRadius = 14.0;

    final rayPaint = Paint()
      ..color = const Color(0xFFFFCC80).withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 7; i++) {
      final angle = -math.pi * 0.85 + (i * (math.pi * 0.7 / 6));
      final start = Offset(
        sunCenter.dx + (sunRadius + 3) * math.cos(angle),
        sunCenter.dy + (sunRadius + 3) * math.sin(angle),
      );
      final end = Offset(
        sunCenter.dx + (sunRadius + 12) * math.cos(angle),
        sunCenter.dy + (sunRadius + 12) * math.sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF3E0), Color(0xFFFF9800), Color(0xFFE64A19)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    final sunsetCloudPaint = Paint()
      ..color = const Color(0xFFFFE0B2).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.48, 68, 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, sunsetCloudPaint);
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.45),
      10,
      sunsetCloudPaint,
    );
  }

  void _drawDawn(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.68, size.height * 0.52);
    const sunRadius = 13.0;

    final dawnGlow = Paint()
      ..color = const Color(0xFFFF80AB).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(sunCenter, sunRadius + 8, dawnGlow);

    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD180), Color(0xFFFF4081)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    final moonCenter = Offset(size.width * 0.25, size.height * 0.26);
    final moonPaint = Paint()
      ..color = const Color(0xFFEDE7F6).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(moonCenter, 7, moonPaint);
    final shadowCutPaint = Paint()
      ..color = const Color(0xFF38325C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(moonCenter.dx + 2.5, moonCenter.dy - 1.5),
      6,
      shadowCutPaint,
    );

    final mistPaint = Paint()
      ..color = const Color(0xFFF8BBD0).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final mistRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.48, 56, 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(mistRRect, mistPaint);
  }

  void _drawNight(Canvas canvas, Size size) {
    final moonCenter = Offset(size.width * 0.65, size.height * 0.34);
    const moonRadius = 14.0;

    final moonHalo = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(moonCenter, moonRadius + 6, moonHalo);

    final moonPaint = Paint()
      ..color = const Color(0xFFFFFDE7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(moonCenter, moonRadius, moonPaint);

    final shadowCutPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(moonCenter.dx + 4.5, moonCenter.dy - 2.5),
      moonRadius - 1,
      shadowCutPaint,
    );

    final cloudPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.45, 54, 14),
      const Radius.circular(7),
    );
    canvas.drawRRect(rrect, cloudPaint);
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.42),
      9,
      cloudPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherSkyPainter oldDelegate) =>
      oldDelegate.period != period;
}

class _WeatherCardLandscapePainter extends CustomPainter {
  final DayPeriod period;

  const _WeatherCardLandscapePainter({required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    if (period == DayPeriod.noche || period == DayPeriod.madrugada) {
      final starPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: period == DayPeriod.noche ? 0.75 : 0.45,
        );
      final stars = [
        Offset(size.width * 0.12, size.height * 0.22),
        Offset(size.width * 0.26, size.height * 0.14),
        Offset(size.width * 0.40, size.height * 0.26),
        Offset(size.width * 0.54, size.height * 0.16),
        Offset(size.width * 0.78, size.height * 0.28),
        Offset(size.width * 0.88, size.height * 0.12),
        Offset(size.width * 0.32, size.height * 0.38),
        Offset(size.width * 0.82, size.height * 0.42),
      ];
      for (int i = 0; i < stars.length; i++) {
        final r = (i % 3 == 0) ? 1.8 : 1.2;
        canvas.drawCircle(stars[i], r, starPaint);
      }
    }

    final Color backHillColor;
    final Color frontHillColor;
    final Color foliageColor;

    switch (period) {
      case DayPeriod.madrugada:
        backHillColor = const Color(0xFF2A5043).withValues(alpha: 0.7);
        frontHillColor = const Color(0xFF1B3D32).withValues(alpha: 0.85);
        foliageColor = const Color(0xFF112C24);
        break;
      case DayPeriod.manana:
        backHillColor = const Color(0xFF5CB85C).withValues(alpha: 0.65);
        frontHillColor = const Color(0xFF388E3C).withValues(alpha: 0.85);
        foliageColor = const Color(0xFF1B5E20);
        break;
      case DayPeriod.mediodia:
        backHillColor = const Color(0xFF66BB6A).withValues(alpha: 0.6);
        frontHillColor = const Color(0xFF2E7D32).withValues(alpha: 0.85);
        foliageColor = const Color(0xFF1B5E20);
        break;
      case DayPeriod.tarde:
        backHillColor = const Color(0xFF688A4E).withValues(alpha: 0.65);
        frontHillColor = const Color(0xFF4A6836).withValues(alpha: 0.85);
        foliageColor = const Color(0xFF2E461E);
        break;
      case DayPeriod.noche:
        backHillColor = const Color(0xFF1F382B).withValues(alpha: 0.7);
        frontHillColor = const Color(0xFF14291E).withValues(alpha: 0.9);
        foliageColor = const Color(0xFF0C1B13);
        break;
    }

    final backHillPaint = Paint()
      ..color = backHillColor
      ..style = PaintingStyle.fill;
    final backHillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.74,
        size.width * 0.75,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.92,
        size.width,
        size.height * 0.94,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(backHillPath, backHillPaint);

    final frontHillPaint = Paint()
      ..color = frontHillColor
      ..style = PaintingStyle.fill;
    final frontHillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.95)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.96,
        size.width * 0.60,
        size.height * 0.86,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.78,
        size.width,
        size.height * 0.83,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(frontHillPath, frontHillPaint);

    final leafPaint = Paint()
      ..color = foliageColor
      ..style = PaintingStyle.fill;
    final leafBase = Offset(size.width * 0.95, size.height * 0.99);

    _drawLeaf(canvas, leafBase, -math.pi * 0.52, size.height * 0.25, leafPaint);
    _drawLeaf(canvas, leafBase, -math.pi * 0.68, size.height * 0.22, leafPaint);
    _drawLeaf(canvas, leafBase, -math.pi * 0.82, size.height * 0.18, leafPaint);
    _drawLeaf(canvas, leafBase, -math.pi * 0.38, size.height * 0.21, leafPaint);
    _drawLeaf(canvas, leafBase, -math.pi * 0.22, size.height * 0.16, leafPaint);
  }

  void _drawLeaf(
    Canvas canvas,
    Offset base,
    double angle,
    double length,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-length * 0.20, length * 0.5, 0, length)
      ..quadraticBezierTo(length * 0.20, length * 0.5, 0, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeatherCardLandscapePainter oldDelegate) =>
      oldDelegate.period != period;
}
