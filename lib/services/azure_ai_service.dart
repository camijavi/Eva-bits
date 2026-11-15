import 'dart:convert';
import 'package:http/http.dart' as http;
import 'agro_prediction_engine.dart';
import 'eve_knowledge_base.dart';
import 'subplot_graph_service.dart';
import '../languages/app_strings.dart';

class AzureAiService {
  // Configured for Azure AI Foundry deployment (Resource: eva-bits-open-ai)
  static String endpoint =
      "https://eva-bits-open-ai.openai.azure.com/openai/deployments/gpt-5-mini/chat/completions?api-version=2024-08-01-preview";
  static String bearerToken = ""; // Microsoft Entra ID Bearer Token
  static String apiKey =
      const String.fromEnvironment('AZURE_AI_API_KEY', defaultValue: '');
  static String modelDeployment = "gpt-5-mini";

  /// Queries Eve (Azure AI Foundry gpt-5-mini) with NASA telemetry, spatial graph topology,
  /// deterministic predictions, and the Eva-Bits Biotechnology & Agronomy research corpus.
  static Future<String> askEve({
    required String userQuery,
    required Map<String, dynamic> farmData,
    required Map<String, dynamic> nasaData,
    FarmPredictionsReport? predictionsReport,
    SubplotGraph? graph,
    List<Map<String, dynamic>>? subplots,
    String? activeCrop,
    String? activeSoil,
  }) async {
    final s = AppLanguage.strings;
    final crop = activeCrop ??
        (subplots != null && subplots.isNotEmpty
            ? (subplots.first['crop']?.toString() ?? s.kDefaultCropName)
            : s.kDefaultCropName);
    final soil = activeSoil ??
        (subplots != null && subplots.isNotEmpty
            ? (subplots.first['soil_type']?.toString() ?? s.kDefaultSoilName)
            : s.kDefaultSoilName);

    final report = predictionsReport ??
        AgroPredictionEngine.generateReport(
          farmData: farmData,
          nasaData: nasaData,
          graph: graph,
          subplots: subplots,
          targetCrop: crop,
          targetSoilType: soil,
          strings: s,
        );

    final bool hasAuth = bearerToken.isNotEmpty || apiKey.isNotEmpty;
    if (endpoint.isNotEmpty && hasAuth) {
      try {
        final url = Uri.parse(endpoint);
        final systemPrompt = _buildSystemPrompt(
          farm: farmData,
          nasa: nasaData,
          report: report,
          graph: graph,
          crop: crop,
          soil: soil,
        );

        final Map<String, String> headers = {
          'Content-Type': 'application/json',
        };
        if (bearerToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $bearerToken';
        } else if (apiKey.isNotEmpty) {
          headers['api-key'] = apiKey;
        }

        final response = await http
            .post(
              url,
              headers: headers,
              body: jsonEncode({
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': userQuery},
                ],
                'max_completion_tokens': 1100,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content =
              data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
      } catch (_) {
        // Fall back to deterministic grounded response if offline or timeout
      }
    }

    return _generateGroundedResponse(
      farm: farmData,
      nasa: nasaData,
      report: report,
      query: userQuery,
      crop: crop,
      soil: soil,
    );
  }

  /// Backward-compatible alias for existing callers
  static Future<String> askIvy({
    required String userQuery,
    required Map<String, dynamic> farmData,
    required Map<String, dynamic> nasaData,
    FarmPredictionsReport? predictionsReport,
    SubplotGraph? graph,
    List<Map<String, dynamic>>? subplots,
    String? activeCrop,
    String? activeSoil,
  }) {
    return askEve(
      userQuery: userQuery,
      farmData: farmData,
      nasaData: nasaData,
      predictionsReport: predictionsReport,
      graph: graph,
      subplots: subplots,
      activeCrop: activeCrop,
      activeSoil: activeSoil,
    );
  }

  static String _buildSystemPrompt({
    required Map<String, dynamic> farm,
    required Map<String, dynamic> nasa,
    required FarmPredictionsReport report,
    required String crop,
    required String soil,
    SubplotGraph? graph,
  }) {
    final topology =
        graph?.toIvyTopologyContext() ?? 'Topología espacial no configurada.';
    final summary = nasa['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final solarMj =
        (summary['avg_solar_radiation_mj'] as num?)?.toDouble() ?? 18.5;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final soilConcept = EveKnowledgeBase.getSoilScientificConcept(soil);
    final phenomena = EveKnowledgeBase.evaluateNaturalPhenomena(
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      solarMj: solarMj,
      soilType: soil,
      crop: crop,
    );
    final pests = EveKnowledgeBase.getPestWarningsForCrop(
      crop: crop,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      soilType: soil,
    );
    final irrigationSystems = EveKnowledgeBase.getIrrigationSystemsForSoil(
      soilType: soil,
      recommendedWaterMm: report.irrigation.recommendedWaterMm,
    );
    final projection3w = EveKnowledgeBase.generateThreeWeekProjection(
      crop: crop,
      soilType: soil,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisturePct: report.irrigation.soilMoisturePct,
      weeklyDeficitMm: report.irrigation.weeklyDeficitMm,
      accumulatedGdd7d: report.calendar.accumulatedGdd7d,
      suggestedRotationCrop: report.rotation.suggestedCrop,
    );

    final phenomenaText = phenomena
        .map((p) =>
            '- ${p.phenomenonName} [${p.severity.toUpperCase()}] (${p.citation}): ${p.description} Prevención: ${p.preventionMeasure}')
        .join('\n');

    final pestsText = pests
        .map((p) =>
            '- ${p.pestName} (${p.scientificName}) [Riesgo: ${p.riskLevel.toUpperCase()}] (Fuente: ${p.sourceCitation}): Disparador: ${p.climateTrigger}. Impacto: ${p.symptomsAndImpact} Prevención: ${p.preventionAction}')
        .join('\n');

    final irrigationText = irrigationSystems
        .map((i) =>
            '- ${i.systemName} (Eficiencia ${i.efficiencyPct}, ideal para ${i.bestForSoil})${i.isRecommendedForCurrentSoil ? ' [RECOMENDADO PARA TU SUELO]' : ''}: ${i.description} (${i.nasaIntegrationNote})')
        .join('\n');

    final projectionText = projection3w.phases
        .map((ph) =>
            '- ${ph.title} (${ph.dateRangeLabel}): ${ph.expectedMetrics}. Acción: ${ph.recommendedAction}')
        .join('\n');

    return '''
Eres Eve, la asistente virtual agroecológica y fitosanitaria de Eva-Bits para agricultores en el reto NASA Space Apps Challenge 2026 ("Field Shift: Adapting Farms with NASA Data").
Operas con el modelo gpt-5-mini de Azure AI Foundry.

REGLAS ESTRICTAS DE RESPUESTA Y CITACIÓN:
1. Tu nombre es únicamente Eve (nunca te llames Ivy ni Evita).
2. NUNCA uses emojis en tus respuestas. Usa viñetas limpias y subtítulos claros.
3. CITA OBLIGATORIAMENTE LAS FUENTES EXACTAS que se te entregan en este contexto (ej. NASA POWER, NASA SMAP, NASA GPM, GRACE, Misión NASA-ISRO, Gray 2021, NASA Ciencia 2022/2024/2026, Alianza Bioversity and CIAT 2026, Vilela 2026, Cañizo s.f., Dubón 2006, Monge 2018, Murray y Aiston 2012, Delgado 2024, Porres y Cuxil 2024, Campos Hernández & Lugo Alonso 2012, JICA s.f., Deiss 2025, Sihdu 2022, Agrotec 2025).
4. No inventes datos numéricos fuera de las lecturas satelitales y del motor determinista proporcionado.
5. Mantén un tono empático, claro, práctico y orientado al agricultor.

=== PERFIL DE LA FINCA Y PARCELA ACTIVA ===
- Finca: ${farm['name'] ?? 'Mi Finca'} (${farm['zone'] ?? 'Región Agrícola'})
- Superficie total: ${farm['total_surface'] ?? 2.5} ${farm['unit'] ?? 'ha'}
- Cultivo analizado: $crop
- Tipo de suelo: $soil
- Diagnóstico edafológico: $soilConcept

=== TELEMETRÍA SATELITAL NASA ===
- Temperatura media (NASA POWER T2M): $tempC °C
- Precipitación 7 días (NASA GPM / POWER): $rainMm mm
- Radiación solar (NASA POWER): $solarMj MJ/m²/día (~240 W/m² base climática según NASA, 2009)
- Humedad radicular (NASA SMAP L4 GWETROOT): ${report.irrigation.soilMoisturePct}%

=== TOPOLOGÍA ESPACIAL DE SUBLOTES ===
$topology

=== ADVERTENCIAS DE FENÓMENOS NATURALES Y CLIMA EXTREMO ===
$phenomenaText

=== VIGILANCIA DE PLAGAS Y ENFERMEDADES PARA $crop ===
$pestsText

=== SISTEMAS DE RIEGO DE PRECISIÓN RECOMENDADOS ===
$irrigationText

=== PROYECCIÓN A 3 SEMANAS (${projection3w.fullDateRange}) Y CAMBIOS SEMANALES ===
$projectionText
- Comparativa últimos 7 días (${projection3w.weeklyCheckpointPeriod}): ${projection3w.weeklyChangesDetected.join(' ')}
- ${projection3w.longTermClimateNote}

=== PREDICCIONES DETERMINISTAS DEL MOTOR EVA-BITS ===
- Riego: ${report.irrigation.actionTitle} | Déficit: ${report.irrigation.weeklyDeficitMm} mm | Lámina requerida: ${report.irrigation.recommendedWaterMm} mm.
- Rotación: Compatibilidad ${report.rotation.score}% (${report.rotation.compatibilityLevel}) -> Sugerido: ${report.rotation.suggestedCrop}. Corredor de plagas: ${report.rotation.hasSpatialCorridorRisk ? 'SÍ' : 'NO'}.
- Siembra y GDD: ${report.calendar.windowStatus} (${report.calendar.recommendedDateRange}) | ${report.calendar.accumulatedGdd7d} GDD acumulados.
- Salud y Rendimiento (NDVI Proxy): ${report.health.vigorStatus} (NDVI ${report.health.estimatedNdviProxy}, rendimiento estimado ${report.health.expectedYieldRatioPct}%).
- Balance de Nitrógeno: ${report.nutrition.projectedNitrogenGainKgPerHa} kg N/ha (Ahorro urea: ${report.nutrition.estimatedUreaSavingsKg} kg).
''';
  }

  static String _generateGroundedResponse({
    required Map<String, dynamic> farm,
    required Map<String, dynamic> nasa,
    required FarmPredictionsReport report,
    required String query,
    required String crop,
    required String soil,
  }) {
    final es = AppLanguage.isSpanish;
    final farmName = farm['name'] ?? (es ? 'tu finca' : 'your farm');
    final zone = farm['zone'] ?? 'Nicaragua';
    final summary = nasa['summary'] as Map<String, dynamic>? ?? {};
    final tempC = (summary['avg_temp_c'] as num?)?.toDouble() ?? 24.5;
    final rainMm = (summary['avg_rainfall_mm'] as num?)?.toDouble() ?? 3.2;
    final solarMj =
        (summary['avg_solar_radiation_mj'] as num?)?.toDouble() ?? 18.5;
    final soilMoisture =
        (summary['root_soil_moisture_index'] as num?)?.toDouble() ?? 0.58;

    final soilConcept =
        EveKnowledgeBase.getSoilScientificConcept(soil, isSpanish: es);
    final phenomena = EveKnowledgeBase.evaluateNaturalPhenomena(
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      solarMj: solarMj,
      soilType: soil,
      crop: crop,
      isSpanish: es,
    );
    final pests = EveKnowledgeBase.getPestWarningsForCrop(
      crop: crop,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisture: soilMoisture,
      soilType: soil,
      isSpanish: es,
    );
    final irrigationSystems = EveKnowledgeBase.getIrrigationSystemsForSoil(
      soilType: soil,
      recommendedWaterMm: report.irrigation.recommendedWaterMm,
      isSpanish: es,
    );
    final recommendedSystem = irrigationSystems.firstWhere(
      (s) => s.isRecommendedForCurrentSoil,
      orElse: () => irrigationSystems.first,
    );
    final projection3w = EveKnowledgeBase.generateThreeWeekProjection(
      crop: crop,
      soilType: soil,
      tempC: tempC,
      rain7dMm: rainMm,
      soilMoisturePct: report.irrigation.soilMoisturePct,
      weeklyDeficitMm: report.irrigation.weeklyDeficitMm,
      accumulatedGdd7d: report.calendar.accumulatedGdd7d,
      suggestedRotationCrop: report.rotation.suggestedCrop,
      isSpanish: es,
    );

    final pestsBullets = pests
        .map((p) =>
            '• **${p.pestName} (*${p.scientificName}*)** — *${p.sourceCitation}*:\n  ${p.symptomsAndImpact}\n  *Prevención:* ${p.preventionAction}')
        .join('\n');

    final phenomenaBullets = phenomena
        .take(2)
        .map((ph) =>
            '• **${ph.phenomenonName}** (*${ph.citation}*):\n  ${ph.description}\n  *Acción:* ${ph.preventionMeasure}')
        .join('\n');

    final phasesBullets = projection3w.phases
        .map((ph) =>
            '• **${ph.title}** (${ph.dateRangeLabel}):\n  ${ph.expectedMetrics}\n  *Meta:* ${ph.recommendedAction}')
        .join('\n');

    if (!es) {
      return '''
Hello! I am **Eve**, your virtual agroecological and phytosanitary assistant in **Eva-Bits** (powered by *gpt-5-mini* and grounded in NASA Earth Observations & the Eva-Bits Biotechnology Research Corpus).

Here is the scientific diagnosis for **$farmName** ($zone) for **$crop** on **$soil** soil:

**1. Soil & Precision Irrigation Diagnosis (NASA SMAP / NISAR / CIAT):**
• **Status:** ${report.irrigation.actionTitle} (Root moisture: ${report.irrigation.soilMoisturePct}%, 7-day deficit: ${report.irrigation.weeklyDeficitMm} mm).
• **Soil Science:** $soilConcept
• **Recommended Irrigation System:** **${recommendedSystem.systemName}** (Efficiency: ${recommendedSystem.efficiencyPct}). ${recommendedSystem.description} *(${recommendedSystem.nasaIntegrationNote})*.

**2. Natural Phenomena & Extreme Climate Warnings (NASA GPM / GRACE / Climate):**
$phenomenaBullets

**3. Crop Pest & Disease Surveillance for $crop:**
$pestsBullets

**4. 3-Week Rolling Projection (${projection3w.fullDateRange}):**
$phasesBullets

**5. Weekly Evolution Alert (Past 7 Days: ${projection3w.weeklyCheckpointPeriod}):**
• ${projection3w.weeklyChangesDetected.join('\n• ')}

**6. Spatial Crop Rotation & Nitrogen Balance:**
• **Recommended Rotation:** **${report.rotation.suggestedCrop}** (Compatibility: ${report.rotation.score}%).
• **Biological Nitrogen Fixation:** ${report.nutrition.projectedNitrogenGainKgPerHa > 0 ? '+${report.nutrition.projectedNitrogenGainKgPerHa}' : '${report.nutrition.projectedNitrogenGainKgPerHa}'} kg N/ha (~${report.nutrition.estimatedUreaSavingsKg.toStringAsFixed(0)} kg commercial urea saved).

Ask me about a specific pest, irrigation system, or 3-week rotation scenario!
''';
    }

    return '''
Hola, soy **Eve**, tu asistente virtual agroecológica de **Eva-Bits** (impulsada por *gpt-5-mini* y fundamentada en datos satelitales de la **NASA** y el documento científico de **Biotecnología Eva-Bits**).

Analicé tu finca **$farmName** en **$zone** para el cultivo de **$crop** en suelo **$soil** citando las fuentes oficiales:

**1. Diagnóstico Hídrico, Suelo y Sistema de Riego (NASA SMAP / Misión NASA-ISRO / CIAT):**
• **Estado Hídrico:** ${report.irrigation.actionTitle} (Humedad radicular: ${report.irrigation.soilMoisturePct}%, déficit semanal: ${report.irrigation.weeklyDeficitMm} mm, lámina: ${report.irrigation.recommendedWaterMm} mm).
• **Base Edafológica:** $soilConcept
• **Sistema de Riego Recomendado:** **${recommendedSystem.systemName}** (Eficiencia: ${recommendedSystem.efficiencyPct}). ${recommendedSystem.description} *(${recommendedSystem.nasaIntegrationNote})*.

**2. Advertencias de Fenómenos Naturales y Clima (NASA GPM / SMAP / GRACE):**
$phenomenaBullets

**3. Vigilancia de Plagas y Enfermedades para $crop:**
$pestsBullets

**4. Proyección Tri-Semanal (${projection3w.fullDateRange}):**
$phasesBullets

**5. Control de Cambios tras 1 Semana (${projection3w.weeklyCheckpointPeriod}):**
• ${projection3w.weeklyChangesDetected.join('\n• ')}

**6. Rotación Espacial y Balance de Nitrógeno:**
• **Rotación Sugerida:** **${report.rotation.suggestedCrop}** (Compatibilidad: **${report.rotation.score}%** — ${report.rotation.compatibilityLevel}).
• **Aporte Biológico:** ${report.nutrition.projectedNitrogenGainKgPerHa > 0 ? '+${report.nutrition.projectedNitrogenGainKgPerHa}' : '${report.nutrition.projectedNitrogenGainKgPerHa}'} kg N/ha (ahorro estimado de ${report.nutrition.estimatedUreaSavingsKg.toStringAsFixed(0)} kg de urea).

¿Deseas profundizar en el control de alguna plaga de tu cultivo, comparar los sistemas de riego o revisar la proyección de las próximas 3 semanas?
''';
  }
}
