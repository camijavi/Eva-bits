import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/nasa_power_service.dart';
import '../services/agro_prediction_engine.dart';
import '../services/eve_knowledge_base.dart';
import '../services/subplot_graph_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/eve_animated_avatar.dart';

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
  List<Map<String, dynamic>> _lots = [];
  List<Map<String, dynamic>> _subplots = [];
  bool _isLoading = true;

  // Active filter / simulator
  int? _activeSubplotId;
  String _selectedContextValue = 'farm';
  String _selectedCrop = 'Maíz';
  String _selectedSoil = 'Franco';

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
          _lots = lotsWithSubplots;
          final List<Map<String, dynamic>> flat = [];
          for (final lot in lotsWithSubplots) {
            final lotCrop = lot['crop']?.toString();
            final spList = lot['subplots'] as List<dynamic>? ?? [];
            for (final sp in spList) {
              if (sp is Map<String, dynamic>) {
                final copy = Map<String, dynamic>.from(sp);
                copy['lot_name'] = lot['name'] ?? 'Lote';
                if ((copy['crop'] == null ||
                        copy['crop'].toString().trim().isEmpty) &&
                    lotCrop != null &&
                    lotCrop.isNotEmpty) {
                  copy['crop'] = lotCrop;
                }
                flat.add(copy);
              }
            }
          }
          _subplots = flat;

          if (_activeSubplotId != null) {
            _selectedContextValue = 'sub:$_activeSubplotId';
            final found = _subplots.firstWhere(
              (s) => s['id'] == _activeSubplotId,
              orElse: () => _subplots.isNotEmpty ? _subplots.first : {},
            );
            if (found.isNotEmpty) {
              _selectedCrop = EveKnowledgeBase.normalizeCropName(
                  found['crop']?.toString());
              _selectedSoil = EveKnowledgeBase.normalizeSoilName(
                  found['soil_type']?.toString());
            }
          } else if (_subplots.isNotEmpty) {
            _selectedContextValue = 'farm';
            _selectedCrop = EveKnowledgeBase.normalizeCropName(
                _subplots.first['crop']?.toString());
            _selectedSoil = EveKnowledgeBase.normalizeSoilName(
                _subplots.first['soil_type']?.toString());
          } else if (_lots.isNotEmpty) {
            _selectedContextValue = 'farm';
            _selectedCrop = EveKnowledgeBase.normalizeCropName(
                _lots.first['crop']?.toString());
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

  void _onContextDropdownChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedContextValue = val;
      if (val == 'farm') {
        _activeSubplotId = null;
      } else if (val.startsWith('lot:')) {
        final lotId = int.tryParse(val.substring(4));
        _activeSubplotId = null;
        if (lotId != null) {
          final matchLot = _lots.firstWhere(
            (l) => l['id'] == lotId,
            orElse: () => {},
          );
          if (matchLot.isNotEmpty) {
            final spList = matchLot['subplots'] as List<dynamic>? ?? [];
            if (spList.isNotEmpty && spList.first is Map<String, dynamic>) {
              final firstSp = spList.first as Map<String, dynamic>;
              _selectedCrop = EveKnowledgeBase.normalizeCropName(
                  (matchLot['crop'] ?? firstSp['crop'])?.toString());
              _selectedSoil = EveKnowledgeBase.normalizeSoilName(
                  firstSp['soil_type']?.toString());
            } else {
              _selectedCrop = EveKnowledgeBase.normalizeCropName(
                  matchLot['crop']?.toString());
            }
          }
        }
      } else if (val.startsWith('sub:')) {
        final subplotId = int.tryParse(val.substring(4));
        _activeSubplotId = subplotId;
        if (subplotId != null) {
          final match = _subplots.firstWhere(
            (s) => s['id'] == subplotId,
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            _selectedCrop = EveKnowledgeBase.normalizeCropName(
                match['crop']?.toString());
            _selectedSoil = EveKnowledgeBase.normalizeSoilName(
                match['soil_type']?.toString());
          }
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
            backgroundColor: AppColors.getBackground(context),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(s.kPredictionsTitle),
              backgroundColor: AppColors.getHeaderBg(context),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final report = _generateCurrentReport(s);

        return Scaffold(
          backgroundColor: AppColors.getBackground(context),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: AppColors.getHeaderBg(context),
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
              // Interactive Parcel Context Dropdown & Weekly Evolution Banner
              _buildInteractiveContextBar(report, s),

              // The 6 Prediction Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIrrigationTab(report.irrigation, s),
                    _buildRotationTab(report.rotation, s),
                    _buildCalendarTab(report, s),
                    _buildHealthTab(report.health, s),
                    _buildRisksTab(report.risks, s),
                    _buildNutritionTab(report.nutrition, s),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: EveFloatingLauncherButton(
            tooltip: s.kAskIvyTooltip,
            farmData: _farm,
            nasaData: _nasaData,
            report: report,
            graph: _graph,
            subplots: _subplots,
            activeCrop: _selectedCrop,
            activeSoil: _selectedSoil,
          ),
          bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
        );
      },
    );
  }

  // ===========================================================================
  // INTERACTIVE CONTEXT BAR & WEEKLY NOTIFICATION BANNER
  // ===========================================================================
  Widget _buildInteractiveContextBar(
      FarmPredictionsReport report, AppStrings s) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                  color: isDark ? AppColors.primaryLight : const Color(0xFF1B5E20),
                  bgColor: isDark ? const Color(0xFF1E3024) : const Color(0xFFE8F5E9),
                  size: 16,
                  containerSize: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.kPredictionContext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // What-If Simulator Button
                Flexible(
                  flex: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showWhatIfSimulatorDialog(s),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF1E3024), Color(0xFF263D2E)]
                                : const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFA5D6A7),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: isDark ? AppColors.primaryLight : const Color(0xFF1B5E20),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                s.kWhatIfSimulator,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.primaryLight : const Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dropdown Field for Lots & Subplots
          _buildLotSubplotDropdown(s),

          // Weekly (+7 Days) Evolution Notification Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showWeeklyDeltaDialog(report, s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2414) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4A381E) : const Color(0xFFFFE082),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.kWeeklyNotificationBannerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFFCC80) : const Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOT & SUBPLOT DROPDOWN FIELD
  // ===========================================================================
  Widget _buildLotSubplotDropdown(AppStrings s) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textMuted = AppColors.getTextMuted(context);

    final validValues = <String>{'farm'};
    for (final lot in _lots) {
      validValues.add('lot:${lot['id']}');
    }
    for (final sp in _subplots) {
      validValues.add('sub:${sp['id']}');
    }
    final effectiveValue =
        validValues.contains(_selectedContextValue) ? _selectedContextValue : 'farm';

    final items = <DropdownMenuItem<String>>[
      // Option 0: Whole Farm General
      DropdownMenuItem<String>(
        value: 'farm',
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF24362B) : const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.nature_people_rounded,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.kWholeFarmGeneral,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '$_selectedCrop • $_selectedSoil',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    for (final lot in _lots) {
      final lotId = lot['id'];
      final lotName = lot['name']?.toString() ?? '${s.kLot} $lotId';
      final lotSurface = lot['surface']?.toString() ?? '0';
      final lotCrop = lot['crop']?.toString() ?? _selectedCrop;
      final lotIcon = _getCropIcon(lotCrop);

      items.add(
        DropdownMenuItem<String>(
          value: 'lot:$lotId',
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B3028) : const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFB2DFDB),
                  ),
                ),
                child: Icon(
                  lotIcon,
                  color: isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${s.kLot}: $lotName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '$lotCrop • $lotSurface ha',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final spList = lot['subplots'] as List<dynamic>? ?? [];
      for (final sp in spList) {
        if (sp is! Map<String, dynamic>) continue;
        final spId = sp['id'];
        final spName = sp['name']?.toString() ?? '${s.kSubplot} $spId';
        final spCrop = sp['crop']?.toString() ?? s.kDefaultCropName;
        final spSoil = sp['soil_type']?.toString() ?? s.kDefaultSoilName;
        final spSurface = sp['surface']?.toString() ?? '1.0';
        final spIcon = _getCropIcon(spCrop);

        items.add(
          DropdownMenuItem<String>(
            value: 'sub:$spId',
            child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3024) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFC8E6C9),
                  ),
                ),
                child: Icon(
                  spIcon,
                  color: isDark ? AppColors.primaryLight : const Color(0xFF2E7D32),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$lotName › $spName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '$spCrop ($spSoil) • $spSurface ha',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
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
  }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.getInputBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFA5D6A7),
            width: 1.4,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: effectiveValue,
            isExpanded: true,
            itemHeight: 52,
            menuMaxHeight: 260,
            elevation: 4,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary.withValues(alpha: 0.22) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.primaryLight : const Color(0xFF1B5E20),
                size: 20,
              ),
            ),
            dropdownColor: AppColors.getCardBg(context),
            borderRadius: BorderRadius.circular(16),
            items: items,
            onChanged: _onContextDropdownChanged,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. PREDICCIÓN DE RIEGO Y DÉFICIT
  // ===========================================================================
  Widget _buildIrrigationTab(IrrigationPrediction item, AppStrings s) {
    final isDark = AppColors.isDark(context);
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : Colors.grey.shade700),
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
                  color: AppColors.getCardBg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                ),
                child: Text(
                  item.actionRecommendation,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextPrimary(context),
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
            color: isDark ? const Color(0xFF221C16) : const Color(0xFFFAF6F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3E3228) : const Color(0xFFE0D7C6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconBadge(
                icon: Icons.terrain_rounded,
                color: const Color(0xFF5D4037),
                bgColor: isDark ? const Color(0xFF33261C) : const Color(0xFFEFEBE9),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFE5D5C5)
                            : const Color(0xFF4A3E2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      EveKnowledgeBase.getSoilScientificConcept(_selectedSoil),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextPrimary(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Precision Irrigation Systems Catalog (NASA-ISRO & CIAT)
        _buildIrrigationSystemsCatalog(item, s),
      ],
    );
  }

  Widget _buildIrrigationSystemsCatalog(
      IrrigationPrediction item, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final systems = EveKnowledgeBase.getIrrigationSystemsForSoil(
      soilType: _selectedSoil,
      recommendedWaterMm: item.recommendedWaterMm,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFC8E6C9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBadge(
                icon: Icons.opacity_rounded,
                color: const Color(0xFF0277BD),
                bgColor: isDark ? const Color(0xFF162D3D) : const Color(0xFFE1F5FE),
                size: 20,
                containerSize: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.kIrrigationSystemsSectionTitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      s.kIrrigationSystemsSectionSub,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...systems.map((sys) {
            final isRec = sys.isRecommendedForCurrentSoil;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRec
                    ? (isDark ? const Color(0xFF1B2F21) : const Color(0xFFF1F8E9))
                    : (isDark ? const Color(0xFF1A261F) : const Color(0xFFF9FAFB)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRec
                      ? const Color(0xFF2E7D32)
                      : (isDark ? AppColors.borderDark : Colors.grey.shade200),
                  width: isRec ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isRec
                            ? Icons.verified_rounded
                            : Icons.water_drop_outlined,
                        size: 16,
                        color: isRec
                            ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20))
                            : const Color(0xFF0277BD),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sys.systemName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isRec
                                ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20))
                                : AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      if (isRec)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            s.kRecommendedSystemBadge,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${s.kEfficiencyLabel} ${sys.efficiencyPct}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0277BD),
                        ),
                      ),
                      Text(
                        '• ${s.kBestForSoilLabel} ${sys.bestForSoil}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMutedDark : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sys.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getTextPrimary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sys.nasaIntegrationNote,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. PREDICCIÓN DE ROTACIÓN Y COMPATIBILIDAD ESPACIAL
  // ===========================================================================
  Widget _buildRotationTab(RotationCompatibilityPrediction item, AppStrings s) {
    final isDark = AppColors.isDark(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Compatibility Hero Meter
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1B2F22), const Color(0xFF14241A)]
                  : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2E4E36) : const Color(0xFFC8E6C9),
            ),
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
                      backgroundColor: isDark ? const Color(0xFF26382C) : Colors.white,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.score}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
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
                        Flexible(
                          child: Text(
                            '${s.kCropPrefix} $_selectedCrop',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 12, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.suggestedCrop,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pest Corridor Alert Banner
        if (item.hasSpatialCorridorRisk) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF332014), const Color(0xFF26180E)]
                    : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF6B3A1A) : const Color(0xFFFFB74D),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconBadge(
                  icon: Icons.pest_control_rounded,
                  color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                  bgColor: isDark ? const Color(0xFF45220E) : Colors.white,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.kCorridorRiskDescription,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFE2C4A8) : const Color(0xFF5D4037)),
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
            color: AppColors.getCardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBadge(
                    icon: Icons.agriculture_rounded,
                    color: const Color(0xFF2E7D32),
                    bgColor: isDark ? const Color(0xFF1E3024) : const Color(0xFFE8F5E9),
                    size: 18,
                    containerSize: 30,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.kAgroJustificationTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.explanation,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextPrimary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildIconBadge(
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF2E7D32),
                    bgColor: isDark ? const Color(0xFF1E3024) : const Color(0xFFE8F5E9),
                    size: 16,
                    containerSize: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.kAlternativeCropsTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.getTextPrimary(context),
                      ),
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
                      color: isDark ? AppColors.chipBgDark : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark ? AppColors.chipBorderDark : const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(altCropIcon,
                            size: 14,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20)),
                        const SizedBox(width: 6),
                        Text(
                          c,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
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
  // 3. PREDICCIÓN DE SIEMBRA, GDD Y PROYECCIÓN TRI-SEMANAL (21 DÍAS)
  // ===========================================================================
  Widget _buildCalendarTab(FarmPredictionsReport report, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final item = report.calendar;
    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;

    final projection3w = EveKnowledgeBase.generateThreeWeekProjection(
      crop: _selectedCrop,
      soilType: _selectedSoil,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisturePct: report.irrigation.soilMoisturePct,
      weeklyDeficitMm: report.irrigation.weeklyDeficitMm,
      accumulatedGdd7d: item.accumulatedGdd7d,
      suggestedRotationCrop: report.rotation.suggestedCrop,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Planting Window Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.isWindowOpen
                  ? (isDark
                      ? [const Color(0xFF1E3324), const Color(0xFF16261B)]
                      : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)])
                  : (isDark
                      ? [const Color(0xFF332A15), const Color(0xFF241D0E)]
                      : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isWindowOpen
                  ? (isDark ? const Color(0xFF2E5A38) : const Color(0xFFA5D6A7))
                  : (isDark ? const Color(0xFF6B5820) : const Color(0xFFFFD54F)),
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
                        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20))
                        : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
                    bgColor: isDark ? const Color(0xFF26382C) : Colors.white,
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
                                ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20))
                                : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
                          ),
                        ),
                        Text(
                          '${s.kRecommendedRangePrefix} ${item.recommendedDateRange}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
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
                  color: isDark ? const Color(0xFF1E2821) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.thermalAdvice,
                  style: TextStyle(fontSize: 11, color: AppColors.getTextPrimary(context)),
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
                bgColor: isDark ? const Color(0xFF35201B) : const Color(0xFFFBE9E7),
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
                bgColor: isDark ? const Color(0xFF2E1C38) : const Color(0xFFF3E5F5),
                title: s.kMetricDaysToFlowering,
                value: '~${item.estimatedDaysToFlowering} ${s.kDaysUnit}',
                subtitle: '${s.kCropPrefix} $_selectedCrop',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3-Week Rolling Projection Card (From Date X to Date Y)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCardBg(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFC8E6C9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBadge(
                    icon: Icons.date_range_rounded,
                    color: const Color(0xFF1B5E20),
                    bgColor: isDark ? const Color(0xFF1E3024) : const Color(0xFFE8F5E9),
                    size: 20,
                    containerSize: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.kThreeWeekProjectionTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          '${projection3w.fullDateRange} • ${s.kThreeWeekProjectionSub}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...projection3w.phases.map((phase) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B271F) : const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE0E7E1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              phase.dateRangeLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phase.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        phase.expectedMetrics,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0277BD),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phase.recommendedAction,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextPrimary(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              Text(
                projection3w.longTermClimateNote,
                style: TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.getTextMuted(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. PREDICCIÓN DE VIGOR Y NDVI PROXY
  // ===========================================================================
  Widget _buildHealthTab(CropHealthPrediction item, AppStrings s) {
     final isDark = AppColors.isDark(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Biomass Vigor Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3324), const Color(0xFF16261B)]
                  : [const Color(0xFFE8F5E9), const Color(0xFFDCEDC8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2E5A38) : const Color(0xFFAED581),
            ),
          ),
          child: Row(
            children: [
              _buildIconBadge(
                icon: Icons.eco_rounded,
                color: const Color(0xFF1B5E20),
                bgColor: isDark ? const Color(0xFF26382C) : Colors.white,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.biomassCondition,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextPrimary(context)),
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
    final isDark = AppColors.isDark(context);
    final bool isDanger = item.severity == 'danger';
    final bool isWarning = item.severity == 'warning';

    final Color cardColor = isDark
        ? (isDanger
            ? const Color(0xFF3B1A1E)
            : (isWarning ? const Color(0xFF3D2E14) : const Color(0xFF1B2F22)))
        : (isDanger
            ? const Color(0xFFFFEBEE)
            : (isWarning ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9)));
    final Color borderColor = isDark
        ? (isDanger
            ? const Color(0xFF6B2A30)
            : (isWarning ? const Color(0xFF6E5220) : const Color(0xFF2E4E36)))
        : (isDanger
            ? const Color(0xFFFFCDD2)
            : (isWarning ? const Color(0xFFFFECB3) : const Color(0xFFC8E6C9)));
    final Color textColor = isDark
        ? (isDanger
            ? const Color(0xFFEF5350)
            : (isWarning ? const Color(0xFFFFB74D) : const Color(0xFF81C784)))
        : (isDanger
            ? const Color(0xFFC62828)
            : (isWarning ? const Color(0xFFF57F17) : const Color(0xFF2E7D32)));
    final IconData riskIcon = isDanger
        ? Icons.warning_rounded
        : (isWarning ? Icons.report_problem_rounded : Icons.shield_rounded);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                    bgColor: isDark
                        ? (isDanger
                            ? const Color(0xFF4A2025)
                            : (isWarning ? const Color(0xFF4A3816) : const Color(0xFF26382C)))
                        : Colors.white,
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
                  color: isDark ? const Color(0xFF1E2821) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  item.mitigationAdvice,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextPrimary(context),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Crop-Specific Pest & Disease Warnings (Biotech Corpus)
        _buildCropPestsSection(s),
        const SizedBox(height: 16),

        // Natural Phenomena & Compound Climate Warnings (NASA GPM / SMAP / GRACE)
        _buildNaturalPhenomenaSection(s),
      ],
    );
  }

  Widget _buildCropPestsSection(AppStrings s) {
    final isDark = AppColors.isDark(context);
    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final pests = EveKnowledgeBase.getPestWarningsForCrop(
      crop: _selectedCrop,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      soilType: _selectedSoil,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFFFCCBC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBadge(
                icon: Icons.pest_control_rounded,
                color: const Color(0xFFD84315),
                bgColor: isDark ? const Color(0xFF35201B) : const Color(0xFFFBE9E7),
                size: 20,
                containerSize: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.kCropPestsSectionTitle} ($_selectedCrop)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      '${s.kSoilPrefix} $_selectedSoil',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pests.map((p) {
            final isHigh = p.riskLevel == 'high';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHigh
                    ? (isDark ? const Color(0xFF351C1B) : const Color(0xFFFFF8F6))
                    : (isDark ? const Color(0xFF1E2821) : const Color(0xFFF9FAFB)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHigh
                      ? (isDark ? const Color(0xFF6B2B28) : const Color(0xFFFFAB91))
                      : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isHigh
                            ? Icons.bug_report_rounded
                            : Icons.visibility_rounded,
                        size: 16,
                        color: isHigh
                            ? const Color(0xFFC62828)
                            : const Color(0xFFF57F17),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${p.pestName} (${p.scientificName})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isHigh
                              ? const Color(0xFFC62828)
                              : const Color(0xFFF57F17),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isHigh ? s.kHighRiskBadge : s.kModerateRiskBadge,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    p.climateTrigger,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD84315),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.symptomsAndImpact,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getTextPrimary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${s.kPreventionLabel} ${p.preventionAction}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNaturalPhenomenaSection(AppStrings s) {
    final isDark = AppColors.isDark(context);
    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final solarMj =
        (summary['avg_solar_radiation_mj'] as num?)?.toDouble() ?? 18.5;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final phenomena = EveKnowledgeBase.evaluateNaturalPhenomena(
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      solarMj: solarMj,
      soilType: _selectedSoil,
      crop: _selectedCrop,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFBBDEFB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBadge(
                icon: Icons.thunderstorm_rounded,
                color: const Color(0xFF1565C0),
                bgColor: isDark ? const Color(0xFF162D3D) : const Color(0xFFE3F2FD),
                size: 20,
                containerSize: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.kNaturalPhenomenaSectionTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...phenomena.map((ph) {
            final isDanger = ph.severity == 'danger';
            final isWarn = ph.severity == 'warning';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDanger
                    ? (isDark ? const Color(0xFF351C1B) : const Color(0xFFFFF8F6))
                    : (isWarn
                        ? (isDark ? const Color(0xFF383018) : const Color(0xFFFFFDE7))
                        : (isDark ? const Color(0xFF162536) : const Color(0xFFF5F9FF))),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDanger
                      ? (isDark ? const Color(0xFF6B2B28) : const Color(0xFFFFCDD2))
                      : (isWarn
                          ? (isDark ? const Color(0xFF6E5E20) : const Color(0xFFFFF59D))
                          : (isDark ? const Color(0xFF264566) : const Color(0xFFBBDEFB))),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDanger
                            ? Icons.warning_amber_rounded
                            : Icons.satellite_alt_rounded,
                        size: 16,
                        color: isDanger
                            ? const Color(0xFFC62828)
                            : const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ph.phenomenonName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ph.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getTextPrimary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${s.kPreventionLabel} ${ph.preventionMeasure}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. NUTRICIÓN Y BALANCE DE NITRÓGENO
  // ===========================================================================
  Widget _buildNutritionTab(SoilNutritionPrediction item, AppStrings s) {
    final isDark = AppColors.isDark(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Fertilizer Sack Savings Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3324), const Color(0xFF16261B)]
                  : [const Color(0xFFE8F5E9), const Color(0xFFDCEDC8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2E5A38) : const Color(0xFFAED581),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBadge(
                    icon: Icons.savings_rounded,
                    color: const Color(0xFF1B5E20),
                    bgColor: isDark ? const Color(0xFF26382C) : Colors.white,
                    size: 20,
                    containerSize: 34,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.kMetricBiologicalNFixation,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                      ),
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
                        color: isDark ? const Color(0xFF1E2821) : Colors.white,
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
                              Flexible(
                                child: Text(s.kBiologicalNFixationPerHa,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textMutedDark : Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.projectedNitrogenGainKgPerHa > 0 ? '+' : ''}${item.projectedNitrogenGainKgPerHa} kg/ha',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
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
                        color: isDark ? const Color(0xFF1E2821) : Colors.white,
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
                              Flexible(
                                child: Text(s.kUreaSavingsShort,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textMutedDark : Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '~${item.estimatedUreaSavingsKg.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
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
                  color: isDark
                      ? const Color(0xFF1E2821)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.regenerationDiagnosis,
                  style: TextStyle(fontSize: 11, color: AppColors.getTextPrimary(context)),
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
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                color: isDark ? AppColors.primaryLight : color,
                bgColor: isDark ? color.withValues(alpha: 0.22) : bgColor,
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
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: AppColors.getTextMuted(context)),
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
        final isDark = AppColors.isDark(ctx);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.getModalBg(ctx),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
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
                            bgColor: isDark ? const Color(0xFF1E3024) : const Color(0xFFE8F5E9),
                            size: 20,
                            containerSize: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.kSimulatorTitle,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextPrimary(ctx)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: AppColors.getTextPrimary(ctx)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.kSimulatorCropQuestion,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(ctx)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        menuMaxHeight: 260,
                        initialValue: tempCrop,
                        dropdownColor: AppColors.getCardBg(ctx),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.getInputBg(ctx),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.getBorder(ctx)),
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
                                Icon(cIcon,
                                    size: 16, color: const Color(0xFF2E7D32)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                        color: AppColors.getTextPrimary(ctx)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(ctx)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        menuMaxHeight: 260,
                        dropdownColor: AppColors.getCardBg(ctx),
                        initialValue: soilOptionsLocalized.firstWhere(
                          (item) => item['key']!
                              .toLowerCase()
                              .contains(tempSoil.toLowerCase()),
                          orElse: () => soilOptionsLocalized.first,
                        )['key'],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.getInputBg(ctx),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: soilOptionsLocalized.map((item) {
                          return DropdownMenuItem(
                            value: item['key'],
                            child: Text(
                              item['desc']!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getTextPrimary(ctx)),
                              overflow: TextOverflow.ellipsis,
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
                            overflow: TextOverflow.ellipsis,
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // WEEKLY (+7 DAYS) EVOLUTION NOTIFICATION DIALOG
  // ===========================================================================
  void _showWeeklyDeltaDialog(FarmPredictionsReport report, AppStrings s) {
    final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;

    final projection3w = EveKnowledgeBase.generateThreeWeekProjection(
      crop: _selectedCrop,
      soilType: _selectedSoil,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisturePct: report.irrigation.soilMoisturePct,
      weeklyDeficitMm: report.irrigation.weeklyDeficitMm,
      accumulatedGdd7d: report.calendar.accumulatedGdd7d,
      suggestedRotationCrop: report.rotation.suggestedCrop,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = AppColors.isDark(ctx);

        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.getModalBg(ctx),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildIconBadge(
                        icon: Icons.notifications_active_rounded,
                        color: const Color(0xFFE65100),
                        bgColor: isDark ? const Color(0xFF382315) : const Color(0xFFFFF3E0),
                        size: 20,
                        containerSize: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.kWeeklyDeltaDialogTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(ctx),
                              ),
                            ),
                            Text(
                              projection3w.weeklyCheckpointPeriod,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextMuted(ctx),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppColors.getTextPrimary(ctx)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    projection3w.weeklyCheckpointSummary,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextPrimary(ctx),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...projection3w.weeklyChangesDetected.map((change) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2B22) : const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFC8E6C9),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.analytics_rounded,
                              size: 16, color: Color(0xFF1B5E20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              change,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.getTextPrimary(ctx),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
