import 'package:flutter/material.dart';
import '../languages/app_strings.dart';

class SoilTypeDefinition {
  final String key;
  final String Function(AppStrings s) label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color barColor;
  final IconData icon;

  const SoilTypeDefinition({
    required this.key,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.barColor,
    required this.icon,
  });
}

class SoilTypes {
  static final List<SoilTypeDefinition> all = [
    SoilTypeDefinition(
      key: 'franco',
      label: (s) => s.kSoilLoam,
      bgColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFFA5D6A7),
      textColor: const Color(0xFF1B5E20),
      barColor: const Color(0xFF2E7D32),
      icon: Icons.grass_rounded,
    ),
    SoilTypeDefinition(
      key: 'arcilloso',
      label: (s) => s.kSoilClay,
      bgColor: const Color(0xFFFBE9E7),
      borderColor: const Color(0xFFFFCCBC),
      textColor: const Color(0xFFD84315),
      barColor: const Color(0xFFE64A19),
      icon: Icons.layers_rounded,
    ),
    SoilTypeDefinition(
      key: 'arenoso',
      label: (s) => s.kSoilSandy,
      bgColor: const Color(0xFFFFF8E1),
      borderColor: const Color(0xFFFFECB3),
      textColor: const Color(0xFFF57F17),
      barColor: const Color(0xFFFFB300),
      icon: Icons.grain_rounded,
    ),
    SoilTypeDefinition(
      key: 'franco_arcilloso',
      label: (s) => s.kSoilClayLoam,
      bgColor: const Color(0xFFEFEBE9),
      borderColor: const Color(0xFFD7CCC8),
      textColor: const Color(0xFF4E342E),
      barColor: const Color(0xFF8D6E63),
      icon: Icons.terrain_rounded,
    ),
    SoilTypeDefinition(
      key: 'franco_arenoso',
      label: (s) => s.kSoilSandyLoam,
      bgColor: const Color(0xFFF9FBE7),
      borderColor: const Color(0xFFE6EE9C),
      textColor: const Color(0xFF827717),
      barColor: const Color(0xFF9E9D24),
      icon: Icons.scatter_plot_rounded,
    ),
    SoilTypeDefinition(
      key: 'limoso',
      label: (s) => s.kSoilSilt,
      bgColor: const Color(0xFFECEFF1),
      borderColor: const Color(0xFFCFD8DC),
      textColor: const Color(0xFF37474F),
      barColor: const Color(0xFF607D8B),
      icon: Icons.water_damage_rounded,
    ),
    SoilTypeDefinition(
      key: 'humifero',
      label: (s) => s.kSoilOrganic,
      bgColor: const Color(0xFFE0F2F1),
      borderColor: const Color(0xFFB2DFDB),
      textColor: const Color(0xFF004D40),
      barColor: const Color(0xFF00796B),
      icon: Icons.compost_rounded,
    ),
    SoilTypeDefinition(
      key: 'pedregoso',
      label: (s) => s.kSoilRocky,
      bgColor: const Color(0xFFF5F5F5),
      borderColor: const Color(0xFFE0E0E0),
      textColor: const Color(0xFF424242),
      barColor: const Color(0xFF757575),
      icon: Icons.landscape_rounded,
    ),
  ];

  static SoilTypeDefinition getByKey(String? key) {
    if (key == null || key.isEmpty) {
      return defaultDefinition;
    }
    return all.firstWhere(
      (type) => type.key == key,
      orElse: () => defaultDefinition,
    );
  }

  static final SoilTypeDefinition defaultDefinition = SoilTypeDefinition(
    key: 'unknown',
    label: (s) => s.kSoilUnknown,
    bgColor: const Color(0xFFF1F5F2),
    borderColor: const Color(0xFFE2E8F0),
    textColor: const Color(0xFF4A5568),
    barColor: const Color(0xFF9E9E9E),
    icon: Icons.help_outline_rounded,
  );
}
