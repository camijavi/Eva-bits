import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/crop_types.dart';
import '../constants/soil_types.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';
import '../services/subplot_graph_service.dart';
import '../widgets/new_edit_subplot.dart';

/// Interactive 2.5D Isometric Aerial Map for a Farm Lot.
/// Renders subplots as tactile land parcels with floating crop pins,
/// bounding highlight boxes, and graph neighbor relations.
class LotMapScreen extends StatefulWidget {
  final Map<String, dynamic> lot;
  final String? surfaceUnit;

  const LotMapScreen({
    super.key,
    required this.lot,
    this.surfaceUnit,
  });

  @override
  State<LotMapScreen> createState() => _LotMapScreenState();
}

class _LotMapScreenState extends State<LotMapScreen> {
  bool _isLoading = true;
  late Map<String, dynamic> _currentLot;
  List<Map<String, dynamic>> _subplots = [];
  Map<int, List<Map<String, dynamic>>> _adjacencies = {};
  int? _selectedSubplotId;
  bool _isIsometricView = true;

  @override
  void initState() {
    super.initState();
    _currentLot = Map<String, dynamic>.from(widget.lot);
    _loadLotAndSubplots();
  }

  int get _lotId => _currentLot['id'] as int? ?? 0;
  String get _surfaceUnit =>
      widget.surfaceUnit ?? AppSettings.getSurfaceUnitShort();
  double get _lotSurface =>
      (_currentLot['surface'] as num?)?.toDouble() ?? 0.0;

