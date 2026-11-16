import 'package:flutter/material.dart';

enum CropCategory {
  grains,
  commercial,
  fruits,
}

class CropDefinition {
  final String key;
  final String nameEn;
  final String nameEs;
  final IconData icon;
  final CropCategory category;
  final Color color;
  final Color bgColor;
  final Color textColor;

  const CropDefinition({
    required this.key,
    required this.nameEn,
    required this.nameEs,
    required this.icon,
    required this.category,
    required this.color,
    required this.bgColor,
    required this.textColor,
  });

  String localizedName(bool isSpanish) => isSpanish ? nameEs : nameEn;
}

class CropTypes {
  static const List<CropDefinition> all = [
    // Grains & Legumes
    CropDefinition(
      key: 'corn',
      nameEn: 'Corn',
      nameEs: 'Maíz',
      icon: Icons.grass_rounded,
      category: CropCategory.grains,
      color: Color(0xFFF57F17),
      bgColor: Color(0xFFFFF9E6),
      textColor: Color(0xFFB76E00),
    ),
    CropDefinition(
      key: 'beans',
      nameEn: 'Beans',
      nameEs: 'Frijol',
      icon: Icons.egg_alt_rounded,
      category: CropCategory.grains,
      color: Color(0xFF8D4925),
      bgColor: Color(0xFFFBE9E7),
      textColor: Color(0xFF6D3012),
    ),
    CropDefinition(
      key: 'rice',
      nameEn: 'Rice',
      nameEs: 'Arroz',
      icon: Icons.rice_bowl_rounded,
      category: CropCategory.grains,
      color: Color(0xFF558B2F),
      bgColor: Color(0xFFF1F8E9),
      textColor: Color(0xFF33691E),
    ),
    CropDefinition(
      key: 'soybean',
      nameEn: 'Soybean',
      nameEs: 'Soya',
      icon: Icons.spa_rounded,
      category: CropCategory.grains,
      color: Color(0xFF689F38),
      bgColor: Color(0xFFF4F9ED),
      textColor: Color(0xFF33691E),
    ),
    CropDefinition(
      key: 'wheat',
      nameEn: 'Wheat',
      nameEs: 'Trigo',
      icon: Icons.grain_rounded,
      category: CropCategory.grains,
      color: Color(0xFFD4A017),
      bgColor: Color(0xFFFFFDE7),
      textColor: Color(0xFF9E7800),
    ),

    // Commercial & Cash Crops
    CropDefinition(
      key: 'coffee',
      nameEn: 'Coffee',
      nameEs: 'Café',
      icon: Icons.coffee_rounded,
      category: CropCategory.commercial,
      color: Color(0xFF5D4037),
      bgColor: Color(0xFFEFEBE9),
      textColor: Color(0xFF3E2723),
    ),
    CropDefinition(
      key: 'sugarcane',
      nameEn: 'Sugarcane',
      nameEs: 'Caña de azúcar',
      icon: Icons.forest_rounded,
      category: CropCategory.commercial,
      color: Color(0xFF2E7D32),
      bgColor: Color(0xFFE8F5E9),
      textColor: Color(0xFF1B5E20),
    ),

    // Fruits
    CropDefinition(
      key: 'plantain',
      nameEn: 'Plantain',
      nameEs: 'Plátano',
      icon: Icons.energy_savings_leaf_rounded,
      category: CropCategory.fruits,
      color: Color(0xFFE65100),
      bgColor: Color(0xFFFFF3E0),
      textColor: Color(0xFFBF360C),
    ),
    CropDefinition(
      key: 'banana',
      nameEn: 'Banana',
      nameEs: 'Banano',
      icon: Icons.yard_rounded,
      category: CropCategory.fruits,
      color: Color(0xFFF9A825),
      bgColor: Color(0xFFFFFDE7),
      textColor: Color(0xFFB77900),
    ),
    CropDefinition(
      key: 'watermelon',
      nameEn: 'Watermelon',
      nameEs: 'Sandía',
      icon: Icons.water_drop_rounded,
      category: CropCategory.fruits,
      color: Color(0xFFC2185B),
      bgColor: Color(0xFFFCE4EC),
      textColor: Color(0xFF880E4F),
    ),
    CropDefinition(
      key: 'melon',
      nameEn: 'Melon',
      nameEs: 'Melón',
      icon: Icons.circle_rounded,
      category: CropCategory.fruits,
      color: Color(0xFF827717),
      bgColor: Color(0xFFF9FBE7),
      textColor: Color(0xFF554E00),
    ),
    CropDefinition(
      key: 'pineapple',
      nameEn: 'Pineapple',
      nameEs: 'Piña',
      icon: Icons.park_rounded,
      category: CropCategory.fruits,
      color: Color(0xFFE65100),
      bgColor: Color(0xFFFFF8E1),
      textColor: Color(0xFF9E3D00),
    ),
    CropDefinition(
      key: 'mango',
      nameEn: 'Mango',
      nameEs: 'Mango',
      icon: Icons.local_florist_rounded,
      category: CropCategory.fruits,
      color: Color(0xFFEF6C00),
      bgColor: Color(0xFFFFF3E0),
      textColor: Color(0xFFB54500),
    ),
    CropDefinition(
      key: 'orange',
      nameEn: 'Orange',
      nameEs: 'Naranja',
      icon: Icons.brightness_7_rounded,
      category: CropCategory.fruits,
      color: Color(0xFFF57C00),
      bgColor: Color(0xFFFFF3E0),
      textColor: Color(0xFFB25000),
    ),
    CropDefinition(
      key: 'apple',
      nameEn: 'Apple',
      nameEs: 'Manzana',
      icon: Icons.eco_rounded,
      category: CropCategory.fruits,
      color: Color(0xFFC62828),
      bgColor: Color(0xFFFFEBEE),
      textColor: Color(0xFF8E0000),
    ),
    CropDefinition(
      key: 'grapes',
      nameEn: 'Grapes',
      nameEs: 'Uvas',
      icon: Icons.bubble_chart_rounded,
      category: CropCategory.fruits,
      color: Color(0xFF6A1B9A),
      bgColor: Color(0xFFF3E5F5),
      textColor: Color(0xFF4A148C),
    ),
  ];

  /// Top most popular/frequent crops in Central/Latin America for 1-tap quick pick
  static const List<String> popularKeys = [
    'corn',
    'beans',
    'coffee',
    'rice',
  ];

  static CropDefinition? getByKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final normalized = key.trim().toLowerCase();
    for (final crop in all) {
      if (crop.key == normalized ||
          crop.nameEn.toLowerCase() == normalized ||
          crop.nameEs.toLowerCase() == normalized) {
        return crop;
      }
    }
    return null;
  }
}
