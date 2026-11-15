import 'dart:math' as math;
import 'subplot_graph_service.dart';

// =============================================================================
// DATA MODELS FOR THE 6 PREDICTIONS
// =============================================================================

/// 1. Gestor de Riego y Déficit Hídrico a 7 Días
class IrrigationPrediction {
  final String status; // 'optimal' (Verde), 'moderate' (Amarillo), 'critical' (Rojo)
  final double soilMoisturePct;
  final double weeklyDeficitMm;
  final int daysUntilStress;
  final double recommendedWaterMm;
  final String actionTitle;
  final String actionRecommendation;

  const IrrigationPrediction({
    required this.status,
    required this.soilMoisturePct,
    required this.weeklyDeficitMm,
    required this.daysUntilStress,
    required this.recommendedWaterMm,
    required this.actionTitle,
    required this.actionRecommendation,
  });

  Map<String, dynamic> toMap() => {
        'status': status,
        'soil_moisture_pct': soilMoisturePct,
        'weekly_deficit_mm': weeklyDeficitMm,
        'days_until_stress': daysUntilStress,
        'recommended_water_mm': recommendedWaterMm,
        'action_title': actionTitle,
        'action_recommendation': actionRecommendation,
      };
}

/// 2. Simulador de Rotación y Compatibilidad Espacial
class RotationCompatibilityPrediction {
  final int score; // 0 to 100%
  final String compatibilityLevel; // 'Alta', 'Media', 'Desaconsejada'
  final String suggestedCrop;
  final List<String> alternativeCrops;
  final bool hasSpatialCorridorRisk;
  final String explanation;

  const RotationCompatibilityPrediction({
    required this.score,
    required this.compatibilityLevel,
    required this.suggestedCrop,
    required this.alternativeCrops,
    required this.hasSpatialCorridorRisk,
    required this.explanation,
  });

  Map<String, dynamic> toMap() => {
        'score': score,
        'compatibility_level': compatibilityLevel,
        'suggested_crop': suggestedCrop,
        'alternative_crops': alternativeCrops,
        'has_spatial_corridor_risk': hasSpatialCorridorRisk,
        'explanation': explanation,
      };
}

/// 3. Calendario Agrícola y Ventana de Siembra (GDD)
class PlantingCalendarPrediction {
  final bool isWindowOpen;
  final String windowStatus; // 'Óptima', 'Desfavorable', 'Esperar humedad'
  final String recommendedDateRange;
  final double accumulatedGdd7d;
  final int estimatedDaysToFlowering;
  final String thermalAdvice;

  const PlantingCalendarPrediction({
    required this.isWindowOpen,
    required this.windowStatus,
    required this.recommendedDateRange,
    required this.accumulatedGdd7d,
    required this.estimatedDaysToFlowering,
    required this.thermalAdvice,
  });

  Map<String, dynamic> toMap() => {
        'is_window_open': isWindowOpen,
        'window_status': windowStatus,
        'recommended_date_range': recommendedDateRange,
        'accumulated_gdd_7d': accumulatedGdd7d,
        'days_to_flowering': estimatedDaysToFlowering,
        'thermal_advice': thermalAdvice,
      };
}

/// 4. Salud del Cultivo y Proyección de Rendimiento (NDVI Proxy)
class CropHealthPrediction {
  final String vigorStatus; // 'Excelente', 'Normal', 'Bajo estrés'
  final double estimatedNdviProxy; // 0.0 to 1.0
  final double expectedYieldRatioPct; // e.g. 88.5%
  final String biomassCondition;

  const CropHealthPrediction({
    required this.vigorStatus,
    required this.estimatedNdviProxy,
    required this.expectedYieldRatioPct,
    required this.biomassCondition,
  });

  Map<String, dynamic> toMap() => {
        'vigor_status': vigorStatus,
        'estimated_ndvi_proxy': estimatedNdviProxy,
        'expected_yield_ratio_pct': expectedYieldRatioPct,
        'biomass_condition': biomassCondition,
      };
}

/// 5. Alerta Temprana de Sequía Relámpago y Encharcamiento
class ExtremeRiskAlert {
  final String alertType; // 'none', 'flash_drought', 'waterlogging', 'heat_stress'
  final String severity; // 'info', 'warning', 'danger'
  final String headline;
  final String mitigationAdvice;

