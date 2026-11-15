import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/nasa_power_service.dart';
import '../services/agro_prediction_engine.dart';
import '../services/subplot_graph_service.dart';
import '../services/azure_ai_service.dart';
import '../widgets/bottom_nav_bar.dart';

class PredictionsScreen extends StatefulWidget {
  final int initialTab;
  final int? selectedSubplotId;

  const PredictionsScreen({
    super.key,
    this.initialTab = 0,
    this.selectedSubplotId,
  });

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _farm;
  Map<String, dynamic>? _nasaData;
  SubplotGraph? _graph;
  List<Map<String, dynamic>> _subplots = [];
  bool _isLoading = true;

  // Active filter / simulator
  int? _activeSubplotId;
  String _selectedCrop = 'Maíz';
  String _selectedSoil = 'Franco';

  // Toggle between 2.5D Map view and compact list view
  bool _show2dMap = true;

  final List<String> _cropOptions = [
    'Maíz',
    'Frijol',
    'Café',
    'Arroz',
    'Soya',
    'Sorgo',
    'Caña de azúcar',
    'Plátano',
    'Sandía',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 5),
    );
    _activeSubplotId = widget.selectedSubplotId;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final farm = await DatabaseManager().getLatestFarm();
      _farm = farm;

      if (farm != null && farm['id'] != null) {
        final farmId = farm['id'] as int;

        try {
          _graph = await SubplotGraphService.getGraphForFarm(farmId);
          final lotsWithSubplots =
              await DatabaseManager().getAllLotsWithSubplots(farmId: farmId);
          final List<Map<String, dynamic>> flat = [];
          for (final lot in lotsWithSubplots) {
            final spList = lot['subplots'] as List<dynamic>? ?? [];
            for (final sp in spList) {
              if (sp is Map<String, dynamic>) {
                final copy = Map<String, dynamic>.from(sp);
                copy['lot_name'] = lot['name'] ?? 'Lote';
                flat.add(copy);
              }
            }
          }
          _subplots = flat;

          if (_activeSubplotId != null) {
            final found = _subplots.firstWhere(
              (s) => s['id'] == _activeSubplotId,
              orElse: () => _subplots.isNotEmpty ? _subplots.first : {},
            );
            if (found.isNotEmpty) {
              _selectedCrop = found['crop']?.toString() ?? 'Maíz';
              _selectedSoil = found['soil_type']?.toString() ?? 'Franco';
            }
          } else if (_subplots.isNotEmpty) {
            _selectedCrop = _subplots.first['crop']?.toString() ?? 'Maíz';
            _selectedSoil = _subplots.first['soil_type']?.toString() ?? 'Franco';
          }
        } catch (_) {}

        double lat = 13.0910;
        double lon = -86.3538;
        if (farm['latitude'] != null && farm['longitude'] != null) {
          final pLat = (farm['latitude'] as num).toDouble();
          final pLon = (farm['longitude'] as num).toDouble();
          if (pLat != 0.0 || pLon != 0.0) {
            lat = pLat;
            lon = pLon;
          }
        }

        final nasa = await NasaPowerService.fetchClimateData(
          latitude: lat,
          longitude: lon,
        );
        _nasaData = nasa;
      }
    } catch (_) {
      _nasaData = NasaPowerService.getFallbackData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  FarmPredictionsReport _generateCurrentReport([AppStrings? strings]) {
    return AgroPredictionEngine.generateReport(
      farmData: _farm ?? {
        'name': 'Mi Finca',
        'zone': 'Nicaragua',
        'total_surface': 2.5,
        'unit': 'ha',
      },
      nasaData: _nasaData ?? NasaPowerService.getFallbackData(),
      graph: _graph,
      subplots: _subplots,
      targetCrop: _selectedCrop,
      targetSoilType: _selectedSoil,
      strings: strings,
    );
  }

  void _onSubplotSelected(int? subplotId) {
    setState(() {
      _activeSubplotId = subplotId;
      if (subplotId != null) {
        final match = _subplots.firstWhere(
          (s) => s['id'] == subplotId,
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          _selectedCrop = match['crop']?.toString() ?? 'Maíz';
          _selectedSoil = match['soil_type']?.toString() ?? 'Franco';
        }
      }
    });
  }

  // ===========================================================================
  // ICON HELPER - ZERO EMOJIS COMPLIANCE
  // ===========================================================================
  IconData _getCropIcon(String crop) {
    final lower = crop.toLowerCase();
    if (lower.contains('maíz') || lower.contains('corn')) {
      return Icons.grass_rounded;
    }
    if (lower.contains('frijol') || lower.contains('bean')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('café') || lower.contains('coffee')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('arroz') || lower.contains('rice')) {
      return Icons.rice_bowl_rounded;
    }
    if (lower.contains('soya') || lower.contains('soy')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('sorgo') || lower.contains('sorghum')) {
      return Icons.grain_rounded;
    }
    if (lower.contains('caña') || lower.contains('sugar')) {
      return Icons.forest_rounded;
    }
    if (lower.contains('plátano') || lower.contains('banana')) {
      return Icons.energy_savings_leaf_rounded;
    }
    if (lower.contains('sandía') || lower.contains('melon')) {
      return Icons.yard_rounded;
    }
    return Icons.eco_rounded;
  }

  Color _getSoilColor(String soil) {
    final lower = soil.toLowerCase();
    if (lower.contains('arenoso') || lower.contains('sandy')) {
      return const Color(0xFFD7CCC8);
    }
    if (lower.contains('arcilloso') || lower.contains('clay')) {
      return const Color(0xFFBCAAA4);
    }
    if (lower.contains('limoso') || lower.contains('silt')) {
      return const Color(0xFFCFD8DC);
    }
    return const Color(0xFFA5D6A7); // Franco
  }

  Widget _buildIconBadge({
    required IconData icon,
    required Color color,
    required Color bgColor,
    double size = 18,
    double containerSize = 34,
  }) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Icon(icon, size: size, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FAF7),
            appBar: AppBar(
              title: Text(s.kPredictionsTitle),
              backgroundColor: const Color(0xFF0F5A37),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final report = _generateCurrentReport(s);

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF0F5A37),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.kPredictionsTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF81C784),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.kPredictionsSubtitle,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFC8E6C9)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: s.kAskIvyTooltip,
                icon: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFFFD54F)),
                onPressed: () => _openIvySheet(report, s),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFFFFD54F),
              indicatorWeight: 3.5,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFA5D6A7),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                    icon: const Icon(Icons.water_drop_rounded, size: 20),
                    text: s.kTabIrrigation),
                Tab(
                    icon: const Icon(Icons.sync_alt_rounded, size: 20),
                    text: s.kTabRotation),
                Tab(
                    icon: const Icon(Icons.wb_sunny_rounded, size: 20),
                    text: s.kTabPlantingGdd),
                Tab(
                    icon: const Icon(Icons.eco_rounded, size: 20),
                    text: s.kTabVigorNdvi),
                Tab(
                    icon: const Icon(Icons.warning_amber_rounded, size: 20),
                    text: s.kTabRisks),
                Tab(
                    icon: const Icon(Icons.science_rounded, size: 20),
                    text: s.kTabNutrition),
              ],
            ),
          ),
          body: Column(
            children: [
              // Interactive 2.5D Isometric Parcel Selector Bar
              _buildInteractiveContextBar(s),

              // The 6 Prediction Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIrrigationTab(report.irrigation, s),
                    _buildRotationTab(report.rotation, s),
                    _buildCalendarTab(report.calendar, s),
                    _buildHealthTab(report.health, s),
                    _buildRisksTab(report.risks, s),
                    _buildNutritionTab(report.nutrition, s),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFFFD54F), size: 20),
            label: Text(
              s.kAskIvyButton,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () => _openIvySheet(report, s),
          ),
          bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
        );
      },
    );
  }

  // ===========================================================================
  // INTERACTIVE CONTEXT BAR & 2.5D ISOMETRIC PARCEL MAP
  // ===========================================================================
  Widget _buildInteractiveContextBar(AppStrings s) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                _buildIconBadge(
                  icon: Icons.landscape_rounded,
                  color: const Color(0xFF1B5E20),
                  bgColor: const Color(0xFFE8F5E9),
                  size: 16,
                  containerSize: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  s.kPredictionContext,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2D24),
                  ),
                ),
                const Spacer(),
                // View Mode Toggle (2.5D Map vs Horizontal List)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _show2dMap = !_show2dMap),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCFD8DC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _show2dMap
                                ? Icons.view_in_ar_rounded
                                : Icons.view_carousel_rounded,
                            size: 14,
                            color: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _show2dMap ? s.kVisualParcelView : s.kCompactListView,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // What-If Simulator Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showWhatIfSimulatorDialog(s),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune_rounded,
                              size: 14, color: Color(0xFF1B5E20)),
                          const SizedBox(width: 4),
                          Text(
                            s.kWhatIfSimulator,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Visual 2.5D Isometric View or Horizontal Carousel
          if (_show2dMap)
            _buildIsometricParcelOverview(s)
          else
            _buildHorizontalSubplotCarousel(s),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2.5D ISOMETRIC PARCEL OVERVIEW (TACTILE & FARMER-FRIENDLY)
  // ===========================================================================
  Widget _buildIsometricParcelOverview(AppStrings s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DECF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded,
                  size: 14, color: Color(0xFF6D4C41)),
              const SizedBox(width: 6),
              Text(
                s.kTapToInspectSubplot,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_selectedCrop • $_selectedSoil',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Isometric Parcel Tiles Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Whole Farm Card
              _buildIsometricTile(
                title: s.kWholeFarmGeneral,
                crop: _selectedCrop,
                soil: _selectedSoil,
                isSelected: _activeSubplotId == null,
                onTap: () => _onSubplotSelected(null),
                isWholeFarm: true,
                badgeLabel: s.kActiveSubplotBadge,
              ),

              // Individual Subplots
              ..._subplots.map((sp) {
                final id = sp['id'] as int;
                final name = sp['name'] ?? '${s.kSubplot} $id';
                final crop = sp['crop'] ?? 'Maíz';
                final soil = sp['soil_type'] ?? 'Franco';
                final surface = sp['surface']?.toString() ?? '1.0';
                final isSelected = _activeSubplotId == id;

                return _buildIsometricTile(
                  title: name,
                  crop: crop,
                  soil: soil,
                  surface: surface,
                  isSelected: isSelected,
                  onTap: () => _onSubplotSelected(id),
                  badgeLabel: s.kActiveSubplotBadge,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIsometricTile({
    required String title,
    required String crop,
    required String soil,
    required bool isSelected,
    required VoidCallback onTap,
    String? surface,
    bool isWholeFarm = false,
    required String badgeLabel,
  }) {
    final soilBaseColor = _getSoilColor(soil);
    final cropIcon = _getCropIcon(crop);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 145,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD54F)
                  : const Color(0xFFD7CCC8),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 8 : 3,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Isometric Ground Plate Layer
              Container(
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      soilBaseColor.withValues(alpha: 0.8),
                      soilBaseColor.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD54F)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Stack(
                  children: [
                    // Soil layer stripe
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D4037).withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(7)),
                        ),
                      ),
                    ),
                    // Floating Center Crop Pin
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isWholeFarm ? Icons.nature_people_rounded : cropIcon,
                          size: 15,
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 2,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1E2D24),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isWholeFarm ? '$crop • $soil' : '$crop ($soil)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected
                            ? const Color(0xFFC8E6C9)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (surface != null)
                    Text(
                      '$surface ha',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HORIZONTAL SUBPLOT CAROUSEL
  // ===========================================================================
  Widget _buildHorizontalSubplotCarousel(AppStrings s) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _buildSubplotFilterCard(
            title: s.kWholeFarmGeneral,
            crop: _selectedCrop,
            soil: _selectedSoil,
            isSelected: _activeSubplotId == null,
            onTap: () => _onSubplotSelected(null),
            isWholeFarm: true,
          ),
          ..._subplots.map((sp) {
            final id = sp['id'] as int;
            final name = sp['name'] ?? '${s.kSubplot} $id';
            final crop = sp['crop'] ?? 'Maíz';
            final soil = sp['soil_type'] ?? 'Franco';
            final isSelected = _activeSubplotId == id;

            return _buildSubplotFilterCard(
              title: name,
              crop: crop,
              soil: soil,
              isSelected: isSelected,
              onTap: () => _onSubplotSelected(id),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubplotFilterCard({
    required String title,
    required String crop,
    required String soil,
    required bool isSelected,
    required VoidCallback onTap,
    bool isWholeFarm = false,
  }) {
    final cropIcon = _getCropIcon(crop);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFF1F6F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWholeFarm ? Icons.nature_people_rounded : cropIcon,
                  size: 16,
                  color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF1E2D24),
                      ),
                    ),
                    Text(
                      '$crop • $soil',
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected
                            ? const Color(0xFFC8E6C9)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. PREDICCIÓN DE RIEGO Y DÉFICIT
  // ===========================================================================
  Widget _buildIrrigationTab(IrrigationPrediction item, AppStrings s) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (item.status == 'critical') {
      statusColor = const Color(0xFFD32F2F);
      statusIcon = Icons.warning_rounded;
      statusLabel = s.kStatusAttentionRequired;
    } else if (item.status == 'moderate') {
      statusColor = const Color(0xFFF57F17);
      statusIcon = Icons.schedule_rounded;
      statusLabel = s.kStatusPlanIrrigation;
    } else {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded;
      statusLabel = s.kStatusOptimalMoisture;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Moisture Gauge Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withValues(alpha: 0.12),
                statusColor.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Circular Moisture Level Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: (item.soilMoisturePct / 100).clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          color: statusColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop_rounded,
                              size: 20, color: statusColor),
                          Text(
                            '${item.soilMoisturePct.toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.actionTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.kCropPrefix} $_selectedCrop • ${s.kSoilPrefix} $_selectedSoil',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  item.actionRecommendation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Key Metric Tiles
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF0288D1),
                bgColor: const Color(0xFFE1F5FE),
                title: s.kMetricRootMoisture,
                value: '${item.soilMoisturePct}%',
                subtitle: s.kMetricRootMoistureSub,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFE65100),
                bgColor: const Color(0xFFFFF3E0),
                title: s.kMetric7dDeficit,
                value: '${item.weeklyDeficitMm} mm',
                subtitle: s.kMetric7dDeficitSub,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.hourglass_bottom_rounded,
                color: const Color(0xFF5D4037),
                bgColor: const Color(0xFFEFEBE9),
                title: s.kMetricReserveDays,
                value: '${item.daysUntilStress} ${s.kDaysUnit}',
                subtitle: s.kMetricReserveDaysSub,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.opacity_rounded,
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                title: s.kMetricRequiredDepth,
                value: '${item.recommendedWaterMm} mm',
                subtitle: s.kMetricRequiredDepthSub,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Soil Impact Advice Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0D7C6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconBadge(
                icon: Icons.terrain_rounded,
                color: const Color(0xFF5D4037),
                bgColor: const Color(0xFFEFEBE9),
                size: 22,
                containerSize: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.kSoilImpactTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3E2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.kSoilImpactDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. PREDICCIÓN DE ROTACIÓN Y COMPATIBILIDAD ESPACIAL
  // ===========================================================================
  Widget _buildRotationTab(RotationCompatibilityPrediction item, AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compatibility Hero Meter
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            children: [
              // Radial Synergy Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: item.score / 100.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.white,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.score}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        s.kSynergyLabel,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.compatibilityLevel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.kOptimalCropPrefix} ${item.suggestedCrop}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${s.kCropPrefix} $_selectedCrop',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 12, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Text(
                          item.suggestedCrop,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
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
        const SizedBox(height: 16),

        // Pest Corridor Alert Banner
        if (item.hasSpatialCorridorRisk) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconBadge(
                  icon: Icons.pest_control_rounded,
                  color: const Color(0xFFE65100),
                  bgColor: Colors.white,
                  size: 24,
                  containerSize: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.kCorridorRiskTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.kCorridorRiskDescription,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF5D4037)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Agroecological Justification Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBadge(
                    icon: Icons.agriculture_rounded,
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    size: 18,
                    containerSize: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.kAgroJustificationTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E2D24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.explanation,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildIconBadge(
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    size: 16,
                    containerSize: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.kAlternativeCropsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF1E2D24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.alternativeCrops.map((c) {
                  final altCropIcon = _getCropIcon(c);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(altCropIcon, size: 14, color: const Color(0xFF1B5E20)),
                        const SizedBox(width: 6),
                        Text(
                          c,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. PREDICCIÓN DE SIEMBRA Y GDD
  // ===========================================================================
  Widget _buildCalendarTab(PlantingCalendarPrediction item, AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Planting Window Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.isWindowOpen
                  ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                  : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isWindowOpen
                  ? const Color(0xFFA5D6A7)
                  : const Color(0xFFFFD54F),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBadge(
                    icon: item.isWindowOpen
                        ? Icons.calendar_month_rounded
                        : Icons.schedule_rounded,
                    color: item.isWindowOpen
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFE65100),
                    bgColor: Colors.white,
                    size: 26,
                    containerSize: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.windowStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: item.isWindowOpen
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFFE65100),
                          ),
                        ),
                        Text(
                          '${s.kRecommendedRangePrefix} ${item.recommendedDateRange}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.thermalAdvice,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFD84315),
                bgColor: const Color(0xFFFBE9E7),
                title: s.kMetricThermalSumGdd,
                value: '${item.accumulatedGdd7d} GDD',
                subtitle: s.kMetricThermalSumGddSub,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.local_florist_rounded,
                color: const Color(0xFF6A1B9A),
                bgColor: const Color(0xFFF3E5F5),
                title: s.kMetricDaysToFlowering,
                value: '~${item.estimatedDaysToFlowering} ${s.kDaysUnit}',
                subtitle: '${s.kCropPrefix} $_selectedCrop',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. PREDICCIÓN DE VIGOR Y NDVI PROXY
  // ===========================================================================
  Widget _buildHealthTab(CropHealthPrediction item, AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Biomass Vigor Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFAED581)),
          ),
          child: Row(
            children: [
              _buildIconBadge(
                icon: Icons.eco_rounded,
                color: const Color(0xFF1B5E20),
                bgColor: Colors.white,
                size: 28,
                containerSize: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.vigorStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.biomassCondition,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.satellite_alt_rounded,
                color: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                title: s.kMetricNdviProxy,
                value: '${item.estimatedNdviProxy}',
                subtitle: s.kMetricNdviProxySub,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                title: s.kMetricRelativeYield,
                value: '${item.expectedYieldRatioPct}%',
                subtitle: s.kMetricRelativeYieldSub,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. ALERTAS CLIMÁTICAS EXTREMAS
  // ===========================================================================
  Widget _buildRisksTab(ExtremeRiskAlert item, AppStrings s) {
    final bool isDanger = item.severity == 'danger';
    final bool isWarning = item.severity == 'warning';

    final Color cardColor = isDanger
        ? const Color(0xFFFFEBEE)
        : (isWarning ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9));
    final Color borderColor = isDanger
        ? const Color(0xFFFFCDD2)
        : (isWarning ? const Color(0xFFFFECB3) : const Color(0xFFC8E6C9));
    final Color textColor = isDanger
        ? const Color(0xFFC62828)
        : (isWarning ? const Color(0xFFF57F17) : const Color(0xFF2E7D32));
    final IconData riskIcon = isDanger
        ? Icons.warning_rounded
        : (isWarning ? Icons.report_problem_rounded : Icons.shield_rounded);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBadge(
                    icon: riskIcon,
                    color: textColor,
                    bgColor: Colors.white,
                    size: 26,
                    containerSize: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.headline,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  item.mitigationAdvice,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade900,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. NUTRICIÓN Y BALANCE DE NITRÓGENO
  // ===========================================================================
  Widget _buildNutritionTab(SoilNutritionPrediction item, AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fertilizer Sack Savings Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFAED581)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBadge(
                    icon: Icons.savings_rounded,
                    color: const Color(0xFF1B5E20),
                    bgColor: Colors.white,
                    size: 20,
                    containerSize: 34,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.kMetricBiologicalNFixation,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.eco_rounded,
                                  size: 14, color: Color(0xFF1B5E20)),
                              const SizedBox(width: 4),
                              Text(s.kBiologicalNFixationPerHa,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.projectedNitrogenGainKgPerHa > 0 ? '+' : ''}${item.projectedNitrogenGainKgPerHa} kg/ha',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_rounded,
                                  size: 14, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Text(s.kUreaSavingsShort,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '~${item.estimatedUreaSavingsKg.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.regenerationDiagnosis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildMetricCard(
          icon: Icons.science_rounded,
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          title: s.kMetricSoilHealthScore,
          value: '${item.soilHealthScore} / 100',
          subtitle: s.kMetricSoilHealthScoreSub,
        ),
      ],
    );
  }

  // ===========================================================================
  // METRIC CARD BUILDER - ZERO EMOJIS COMPLIANCE
  // ===========================================================================
  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBadge(
                icon: icon,
                color: color,
                bgColor: bgColor,
                size: 16,
                containerSize: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2D24),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WHAT-IF SCENARIO SIMULATOR DIALOG
  // ===========================================================================
  void _showWhatIfSimulatorDialog(AppStrings s) {
    String tempCrop = _selectedCrop;
    String tempSoil = _selectedSoil;

    final soilOptionsLocalized = [
      {'key': 'Franco', 'desc': s.kSoilBalancedDesc},
      {'key': 'Arcilloso', 'desc': s.kSoilClayDesc},
      {'key': 'Arenoso', 'desc': s.kSoilSandyDesc},
      {'key': 'Limoso', 'desc': s.kSoilSiltDesc},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildIconBadge(
                        icon: Icons.tune_rounded,
                        color: const Color(0xFF1B5E20),
                        bgColor: const Color(0xFFE8F5E9),
                        size: 20,
                        containerSize: 36,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.kSimulatorTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.kSimulatorCropQuestion,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: tempCrop,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F6F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: _cropOptions.map((c) {
                      final cIcon = _getCropIcon(c);
                      return DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(cIcon, size: 16, color: const Color(0xFF2E7D32)),
                            const SizedBox(width: 8),
                            Text(c),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => tempCrop = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.kSimulatorSoilQuestion,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: soilOptionsLocalized.firstWhere(
                      (item) => item['key']!
                          .toLowerCase()
                          .contains(tempSoil.toLowerCase()),
                      orElse: () => soilOptionsLocalized.first,
                    )['key'],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F6F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: soilOptionsLocalized.map((item) {
                      return DropdownMenuItem(
                        value: item['key'],
                        child: Text(
                          item['desc']!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => tempSoil = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.calculate_rounded),
                      label: Text(
                        s.kSimulatorApplyButton,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCrop = tempCrop;
                          _selectedSoil = tempSoil;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // IVY CHAT SHEET OPENER
  // ===========================================================================
  void _openIvySheet(FarmPredictionsReport report, AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PredictionsIvyChatSheet(
          farmData: _farm ?? {},
          nasaData: _nasaData ?? NasaPowerService.getFallbackData(),
          report: report,
          graph: _graph,
          subplots: _subplots,
          activeCrop: _selectedCrop,
          activeSoil: _selectedSoil,
          s: s,
        );
      },
    );
  }
}

// =============================================================================
// IVY AI CHAT SHEET FOR PREDICTIONS
// =============================================================================
class _PredictionsIvyChatSheet extends StatefulWidget {
  final Map<String, dynamic> farmData;
  final Map<String, dynamic> nasaData;
  final FarmPredictionsReport report;
  final SubplotGraph? graph;
  final List<Map<String, dynamic>> subplots;
  final String activeCrop;
  final String activeSoil;
  final AppStrings s;

  const _PredictionsIvyChatSheet({
    required this.farmData,
    required this.nasaData,
    required this.report,
    required this.graph,
    required this.subplots,
    required this.activeCrop,
    required this.activeSoil,
    required this.s,
  });

  @override
  State<_PredictionsIvyChatSheet> createState() =>
      _PredictionsIvyChatSheetState();
}

class _PredictionsIvyChatSheetState extends State<_PredictionsIvyChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _askIvy(widget.s.kIvyInitialPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askIvy(String query) async {
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await AzureAiService.askIvy(
        userQuery: query,
        farmData: widget.farmData,
        nasaData: widget.nasaData,
        predictionsReport: widget.report,
        graph: widget.graph,
        subplots: widget.subplots,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'text': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': widget.s.kIvyErrorMessage,
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFFFFD54F), size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.s.kIvyCopilotTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.activeCrop} • ${widget.s.kSoilPrefix} ${widget.activeSoil} • gpt-5-mini',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, index) {
                if (index == _messages.length && _isLoading) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCEDC8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.s.kIvyAnalyzingScenario,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFF7FAF7),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isUser
                            ? const Radius.circular(18)
                            : const Radius.circular(4),
                        bottomRight: isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isUser ? Colors.white : const Color(0xFF1E2D24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: widget.s.kIvyInputHint,
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF1F6F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (t) {
                      final q = t.trim();
                      if (q.isNotEmpty && !_isLoading) {
                        _controller.clear();
                        _askIvy(q);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: Color(0xFF1B5E20)),
                  onPressed: () {
                    final q = _controller.text.trim();
                    if (q.isNotEmpty && !_isLoading) {
                      _controller.clear();
                      _askIvy(q);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
