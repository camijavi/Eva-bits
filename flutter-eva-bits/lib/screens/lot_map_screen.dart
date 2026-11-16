import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/crop_types.dart';
import '../constants/soil_types.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';
import '../services/nasa_power_service.dart';
import '../services/agro_prediction_engine.dart';
import '../services/eve_knowledge_base.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/eve_animated_avatar.dart';
import '../widgets/new_edit_subplot.dart';

class EveSubplotInsight {
  final String alertType;
  final String severity; // 'critical', 'warning', 'info', 'opportunity', 'optimal'
  final String title;
  final String summary;
  final String recommendation;
  final IconData icon;
  final Color color;

  const EveSubplotInsight({
    required this.alertType,
    required this.severity,
    required this.title,
    required this.summary,
    required this.recommendation,
    required this.icon,
    required this.color,
  });

  bool get hasRisk => severity == 'critical' || severity == 'warning';
}

/// Interactive 2.5D Isometric Aerial Map for Farm Lots and Subplots.
/// Features lot switching, 2.5D tactile terrain rendering,
/// and real-time Eve AI risk and opportunity diagnostics.
class LotMapScreen extends StatefulWidget {
  final Map<String, dynamic>? lot;
  final String? surfaceUnit;

  const LotMapScreen({
    super.key,
    this.lot,
    this.surfaceUnit,
  });

  @override
  State<LotMapScreen> createState() => _LotMapScreenState();
}

