import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/crop_types.dart';
import '../constants/soil_types.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';
import '../widgets/crop_picker_sheet.dart';
import '../widgets/eve_animated_avatar.dart';
import '../widgets/new_edit_plot.dart';
import '../widgets/new_edit_subplot.dart';
import 'lot_map_screen.dart';

class SubplotScreen extends StatefulWidget {
  final Map<String, dynamic> lot;
  final String? surfaceUnit;
  final List<Map<String, dynamic>>? initialSubplots;

  const SubplotScreen({
    super.key,
    required this.lot,
    this.surfaceUnit,
    this.initialSubplots,
  });

  @override
  State<SubplotScreen> createState() => _SubplotScreenState();
}

class _SubplotScreenState extends State<SubplotScreen> {
  bool _isLoading = true;
  late Map<String, dynamic> _currentLot;
  List<Map<String, dynamic>> _subplots = [];
  late String _surfaceUnit;

  @override
  void initState() {
    super.initState();
    _currentLot = Map<String, dynamic>.from(widget.lot);
    _surfaceUnit = widget.surfaceUnit ?? AppSettings.getSurfaceUnitShort();

    if (widget.initialSubplots != null) {
      _subplots = List<Map<String, dynamic>>.from(widget.initialSubplots!);
      _isLoading = false;
    } else {
      _loadSubplots();
    }
  }

  int get _lotId => _currentLot['id'] as int? ?? 0;

  double get _lotSurface =>
      (_currentLot['surface'] as num?)?.toDouble() ?? 0.0;

  double get _totalAllocatedSurface {
    double sum = 0.0;
    for (final s in _subplots) {
      sum += (s['surface'] as num?)?.toDouble() ?? 0.0;
    }
    return sum;
  }

  double get _unallocatedSurface {
    final remaining = _lotSurface - _totalAllocatedSurface;
    return remaining < 0 ? 0.0 : remaining;
  }

  double get _allocationRatio {
    if (_lotSurface <= 0) return 0.0;
    final ratio = _totalAllocatedSurface / _lotSurface;
    return ratio.clamp(0.0, 1.0);
  }

  Map<String, double> get _soilDistribution {
    final dist = <String, double>{};
    for (final s in _subplots) {
      final soilKey = s['soil_type']?.toString() ?? 'franco';
      final surface = (s['surface'] as num?)?.toDouble() ?? 0.0;
      dist[soilKey] = (dist[soilKey] ?? 0.0) + surface;
    }
    return dist;
  }

