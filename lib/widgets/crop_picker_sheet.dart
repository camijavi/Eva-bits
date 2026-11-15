import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/crop_types.dart';
import '../languages/app_strings.dart';

/// Shows a non-overwhelming, categorized, and searchable modal to pick one of the 16 crops.
Future<String?> showCropPickerModal(
  BuildContext context, {
  String? selectedCropKey,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CropPickerSheet(
      selectedCropKey: selectedCropKey,
    ),
  );
}

class CropPickerSheet extends StatefulWidget {
  final String? selectedCropKey;

  const CropPickerSheet({
    super.key,
    this.selectedCropKey,
  });

  @override
  State<CropPickerSheet> createState() => _CropPickerSheetState();
}

class _CropPickerSheetState extends State<CropPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CropCategory? _selectedCategory; // null = all

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CropDefinition> get _filteredCrops {
    final isSpanish = AppLanguage.isSpanish;
    return CropTypes.all.where((crop) {
      // Category filter
      if (_selectedCategory != null && crop.category != _selectedCategory) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = crop.localizedName(isSpanish).toLowerCase();
        final nameEn = crop.nameEn.toLowerCase();
        final nameEs = crop.nameEs.toLowerCase();
        return name.contains(_searchQuery) ||
            nameEn.contains(_searchQuery) ||
            nameEs.contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLanguage.strings;
    final isSpanish = AppLanguage.isSpanish;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final filtered = _filteredCrops;

    final isDark = AppColors.isDark(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.getModalBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.22)
                      : const Color(0xFFEAF5EC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.eco_rounded,
                    color: isDark ? AppColors.primaryLight : const Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.kAssignCrop,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.kCropHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selectedCropKey != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Navigator.of(context).pop(''), // empty = clear
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(
                    s.kClearCrop,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Search Field
          Container(
            decoration: BoxDecoration(
              color: AppColors.getInputBg(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: s.kSearchCropHint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextMuted(context),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: AppColors.getTextMuted(context),
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  label: s.kAllCrops,
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  label: s.kCategoryGrains,
                  isSelected: _selectedCategory == CropCategory.grains,
                  onTap: () => setState(() => _selectedCategory = CropCategory.grains),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  label: s.kCategoryCommercial,
                  isSelected: _selectedCategory == CropCategory.commercial,
                  onTap: () => setState(() => _selectedCategory = CropCategory.commercial),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  label: s.kCategoryFruits,
                  isSelected: _selectedCategory == CropCategory.fruits,
                  onTap: () => setState(() => _selectedCategory = CropCategory.fruits),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Crop Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s.kNoLotsFound,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final crop = filtered[index];
                      final isSelected = widget.selectedCropKey == crop.key;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).pop(crop.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF1E3324)
                                    : const Color(0xFFEAF5EC))
                                : AppColors.getCardBg(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.primaryLight
                                      : const Color(0xFF0F5A37))
                                  : AppColors.getBorder(context),
                              width: isSelected ? 1.8 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? crop.color.withValues(alpha: 0.24)
                                      : crop.bgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    crop.icon,
                                    size: 18,
                                    color: isDark ? AppColors.primaryLight : crop.textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  crop.localizedName(isSpanish),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? (isDark ? AppColors.primaryLight : const Color(0xFF0F5A37))
                                        : AppColors.getTextPrimary(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: isDark ? AppColors.primaryLight : const Color(0xFF0F5A37),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.getChipBg(context, isSelected: isSelected),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.getChipBorder(context, isSelected: isSelected),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textPrimaryDark : const Color(0xFF4A5568)),
          ),
        ),
      ),
    );
  }
}
