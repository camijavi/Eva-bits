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
    List<String>? allFarmCrops,
  }) async {
    final s = AppLanguage.strings;
    final defaultCrop = EveKnowledgeBase.normalizeCropName(
      activeCrop ??
          (subplots != null && subplots.isNotEmpty
              ? (subplots.first['crop']?.toString() ?? s.kDefaultCropName)
              : s.kDefaultCropName),
    );
    final defaultSoil = EveKnowledgeBase.normalizeSoilName(
      activeSoil ??
          (subplots != null && subplots.isNotEmpty
              ? (subplots.first['soil_type']?.toString() ?? s.kDefaultSoilName)
              : s.kDefaultSoilName),
    );

    final List<String> extractedCrops = allFarmCrops ??
        (subplots ?? [])
            .map((sp) => sp['crop']?.toString() ?? '')
            .where((c) => c.trim().isNotEmpty)
            .map((c) => EveKnowledgeBase.normalizeCropName(c))
            .toSet()
            .toList();

    final crop = EveKnowledgeBase.detectTargetCropFromPrompt(
      userQuery,
      defaultCrop,
    );
    final soil = EveKnowledgeBase.detectTargetSoilFromPrompt(
      userQuery,
      defaultSoil,
    );

    final bool sameCropAndSoil =
        crop == defaultCrop && soil == defaultSoil;

    final report = (predictionsReport != null && sameCropAndSoil)
        ? predictionsReport
        : AgroPredictionEngine.generateReport(
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
            return content.replaceAll('*', '').trim();
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
      allFarmCrops: extractedCrops,
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
            '- ${p.phenomenonName}: ${p.description} Prevención: ${p.preventionMeasure}')
        .join('\n');

    final pestsText = pests
        .map((p) =>
            '- ${p.pestName}: ${p.symptomsAndImpact} Prevención: ${p.preventionAction}')
        .join('\n');

    final irrigationText = irrigationSystems
        .map((i) =>
            '- ${i.systemName} (Eficiencia ${i.efficiencyPct}, ideal para ${i.bestForSoil})${i.isRecommendedForCurrentSoil ? ' [RECOMENDADO]' : ''}: ${i.description}')
        .join('\n');

    final projectionText = projection3w.phases
        .map((ph) =>
            '- ${ph.title} (${ph.dateRangeLabel}): ${ph.expectedMetrics}. Acción: ${ph.recommendedAction}')
        .join('\n');

    return '''
Eres Eve, la asistente virtual de campo para granjeros y productores agrícolas.

REGLAS ESTRICTAS DE RESPUESTA:
1. Tu nombre es únicamente Eve.
2. El usuario final es un granjero: habla de forma cercana, práctica, clara y fácil de aplicar en la parcela. Evita tecnicismos innecesarios.
3. Responde exactamente a lo que el granjero te pregunta. Si pregunta por plagas, riego, clima, rotación, abono, calendario de siembra, suelo o el plan de 3 semanas, enfócate directamente en ese tema (y en el cultivo o suelo por el que pregunta) con pasos concretos.
4. NUNCA uses símbolos de asteriscos (*, **, *****) ni formato Markdown en tus respuestas. Escribe texto limpio y directo.
5. NUNCA menciones modelos de IA (como gpt-5-mini), ni cites autores, años o fuentes académicas. El granjero solo busca la información práctica que necesita para su tierra.
6. NUNCA uses emojis.

=== DATOS DE LA PARCELA ===
- Finca: ${farm['name'] ?? 'Mi Finca'} (${farm['zone'] ?? 'Región Agrícola'})
- Cultivo consultado: $crop | Suelo consultado: $soil
- Comportamiento del suelo: $soilConcept
- Temperatura media: $tempC °C | Lluvia 7 días: $rainMm mm | Humedad en raíz: ${report.irrigation.soilMoisturePct}%
- Topología de lotes: $topology

=== CLIMA Y FENÓMENOS ===
$phenomenaText

=== PLAGAS A VIGILAR EN $crop ===
$pestsText

=== SISTEMAS DE RIEGO ===
$irrigationText

=== PROYECCIÓN A 3 SEMANAS (${projection3w.fullDateRange}) ===
$projectionText
- Cambios de la última semana (${projection3w.weeklyCheckpointPeriod}): ${projection3w.weeklyChangesDetected.join(' ')}

=== RECOMENDACIONES CLAVE ===
- Riego: ${report.irrigation.actionTitle} (Déficit: ${report.irrigation.weeklyDeficitMm} mm, aplicar ${report.irrigation.recommendedWaterMm} mm).
- Rotación sugerida: ${report.rotation.suggestedCrop} (Compatibilidad ${report.rotation.score}%).
- Siembra: ${report.calendar.windowStatus} (${report.calendar.recommendedDateRange}).
- Nutrición: ${report.nutrition.projectedNitrogenGainKgPerHa} kg N/ha (ahorro estimado de ${report.nutrition.estimatedUreaSavingsKg} kg de urea).
''';
  }

  static String _generateGroundedResponse({
    required Map<String, dynamic> farm,
    required Map<String, dynamic> nasa,
    required FarmPredictionsReport report,
    required String query,
    required String crop,
    required String soil,
    List<String>? allFarmCrops,
  }) {
    final es = AppLanguage.isSpanish;
    return EveKnowledgeBase.answerFarmerPrompt(
      query: query,
      farm: farm,
      nasa: nasa,
      report: report,
      activeCrop: crop,
      activeSoil: soil,
      allFarmCrops: allFarmCrops,
      isSpanish: es,
    );
  }
}
