import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
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

  final List<String> _soilOptions = [
    'Franco (Equilibrado)',
    'Arcilloso (Alta retención / Infiltración lenta)',
    'Arenoso (Drenaje rápido / Baja retención)',
    'Limoso (Compactación superficial)',
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

        // Load graph & subplots
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

          // Select initial subplot if specified or fallback
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

        // Load NASA data for farm coordinates
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

  FarmPredictionsReport _generateCurrentReport() {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FBF8),
        appBar: AppBar(
          title: const Text('Predicciones Agroclimáticas'),
          backgroundColor: const Color(0xFF0F5A37),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final report = _generateCurrentReport();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F5A37),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Predicciones Agroclimáticas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF81C784),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'NASA POWER • SMAP L4 • Grafo Espacial',
                  style: TextStyle(fontSize: 10, color: Color(0xFFC8E6C9)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Consultar a Ivy AI',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => _openIvySheet(report),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFA5D6A7),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.water_drop_outlined, size: 20), text: 'Riego'),
            Tab(icon: Icon(Icons.eco_outlined, size: 20), text: 'Rotación'),
            Tab(
                icon: Icon(Icons.calendar_month_outlined, size: 20),
                text: 'Siembra (GDD)'),
            Tab(
                icon: Icon(Icons.energy_savings_leaf_outlined, size: 20),
                text: 'Vigor (NDVI)'),
            Tab(
                icon: Icon(Icons.warning_amber_rounded, size: 20),
                text: 'Alertas'),
            Tab(icon: Icon(Icons.science_outlined, size: 20), text: 'Nutrición'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subplot & Simulation Context Header Card
          _buildContextSelectorCard(),

          // The 6 Subdivided Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIrrigationTab(report.irrigation),
                _buildRotationTab(report.rotation),
                _buildCalendarTab(report.calendar),
                _buildHealthTab(report.health),
                _buildRisksTab(report.risks),
                _buildNutritionTab(report.nutrition),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        label: const Text(
          'Preguntar a Ivy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () => _openIvySheet(report),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  // ===========================================================================
  // SUBPLOT CONTEXT & SIMULATOR SELECTOR CARD
  // ===========================================================================
  Widget _buildContextSelectorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              const Text(
                'Contexto de Predicción:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2D24),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showWhatIfSimulatorDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.science_outlined,
                          size: 14, color: Color(0xFF1B5E20)),
                      SizedBox(width: 4),
                      Text(
                        'Simular qué pasa si...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subplot pills selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Toda la Finca (General)'),
                  selected: _activeSubplotId == null,
                  selectedColor: const Color(0xFFE8F5E9),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _activeSubplotId == null
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.shade700,
                  ),
                  onSelected: (_) => _onSubplotSelected(null),
                ),
                const SizedBox(width: 8),
                ..._subplots.map((sp) {
                  final id = sp['id'] as int;
                  final name = sp['name'] ?? 'Sublote $id';
                  final crop = sp['crop'] ?? 'Maíz';
                  final isSelected = _activeSubplotId == id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$name ($crop)'),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE8F5E9),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF1B5E20)
                            : Colors.grey.shade700,
                      ),
                      onSelected: (_) => _onSubplotSelected(id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Crop and Soil Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grass_rounded,
                        size: 12, color: Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Text(
                      'Cultivo: $_selectedCrop',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD7CCC8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.landscape_rounded,
                        size: 12, color: Color(0xFF5D4037)),
                    const SizedBox(width: 4),
                    Text(
                      'Suelo: $_selectedSoil',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. PREDICCIÓN DE RIEGO Y DÉFICIT
  // ===========================================================================
  Widget _buildIrrigationTab(IrrigationPrediction item) {
    final Color statusColor;
    final IconData statusIcon;
    if (item.status == 'critical') {
      statusColor = const Color(0xFFD32F2F);
      statusIcon = Icons.error_outline_rounded;
    } else if (item.status == 'moderate') {
      statusColor = const Color(0xFFF57F17);
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Alert Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.actionTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.actionRecommendation,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Key Quantitative Metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF0288D1),
                bgColor: const Color(0xFFE1F5FE),
                title: 'Humedad Radicular',
                value: '${item.soilMoisturePct}%',
                subtitle: 'NASA SMAP L4 proxy',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFFE65100),
                bgColor: const Color(0xFFFFF3E0),
                title: 'Déficit a 7 Días',
                value: '${item.weeklyDeficitMm} mm',
                subtitle: 'Evapotranspiración - lluvia',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFF5D4037),
                bgColor: const Color(0xFFEFEBE9),
                title: 'Días de Reserva',
                value: '${item.daysUntilStress} días',
                subtitle: 'Antes de marchitez',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.opacity_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                title: 'Lámina Requerida',
                value: '${item.recommendedWaterMm} mm',
                subtitle: 'Riego sugerido',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Soil Texture Explanation Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(width: 6),
                  Text(
                    '¿Cómo influye el tipo de suelo en el riego?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2D24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'En suelos arenosos el agua se filtra rápidamente, requiriendo riegos cortos más frecuentes. En suelos arcillosos, el agua se retiene por más tiempo pero existe riesgo de asfixia radicular si se sobre-irriga.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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
  Widget _buildRotationTab(RotationCompatibilityPrediction item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compatibility Score Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2E7D32),
                ),
                child: Center(
                  child: Text(
                    '${item.score}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.compatibilityLevel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2D24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sugerencia: ${item.suggestedCrop}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Spatial Corridor Risk Banner
        if (item.hasSpatialCorridorRisk) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE65100), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Corredor de Plagas Detectado por Grafo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Los sublotes vecinos comparten cultivos de la misma familia botánica. Rotar con leguminosas cortará la vía de propagación biológica.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Agronomic Explanation
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
              const Text(
                'Justificación Agroecológica:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E2D24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.explanation,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cultivos Alternativos Recomendados:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1E2D24),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.alternativeCrops.map((c) {
                  return Chip(
                    backgroundColor: const Color(0xFFE8F5E9),
                    label: Text(
                      c,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    avatar: const Icon(Icons.check,
                        size: 14, color: Color(0xFF2E7D32)),
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
  Widget _buildCalendarTab(PlantingCalendarPrediction item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isWindowOpen
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isWindowOpen
                  ? const Color(0xFFC8E6C9)
                  : const Color(0xFFFFECB3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.isWindowOpen
                        ? Icons.check_circle_rounded
                        : Icons.pause_circle_rounded,
                    color: item.isWindowOpen
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF57F17),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.windowStatus,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.isWindowOpen
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57F17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rango recomendado: ${item.recommendedDateRange}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.thermalAdvice,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
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
                iconColor: const Color(0xFFD84315),
                bgColor: const Color(0xFFFBE9E7),
                title: 'Suma Térmica (GDD)',
                value: '${item.accumulatedGdd7d} GDD',
                subtitle: 'Acumulación 7 días (Tbase 10°C)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.local_florist_rounded,
                iconColor: const Color(0xFF6A1B9A),
                bgColor: const Color(0xFFF3E5F5),
                title: 'Días a Floración',
                value: '~${item.estimatedDaysToFlowering} días',
                subtitle: 'Para $_selectedCrop',
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
  Widget _buildHealthTab(CropHealthPrediction item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.energy_savings_leaf_rounded,
                      color: Color(0xFF2E7D32), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    item.vigorStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.biomassCondition,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
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
                iconColor: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                title: 'NDVI Proxy',
                value: '${item.estimatedNdviProxy}',
                subtitle: 'Rango satelital 0.0 - 1.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                title: 'Rendimiento Relativo',
                value: '${item.expectedYieldRatioPct}%',
                subtitle: 'Del potencial máximo',
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
  Widget _buildRisksTab(ExtremeRiskAlert item) {
    final bool isDanger = item.severity == 'danger';
    final bool isWarning = item.severity == 'warning';

    final Color cardColor = isDanger
        ? const Color(0xFFFFEBEE)
        : (isWarning ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9));
    final Color borderColor = isDanger
        ? const Color(0xFFFFCDD2)
        : (isWarning ? const Color(0xFFFFECB3) : const Color(0xFFC8E6C9));
    final Color iconColor = isDanger
        ? const Color(0xFFC62828)
        : (isWarning ? const Color(0xFFF57F17) : const Color(0xFF2E7D32));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isDanger
                        ? Icons.warning_rounded
                        : (isWarning
                            ? Icons.report_problem_rounded
                            : Icons.shield_rounded),
                    color: iconColor,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.headline,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.mitigationAdvice,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade900,
                  height: 1.35,
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
  Widget _buildNutritionTab(SoilNutritionPrediction item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCEDC8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_rounded,
                      color: Color(0xFF33691E), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Fijación Biológica de Nitrógeno (FBN)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF33691E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.projectedNitrogenGainKgPerHa > 0 ? '+' : ''}${item.projectedNitrogenGainKgPerHa} kg/ha',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text('Balance de N por ha',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.estimatedUreaSavingsKg.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text('Ahorro en urea comercial',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.regenerationDiagnosis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildMetricCard(
          icon: Icons.eco_rounded,
          iconColor: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          title: 'Índice de Salud y Regeneración del Suelo',
          value: '${item.soilHealthScore} / 100',
          subtitle: 'Calculado según cultivo, textura y aporte orgánico',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
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
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WHAT-IF SCENARIO SIMULATOR DIALOG
  // ===========================================================================
  void _showWhatIfSimulatorDialog() {
    String tempCrop = _selectedCrop;
    String tempSoil = _selectedSoil;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
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
                      const Icon(Icons.science_rounded,
                          color: Color(0xFF2E7D32), size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Simulador de Cultivo y Suelo',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Qué cultivo deseas evaluar?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                    items: _cropOptions
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => tempCrop = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '¿Qué textura de suelo tiene la parcela?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _soilOptions.firstWhere(
                      (s) => s.toLowerCase().contains(tempSoil.toLowerCase()),
                      orElse: () => _soilOptions.first,
                    ),
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
                    items: _soilOptions
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          if (val.contains('Arcilloso')) tempSoil = 'Arcilloso';
                          else if (val.contains('Arenoso')) tempSoil = 'Arenoso';
                          else if (val.contains('Limoso')) tempSoil = 'Limoso';
                          else tempSoil = 'Franco';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCrop = tempCrop;
                          _selectedSoil = tempSoil;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Aplicar Simulación'),
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
  void _openIvySheet(FarmPredictionsReport report) {
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

  const _PredictionsIvyChatSheet({
    required this.farmData,
    required this.nasaData,
    required this.report,
    required this.graph,
    required this.subplots,
    required this.activeCrop,
    required this.activeSoil,
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
    _askIvy(
        'Explícame las predicciones para mi cultivo de ${widget.activeCrop} en suelo ${widget.activeSoil}.');
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
            'text':
                'Ocurrió un error al contactar a Ivy. Intenta nuevamente.',
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
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ivy • Copiloto Agroclimático',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.activeCrop} • Suelo ${widget.activeSoil} • gpt-5-mini',
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
                            'Ivy está analizando el escenario...',
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
                      borderRadius: BorderRadius.circular(16),
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
                      hintText: 'Pregunta sobre este sublote...',
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