  Future<void> _loadLotAndSubplots() async {
    setState(() => _isLoading = true);
    try {
      if (_lotId > 0) {
        final updatedLot = await DatabaseManager().getLotById(_lotId);
        if (updatedLot != null) {
          _currentLot = updatedLot;
        }

        final subplots = await DatabaseManager().getSubplotsByLot(_lotId);

        // Fetch graph adjacencies for each subplot
        final Map<int, List<Map<String, dynamic>>> adjMap = {};
        for (final sp in subplots) {
          final id = sp['id'] as int?;
          if (id != null) {
            final neighbors =
                await DatabaseManager().getSubplotAdjacencies(id);
            adjMap[id] = neighbors;
          }
        }

        if (mounted) {
          setState(() {
            _subplots = subplots;
            _adjacencies = adjMap;
            if (_subplots.isNotEmpty && _selectedSubplotId == null) {
              _selectedSubplotId = _subplots.first['id'] as int?;
            }
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? get _selectedSubplot {
    if (_selectedSubplotId == null) return null;
    try {
      return _subplots.firstWhere((s) => s['id'] == _selectedSubplotId);
    } catch (_) {
      return null;
    }
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
      onSaved: _loadLotAndSubplots,
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
      onSaved: _loadLotAndSubplots,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLanguage.strings;
    final isSpanish = AppLanguage.current.value == AppLanguageType.spanish;
    final lotName = _currentLot['name']?.toString() ?? s.kLot;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EFE9), // Soft warm earthy backdrop
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
          // 3D / 2D Perspective Toggle Pill
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
          : Stack(
              children: [
                // 1. Terrain Canvas Viewport
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

                // 2. Legend / Compass floating widget (Top-Left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildCompassAndLegendBadge(),
                ),

                // 3. Floating Bottom Inspector Card
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: _buildBottomInspectorCard(s, isSpanish),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Terrain & Subplot Canvas
  // ---------------------------------------------------------------------------

  Widget _buildTerrainParcel(bool isSpanish) {
    if (_subplots.isEmpty) {
      return _buildEmptyLotPrompt();
    }

    // Grid dimension calculation based on subplots count
    final count = _subplots.length;
    final int cols = count <= 2 ? count : (count <= 4 ? 2 : 3);
    final int rows = (count / cols).ceil();

    final parcelGrid = Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF2C5E2E), // Base lush grass field
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1B431D),
          width: 3,
        ),
        boxShadow: [
          // Simulated 3D Soil Slab Depth (Soil layer below the grass)
          BoxShadow(
            color: const Color(0xFF4A3525), // Earthy brown soil
            offset: _isIsometricView ? const Offset(-8, 16) : const Offset(0, 8),
            blurRadius: 0,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: _isIsometricView ? const Offset(-12, 28) : const Offset(0, 16),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Natural field soil texture background
            Positioned.fill(
              child: CustomPaint(
                painter: _FieldTexturePainter(),
              ),
            ),

            // Perimeter Trees / Agroforestry fence (just like the reference image)
            _buildPerimeterTrees(),

            // Inner Subplots Grid
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

    // Apply 2.5D Isometric Transformation if enabled
    if (_isIsometricView) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012) // Perspective foreshortening
          ..rotateX(0.78) // ~45 deg pitch down
          ..rotateZ(-0.62), // ~35 deg yaw angle
        child: parcelGrid,
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
    final hasNeighbors = (_adjacencies[id]?.isNotEmpty) ?? false;

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
              // Glowing yellow bounding box when selected (as in reference photo!)
              color: isSelected
                  ? const Color(0xFFFFD600)
                  : Colors.white.withValues(alpha: 0.35),
              width: isSelected ? 3.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD600).withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Graph connectivity badge (icon in corner if linked to a neighbor)
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

              // Center Floating Crop Pin Badge
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating circular pin badge
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
                          color: Colors.white,
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

                    // Floating name tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFD600)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
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
    // Generates subtle border tree icons around the parcel perimeter
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  8,
                  (i) => Icon(
                    Icons.park_rounded,
                    size: 16,
                    color: const Color(0xFF1B4D20).withValues(alpha: 0.8),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  8,
                  (i) => Icon(
                    Icons.park_rounded,
                    size: 16,
                    color: const Color(0xFF1B4D20).withValues(alpha: 0.8),
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
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Lote sin sublotes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E1C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Divide este lote en sublotes para visualizar su mapa 2.5D, cultivos y vecinos.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
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
            angle: _isIsometricView ? -0.62 : 0,
            child: const Icon(
              Icons.navigation_rounded,
              size: 16,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Norte',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4034),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Inspector Card
  // ---------------------------------------------------------------------------

  Widget _buildBottomInspectorCard(AppStrings s, bool isSpanish) {
    final subplot = _selectedSubplot;

    if (subplot == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                'Toca cualquier sublote en el mapa para ver sus detalles y vecinos.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFFFD600), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Crop icon, Subplot name, Edit button
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cropDef?.color ?? const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      cropDef?.icon ?? Icons.eco_rounded,
                      color: cropDef != null
                          ? Colors.white
                          : AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B2E1C),
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
                              color: const Color(0xFFFFF9C4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Seleccionado',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF57F17),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cropDef != null
                            ? cropDef.localizedName(isSpanish)
                            : 'Sin cultivo asignado',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF5EC),
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar Sublote',
                  onPressed: _openEditSelectedSubplot,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chips Row: Surface, Soil, Moisture estimate
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(
                  icon: Icons.square_foot_rounded,
                  label: '${surface.toStringAsFixed(2)} $_surfaceUnit',
                  bgColor: const Color(0xFFF1F6F2),
                  textColor: const Color(0xFF2E4034),
                ),
                _buildInfoChip(
                  icon: Icons.terrain_rounded,
                  label: soilDef.label(s),
                  bgColor: soilDef.bgColor,
                  textColor: soilDef.textColor,
                ),
                _buildInfoChip(
                  icon: Icons.grass_rounded,
                  label: 'SMAP: 58%',
                  bgColor: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2E7D32),
                ),
              ],
            ),

            // Graph Neighbor connection note
            if (neighbors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Colinda con: ${neighbors.first['target_name'] ?? 'Sublote'} (${SubplotRelationshipType.getLabel(neighbors.first['relationship_type']?.toString() ?? 'neighbor')})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B2E1C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

/// Custom painter to generate organic agricultural soil / crop furrows texture
class _FieldTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF235325).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Gentle agricultural furrow lines
    const step = 14.0;
    for (double x = 0; x < size.width * 2; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
