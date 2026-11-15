import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/crop_types.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/eve_animated_avatar.dart';
import '../widgets/new_edit_plot.dart';
import '../services/app_settings.dart';
import 'subplot_screen.dart';

enum LotFilterPriority {
  all,
  largestSurface,
  smallestSurface,
  withSubplots,
}

class LotsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialLots;
  final String? surfaceUnit;

  const LotsScreen({
    super.key,
    this.initialLots,
    this.surfaceUnit,
  });

  @override
  State<LotsScreen> createState() => _LotsScreenState();
}

class _LotsScreenState extends State<LotsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = true;
  String _searchQuery = '';
  LotFilterPriority _selectedPriority = LotFilterPriority.all;

  List<Map<String, dynamic>> _allLots = [];
  String _surfaceUnit = 'ha';
  int? _farmId;

  @override
  void initState() {
    super.initState();
    if (widget.initialLots != null) {
      _allLots = List<Map<String, dynamic>>.from(widget.initialLots!);
      _surfaceUnit = widget.surfaceUnit ?? 'ha';
      _isLoading = false;
    } else {
      _loadLots();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadLots() async {
    setState(() => _isLoading = true);
    try {
      final latestFarm = await DatabaseManager().getLatestFarm();
      if (latestFarm != null) {
        _farmId = latestFarm['id'] as int?;
        _surfaceUnit = latestFarm['surface_unit']?.toString() ??
            AppSettings.getSurfaceUnitShort();
      } else {
        _farmId = await DatabaseManager().getOrCreateDefaultFarmId();
        _surfaceUnit = AppSettings.getSurfaceUnitShort();
      }

      if (_farmId != null) {
        await DatabaseManager().seedInitialLotsIfEmpty(_farmId!);
      }

      final lots = await DatabaseManager().getAllLotsWithSubplots(
          farmId: _farmId);

      if (mounted) {
        setState(() {
          _allLots = lots;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAndSortedLots {
    var result = List<Map<String, dynamic>>.from(_allLots);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((lot) {
        final name = (lot['name'] ?? '').toString().toLowerCase();
        final surface = (lot['surface'] ?? '').toString().toLowerCase();
        final cropKey = (lot['crop'] ?? '').toString().toLowerCase();
        final subplots = (lot['subplots'] as List<dynamic>?) ?? [];
        final hasMatchingSubplot = subplots.any((sub) =>
            (sub['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
            (sub['crop'] ?? '').toString().toLowerCase().contains(_searchQuery));

        return name.contains(_searchQuery) ||
            surface.contains(_searchQuery) ||
            cropKey.contains(_searchQuery) ||
            hasMatchingSubplot;
      }).toList();
    }

    // Apply priority / sort chips
    switch (_selectedPriority) {
      case LotFilterPriority.largestSurface:
        result.sort((a, b) {
          final surfaceA = (a['surface'] as num?)?.toDouble() ?? 0.0;
          final surfaceB = (b['surface'] as num?)?.toDouble() ?? 0.0;
          return surfaceB.compareTo(surfaceA);
        });
        break;
      case LotFilterPriority.smallestSurface:
        result.sort((a, b) {
          final surfaceA = (a['surface'] as num?)?.toDouble() ?? 0.0;
          final surfaceB = (b['surface'] as num?)?.toDouble() ?? 0.0;
          return surfaceA.compareTo(surfaceB);
        });
        break;
      case LotFilterPriority.withSubplots:
        result = result.where((lot) {
          final subplots = (lot['subplots'] as List<dynamic>?) ?? [];
          return subplots.isNotEmpty;
        }).toList();
        break;
      case LotFilterPriority.all:
        break;
    }

    return result;
  }

  double get _totalSurface {
    double sum = 0.0;
    for (final lot in _allLots) {
      final s = (lot['surface'] as num?)?.toDouble() ?? 0.0;
      sum += s;
    }
    return sum;
  }

  int get _totalSubplotsCount {
    int count = 0;
    for (final lot in _allLots) {
      final subplots = (lot['subplots'] as List<dynamic>?) ?? [];
      count += subplots.length;
    }
    return count;
  }

  void _openAddLotModal() {
    showNewOrEditLotModal(
      context,
      surfaceUnit: _surfaceUnit,
      onSaved: _loadLots,
    );
  }

  void _openEditLotModal(Map<String, dynamic> lot) {
    showNewOrEditLotModal(
      context,
      lot: lot,
      surfaceUnit: _surfaceUnit,
      onSaved: _loadLots,
    );
  }

  void _navigateToSubplots(Map<String, dynamic> lot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubplotScreen(
          lot: lot,
          surfaceUnit: _surfaceUnit,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadLots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;
        final filteredLots = _filteredAndSortedLots;
        final scaffoldBg = AppColors.getBackground(context);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadLots,
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
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleAndSubtitle(context, s),
                          const SizedBox(height: 16),
                          _buildSearchField(context, s),
                          const SizedBox(height: 20),
                          _buildPriorityFilterSection(context, s),
                          const SizedBox(height: 20),
                          _buildQuickSummaryCard(context, s),
                          const SizedBox(height: 24),
                          _buildRegisteredLotsHeader(
                              context, s, filteredLots.length),
                          const SizedBox(height: 12),
                          if (filteredLots.isEmpty)
                            _buildEmptyState(context, s)
                          else
                            ...filteredLots.map((lot) => _buildLotCard(context, s, lot)),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: EveFloatingLauncherButton(
            tooltip: s.kAskIvyTooltip,
            onAddPressed: _openAddLotModal,
            addTooltip: s.kAddLot,
          ),
          bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
        );
      },
    );
  }

  Widget _buildTitleAndSubtitle(BuildContext context, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final subtextColor = AppColors.getTextMuted(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.kLotsScreenTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.kLotsScreenSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.getCardBg(context);
    final borderCol = AppColors.getBorder(context);
    final textCol = AppColors.getTextPrimary(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textCol,
        ),
        decoration: InputDecoration(
          hintText: s.kSearchLotsHint,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityFilterSection(BuildContext context, AppStrings s) {
    final textColor = AppColors.getTextPrimary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.kFilterPriorityTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                context: context,
                label: s.kFilterAll,
                isSelected: _selectedPriority == LotFilterPriority.all,
                onTap: () =>
                    setState(() => _selectedPriority = LotFilterPriority.all),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: s.kFilterLargest,
                isSelected:
                    _selectedPriority == LotFilterPriority.largestSurface,
                onTap: () => setState(
                    () => _selectedPriority = LotFilterPriority.largestSurface),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: s.kFilterSmallest,
                isSelected:
                    _selectedPriority == LotFilterPriority.smallestSurface,
                onTap: () => setState(
                    () => _selectedPriority = LotFilterPriority.smallestSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final unselectedBg = isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2);
    final unselectedBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final unselectedText = isDark ? Colors.grey.shade300 : const Color(0xFF4A5568);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5A37) : unselectedBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F5A37) : unselectedBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F5A37).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : unselectedText,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSummaryCard(BuildContext context, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? const Color(0xFF1A261E) : const Color(0xFFEAF5EC);
    final borderCol = isDark ? const Color(0xFF2C3E33) : const Color(0xFFC8E6C9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context: context,
            icon: Icons.layers_outlined,
            title: '${_allLots.length}',
            subtitle: s.kTotalLots,
          ),
          Container(
            height: 36,
            width: 1,
            color: borderCol,
          ),
          _buildSummaryItem(
            context: context,
            icon: Icons.square_foot_rounded,
            title: '${_totalSurface.toStringAsFixed(1)} $_surfaceUnit',
            subtitle: s.kTotalSurfaceLabel,
          ),
          Container(
            height: 36,
            width: 1,
            color: borderCol,
          ),
          _buildSummaryItem(
            context: context,
            icon: Icons.grid_view_rounded,
            title: '$_totalSubplotsCount',
            subtitle: s.kTotalSubplots,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = AppColors.isDark(context);
    final brandColor = isDark ? AppColors.primaryLight : const Color(0xFF0F5A37);
    final subtextColor = AppColors.getTextMuted(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: brandColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: brandColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredLotsHeader(
      BuildContext context, AppStrings s, int count) {
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.getTextPrimary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          s.kRegisteredLotsTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF5EC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLotCard(
      BuildContext context, AppStrings s, Map<String, dynamic> lot) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.getCardBg(context);
    final borderCol = AppColors.getBorder(context);
    final textCol = AppColors.getTextPrimary(context);
    final subtextCol = AppColors.getTextMuted(context);

    final name = lot['name']?.toString() ?? s.kLot;
    final surface = lot['surface']?.toString() ?? '0';
    final subplots = (lot['subplots'] as List<dynamic>?) ?? [];
    final subplotsCount = subplots.length;
    final isSpanish = AppLanguage.isSpanish;

    final lotCrop = CropTypes.getByKey(lot['crop']?.toString());
    final subplotsCrops = <CropDefinition>[];
    for (final sub in subplots) {
      final c = CropTypes.getByKey(sub['crop']?.toString());
      if (c != null && !subplotsCrops.any((existing) => existing.key == c.key)) {
        subplotsCrops.add(c);
      }
    }

    final cropBadgeText = lotCrop != null
        ? lotCrop.localizedName(isSpanish)
        : (subplotsCrops.isNotEmpty
            ? subplotsCrops.map((c) => c.localizedName(isSpanish)).join(', ')
            : null);

    final subplotsInfo = subplotsCount > 0
        ? '$subplotsCount ${subplotsCount == 1 ? s.kSubplotSingular : s.kSubplotsCount}'
        : null;

    final parts = <String>['$surface $_surfaceUnit'];
    if (cropBadgeText != null) {
      parts.add(cropBadgeText);
    }
    if (subplotsInfo != null) {
      parts.add(subplotsInfo);
    }
    final detailsText = parts.join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToSubplots(lot),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF233529)
                        : const Color(0xFFEAF5EC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.eco_rounded,
                      color: isDark
                          ? AppColors.primaryLight
                          : const Color(0xFF2E7D32),
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
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detailsText,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtextCol,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: isDark
                        ? AppColors.primaryLight
                        : const Color(0xFF0F5A37),
                    size: 22,
                  ),
                  tooltip: s.kEditLot,
                  onPressed: () => _openEditLotModal(lot),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppStrings s) {
    final isSearching = _searchQuery.isNotEmpty;
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.getCardBg(context);
    final borderCol = AppColors.getBorder(context);
    final textCol = AppColors.getTextPrimary(context);
    final subtextCol = AppColors.getTextMuted(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF233529) : const Color(0xFFEAF5EC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.landscape_outlined,
              size: 34,
              color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? s.kNoLotsFound : s.kNoLotsRegistered,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? '${s.kNoLotsFound} "$_searchQuery"'
                : s.kNoLotsYetSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: subtextCol,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (isSearching)
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              child: Text(s.kFilterAll),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primary : const Color(0xFF0F5A37),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _openAddLotModal,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(s.kAddNewLot),
            ),
        ],
      ),
    );
  }
}
