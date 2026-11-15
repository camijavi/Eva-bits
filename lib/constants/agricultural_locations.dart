/// Predefined agricultural regions and countries supported for NASA Earth Observations.
/// NASA POWER and SMAP APIs have global grid coverage (-90° to +90° Lat, -180° to +180° Lon).
class AgriculturalLocation {
  final String id;
  final String displayName;
  final String country;
  final String region;
  final double latitude;
  final double longitude;

  const AgriculturalLocation({
    required this.id,
    required this.displayName,
    required this.country,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  /// The custom/other option allows entering custom coordinates or using device GPS anywhere globally.
  static const String customId = 'custom_global';

  static const List<AgriculturalLocation> presets = [
    // --- Nicaragua (Local Agroecological Hubs) ---
    AgriculturalLocation(
      id: 'nic_esteli',
      displayName: '🇳🇮 Nicaragua - Estelí (Corredor Seco)',
      country: 'Nicaragua',
      region: 'Estelí',
      latitude: 13.0910,
      longitude: -86.3538,
    ),
    AgriculturalLocation(
      id: 'nic_matagalpa',
      displayName: '🇳🇮 Nicaragua - Matagalpa (Café & Granos)',
      country: 'Nicaragua',
      region: 'Matagalpa',
      latitude: 12.9256,
      longitude: -85.9175,
    ),
    AgriculturalLocation(
      id: 'nic_jinotega',
      displayName: '🇳🇮 Nicaragua - Jinotega (Café de Altura)',
      country: 'Nicaragua',
      region: 'Jinotega',
      latitude: 13.0905,
      longitude: -86.0028,
    ),
    AgriculturalLocation(
      id: 'nic_leon',
      displayName: '🇳🇮 Nicaragua - León (Caña & Granos)',
      country: 'Nicaragua',
      region: 'León',
      latitude: 12.4379,
      longitude: -86.8780,
    ),
    AgriculturalLocation(
      id: 'nic_chinandega',
      displayName: '🇳🇮 Nicaragua - Chinandega (Agro Intensivo)',
      country: 'Nicaragua',
      region: 'Chinandega',
      latitude: 12.6294,
      longitude: -87.1311,
    ),
    AgriculturalLocation(
      id: 'nic_rivas',
      displayName: '🇳🇮 Nicaragua - Rivas (Plátano & Caña)',
      country: 'Nicaragua',
      region: 'Rivas',
      latitude: 11.4372,
      longitude: -85.8263,
    ),

    // --- United States (Major Agricultural Belts) ---
    AgriculturalLocation(
      id: 'usa_midwest',
      displayName: '🇺🇸 United States - Midwest / Corn Belt (Iowa / Illinois)',
      country: 'United States',
      region: 'Midwest',
      latitude: 41.8780,
      longitude: -93.0977,
    ),
    AgriculturalLocation(
      id: 'usa_california',
      displayName: '🇺🇸 United States - California (Central Valley)',
      country: 'United States',
      region: 'California',
      latitude: 36.7783,
      longitude: -119.4179,
    ),
    AgriculturalLocation(
      id: 'usa_plains',
      displayName: '🇺🇸 United States - Great Plains / Wheat Belt (Kansas)',
      country: 'United States',
      region: 'Great Plains',
      latitude: 38.5266,
      longitude: -96.7265,
    ),
    AgriculturalLocation(
      id: 'usa_southeast',
      displayName: '🇺🇸 United States - Southeast (Florida / Georgia)',
      country: 'United States',
      region: 'Southeast',
      latitude: 28.3744,
      longitude: -81.5494,
    ),

    // --- Latin America & Caribbean ---
    AgriculturalLocation(
      id: 'mex_bajio',
      displayName: '🇲🇽 México - El Bajío / Jalisco (Granos & Hortalizas)',
      country: 'México',
      region: 'El Bajío',
      latitude: 20.6597,
      longitude: -103.3496,
    ),
    AgriculturalLocation(
      id: 'col_coffee',
      displayName: '🇨🇴 Colombia - Eje Cafetero (Caldas / Quindío)',
      country: 'Colombia',
      region: 'Eje Cafetero',
      latitude: 4.5350,
      longitude: -75.6757,
    ),
    AgriculturalLocation(
      id: 'bra_cerrado',
      displayName: '🇧🇷 Brasil - Mato Grosso (Cerrado Agro)',
      country: 'Brasil',
      region: 'Mato Grosso',
      latitude: -12.6819,
      longitude: -55.6186,
    ),
    AgriculturalLocation(
      id: 'arg_pampa',
      displayName: '🇦🇷 Argentina - Pampa Húmeda (Buenos Aires / Córdoba)',
      country: 'Argentina',
      region: 'Pampa Húmeda',
      latitude: -34.6037,
      longitude: -58.3816,
    ),
    AgriculturalLocation(
      id: 'gtm_altiplano',
      displayName: '🇬🇹 Guatemala - Altiplano Occidental',
      country: 'Guatemala',
      region: 'Altiplano',
      latitude: 14.8347,
      longitude: -91.5180,
    ),
    AgriculturalLocation(
      id: 'hnd_comayagua',
      displayName: '🇭🇳 Honduras - Valle de Comayagua',
      country: 'Honduras',
      region: 'Comayagua',
      latitude: 14.4594,
      longitude: -87.6372,
    ),
    AgriculturalLocation(
      id: 'cri_valle',
      displayName: '🇨🇷 Costa Rica - Valle Central / Alajuela',
      country: 'Costa Rica',
      region: 'Valle Central',
      latitude: 10.0163,
      longitude: -84.2116,
    ),

    // --- Global Agricultural Zones (Europe, Africa, Asia, Oceania) ---
    AgriculturalLocation(
      id: 'esp_andalucia',
      displayName: '🇪🇸 España - Andalucía (Olivares & Huertas)',
      country: 'España',
      region: 'Andalucía',
      latitude: 37.3891,
      longitude: -5.9845,
    ),
    AgriculturalLocation(
      id: 'ind_punjab',
      displayName: '🇮🇳 India - Punjab (Indo-Gangetic Plain)',
      country: 'India',
      region: 'Punjab',
      latitude: 31.1471,
      longitude: 75.3412,
    ),
    AgriculturalLocation(
      id: 'ken_rift',
      displayName: '🇰🇪 Kenya - Rift Valley (Maize & Tea)',
      country: 'Kenya',
      region: 'Rift Valley',
      latitude: 0.5143,
      longitude: 35.2698,
    ),
    AgriculturalLocation(
      id: 'aus_murray',
      displayName: '🇦🇺 Australia - Murray-Darling Basin',
      country: 'Australia',
      region: 'Murray-Darling',
      latitude: -34.1132,
      longitude: 142.1648,
    ),
  ];

  /// Finds matching preset by exact id or fuzzy name matching.
  static AgriculturalLocation? findByText(String text) {
    if (text.trim().isEmpty) return null;
    final lower = text.toLowerCase();
    for (final loc in presets) {
      if (loc.id == text ||
          loc.displayName.toLowerCase().contains(lower) ||
          loc.region.toLowerCase().contains(lower) ||
          loc.country.toLowerCase() == lower) {
        return loc;
      }
    }
    return null;
  }
}