  Future<void> _loadSubplots() async {
    setState(() => _isLoading = true);
    try {
      if (_lotId > 0) {
        // Refresh lot data if available
        final updatedLot = await DatabaseManager().getLotById(_lotId);
        if (updatedLot != null) {
          _currentLot = updatedLot;
        }

        final subplots = await DatabaseManager().getSubplotsByLot(_lotId);
        if (mounted) {
          setState(() {
            _subplots = subplots;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openAddSubplotModal() {
    showNewOrEditSubplotModal(
      context,
      lotId: _lotId,
      lotSurface: _lotSurface,
      currentOtherSubplotsSurface: _totalAllocatedSurface,
      surfaceUnit: _surfaceUnit,
      onSaved: _loadSubplots,
    );
  }

  void _openEditSubplotModal(Map<String, dynamic> subplot) {
    final otherSubplotsSurface = _totalAllocatedSurface -
        ((subplot['surface'] as num?)?.toDouble() ?? 0.0);

    showNewOrEditSubplotModal(
      context,
      lotId: _lotId,
      lotSurface: _lotSurface,
      currentOtherSubplotsSurface: otherSubplotsSurface,
      subplot: subplot,
      surfaceUnit: _surfaceUnit,
      onSaved: _loadSubplots,
    );
  }

  void _openEditLotModal() {
    showNewOrEditLotModal(
      context,
      lot: _currentLot,
      surfaceUnit: _surfaceUnit,
      onSaved: () async {
        if (_lotId > 0) {
          final updated = await DatabaseManager().getLotById(_lotId);
          if (mounted && updated != null) {
            setState(() {
              _currentLot = updated;
            });
          }
        }
        _loadSubplots();
      },
    );
  }

  void _openLotMapScreen() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => LotMapScreen(
          lot: _currentLot,
          surfaceUnit: _surfaceUnit,
        ),
      ),
    ).then((_) => _loadSubplots());
  }

  Future<void> _pickCropForLot(AppStrings s) async {
    final result = await showCropPickerModal(
      context,
      selectedCropKey: _currentLot['crop']?.toString(),
    );
    if (result != null) {
      final newCrop = result.isEmpty ? null : result;
      if (_lotId > 0) {
        await DatabaseManager().updateLotCrop(_lotId, newCrop);
      }
      setState(() {
        _currentLot['crop'] = newCrop;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              s.kCropUpdatedSuccessfully,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickCropForSubplot(Map<String, dynamic> subplot, AppStrings s) async {
    final result = await showCropPickerModal(
      context,
      selectedCropKey: subplot['crop']?.toString(),
    );
    if (result != null) {
      final newCrop = result.isEmpty ? null : result;
      final subplotId = subplot['id'] as int? ?? 0;
      if (subplotId > 0) {
        await DatabaseManager().updateSubplotCrop(subplotId, newCrop);
        _loadSubplots();
      } else {
        setState(() {
          subplot['crop'] = newCrop;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              s.kCropUpdatedSuccessfully,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;
        final lotName = _currentLot['name']?.toString() ?? s.kLot;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF8),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F5A37),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              lotName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.view_in_ar_rounded, color: Colors.white),
                tooltip: 'Ver Mapa 2.5D del Lote',
                onPressed: _openLotMapScreen,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: s.kEditLot,
                onPressed: _openEditLotModal,
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadSubplots,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLotHeroCard(s),
                          const SizedBox(height: 16),
                          _buildInteractiveMapBanner(s),
                          const SizedBox(height: 20),
                          _buildSubplotsHeader(s),
                          const SizedBox(height: 14),
                          if (_subplots.isEmpty)
                            _buildEmptyState(s)
                          else
                            ..._subplots.map((sub) => _buildSubplotCard(s, sub)),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: EveFloatingLauncherButton(
            tooltip: s.kAskIvyTooltip,
            onAddPressed: _openAddSubplotModal,
            addTooltip: s.kAddNewSubplot,
          ),
        );
      },
    );
  }

  Widget _buildLotHeroCard(AppStrings s) {
    final lotName = _currentLot['name']?.toString() ?? s.kLot;
    final totalAllocated = _totalAllocatedSurface;
    final unallocated = _unallocatedSurface;
    final ratio = _allocationRatio;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Identity Row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF5EC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF2E7D32),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lotName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E1C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.kTotalLotSurface}: ${_lotSurface.toStringAsFixed(2)} $_surfaceUnit',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildLotCropPill(s),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Allocation Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.kLotAllocation,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F5A37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8ECE8),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F5A37)),
            ),
          ),
          const SizedBox(height: 14),

          // Area breakdown chips
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD4E8D6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.kAllocatedToSubplots,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${totalAllocated.toStringAsFixed(2)} $_surfaceUnit',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F5A37),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.kUnallocatedFromLot,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${unallocated.toStringAsFixed(2)} $_surfaceUnit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_subplots.isNotEmpty && totalAllocated > 0) ...[
            const Divider(height: 28, color: Color(0xFFE5E7EB)),
            _buildSoilCompositionSection(s),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveMapBanner(AppStrings s) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F5A37),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5A37).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openLotMapScreen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      color: Color(0xFFFFD600), // Vibrant gold accent
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mapa 2.5D del Lote',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Vista aérea interactiva, cultivos y vecinos',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Ver Mapa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2E1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoilCompositionSection(AppStrings s) {
    final dist = _soilDistribution;
    final totalAllocated = _totalAllocatedSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.terrain_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              s.kSoilComposition,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2E1C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Multi-segmented colored soil bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: dist.entries.map((entry) {
                final soilDef = SoilTypes.getByKey(entry.key);
                final flex = (entry.value * 1000).toInt();
                return Expanded(
                  flex: flex > 0 ? flex : 1,
                  child: Container(
                    color: soilDef.barColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Legend chips wrap
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: dist.entries.map((entry) {
            final soilDef = SoilTypes.getByKey(entry.key);
            final surface = entry.value;
            final pct =
                totalAllocated > 0 ? (surface / totalAllocated) * 100 : 0.0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: soilDef.bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: soilDef.borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: soilDef.barColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${soilDef.label(s)}: ${surface.toStringAsFixed(1)} $_surfaceUnit (${pct.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: soilDef.textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubplotsHeader(AppStrings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              s.kSubplotsTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2E1C),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_subplots.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F5A37),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubplotCard(AppStrings s, Map<String, dynamic> subplot) {
    final name = subplot['name']?.toString() ?? s.kSubplot;
    final surface = (subplot['surface'] as num?)?.toDouble() ?? 0.0;
    final percentage = _lotSurface > 0 ? (surface / _lotSurface) * 100 : 0.0;
    final soilKey = subplot['soil_type']?.toString();
    final soilDef = SoilTypes.getByKey(soilKey);
    final isSpanish = AppLanguage.isSpanish;
    final crop = CropTypes.getByKey(subplot['crop']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEditSubplotModal(subplot),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Circular icon badge tinted by soil type
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: soilDef.bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: soilDef.borderColor, width: 1.2),
                  ),
                  child: Center(
                    child: Icon(
                      soilDef.icon,
                      color: soilDef.barColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Subplot Name, Soil Badge & Surface info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2D24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: soilDef.bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: soilDef.borderColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: soilDef.barColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  soilDef.label(s),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: soilDef.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildSubplotCropPill(subplot, crop, s, isSpanish),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${surface.toStringAsFixed(2)} $_surfaceUnit • ${percentage.toStringAsFixed(0)}% ${s.kTotalLotSurface.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Pen Icon
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0F5A37),
                    size: 20,
                  ),
                  tooltip: s.kEditSubplot,
                  onPressed: () => _openEditSubplotModal(subplot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLotCropPill(AppStrings s) {
    final isSpanish = AppLanguage.isSpanish;
    final lotCrop = CropTypes.getByKey(_currentLot['crop']?.toString());

    if (lotCrop != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pickCropForLot(s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: lotCrop.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lotCrop.color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(lotCrop.icon, size: 14, color: lotCrop.textColor),
              const SizedBox(width: 5),
              Text(
                '${s.kCropLabel}: ${lotCrop.localizedName(isSpanish)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: lotCrop.textColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_rounded, size: 12, color: lotCrop.textColor),
            ],
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _pickCropForLot(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 14, color: Color(0xFF0F5A37)),
            const SizedBox(width: 4),
            Text(
              s.kAssignCrop,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F5A37),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubplotCropPill(
    Map<String, dynamic> subplot,
    CropDefinition? crop,
    AppStrings s,
    bool isSpanish,
  ) {
    if (crop != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _pickCropForSubplot(subplot, s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: crop.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: crop.color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(crop.icon, size: 12, color: crop.textColor),
              const SizedBox(width: 4),
              Text(
                crop.localizedName(isSpanish),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: crop.textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _pickCropForSubplot(subplot, s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 11, color: Color(0xFF0F5A37)),
            const SizedBox(width: 2),
            Text(
              s.kCropLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F5A37),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
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
              size: 30,
              color: Color(0xFF0F5A37),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.kNoSubplotsYet,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E1C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            s.kNoSubplotsSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5A37),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _openAddSubplotModal,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              s.kAddNewSubplot,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
