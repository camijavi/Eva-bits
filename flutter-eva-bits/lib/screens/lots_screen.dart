import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
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
                          const SizedBox(height: 18),
                          _buildPriorityFilterSection(context, s),
                          const SizedBox(height: 20),
                          _buildQuickSummaryCard(context, s),
                          const SizedBox(height: 24),
                          _buildRegisteredLotsHeader(
                              context, s, filteredLots.length),
                          const SizedBox(height: 14),
                          if (filteredLots.isEmpty)
                            _buildEmptyState(context, s)
                          else
                            ...filteredLots.map(
                              (lot) => _buildLotCard(context, s, lot),
                            ),
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
        ),
      );
    },
    );
  }

  Widget _buildTitleAndSubtitle(BuildContext context, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final subtextColor = AppColors.getTextMuted(context);
    final isSpanish = AppLanguage.isSpanish;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B2B20)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFA5D6A7),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.primaryLight
                        : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSpanish ? 'Zonificación de Campo' : 'Field Zoning',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.primaryLight
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          s.kLotsScreenTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
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
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? (isDark ? AppColors.primaryLight : const Color(0xFF0F5A37))
              : borderCol,
          width: 1.2,
        ),
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
    final isSpanish = AppLanguage.isSpanish;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.kFilterPriorityTitle,
          style: TextStyle(
            fontSize: 15,
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
                icon: Icons.tune_rounded,
                isSelected: _selectedPriority == LotFilterPriority.all,
                onTap: () =>
                    setState(() => _selectedPriority = LotFilterPriority.all),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: s.kFilterLargest,
                icon: Icons.arrow_upward_rounded,
                isSelected:
                    _selectedPriority == LotFilterPriority.largestSurface,
                onTap: () => setState(
                    () => _selectedPriority = LotFilterPriority.largestSurface),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: s.kFilterSmallest,
                icon: Icons.arrow_downward_rounded,
                isSelected:
                    _selectedPriority == LotFilterPriority.smallestSurface,
                onTap: () => setState(
                    () => _selectedPriority = LotFilterPriority.smallestSurface),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: isSpanish ? 'Con parcelas' : 'With subplots',
                icon: Icons.grid_view_rounded,
                isSelected:
                    _selectedPriority == LotFilterPriority.withSubplots,
                onTap: () => setState(
                    () => _selectedPriority = LotFilterPriority.withSubplots),
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final unselectedBg =
        isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2);
    final unselectedBorder =
        isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final unselectedText =
        isDark ? Colors.grey.shade300 : const Color(0xFF4A5568);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : unselectedText,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummaryCard(BuildContext context, AppStrings s) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? const Color(0xFF16231A) : const Color(0xFFEAF5EC);
    final borderCol =
        isDark ? const Color(0xFF2C3E33) : const Color(0xFFC8E6C9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context: context,
              icon: Icons.layers_rounded,
              iconColor: const Color(0xFF2E7D32),
              iconBgColor: const Color(0xFFE8F5E9),
              title: '${_allLots.length}',
              subtitle: s.kTotalLots,
            ),
          ),
          Container(
            height: 38,
            width: 1,
            color: borderCol,
          ),
          Expanded(
            child: _buildSummaryItem(
              context: context,
              icon: Icons.square_foot_rounded,
              iconColor: const Color(0xFF00796B),
              iconBgColor: const Color(0xFFE0F2F1),
              title: '${_totalSurface.toStringAsFixed(1)} $_surfaceUnit',
              subtitle: s.kTotalSurfaceLabel,
            ),
          ),
          Container(
            height: 38,
            width: 1,
            color: borderCol,
          ),
          Expanded(
            child: _buildSummaryItem(
              context: context,
              icon: Icons.grid_view_rounded,
              iconColor: const Color(0xFFE65100),
              iconBgColor: const Color(0xFFFFF3E0),
              title: '$_totalSubplotsCount',
              subtitle: s.kTotalSubplots,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    final isDark = AppColors.isDark(context);
    final brandColor =
        isDark ? AppColors.primaryLight : const Color(0xFF0F5A37);
    final subtextColor = AppColors.getTextMuted(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? iconBgColor.withValues(alpha: 0.2) : iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 17,
              color: isDark ? AppColors.primaryLight : iconColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: brandColor,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: subtextColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        Row(
          children: [
            Icon(
              Icons.format_list_bulleted_rounded,
              size: 18,
              color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
            ),
            const SizedBox(width: 8),
            Text(
              s.kRegisteredLotsTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF5EC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2C3E33)
                  : const Color(0xFFC8E6C9),
            ),
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

    final cropDef =
        lotCrop ?? (subplotsCrops.isNotEmpty ? subplotsCrops.first : null);
    final cropBadgeText = lotCrop != null
        ? lotCrop.localizedName(isSpanish)
        : (subplotsCrops.isNotEmpty
            ? subplotsCrops.map((c) => c.localizedName(isSpanish)).join(', ')
            : null);

    final IconData cropIcon = cropDef?.icon ?? Icons.park_rounded;
    final Color cropColor = cropDef?.color ??
        (isDark ? AppColors.primaryLight : const Color(0xFF2E7D32));
    final Color cropBgColor = isDark
        ? (cropDef?.color.withValues(alpha: 0.22) ?? const Color(0xFF233529))
        : (cropDef?.bgColor ?? const Color(0xFFEAF5EC));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderCol,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToSubplots(lot),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cropBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          cropIcon,
                          color: cropColor,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (cropBadgeText != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF243329)
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    cropBadgeText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.primaryLight
                                          : const Color(0xFF2E7D32),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2822)
                            : const Color(0xFFF1F8F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2C3E33)
                              : const Color(0xFFC8E6C9),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.square_foot_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.primaryLight
                                : const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$surface $_surfaceUnit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : const Color(0xFF2E7D32),
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
                        size: 20,
                      ),
                      tooltip: s.kEditLot,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () => _openEditLotModal(lot),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: borderCol.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B231D)
                            : const Color(0xFFF4F6F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 13,
                            color: subtextCol,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            subplotsCount > 0
                                ? '$subplotsCount ${subplotsCount == 1 ? s.kSubplotSingular : s.kSubplotsCount}'
                                : (isSpanish
                                    ? 'Lote continuo'
                                    : 'Continuous lot'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subtextCol,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSpanish ? 'Ver parcelas' : 'View subplots',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF233529) : const Color(0xFFEAF5EC),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFA5D6A7),
                width: 1.5,
              ),
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.landscape_rounded,
              size: 36,
              color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? s.kNoLotsFound : s.kNoLotsRegistered,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
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
          const SizedBox(height: 20),
          if (isSearching)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(
                  color: isDark
                      ? AppColors.primaryLight
                      : const Color(0xFF0F5A37),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              child: Text(s.kFilterAll),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.primary : const Color(0xFF0F5A37),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 2,
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
