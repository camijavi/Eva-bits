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
Eres Eve, la asistente virtual agrícola para agricultores.

REGLAS ESTRICTAS DE RESPUESTA:
1. Tu nombre es únicamente Eve.
2. NUNCA uses símbolos de asteriscos (*, **, *****) ni formato Markdown en tus respuestas. Escribe texto limpio y directo.
3. NUNCA menciones modelos de IA (como gpt-5-mini), ni cites autores, años o fuentes académicas. El agricultor solo busca la información práctica que necesita para su parcela.
4. NUNCA uses emojis.
5. Sé breve, clara, conversacional y directa.

=== DATOS DE LA PARCELA ===
- Finca: ${farm['name'] ?? 'Mi Finca'} (${farm['zone'] ?? 'Región Agrícola'})
- Cultivo: $crop | Suelo: $soil
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
  }) {
    final es = AppLanguage.isSpanish;
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

    final qLower = query.toLowerCase();

    // Focused response if the farmer asked specifically about pests
    if (qLower.contains('plaga') || qLower.contains('pest') || qLower.contains('enfermedad')) {
      final pestLines = pests
          .map((p) =>
              '• ${p.pestName}: ${p.symptomsAndImpact}\n  Prevención: ${p.preventionAction}')
          .join('\n\n');
      return es
          ? 'Para tu cultivo de $crop en suelo $soil, vigila principalmente estas plagas:\n\n$pestLines'
          : 'For your $crop crop in $soil soil, watch out for these main pests:\n\n$pestLines';
    }

    // Focused response if the farmer asked about natural phenomena / weather
    if (qLower.contains('fenómeno') || qLower.contains('fenomeno') || qLower.contains('phenomena') || qLower.contains('clima')) {
      final phLines = phenomena
          .take(3)
          .map((ph) =>
              '• ${ph.phenomenonName}: ${ph.description}\n  Recomendación: ${ph.preventionMeasure}')
          .join('\n\n');
      return es
          ? 'Estas son las condiciones climáticas y alertas para tu zona:\n\n$phLines'
          : 'Here are the weather conditions and alerts for your area:\n\n$phLines';
    }

    // Focused response if the farmer asked about 3-week projections
    if (qLower.contains('3 semana') || qLower.contains('3-week') || qLower.contains('proyecci')) {
      final phLines = projection3w.phases
          .map((ph) =>
              '• ${ph.title} (${ph.dateRangeLabel}):\n  ${ph.expectedMetrics}\n  Acción: ${ph.recommendedAction}')
          .join('\n\n');
      return es
          ? 'Proyección de las próximas 3 semanas (${projection3w.fullDateRange}) para $crop:\n\n$phLines\n\nCambios de la última semana:\n• ${projection3w.weeklyChangesDetected.join('\n• ')}'
          : 'Projection for the next 3 weeks (${projection3w.fullDateRange}) for $crop:\n\n$phLines\n\nChanges over the past week:\n• ${projection3w.weeklyChangesDetected.join('\n• ')}';
    }

    // Focused response if the farmer asked about irrigation systems
    if (qLower.contains('riego') || qLower.contains('irrigat') || qLower.contains('agua')) {
      return es
          ? 'Tu suelo $soil tiene actualmente ${report.irrigation.soilMoisturePct}% de humedad (${report.irrigation.actionTitle}).\n\n'
              'El sistema ideal para tu terreno es ${recommendedSystem.systemName} (Eficiencia: ${recommendedSystem.efficiencyPct}).\n\n'
              '${recommendedSystem.description}'
          : 'Your $soil soil currently has ${report.irrigation.soilMoisturePct}% moisture (${report.irrigation.actionTitle}).\n\n'
              'The ideal system for your land is ${recommendedSystem.systemName} (Efficiency: ${recommendedSystem.efficiencyPct}).\n\n'
              '${recommendedSystem.description}';
    }

    final mainPest = pests.first;
    final mainPhenomenon = phenomena.first;

    if (!es) {
      return '''
Hi! Here is what you need to know today for your $crop crop on $soil soil:

1. Water & Irrigation:
• ${report.irrigation.actionTitle} (Root moisture: ${report.irrigation.soilMoisturePct}%, required water: ${report.irrigation.recommendedWaterMm} mm).
• Best system for your soil: ${recommendedSystem.systemName} (${recommendedSystem.efficiencyPct} efficiency).
• $soilConcept

2. Weather & Field Watch:
• ${mainPhenomenon.phenomenonName}: ${mainPhenomenon.preventionMeasure}

3. Pest Alert for $crop:
• ${mainPest.pestName}: ${mainPest.symptomsAndImpact}
• Prevention: ${mainPest.preventionAction}

4. Next 3 Weeks (${projection3w.fullDateRange}):
• ${projection3w.phases.first.title}: ${projection3w.phases.first.recommendedAction}
• Suggested rotation: ${report.rotation.suggestedCrop} (${report.rotation.score}% compatibility, +${report.nutrition.projectedNitrogenGainKgPerHa} kg N/ha).
''';
    }

    return '''
Hola, aquí tienes el resumen práctico para tu cultivo de $crop en suelo $soil:

1. Agua y Riego:
• ${report.irrigation.actionTitle} (Humedad actual: ${report.irrigation.soilMoisturePct}%, lámina recomendada: ${report.irrigation.recommendedWaterMm} mm).
• Sistema ideal: ${recommendedSystem.systemName} (Eficiencia ${recommendedSystem.efficiencyPct}).
• $soilConcept

2. Clima en tu Zona:
• ${mainPhenomenon.phenomenonName}: ${mainPhenomenon.preventionMeasure}

3. Cuidado contra Plagas ($crop):
• ${mainPest.pestName}: ${mainPest.symptomsAndImpact}
• Prevención: ${mainPest.preventionAction}

4. Próximas 3 Semanas (${projection3w.fullDateRange}):
• ${projection3w.phases.first.title}: ${projection3w.phases.first.recommendedAction}
• Rotación recomendada: ${report.rotation.suggestedCrop} (${report.rotation.score}% de compatibilidad, aporta ${report.nutrition.projectedNitrogenGainKgPerHa} kg N/ha).
''';
  }
}
