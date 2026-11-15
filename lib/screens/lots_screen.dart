import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../widgets/bottom_nav_bar.dart';
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
        final subplots = (lot['subplots'] as List<dynamic>?) ?? [];
        final hasMatchingSubplot = subplots.any((sub) =>
            (sub['name'] ?? '').toString().toLowerCase().contains(
                _searchQuery));

        return name.contains(_searchQuery) ||
            surface.contains(_searchQuery) ||
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
      // Keep default order (by id)
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

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF8),
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
                    _buildTopBar(context, s),
                    const SizedBox(height: 12),
                    _buildTitleAndSubtitle(s),
                    const SizedBox(height: 16),
                    _buildSearchField(s),
                    const SizedBox(height: 20),
                    _buildPriorityFilterSection(s),
                    const SizedBox(height: 20),
                    _buildQuickSummaryCard(s),
                    const SizedBox(height: 24),
                    _buildRegisteredLotsHeader(s, filteredLots.length),
                    const SizedBox(height: 12),
                    if (filteredLots.isEmpty)
                      _buildEmptyState(s)
                    else
                      ...filteredLots.map((lot) => _buildLotCard(s, lot)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, AppStrings s) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _openAddLotModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_rounded,
                  color: Color(0xFF0F5A37),
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  s.kAddLot,
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
      ),
    );
  }

  Widget _buildTitleAndSubtitle(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.kLotsScreenTitle,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F5A37),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.kLotsScreenSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppStrings s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B2E1C),
        ),
        decoration: InputDecoration(
          hintText: s.kSearchLotsHint,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF0F5A37),
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

  Widget _buildPriorityFilterSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.kFilterPriorityTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2E1C),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: s.kFilterAll,
                isSelected: _selectedPriority == LotFilterPriority.all,
                onTap: () =>
                    setState(() => _selectedPriority = LotFilterPriority.all),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: s.kFilterLargest,
                isSelected: _selectedPriority ==
                    LotFilterPriority.largestSurface,
                onTap: () =>
                    setState(() =>
                _selectedPriority = LotFilterPriority.largestSurface),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: s.kFilterSmallest,
                isSelected: _selectedPriority ==
                    LotFilterPriority.smallestSurface,
                onTap: () =>
                    setState(() =>
                _selectedPriority = LotFilterPriority.smallestSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Style matches the image attached:
    // Selected is solid dark green pill with white text.
    // Inactive is light soft pill with dark text.
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F5A37) : const Color(
                0xFFE2E8F0),
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
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSummaryCard(AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.layers_outlined,
            title: '${_allLots.length}',
            subtitle: s.kTotalLots,
          ),
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFC8E6C9),
          ),
          _buildSummaryItem(
            icon: Icons.square_foot_rounded,
            title: '${_totalSurface.toStringAsFixed(1)} $_surfaceUnit',
            subtitle: s.kTotalSurfaceLabel,
          ),
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFC8E6C9),
          ),
          _buildSummaryItem(
            icon: Icons.grid_view_rounded,
            title: '$_totalSubplotsCount',
            subtitle: s.kTotalSubplots,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0F5A37)),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F5A37),
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
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredLotsHeader(AppStrings s, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          s.kRegisteredLotsTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2E1C),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F5A37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLotCard(AppStrings s, Map<String, dynamic> lot) {
    final name = lot['name']?.toString() ?? s.kLot;
    final surface = lot['surface']?.toString() ?? '0';
    final subplots = (lot['subplots'] as List<dynamic>?) ?? [];
    final subplotsCount = subplots.length;

    final subplotsInfo = subplotsCount > 0
        ? '$subplotsCount ${subplotsCount == 1 ? s.kSubplotSingular : s
        .kSubplotsCount}'
        : null;

    final detailsText = subplotsInfo != null
        ? '$surface $_surfaceUnit • $subplotsInfo'
        : '$surface $_surfaceUnit';

    // UI mirrors the image attached:
    // White rounded rectangle card with subtle light gray border.
    // Left: circular soft green background badge with green plant icon.
    // Center: bold title + subtitle text.
    // Right: pen icon for editing + chevron.
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
          onTap: () => _navigateToSubplots(lot),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Soft green circular icon badge
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

                // Lot Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2D24),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detailsText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pen icon to handle editing
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0F5A37),
                    size: 22,
                  ),
                  tooltip: s.kEditLot,
                  onPressed: () => _openEditLotModal(lot),
                ),

                // Chevron icon (as in the screenshot)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9E9E9E),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    final isSearching = _searchQuery.isNotEmpty;

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
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5EC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.landscape_outlined,
              size: 34,
              color: const Color(0xFF0F5A37),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? s.kNoLotsFound : s.kNoLotsRegistered,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E1C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? '${s.kNoLotsFound} "$_searchQuery"'
                : s.kNoLotsYetSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
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
                backgroundColor: const Color(0xFF0F5A37),
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