  const ExtremeRiskAlert({
    required this.alertType,
    required this.severity,
    required this.headline,
    required this.mitigationAdvice,
  });

  Map<String, dynamic> toMap() => {
        'alert_type': alertType,
        'severity': severity,
        'headline': headline,
        'mitigation_advice': mitigationAdvice,
      };
}

/// 6. Balance Nutricional y Regeneración del Suelo
class SoilNutritionPrediction {
  final double projectedNitrogenGainKgPerHa;
  final double totalFarmNitrogenGainKg;
  final int soilHealthScore; // 0 to 100
  final double estimatedUreaSavingsKg;
  final String regenerationDiagnosis;

  const SoilNutritionPrediction({
    required this.projectedNitrogenGainKgPerHa,
    required this.totalFarmNitrogenGainKg,
    required this.soilHealthScore,
    required this.estimatedUreaSavingsKg,
    required this.regenerationDiagnosis,
  });

  Map<String, dynamic> toMap() => {
        'nitrogen_gain_kg_ha': projectedNitrogenGainKgPerHa,
        'total_farm_nitrogen_kg': totalFarmNitrogenGainKg,
        'soil_health_score': soilHealthScore,
        'estimated_urea_savings_kg': estimatedUreaSavingsKg,
        'regeneration_diagnosis': regenerationDiagnosis,
      };
}

/// Comprehensive Report bundling all 6 Predictions
class FarmPredictionsReport {
  final DateTime generatedAt;
  final IrrigationPrediction irrigation;
  final RotationCompatibilityPrediction rotation;
  final PlantingCalendarPrediction calendar;
  final CropHealthPrediction health;
  final ExtremeRiskAlert risks;
  final SoilNutritionPrediction nutrition;

  const FarmPredictionsReport({
    required this.generatedAt,
    required this.irrigation,
    required this.rotation,
    required this.calendar,
    required this.health,
    required this.risks,
    required this.nutrition,
  });

  Map<String, dynamic> toMap() => {
        'generated_at': generatedAt.toIso8601String(),
        'irrigation_7d': irrigation.toMap(),
        'rotation_simulation': rotation.toMap(),
        'planting_calendar_gdd': calendar.toMap(),
        'crop_health_biomass': health.toMap(),
        'extreme_risks': risks.toMap(),
        'soil_nutrition': nutrition.toMap(),
      };

  /// Prepares a structured payload for LLM (Ivy / gpt-5-mini) grounding.
  Map<String, dynamic> toIvyGroundingPayload() => {
        'timestamp': generatedAt.toIso8601String(),
        'summary_metrics': {
          'irrigation_urgency': irrigation.status,
          'water_deficit_mm': irrigation.weeklyDeficitMm,
          'soil_moisture_pct': irrigation.soilMoisturePct,
          'rotation_score': rotation.score,
          'suggested_rotation': rotation.suggestedCrop,
          'spatial_corridor_risk': rotation.hasSpatialCorridorRisk,
          'planting_window_open': calendar.isWindowOpen,
          'accumulated_gdd': calendar.accumulatedGdd7d,
          'crop_vigor': health.vigorStatus,
          'relative_yield_pct': health.expectedYieldRatioPct,
          'extreme_alert': risks.headline,
          'nitrogen_gain_kg_ha': nutrition.projectedNitrogenGainKgPerHa,
          'soil_health_score': nutrition.soilHealthScore,
        },
      };
}

// =============================================================================
// DETERMINISTIC AGRO-PREDICTION ENGINE
// =============================================================================

class AgroPredictionEngine {
  /// Botanical family mapping to assess biological corridors and crop compatibility
  static const Map<String, String> _botanicalFamilies = {
    'corn': 'Poaceae (Gramíneas)',
    'maíz': 'Poaceae (Gramíneas)',
    'rice': 'Poaceae (Gramíneas)',
    'arroz': 'Poaceae (Gramíneas)',
    'wheat': 'Poaceae (Gramíneas)',
    'trigo': 'Poaceae (Gramíneas)',
    'sugarcane': 'Poaceae (Gramíneas)',
    'caña de azúcar': 'Poaceae (Gramíneas)',
    'sorghum': 'Poaceae (Gramíneas)',
    'sorgo': 'Poaceae (Gramíneas)',
    'beans': 'Fabaceae (Leguminosas)',
    'frijol': 'Fabaceae (Leguminosas)',
    'soybean': 'Fabaceae (Leguminosas)',
    'soya': 'Fabaceae (Leguminosas)',
    'coffee': 'Rubiaceae',
    'café': 'Rubiaceae',
    'plantain': 'Musaceae',
    'plátano': 'Musaceae',
    'banana': 'Musaceae',
    'banano': 'Musaceae',
    'watermelon': 'Cucurbitaceae',
    'sandía': 'Cucurbitaceae',
    'melon': 'Cucurbitaceae',
    'melón': 'Cucurbitaceae',
    'orange': 'Rutaceae',
    'naranja': 'Rutaceae',
    'apple': 'Rosaceae',
    'manzana': 'Rosaceae',
  };

