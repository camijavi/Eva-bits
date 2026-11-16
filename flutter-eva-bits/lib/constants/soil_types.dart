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
      key: 'arenoso',
      label: (s) => s.kSoilSandy,
      bgColor: const Color(0xFFFFF8E1),
      borderColor: const Color(0xFFFFECB3),
      textColor: const Color(0xFFF57F17),
      barColor: const Color(0xFFFFB300),
      icon: Icons.grain_rounded,
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
      key: 'limoso',
      label: (s) => s.kSoilSilt,
      bgColor: const Color(0xFFECEFF1),
      borderColor: const Color(0xFFCFD8DC),
      textColor: const Color(0xFF37474F),
      barColor: const Color(0xFF607D8B),
      icon: Icons.water_damage_rounded,
    ),
    SoilTypeDefinition(
      key: 'franco',
      label: (s) => s.kSoilLoam,
      bgColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFFA5D6A7),
      textColor: const Color(0xFF1B5E20),
      barColor: const Color(0xFF2E7D32),
      icon: Icons.grass_rounded,
    ),
  ];

  static SoilTypeDefinition getByKey(String? key) {
    if (key == null || key.isEmpty) {
      return defaultDefinition;
    }
    for (final type in all) {
      if (type.key == key) return type;
    }
    // Gracefully map legacy or alternative keys to the 4 core types
    final lower = key.toLowerCase();
    if (lower.contains('aren')) {
      return all[0]; // arenoso
    } else if (lower.contains('arcill')) {
      return all[1]; // arcilloso
    } else if (lower.contains('lim')) {
      return all[2]; // limoso
    } else if (lower.contains('franc')) {
      return all[3]; // franco
    }
    return defaultDefinition;
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
