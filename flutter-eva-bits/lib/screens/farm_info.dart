import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/responsive.dart';
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

        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
          child: Scaffold(
            backgroundColor: AppColors.getBackground(context),
            appBar: AppBar(
              backgroundColor: AppColors.getHeaderBg(context),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                s.kFarmDetailsTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Colors.white,
                ),
              ),
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

    final isTablet = Responsive(context).isTabletOrDesktop;

    final heroCard = _buildHeroCard(
      s: s,
      name: name,
      country: country,
      surface: surface,
      surfaceUnit: surfaceUnit,
      latitude: latitude,
      longitude: longitude,
    );

    final landAllocationCard = _buildLandAllocationCard(
      s: s,
      totalSurface: surface,
      surfaceUnit: surfaceUnit,
      allocatedSurface: totalAllocatedLotSurface,
      allocationRatio: allocationRatio,
      totalLots: lots.length,
      totalSubplots: totalSubplotsCount,
      lots: lots,
    );

    final environmentalCard = _buildEnvironmentalCard(
      s: s,
      latitude: latitude,
      longitude: longitude,
    );

    Widget content;
    if (isTablet) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heroCard,
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: landAllocationCard,
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 5,
                child: environmentalCard,
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heroCard,
          const SizedBox(height: 16),
          landAllocationCard,
          const SizedBox(height: 16),
          environmentalCard,
          const SizedBox(height: 24),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 20 : 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive(context).maxContentWidth,
          ),
          child: content,
        ),
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
    final isDark = AppColors.isDark(context);

    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: AppColors.getCardBg(context),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1E2B22), Color(0xFF18231C)]
                : const [Color(0xFFFFFFFF), Color(0xFFF9FDF9)],
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
                    color: isDark ? const Color(0xFF1A3323) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFC8E6C9),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.agriculture_rounded,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 15,
                            color: isDark ? AppColors.primaryLight : const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextMuted(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1A3323) : const Color(0xFFE8F5E9),
                    foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  onPressed: _openEditModal,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  tooltip: s.kEditFarm,
                ),
              ],
            ),
            Divider(
              height: 28,
              color: isDark ? AppColors.borderDark : const Color(0xFFE3ECE4),
            ),

            // Metric Highlights (Total Area & Unit Badge)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16251B) : const Color(0xFFF1F8F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFD4E8D6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.kTotalSurfaceLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                surface.toStringAsFixed(2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              surfaceUnit,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.primaryLight : const Color(0xFF2E7D32),
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
                color: isDark ? const Color(0xFF16251B) : const Color(0xFFFAFCFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE0ECE2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_fixed_rounded,
                    size: 18,
                    color: isDark ? AppColors.primaryLight : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.kGpsCoordinates,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                        Text(
                          (latitude != null && longitude != null)
                              ? '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°'
                              : s.kLocationNotCapturedYet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3324) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.kGpsSynchronized,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
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
    List<Map<String, dynamic>> lots = const [],
  }) {
    final isDark = AppColors.isDark(context);
    final unallocatedSurface = (totalSurface - allocatedSurface).clamp(0.0, totalSurface);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.getCardBg(context),
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_rounded,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.kLandAllocation,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
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
                backgroundColor: isDark ? const Color(0xFF1F2F23) : const Color(0xFFE0E0E0),
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.kAllocatedSurface}: ${allocatedSurface.toStringAsFixed(2)} $surfaceUnit (${(allocationRatio * 100).toStringAsFixed(0)}%)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.primaryLight : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${s.kUnallocatedSurface}: ${unallocatedSurface.toStringAsFixed(2)} $surfaceUnit',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextMuted(context),
                    ),
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
                      color: isDark ? const Color(0xFF16251B) : const Color(0xFFF6FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFDEEADE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.kTotalLots,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.getTextMuted(context),
                                ),
                              ),
                              Text(
                                totalLots.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ],
                          ),
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
                      color: isDark ? const Color(0xFF16251B) : const Color(0xFFF6FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFDEEADE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.layers_rounded,
                          color: isDark ? const Color(0xFF81C784) : const Color(0xFF558B2F),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.kTotalSubplots,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.getTextMuted(context),
                                ),
                              ),
                              Text(
                                totalSubplots.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (lots.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : const Color(0xFFE0E0E0),
              ),
              const SizedBox(height: 12),
              Text(
                s.kLotsSectionTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              ...lots.map((lot) {
                final lotName = lot['name']?.toString() ?? 'Lote';
                final lotSurface =
                    (lot['surface'] as num?)?.toDouble() ?? 0.0;
                final subplots =
                    (lot['subplots'] as List<dynamic>?) ?? [];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF16251B)
                        : const Color(0xFFF6FAF6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFDEEADE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 15,
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lotName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      Text(
                        '${lotSurface.toStringAsFixed(1)} $surfaceUnit • ${subplots.length} ${s.kTotalSubplots.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
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
    final isDark = AppColors.isDark(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.getCardBg(context),
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.eco_rounded,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.kEnvironmentalContext,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
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
                    bgColor: isDark ? const Color(0xFF382E15) : const Color(0xFFFFF9E6),
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
                    bgColor: isDark ? const Color(0xFF382215) : const Color(0xFFFFF3E0),
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
                    bgColor: isDark ? const Color(0xFF162538) : const Color(0xFFE3F2FD),
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
                    bgColor: isDark ? const Color(0xFF1A3323) : const Color(0xFFE8F5E9),
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
                color: isDark ? const Color(0xFF16251B) : const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.transparent,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.satellite_alt_rounded,
                    size: 18,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.kNasaDataDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextMuted(context),
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
                    color: AppColors.getTextMuted(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.getTextMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}