  /// FAO-56 Crop Coefficient (Kc mid-season) for crop water demand
  static const Map<String, double> _cropKc = {
    'corn': 1.15,
    'maíz': 1.15,
    'beans': 1.00,
    'frijol': 1.00,
    'rice': 1.20,
    'arroz': 1.20,
    'soybean': 1.05,
    'soya': 1.05,
    'wheat': 1.10,
    'trigo': 1.10,
    'coffee': 0.95,
    'café': 0.95,
    'sugarcane': 1.25,
    'caña de azúcar': 1.25,
    'plantain': 1.10,
    'plátano': 1.10,
    'banana': 1.10,
    'banano': 1.10,
    'watermelon': 1.00,
    'sandía': 1.00,
    'sorghum': 1.05,
    'sorgo': 1.05,
  };

  /// Soil texture water retention & drainage factors
  /// - Arenoso: Infiltración rápida, baja retención (0.65x). Drena rápido.
  /// - Arcilloso: Infiltración lenta, alta retención (1.35x). Riesgo de asfixia en saturación.
  /// - Limoso: Retención media-alta (1.10x). Susceptible a compactación superficial.
  /// - Franco: Equilibrio agronómico ideal (1.00x).
  static double _getSoilRetentionFactor(String soilType) {
    final lower = soilType.toLowerCase();
    if (lower.contains('aren')) return 0.65;
    if (lower.contains('arcill')) return 1.35;
    if (lower.contains('lim')) return 1.10;
    return 1.0;
  }

