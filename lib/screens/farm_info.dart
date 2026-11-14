import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import 'edit_farm_info.dart';

class FarmInfoDetailScreen extends StatefulWidget {
  const FarmInfoDetailScreen({super.key});

  @override
  State<FarmInfoDetailScreen> createState() => _FarmInfoDetailScreenState();
}

class _FarmInfoDetailScreenState extends State<FarmInfoDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _farm;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _loadFarmData() async {
    setState(() => _isLoading = true);
    try {
      final farmData = await DatabaseManager().getLatestFarm();
      if (mounted) {
        setState(() {
          _farm = farmData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openEditModal() {
    if (_farm == null) return;

    showEditFarmInfoModal(
      context,
      farm: _farm!,
      onFarmUpdated: () {
        _loadFarmData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F5A37),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              s.kFarmDetailsTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Colors.white,
              ),
            ),
            actions: [
              // Language Switcher
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () => AppLanguage.toggleLanguage(),
                icon: const Icon(Icons.language_rounded,
                    size: 16, color: Colors.white),
                label: Text(
                  AppLanguage.isSpanish ? 'ES' : 'EN',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_farm != null)
                IconButton(
                  tooltip: s.kEditFarm,
                  icon: const Icon(Icons.edit_note_rounded, size: 26),
                  onPressed: _openEditModal,
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadFarmData,
                  child: _farm == null
                      ? _buildEmptyState(s)
                      : _buildFarmDetails(s),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.landscape_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.kNoFarmsFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334E3B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmDetails(AppStrings s) {
    final farm = _farm!;
    final name = (farm['name']?.toString() ?? s.kDashboardYourFarm).trim();
    final country = (farm['country']?.toString() ?? 'Nicaragua').trim();
    final surface = (farm['total_surface'] as num?)?.toDouble() ?? 0.0;
    final surfaceUnit = farm['surface_unit']?.toString() ?? 'ha';
    final latitude = (farm['latitude'] as num?)?.toDouble();
    final longitude = (farm['longitude'] as num?)?.toDouble();

    final lots = (farm['lots'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    double totalAllocatedLotSurface = 0.0;
    int totalSubplotsCount = 0;

    for (final lot in lots) {
      final lotSurface = (lot['surface'] as num?)?.toDouble() ?? 0.0;
      totalAllocatedLotSurface += lotSurface;
      final subplots = (lot['subplots'] as List<dynamic>?) ?? [];
      totalSubplotsCount += subplots.length;
    }

    final double allocationRatio = surface > 0
        ? (totalAllocatedLotSurface / surface).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Overview Card
          _buildHeroCard(
            s: s,
            name: name,
            country: country,
            surface: surface,
            surfaceUnit: surfaceUnit,
            latitude: latitude,
            longitude: longitude,
          ),
          const SizedBox(height: 16),

          // 2. Land Allocation Card
          _buildLandAllocationCard(
            s: s,
            totalSurface: surface,
            surfaceUnit: surfaceUnit,
            allocatedSurface: totalAllocatedLotSurface,
            allocationRatio: allocationRatio,
            totalLots: lots.length,
            totalSubplots: totalSubplotsCount,
          ),
          const SizedBox(height: 16),

          // 3. Lots and Subplots Breakdown
          _buildLotsSection(
            s: s,
            lots: lots,
            surfaceUnit: surfaceUnit,
            totalFarmSurface: surface,
          ),
          const SizedBox(height: 16),

          // 4. Agro-Climatic Intelligence Card
          _buildEnvironmentalCard(
            s: s,
            latitude: latitude,
            longitude: longitude,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required AppStrings s,
    required String name,
    required String country,
    required double surface,
    required String surfaceUnit,
    required double? latitude,
    required double? longitude,
  }) {
    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF9FDF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Farm Identity & Quick Edit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2E1C),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 15,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            country,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A6572),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: _openEditModal,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  tooltip: s.kEditFarm,
                ),
              ],
            ),
            const Divider(height: 28, color: Color(0xFFE3ECE4)),

            // Metric Highlights (Total Area & Unit Badge)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD4E8D6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.kTotalSurfaceLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A6572),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              surface.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F5A37),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              surfaceUnit,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // GPS Coordinates Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFCFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0ECE2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.gps_fixed_rounded,
                    size: 18,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.kGpsCoordinates,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          (latitude != null && longitude != null)
                              ? '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°'
                              : s.kLocationNotCapturedYet,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.kGpsSynchronized,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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

  Widget _buildLandAllocationCard({
    required AppStrings s,
    required double totalSurface,
    required String surfaceUnit,
    required double allocatedSurface,
    required double allocationRatio,
    required int totalLots,
    required int totalSubplots,
  }) {
    final unallocatedSurface = (totalSurface - allocatedSurface).clamp(0.0, totalSurface);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.kLandAllocation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2E1C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: allocationRatio,
                minHeight: 10,
                backgroundColor: const Color(0xFFE0E0E0),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${s.kAllocatedSurface}: ${allocatedSurface.toStringAsFixed(2)} $surfaceUnit (${(allocationRatio * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  '${s.kUnallocatedSurface}: ${unallocatedSurface.toStringAsFixed(2)} $surfaceUnit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row (Total Lots & Total Subplots)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDEEADE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.kTotalLots,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              totalLots.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B2E1C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDEEADE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          color: Color(0xFF558B2F),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.kTotalSubplots,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              totalSubplots.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B2E1C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotsSection({
    required AppStrings s,
    required List<Map<String, dynamic>> lots,
    required String surfaceUnit,
    required double totalFarmSurface,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.park_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.kLotsAndSubplots,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E1C),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lots.length} ${s.kLotsSectionTitle.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (lots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  s.kNoLotsRegistered,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lots.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final lot = lots[index];
                  final lotName =
                      lot['name']?.toString() ?? '${s.kLot} ${index + 1}';
                  final lotSurface =
                      (lot['surface'] as num?)?.toDouble() ?? 0.0;
                  final subplots = (lot['subplots'] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAF8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2ECE3)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: index == 0,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          lotName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E1C),
                          ),
                        ),
                        subtitle: Text(
                          '${lotSurface.toStringAsFixed(2)} $surfaceUnit',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        children: [
                          if (subplots.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.kNoSubplots,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: subplots.map((subplot) {
                                  final subplotName =
                                      subplot['name']?.toString() ??
                                          s.kSubplot;
                                  final subplotSurface =
                                      (subplot['surface'] as num?)?.toDouble() ??
                                          0.0;

                                  return Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE8EFE8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.subdirectory_arrow_right_rounded,
                                              size: 16,
                                              color: AppColors.accent,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              subplotName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2B3A2C),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${subplotSurface.toStringAsFixed(2)} $surfaceUnit',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF388E3C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalCard({
    required AppStrings s,
    required double? latitude,
    required double? longitude,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.kEnvironmentalContext,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2E1C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Climate metrics grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFF57F17),
                    bgColor: const Color(0xFFFFF9E6),
                    title: s.kTemperature,
                    value: '28 °C',
                    subtext: s.kDashboardWeatherSummary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.flare_rounded,
                    iconColor: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                    title: s.kSolarRadiation,
                    value: '5.4 kWh',
                    subtext: 'm² / día',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF1976D2),
                    bgColor: const Color(0xFFE3F2FD),
                    title: s.kPrecipitation,
                    value: '14 mm',
                    subtext: '7 días',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.grass_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    title: s.kSoilMoisture,
                    value: '33%',
                    subtext: 'SMAP Nivel 1',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.satellite_alt_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.kNasaDataDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
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

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E1C),
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
