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

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.grey.shade300,
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
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF5EC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF2E7D32),
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
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E1C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.kCropHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
              color: const Color(0xFFF9FBF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.kSearchCropHint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
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

          // Frequent / Quick Pick Row (when not actively searching)
          if (_searchQuery.isEmpty && _selectedCategory == null) ...[
            Text(
              s.kPopularCrops,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CropTypes.popularKeys.map((key) {
                  final crop = CropTypes.getByKey(key);
                  if (crop == null) return const SizedBox.shrink();
                  final isSelected = widget.selectedCropKey == crop.key;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(crop.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFEAF5EC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFC8E6C9),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              crop.icon,
                              size: 16,
                              color: isSelected ? Colors.white : crop.textColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              crop.localizedName(isSpanish),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF0F5A37),
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
            const SizedBox(height: 14),
          ],

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
                            color: isSelected ? const Color(0xFFEAF5EC) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFE5E7EB),
                              width: isSelected ? 1.8 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
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
                                  color: crop.bgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    crop.icon,
                                    size: 18,
                                    color: crop.textColor,
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
                                    color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFF1B2E1C),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: Color(0xFF0F5A37),
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F5A37) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }
}