  /// Generates the complete deterministic 6-prediction report.
  static FarmPredictionsReport generateReport({
    required Map<String, dynamic> farmData,
    required Map<String, dynamic> nasaData,
    SubplotGraph? graph,
    List<Map<String, dynamic>>? subplots,
    String? targetCrop,
    String? targetSoilType,
  }) {
    final summary = nasaData['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final solarMj =
        (summary['avg_solar_radiation_mj'] as num?)?.toDouble() ?? 18.5;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final farmSurfaceHa =
        (farmData['total_surface'] as num?)?.toDouble() ?? 2.5;

    // Detect active crop and soil type
    String activeCrop = targetCrop ?? 'Maíz';
    String activeSoil = targetSoilType ?? 'Franco';

    if (targetCrop == null && subplots != null && subplots.isNotEmpty) {
      final firstCrop = subplots.first['crop']?.toString();
      if (firstCrop != null && firstCrop.isNotEmpty) {
        activeCrop = firstCrop;
      }
    }
    if (targetSoilType == null && subplots != null && subplots.isNotEmpty) {
      final firstSoil = subplots.first['soil_type']?.toString();
      if (firstSoil != null && firstSoil.isNotEmpty) {
        activeSoil = firstSoil;
      }
    }

    // 1. Irrigation Prediction (adjusted for crop Kc and soil retention)
    final irrigation = _calculateIrrigation(
      soilMoisture: soilMoisture,
      rain7dMm: rainMm,
      tempC: tempC,
      solarMj: solarMj,
      crop: activeCrop,
      soilType: activeSoil,
    );

    // 2. Rotation Simulator Prediction
    final rotation = _calculateRotationSimulation(
      currentCrop: activeCrop,
      soilMoisture: soilMoisture,
      graph: graph,
      subplots: subplots,
    );

    // 3. Planting Calendar & GDD Prediction
    final calendar = _calculatePlantingCalendar(
      tempC: tempC,
      soilMoisture: soilMoisture,
      dominantCrop: activeCrop,
    );

    // 4. Crop Health & Biomass Prediction
    final health = _calculateCropHealth(
      solarMj: solarMj,
      soilMoisture: soilMoisture,
      weeklyDeficitMm: irrigation.weeklyDeficitMm,
    );

    // 5. Extreme Risks & Alerts (tailored for soil texture and climate)
    final risks = _detectExtremeRisks(
      soilMoisture: soilMoisture,
      rain7dMm: rainMm,
      tempC: tempC,
      solarMj: solarMj,
      soilType: activeSoil,
    );

    // 6. Soil Nutrition & Nitrogen Gain (adapted for soil leaching)
    final nutrition = _calculateSoilNutrition(
      currentCrop: activeCrop,
      suggestedRotationCrop: rotation.suggestedCrop,
      farmSurfaceHa: farmSurfaceHa,
      soilType: activeSoil,
    );

    return FarmPredictionsReport(
      generatedAt: DateTime.now(),
      irrigation: irrigation,
      rotation: rotation,
      calendar: calendar,
      health: health,
      risks: risks,
      nutrition: nutrition,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. GESTOR DE RIEGO (Déficit Hídrico a 7 Días)
  // ---------------------------------------------------------------------------
  static IrrigationPrediction _calculateIrrigation({
    required double soilMoisture,
    required double rain7dMm,
    required double tempC,
    required double solarMj,
    String crop = 'Maíz',
    String soilType = 'Franco',
  }) {
    final kc = _cropKc[crop.toLowerCase().trim()] ?? 1.05;
    final retentionFactor = _getSoilRetentionFactor(soilType);

    // Reference evapotranspiration approximation ET0 adjusted by Crop Kc (FAO-56)
    final dailyEt0 = (0.16 * solarMj * (tempC / (tempC + 15))).clamp(2.5, 7.0);
    final weeklyCropWaterDemandMm = dailyEt0 * kc * 7;
    final weeklyDeficitMm =
        math.max(0.0, weeklyCropWaterDemandMm - rain7dMm);

    final soilMoisturePct = (soilMoisture * 100).clamp(0.0, 100.0);

    // Soil texture adjusts days of reserve and critical threshold
    final int daysUntilStress =
        (soilMoisture * 10 * retentionFactor / kc).round().clamp(1, 10);

    final String status;
    final double recommendedWaterMm;
    final String actionTitle;
    final String actionRecommendation;

    final double criticalThreshold =
        (0.40 / math.max(0.7, retentionFactor)).clamp(0.32, 0.48);

    if (soilMoisture < criticalThreshold) {
      status = 'critical';
      recommendedWaterMm =
          (weeklyDeficitMm * (1.1 / retentionFactor)).clamp(18.0, 50.0);
      actionTitle = 'Riego Urgente Requerido';
      actionRecommendation =
          'Humedad radicular crítica ($soilMoisturePct%) en suelo $soilType para $crop (Kc: $kc). Aplica lámina de ${recommendedWaterMm.toStringAsFixed(0)} mm en las próximas 48 h para evitar marchitez.';
    } else if (soilMoisture <= 0.65) {
      status = 'moderate';
      recommendedWaterMm =
          (weeklyDeficitMm * 0.55).clamp(10.0, 28.0);
      actionTitle = 'Humedad Moderada - Monitorear';
      actionRecommendation =
          'Suelo $soilType retiene agua para los próximos $daysUntilStress días. Programa riego preventivo (${recommendedWaterMm.toStringAsFixed(0)} mm) al promediar la semana.';
    } else {
      status = 'optimal';
      recommendedWaterMm = 0.0;
      actionTitle = 'Nivel Hídrico Óptimo';
      actionRecommendation =
          'Reserva hídrica suficiente ($soilMoisturePct%) para $crop en suelo $soilType. No se requiere riego en los siguientes 7 días.';
    }

    return IrrigationPrediction(
      status: status,
      soilMoisturePct: double.parse(soilMoisturePct.toStringAsFixed(1)),
      weeklyDeficitMm: double.parse(weeklyDeficitMm.toStringAsFixed(1)),
      daysUntilStress: daysUntilStress,
      recommendedWaterMm:
          double.parse(recommendedWaterMm.toStringAsFixed(1)),
      actionTitle: actionTitle,
      actionRecommendation: actionRecommendation,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SIMULADOR DE ROTACIÓN Y COMPATIBILIDAD ESPACIAL
  // ---------------------------------------------------------------------------
  static RotationCompatibilityPrediction _calculateRotationSimulation({
    required String currentCrop,
    required double soilMoisture,
    SubplotGraph? graph,
    List<Map<String, dynamic>>? subplots,
  }) {
    int score = 85;
    bool hasCorridorRisk = false;
    final currentNormalized = currentCrop.toLowerCase().trim();
    final currentFamily = _botanicalFamilies[currentNormalized] ?? 'Desconocida';

    String suggestedCrop = 'Frijol Rojo (Leguminosa)';
    List<String> alternativeCrops = [
      'Crotalaria / Abono Verde',
      'Soya',
      'Sorgo Tolerante',
    ];

    // Agronomic synergy: Cereals (Gramineae) must rotate into Legumes to regenerate Nitrogen
    if (currentFamily.contains('Gramíneas')) {
      score += 10;
      suggestedCrop = 'Frijol (Fabaceae)';
      alternativeCrops = ['Soya', 'Crotalaria (Abono Verde)', 'Hortalizas'];
    } else if (currentFamily.contains('Leguminosas')) {
      score += 5;
      suggestedCrop = 'Maíz o Sorgo (Gramíneas)';
      alternativeCrops = ['Ajonjolí', 'Girasol', 'Hortalizas'];
    }

    // Spatial Graph check: Penalize if adjacent neighbors share the same crop family
    if (graph != null && subplots != null) {
      for (final sp in subplots) {
        final id = sp['id'] as int?;
        if (id != null) {
          final neighbors = graph.getNeighbors(id);
          for (final n in neighbors) {
            final nCrop = n.crop?.toLowerCase().trim() ?? '';
            final nFamily = _botanicalFamilies[nCrop] ?? '';
            if (nFamily.isNotEmpty && nFamily == currentFamily) {
              hasCorridorRisk = true;
              score -= 20; // Penalize spatial monoculture corridor
              break;
            }
          }
        }
      }
    }

    // Climate adaptation: Penalize high-demand crops if moisture is low
    if (soilMoisture < 0.40) {
      score -= 10;
      suggestedCrop = 'Frijol Alacita / Sorgo Sequero';
    }

    score = score.clamp(30, 98);

    final String level = score >= 80
        ? 'Alta Compatibilidad'
        : (score >= 60 ? 'Media Compatibilidad' : 'Desaconsejada');

    final String explanation = hasCorridorRisk
        ? 'Se detectó que parcelas vecinas comparten la misma familia ($currentFamily). Rotar con $suggestedCrop romperá el corredor biológico de plagas y fijará nitrógeno.'
        : 'La secuencia sugerida ($currentCrop -> $suggestedCrop) optimiza el uso de nutrientes y aprovecha el nivel hídrico actual.';

    return RotationCompatibilityPrediction(
      score: score,
      compatibilityLevel: level,
      suggestedCrop: suggestedCrop,
      alternativeCrops: alternativeCrops,
      hasSpatialCorridorRisk: hasCorridorRisk,
      explanation: explanation,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CALENDARIO AGRÍCOLA Y DÍAS GRADO (GDD)
  // ---------------------------------------------------------------------------
  static PlantingCalendarPrediction _calculatePlantingCalendar({
    required double tempC,
    required double soilMoisture,
    required String dominantCrop,
  }) {
    // Base temperature threshold for tropical grains
    const double tBase = 10.0;
    // Daily GDD estimation: GDD = max(0, Tmean - Tbase)
    final dailyGdd = math.max(0.0, tempC - tBase);
    final accumulatedGdd7d = dailyGdd * 7;

    // Maize flowering typically requires ~750 GDD
    final daysToFlowering =
        dailyGdd > 0 ? (750 / dailyGdd).round().clamp(45, 75) : 60;

    final bool isWindowOpen = soilMoisture >= 0.42 && tempC >= 18.0;

    final String windowStatus;
    final String dateRange;
    final String thermalAdvice;

    if (isWindowOpen) {
      windowStatus = 'Ventana Óptima de Siembra';
      dateRange = 'Próximos 10 a 14 días';
      thermalAdvice =
          'Suma térmica favorable ($accumulatedGdd7d GDD/sem). La germinación ocurrirá en 4 a 6 días sin riesgo de estrés térmico.';
    } else {
      windowStatus = 'Esperar Mayor Humedad';
      dateRange = 'Postergar hasta próximas lluvias';
      thermalAdvice =
          'La humedad radicular (${(soilMoisture * 100).toInt()}%) está por debajo del umbral de germinación uniforme (mínimo 42%).';
    }

    return PlantingCalendarPrediction(
      isWindowOpen: isWindowOpen,
      windowStatus: windowStatus,
      recommendedDateRange: dateRange,
      accumulatedGdd7d: double.parse(accumulatedGdd7d.toStringAsFixed(1)),
      estimatedDaysToFlowering: daysToFlowering,
      thermalAdvice: thermalAdvice,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. SALUD DEL CULTIVO Y BIOMASA (NDVI Proxy)
  // ---------------------------------------------------------------------------
  static CropHealthPrediction _calculateCropHealth({
    required double solarMj,
    required double soilMoisture,
    required double weeklyDeficitMm,
  }) {
    // Model satellite NDVI proxy (0.0 - 1.0) combining radiation and water sufficiency
    final moistureFactor = soilMoisture.clamp(0.0, 1.0);
    final radiationFactor = (solarMj / 22.0).clamp(0.5, 1.0);
    final ndviProxy = (0.25 + (0.55 * moistureFactor * radiationFactor))
        .clamp(0.30, 0.88);

    final double expectedYieldRatioPct;
    final String vigorStatus;
    final String condition;

    if (ndviProxy >= 0.68) {
      vigorStatus = 'Vigor Excelente';
      expectedYieldRatioPct = 92.0 + (ndviProxy * 6);
      condition =
          'Dosel vegetal denso con alta actividad fotosintética. Proyección de cosecha en percentil superior.';
    } else if (ndviProxy >= 0.50) {
      vigorStatus = 'Vigor Normal';
      expectedYieldRatioPct = 80.0 + (ndviProxy * 10);
      condition =
          'Desarrollo vegetativo acorde a la fecha fenológica sin anomalías marcadas.';
    } else {
      vigorStatus = 'Bajo Estrés Hídrico';
      expectedYieldRatioPct = (65.0 + (ndviProxy * 15)).clamp(50.0, 78.0);
      condition =
          'Vigor deprimido por déficit hídrico sostenido. Se proyecta merma del ${(100 - expectedYieldRatioPct).toStringAsFixed(0)}% si no se irriga.';
    }

    return CropHealthPrediction(
      vigorStatus: vigorStatus,
      estimatedNdviProxy: double.parse(ndviProxy.toStringAsFixed(2)),
      expectedYieldRatioPct:
          double.parse(expectedYieldRatioPct.clamp(50.0, 98.0).toStringAsFixed(1)),
      biomassCondition: condition,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ALERTAS TEMPRANAS (Sequía Relámpago y Encharcamiento)
  // ---------------------------------------------------------------------------
  static ExtremeRiskAlert _detectExtremeRisks({
    required double soilMoisture,
    required double rain7dMm,
    required double tempC,
    required double solarMj,
    String soilType = 'Franco',
  }) {
    final isClay = soilType.toLowerCase().contains('arcill');
    final isSandy = soilType.toLowerCase().contains('aren');

    // Flash Drought conditions: Sandy soils are vulnerable with lower heat due to rapid percolation
    final droughtMoistureThreshold = isSandy ? 0.40 : 0.35;
    if (soilMoisture < droughtMoistureThreshold &&
        tempC > 26.0 &&
        solarMj > 17.0 &&
        rain7dMm < 6.0) {
      return ExtremeRiskAlert(
        alertType: 'flash_drought',
        severity: 'danger',
        headline: 'Alerta de Sequía Relámpago (Flash Drought)',
        mitigationAdvice: isSandy
            ? 'Suelo arenoso con drenaje acelerado: la humedad se evapora rápidamente bajo radiación solar intensa. Aplica cobertura vegetal (mulch) y riegos cortos frecuentes.'
            : 'Caída acelerada de humedad por radiación solar extrema. Aplica acolchado (mulch) orgánico en las bases y adelanta ciclos de riego defensivo.',
      );
    }

    // Waterlogging / Root Asphyxia risk: Clay soils waterlog with less rain
    final waterlogMoistureThreshold = isClay ? 0.75 : 0.82;
    final rainThreshold = isClay ? 35.0 : 45.0;
    if (soilMoisture > waterlogMoistureThreshold && rain7dMm > rainThreshold) {
      return ExtremeRiskAlert(
        alertType: 'waterlogging',
        severity: 'warning',
        headline: 'Riesgo de Saturación y Asfixia Radicular',
        mitigationAdvice: isClay
            ? 'Suelo arcilloso con infiltración lenta: el exceso de agua estancada asfixia las raíces. Abre zanjas de evacuación superficial y evita el pisoteo del terreno.'
            : 'Precipitación acumulada excesiva en suelo saturado. Abre zanjas de drenaje superficiales para evacuar escorrentía estancada.',
      );
    }

    // Heat stress during flowering
    if (tempC >= 32.0) {
      return const ExtremeRiskAlert(
        alertType: 'heat_stress',
        severity: 'warning',
        headline: 'Estrés Térmico por Golpe de Calor',
        mitigationAdvice:
            'Temperaturas diurnas elevadas que pueden provocar aborto floral en leguminosas y hortalizas. Mantén hidratado el follaje.',
      );
    }

    return const ExtremeRiskAlert(
      alertType: 'none',
      severity: 'info',
      headline: 'Sin Riesgos Climáticos Extremos Activos',
      mitigationAdvice:
          'Las variables hidroclimáticas se mantienen dentro de los umbrales seguros para los cultivos de la finca.',
    );
  }

  // ---------------------------------------------------------------------------
  // 6. BALANCE NUTRICIONAL Y REGENERACIÓN DE SUELO (Nitrógeno)
  // ---------------------------------------------------------------------------
  static SoilNutritionPrediction _calculateSoilNutrition({
    required String currentCrop,
    required String suggestedRotationCrop,
    required double farmSurfaceHa,
    String soilType = 'Franco',
  }) {
    final suggestedLower = suggestedRotationCrop.toLowerCase();
    final bool isLegume = suggestedLower.contains('frijol') ||
        suggestedLower.contains('soya') ||
        suggestedLower.contains('leguminosa') ||
        suggestedLower.contains('abono');

    final isSandy = soilType.toLowerCase().contains('aren');

    // Biological Nitrogen Fixation (BNF) estimates in kg N / ha
    final double nitrogenGainKgHa = isLegume ? 55.0 : -35.0;
    final double totalFarmNitrogenKg = nitrogenGainKgHa * farmSurfaceHa;

    // Urea is ~46% Nitrogen (1 kg N ~ 2.17 kg Urea)
    final double ureaSavingsKg = isLegume ? (totalFarmNitrogenKg * 2.17) : 0.0;

    int soilHealthScore = isLegume ? 88 : 64;
    if (isSandy) soilHealthScore -= 6; // Sandy soils have lower baseline cation-exchange capacity

    final String diagnosis;
    if (isLegume) {
      diagnosis = isSandy
          ? 'La rotación propuesta con leguminosas aportará ~${nitrogenGainKgHa.toStringAsFixed(0)} kg N/ha. En suelo arenoso, se aconseja incorporar biomasa verde para evitar lixiviación, ahorrando ~${ureaSavingsKg.toStringAsFixed(0)} kg de urea.'
          : 'La rotación propuesta con leguminosas aportará un estimado de ${nitrogenGainKgHa.toStringAsFixed(0)} kg de Nitrógeno biológico por hectárea, ahorrando cerca de ${ureaSavingsKg.toStringAsFixed(0)} kg de urea comercial.';
    } else {
      diagnosis = isSandy
          ? 'Los cereales extraen nitrógeno (-35 kg N/ha) y en suelo arenoso el lavado por lluvia es severo. Incorpora abonos verdes profundos o compost inmediatamente.'
          : 'Los cereales extraen nitrógeno del perfil (-35 kg N/ha). Se recomienda incorporar cobertura vegetal o compost para mantener la fertilidad del suelo.';
    }

    return SoilNutritionPrediction(
      projectedNitrogenGainKgPerHa: nitrogenGainKgHa,
      totalFarmNitrogenGainKg:
          double.parse(totalFarmNitrogenKg.toStringAsFixed(1)),
      soilHealthScore: soilHealthScore,
      estimatedUreaSavingsKg:
          double.parse(ureaSavingsKg.toStringAsFixed(1)),
      regenerationDiagnosis: diagnosis,
    );
  }
}