class _LotMapScreenState extends State<LotMapScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allLots = [];
  Map<String, dynamic>? _currentLot;
  List<Map<String, dynamic>> _subplots = [];
  Map<int, List<Map<String, dynamic>>> _adjacencies = {};
  int? _selectedSubplotId;
  bool _isIsometricView = true;

  Map<String, dynamic>? _nasaData;
  double _soilMoistureIndex = 0.58;

  @override
  void initState() {
    super.initState();
    if (widget.lot != null) {
      _currentLot = Map<String, dynamic>.from(widget.lot!);
    }
    _loadAllLotsAndCurrentMap();
  }

  int get _lotId => _currentLot?['id'] as int? ?? 0;
  String get _surfaceUnit =>
      widget.surfaceUnit ?? AppSettings.getSurfaceUnitShort();
  double get _lotSurface =>
      (_currentLot?['surface'] as num?)?.toDouble() ?? 0.0;

  Future<void> _loadAllLotsAndCurrentMap() async {
    setState(() => _isLoading = true);
    try {
      final latestFarm = await DatabaseManager().getLatestFarm();
      int? farmId = latestFarm?['id'] as int?;
      farmId ??= await DatabaseManager().getOrCreateDefaultFarmId();

      final lots = await DatabaseManager().getAllLotsWithSubplots(farmId: farmId);

      Map<String, dynamic>? selectedLot = _currentLot;
      if (selectedLot == null && lots.isNotEmpty) {
        selectedLot = lots.first;
      } else if (selectedLot != null && lots.isNotEmpty) {
        final match = lots.firstWhere(
          (l) => l['id'] == selectedLot?['id'],
          orElse: () => lots.first,
        );
        selectedLot = match;
      }

      _allLots = lots;
      _currentLot = selectedLot;

      if (_currentLot != null) {
        await _loadSubplotsForSelectedLot();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }

      _fetchNasaClimate(latestFarm);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubplotsForSelectedLot() async {
    if (_lotId <= 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final updatedLot = await DatabaseManager().getLotById(_lotId);
      if (updatedLot != null) {
        _currentLot = updatedLot;
      }

      final subplots = await DatabaseManager().getSubplotsByLot(_lotId);

      final Map<int, List<Map<String, dynamic>>> adjMap = {};
      for (final sp in subplots) {
        final id = sp['id'] as int?;
        if (id != null) {
          final neighbors = await DatabaseManager().getSubplotAdjacencies(id);
          adjMap[id] = neighbors;
        }
      }

      if (mounted) {
        setState(() {
          _subplots = subplots;
          _adjacencies = adjMap;
          if (_subplots.isNotEmpty) {
            final stillExists = _subplots.any((s) => s['id'] == _selectedSubplotId);
            if (!stillExists || _selectedSubplotId == null) {
              _selectedSubplotId = _subplots.first['id'] as int?;
            }
          } else {
            _selectedSubplotId = null;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNasaClimate(Map<String, dynamic>? farm) async {
    try {
      double lat = 13.0910;
      double lon = -86.3538;
      if (farm != null && farm['latitude'] != null && farm['longitude'] != null) {
        lat = (farm['latitude'] as num).toDouble();
        lon = (farm['longitude'] as num).toDouble();
      }
      final data = await NasaPowerService.fetchClimateData(
        latitude: lat,
        longitude: lon,
      );
      final summary = data['summary'] as Map<String, dynamic>? ?? {};
      final rootMoisture =
          (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

      if (mounted) {
        setState(() {
          _nasaData = data;
          _soilMoistureIndex = rootMoisture;
        });
      }
    } catch (_) {}
  }

  void _switchLot(Map<String, dynamic> lot) {
    if (_currentLot?['id'] == lot['id']) return;
    setState(() {
      _currentLot = lot;
      _isLoading = true;
      _selectedSubplotId = null;
    });
    _loadSubplotsForSelectedLot();
  }

  Map<String, dynamic>? get _selectedSubplot {
    if (_selectedSubplotId == null) return null;
    try {
      return _subplots.firstWhere((s) => s['id'] == _selectedSubplotId);
    } catch (_) {
      return null;
    }
  }

  EveSubplotInsight _evaluateSubplotWithEve(
    Map<String, dynamic> subplot,
    List<Map<String, dynamic>> neighbors,
    bool isSpanish,
  ) {
    final cropKey = subplot['crop']?.toString().toLowerCase().trim() ?? '';
    final cropDef = _getCropDefinition(cropKey);
    final cropName = cropDef != null
        ? cropDef.localizedName(isSpanish)
        : (cropKey.isEmpty ? (isSpanish ? 'Sin cultivo' : 'No crop') : cropKey);
    final soilType = subplot['soil_type']?.toString() ?? 'Franco';

    if (_soilMoistureIndex < 0.40) {
      return EveSubplotInsight(
        alertType: 'water_deficit',
        severity: 'critical',
        title: isSpanish ? 'Estrés Hídrico Crítico' : 'Critical Water Deficit',
        summary: isSpanish
            ? 'Humedad radicular en ${(_soilMoistureIndex * 100).toInt()}% (alerta de déficit hídrico).'
            : 'Root zone moisture at ${(_soilMoistureIndex * 100).toInt()}% (water deficit alert).',
        recommendation: isSpanish
            ? 'Eve recomienda aplicar riego preventivo de 18-22 mm en las próximas 36 horas para proteger $cropName.'
            : 'Eve recommends applying 18-22 mm irrigation within 36 hours to protect $cropName.',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFFE53935),
      );
    }

    if (_soilMoistureIndex > 0.75) {
      return EveSubplotInsight(
        alertType: 'waterlogging',
        severity: 'warning',
        title: isSpanish ? 'Saturación Hídrica Alta' : 'High Water Saturation',
        summary: isSpanish
            ? 'Humedad radicular al ${(_soilMoistureIndex * 100).toInt()}%. Riesgo de asfixia radicular en suelo $soilType.'
            : 'Root moisture at ${(_soilMoistureIndex * 100).toInt()}%. Risk of root hypoxia on $soilType soil.',
        recommendation: isSpanish
            ? 'Eve recomienda suspender riego y revisar zanjas de drenaje perimetrales.'
            : 'Eve recommends pausing irrigation and checking perimeter drainage furrows.',
        icon: Icons.waves_rounded,
        color: const Color(0xFF1976D2),
      );
    }

    final currentFamily = AgroPredictionEngine.getBotanicalFamily(cropKey);
    for (final neighbor in neighbors) {
      final neighborCropKey =
          neighbor['target_crop']?.toString().toLowerCase().trim() ?? '';
      final neighborFamily =
          AgroPredictionEngine.getBotanicalFamily(neighborCropKey);
      final neighborName =
          neighbor['target_name']?.toString() ?? 'Sublote vecino';

      if (currentFamily != 'Desconocida' &&
          currentFamily == neighborFamily &&
          cropKey.isNotEmpty) {
        return EveSubplotInsight(
          alertType: 'botanical_risk',
          severity: 'warning',
          title: isSpanish ? 'Corredor de Plagas Vecinas' : 'Pest Corridor Risk',
          summary: isSpanish
              ? 'Colinda con $neighborName. Ambos comparten la familia $currentFamily.'
              : 'Adjacent to $neighborName. Both share the $currentFamily family.',
          recommendation: isSpanish
              ? 'Eve advierte riesgo fitosanitario compartido. Se sugiere intercalar barrera de leguminosas.'
              : 'Eve warns of shared pest risks. Consider planting a legume buffer strip.',
          icon: Icons.hub_rounded,
          color: const Color(0xFFF57F17),
        );
      }
    }

    if (cropKey.isNotEmpty) {
      final summary = _nasaData?['summary'] as Map<String, dynamic>? ?? {};
      final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
      final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;

      final pestWarnings = EveKnowledgeBase.getPestWarningsForCrop(
        crop: cropKey,
        tempC: tempC,
        rain7dMm: rainMm,
        soilMoisture: _soilMoistureIndex,
        soilType: soilType,
        isSpanish: isSpanish,
      );
      if (pestWarnings.isNotEmpty) {
        final pest = pestWarnings.first;
        return EveSubplotInsight(
          alertType: 'pest_risk',
          severity: 'info',
          title: isSpanish
              ? 'Alerta Fitosanitaria: ${pest.pestName}'
              : 'Pest Alert: ${pest.pestName}',
          summary: pest.symptomsAndImpact,
          recommendation: isSpanish
              ? 'Manejo biológico sugerido por Eve: ${pest.preventionAction}.'
              : 'Eve suggested biological control: ${pest.preventionAction}.',
          icon: Icons.bug_report_rounded,
          color: const Color(0xFFE65100),
        );
      }
    }

    if (cropKey.isEmpty || cropKey == 'none') {
      return EveSubplotInsight(
        alertType: 'sowing',
        severity: 'opportunity',
        title: isSpanish ? 'Ventana de Siembra Abierta' : 'Open Sowing Window',
        summary: isSpanish
            ? 'Sublote en descanso con temperatura y humedad favorables.'
            : 'Fallow plot with favorable moisture and thermal conditions.',
        recommendation: isSpanish
            ? 'Eve recomienda incorporar leguminosas (Frijol / Canavalia) para enriquecer el suelo en nitrógeno.'
            : 'Eve recommends sowing legumes to enrich biological soil nitrogen.',
        icon: Icons.spa_rounded,
        color: const Color(0xFF2E7D32),
      );
    }

    return EveSubplotInsight(
      alertType: 'optimal',
      severity: 'optimal',
      title: isSpanish
          ? 'Condiciones Agroecológicas Óptimas'
          : 'Optimal Agroecological Health',
      summary: isSpanish
          ? 'Desarrollo vegetativo en balance con suelo $soilType.'
          : 'Vegetative growth balanced on $soilType soil.',
      recommendation: isSpanish
          ? 'Eve sugiere continuar con el monitoreo preventivo y cobertura viva.'
          : 'Eve suggests maintaining preventive monitoring and live mulch.',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF2E7D32),
    );
  }

  CropDefinition? _getCropDefinition(String? cropKey) {
    if (cropKey == null || cropKey.isEmpty) return null;
    final lower = cropKey.toLowerCase().trim();
    for (final c in CropTypes.all) {
      if (c.key == lower ||
          c.nameEs.toLowerCase() == lower ||
          c.nameEn.toLowerCase() == lower) {
        return c;
      }
    }
    return null;
  }

  void _openEditSelectedSubplot() {
    final subplot = _selectedSubplot;
    if (subplot == null) return;

    double otherSurface = 0.0;
    for (final s in _subplots) {
      if (s['id'] != subplot['id']) {
        otherSurface += (s['surface'] as num?)?.toDouble() ?? 0.0;
      }
    }

    showNewOrEditSubplotModal(
      context,
      lotId: _lotId,
      lotSurface: _lotSurface,
      currentOtherSubplotsSurface: otherSurface,
      subplot: subplot,
      surfaceUnit: _surfaceUnit,
      onSaved: _loadSubplotsForSelectedLot,
    );
  }

  void _openAddSubplot() {
    double totalAllocated = 0.0;
    for (final s in _subplots) {
      totalAllocated += (s['surface'] as num?)?.toDouble() ?? 0.0;
    }

    showNewOrEditSubplotModal(
      context,
      lotId: _lotId,
      lotSurface: _lotSurface,
      currentOtherSubplotsSurface: totalAllocated,
      surfaceUnit: _surfaceUnit,
      onSaved: _loadSubplotsForSelectedLot,
    );
  }

  void _showEveDiagnosisDialog(EveSubplotInsight insight, String subplotName) {
    final isSpanish = AppLanguage.current.value == AppLanguageType.spanish;
    final isDark = AppColors.isDark(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCardBg(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const EveAnimatedAvatar(
              emote: EveEmote.calm,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSpanish ? 'Diagnóstico de Eve' : 'Eve Diagnosis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(ctx),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: insight.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: insight.color.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(insight.icon, size: 16, color: insight.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      insight.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: insight.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${isSpanish ? 'Sublote' : 'Subplot'}: $subplotName',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(ctx),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              insight.summary,
              style: TextStyle(fontSize: 13, color: AppColors.getTextPrimary(ctx)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A261F) : const Color(0xFFF1F8F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFC8E6C9),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpanish ? 'Recomendación de Eve:' : 'Eve Recommendation:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.recommendation,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextPrimary(ctx),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isSpanish ? 'Entendido' : 'Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLanguage.strings;
    final isSpanish = AppLanguage.current.value == AppLanguageType.spanish;
    final lotName = _currentLot?['name']?.toString() ?? s.kLot;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F5A37),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lotName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_lotSurface.toStringAsFixed(1)} $_surfaceUnit • ${_subplots.length} sublotes',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isIsometricView = !_isIsometricView;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isIsometricView
                          ? Icons.view_in_ar_rounded
                          : Icons.grid_on_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isIsometricView ? 'Vista 2.5D' : 'Vista 2D',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            tooltip: s.kAddNewSubplot,
            onPressed: _openAddSubplot,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                if (_allLots.isNotEmpty) _buildLotSelectorBar(isSpanish),
                _buildEveRiskBanner(isSpanish),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          boundaryMargin: const EdgeInsets.all(120),
                          minScale: 0.5,
                          maxScale: 2.5,
                          child: Center(
                            child: _buildTerrainParcel(isSpanish),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _buildCompassAndLegendBadge(),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: _buildBottomInspectorCard(s, isSpanish),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildLotSelectorBar(bool isSpanish) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F5A37),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded, size: 13, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                isSpanish ? 'Selecciona el lote a visualizar:' : 'Select lot to view:',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _allLots.map((lot) {
                final isSelected = lot['id'] == _currentLot?['id'];
                final name = lot['name']?.toString() ?? 'Lote';
                final surface = lot['surface']?.toString() ?? '0';

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _switchLot(lot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD600)
                              : Colors.white.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.landscape_rounded,
                            size: 14,
                            color: isSelected
                                ? const Color(0xFF0F5A37)
                                : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF0F5A37)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($surface $_surfaceUnit)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEveRiskBanner(bool isSpanish) {
    if (_subplots.isEmpty) return const SizedBox.shrink();

    final insights = _subplots.map((s) {
      final id = s['id'] as int? ?? 0;
      final neighbors = _adjacencies[id] ?? [];
      return _evaluateSubplotWithEve(s, neighbors, isSpanish);
    }).toList();

    final criticalCount = insights.where((i) => i.severity == 'critical').length;
    final warningCount = insights.where((i) => i.severity == 'warning').length;
    final hasIssues = criticalCount > 0 || warningCount > 0;

    final selectedSub = _selectedSubplot;
    final selectedInsight = selectedSub != null
        ? _evaluateSubplotWithEve(
            selectedSub,
            _adjacencies[selectedSub['id'] as int? ?? 0] ?? [],
            isSpanish,
          )
        : null;

    final isDark = AppColors.isDark(context);
    final Color bannerBg = isDark
        ? (hasIssues
            ? (criticalCount > 0
                ? const Color(0xFF3B1A1E)
                : const Color(0xFF3D2E14))
            : const Color(0xFF1B2F22))
        : (hasIssues
            ? (criticalCount > 0
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFFFF8E1))
            : const Color(0xFFE8F5E9));
    final Color bannerBorder = isDark
        ? (hasIssues
            ? (criticalCount > 0
                ? const Color(0xFF6B2A30)
                : const Color(0xFF6E5220))
            : const Color(0xFF2E4E36))
        : (hasIssues
            ? (criticalCount > 0
                ? const Color(0xFFEF9A9A)
                : const Color(0xFFFFE082))
            : const Color(0xFFA5D6A7));
    final Color bannerTextColor = isDark
        ? (hasIssues
            ? (criticalCount > 0
                ? const Color(0xFFEF5350)
                : const Color(0xFFFFB74D))
            : const Color(0xFF81C784))
        : (hasIssues
            ? (criticalCount > 0
                ? const Color(0xFFC62828)
                : const Color(0xFFE65100))
            : const Color(0xFF2E7D32));

    final String bannerText;
    if (criticalCount > 0) {
      bannerText = isSpanish
          ? 'Eve detectó $criticalCount alerta crítica de humedad en el mapa'
          : 'Eve detected $criticalCount critical water alert on map';
    } else if (warningCount > 0) {
      bannerText = isSpanish
          ? 'Eve detectó $warningCount advertencia fitosanitaria o de vecinos'
          : 'Eve detected $warningCount pest or neighbor warning';
    } else {
      bannerText = isSpanish
          ? 'Eve: Lote en condiciones óptimas para el ciclo actual'
          : 'Eve: Lot in optimal agroecological condition';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(bottom: BorderSide(color: bannerBorder)),
      ),
      child: Row(
        children: [
          EveAnimatedAvatar(
            emote: hasIssues ? EveEmote.alert : EveEmote.calm,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bannerText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: bannerTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selectedInsight != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${selectedSub!['name']}: ${selectedInsight.title}',
                    style: TextStyle(
                      fontSize: 11,
                      color: bannerTextColor.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (selectedInsight != null)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(50, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _showEveDiagnosisDialog(
                selectedInsight,
                selectedSub!['name']?.toString() ?? 'Sublote',
              ),
              child: Text(
                isSpanish ? 'Ver detalle' : 'Details',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: bannerTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTerrainParcel(bool isSpanish) {
    if (_subplots.isEmpty) {
      return _buildEmptyLotPrompt();
    }

    final count = _subplots.length;
    final int cols = count <= 2 ? count : (count <= 4 ? 2 : 3);
    final int rows = (count / cols).ceil();

    final parcelGrid = Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF2C5E2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1B431D),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3525),
            offset: _isIsometricView ? const Offset(-14, 14) : const Offset(0, 8),
            blurRadius: 0,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: _isIsometricView ? const Offset(-22, 22) : const Offset(0, 16),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FieldTexturePainter(),
              ),
            ),
            _buildPerimeterTrees(),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: List.generate(rows, (r) {
                    return Expanded(
                      child: Row(
                        children: List.generate(cols, (c) {
                          final index = (r * cols) + c;
                          if (index >= _subplots.length) {
                            return const Expanded(child: SizedBox());
                          }
                          final subplot = _subplots[index];
                          return Expanded(
                            child: _buildSubplotTile(subplot, isSpanish),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_isIsometricView) {
      final isDark = AppColors.isDark(context);
      return Stack(
        alignment: Alignment.center,
        children: [
          // Baseplate pedestal tray (matches 2.5D diorama reference)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateX(1.04719755) // 60 degrees tilt for 2:1 isometric ratio
              ..rotateZ(-0.78539816), // -45 degrees (-pi / 4)
            child: Container(
              width: 356,
              height: 356,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16221A) : const Color(0xFFF0F4F1),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C3E33) : const Color(0xFFCFDCD2),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    offset: const Offset(-18, 18),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Main elevated terrain slab
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateX(1.04719755) // 60 degrees tilt for 2:1 isometric ratio
              ..rotateZ(-0.78539816), // -45 degrees (-pi / 4)
            child: parcelGrid,
          ),
        ],
      );
    }

    return parcelGrid;
  }

  Widget _buildSubplotTile(Map<String, dynamic> subplot, bool isSpanish) {
    final id = subplot['id'] as int? ?? 0;
    final isSelected = id == _selectedSubplotId;
    final name = subplot['name']?.toString() ?? 'Sublote';
    final surface = (subplot['surface'] as num?)?.toDouble() ?? 0.0;
    final cropDef = _getCropDefinition(subplot['crop']?.toString());
    final neighbors = _adjacencies[id] ?? [];
    final hasNeighbors = neighbors.isNotEmpty;

    final insight = _evaluateSubplotWithEve(subplot, neighbors, isSpanish);

    final Color borderColor;
    if (isSelected) {
      borderColor = insight.hasRisk ? insight.color : const Color(0xFFFFD600);
    } else {
      borderColor = insight.hasRisk
          ? insight.color.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.35);
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSubplotId = id;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF388E3C).withValues(alpha: 0.85)
                : const Color(0xFF2E6B34).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 3.0 : (insight.hasRisk ? 2.0 : 1.2),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (hasNeighbors)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (insight.hasRisk)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: insight.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: insight.color.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      insight.icon,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cropDef?.color ?? const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: insight.hasRisk ? insight.color : Colors.white,
                          width: 2.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          cropDef?.icon ?? Icons.eco_rounded,
                          size: 20,
                          color: cropDef != null
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (insight.hasRisk ? insight.color : const Color(0xFFFFD600))
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (insight.hasRisk ? Colors.white : Colors.black)
                              : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F5A37),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${surface.toStringAsFixed(1)} $_surfaceUnit',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerimeterTrees() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    8,
                    (i) => Icon(
                      Icons.park_rounded,
                      size: 14,
                      color: const Color(0xFF1B4D20).withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    8,
                    (i) => Icon(
                      Icons.park_rounded,
                      size: 14,
                      color: const Color(0xFF1B4D20).withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (i) => Icon(
                      Icons.park_rounded,
                      size: 14,
                      color: const Color(0xFF1B4D20).withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (i) => Icon(
                      Icons.park_rounded,
                      size: 14,
                      color: const Color(0xFF1B4D20).withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLotPrompt() {
    final isDark = AppColors.isDark(context);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A3323) : const Color(0xFFEAF5EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Lote sin sublotes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Divide este lote en sublotes para visualizar su mapa 2.5D, cultivos y vecinos.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Crear Primer Sublote'),
            onPressed: _openAddSubplot,
          ),
        ],
      ),
    );
  }

  Widget _buildCompassAndLegendBadge() {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2B22).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: _isIsometricView ? -0.785398 : 0,
            child: const Icon(
              Icons.navigation_rounded,
              size: 16,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Norte',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInspectorCard(AppStrings s, bool isSpanish) {
    final isDark = AppColors.isDark(context);
    final subplot = _selectedSubplot;

    if (subplot == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.getCardBg(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSpanish
                    ? 'Toca cualquier sublote en el mapa para ver sus detalles y recomendaciones de Eve.'
                    : 'Tap any subplot on the map to view details and Eve recommendations.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextMuted(context),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final id = subplot['id'] as int? ?? 0;
    final name = subplot['name']?.toString() ?? 'Sublote';
    final surface = (subplot['surface'] as num?)?.toDouble() ?? 0.0;
    final soilKey = subplot['soil_type']?.toString();
    final soilDef = SoilTypes.all.firstWhere(
      (soil) => soil.key == soilKey,
      orElse: () => SoilTypes.all.first,
    );
    final cropDef = _getCropDefinition(subplot['crop']?.toString());
    final neighbors = _adjacencies[id] ?? [];

    final insight = _evaluateSubplotWithEve(subplot, neighbors, isSpanish);

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: insight.hasRisk ? insight.color : const Color(0xFFFFD600),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cropDef?.color ?? (isDark ? const Color(0xFF1B3523) : const Color(0xFFE8F5E9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      cropDef?.icon ?? Icons.eco_rounded,
                      color: cropDef != null
                          ? Colors.white
                          : AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: insight.hasRisk
                                  ? insight.color.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF383015) : const Color(0xFFFFF9C4)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              insight.hasRisk ? 'Alerta' : 'Seleccionado',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: insight.hasRisk
                                    ? insight.color
                                    : (isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cropDef != null
                            ? cropDef.localizedName(isSpanish)
                            : (isSpanish ? 'Sin cultivo asignado' : 'No crop assigned'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextMuted(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1A3323) : const Color(0xFFEAF5EC),
                    foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Editar Sublote',
                  onPressed: _openEditSelectedSubplot,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildInfoChip(
                  icon: Icons.square_foot_rounded,
                  label: '${surface.toStringAsFixed(2)} $_surfaceUnit',
                  bgColor: isDark ? AppColors.chipBgDark : const Color(0xFFF1F6F2),
                  textColor: isDark ? AppColors.textPrimaryDark : const Color(0xFF2E4034),
                ),
                _buildInfoChip(
                  icon: Icons.terrain_rounded,
                  label: soilDef.label(s),
                  bgColor: isDark ? AppColors.chipBgDark : soilDef.bgColor,
                  textColor: isDark ? AppColors.textPrimaryDark : soilDef.textColor,
                ),
                _buildInfoChip(
                  icon: Icons.water_drop_rounded,
                  label: 'SMAP: ${(_soilMoistureIndex * 100).toInt()}%',
                  bgColor: isDark ? const Color(0xFF1B3523) : const Color(0xFFE8F5E9),
                  textColor: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showEveDiagnosisDialog(insight, name),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: insight.color.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: insight.color.withValues(alpha: isDark ? 0.45 : 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(insight.icon, size: 16, color: insight.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eve: ${insight.title}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: insight.color,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            insight.recommendation,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.getTextPrimary(context),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: insight.color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF388E3C).withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
