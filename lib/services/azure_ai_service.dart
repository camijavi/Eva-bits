import 'dart:convert';
import 'package:http/http.dart' as http;
import 'agro_prediction_engine.dart';
import 'subplot_graph_service.dart';

class AzureAiService {
  // Configured for Azure AI Foundry deployment (Resource: eva-bits-open-ai)
  static String endpoint =
      "https://eva-bits-open-ai.openai.azure.com/openai/deployments/gpt-5-mini/chat/completions?api-version=2024-08-01-preview";
  static String bearerToken = ""; // Microsoft Entra ID Bearer Token
  static String apiKey =
      const String.fromEnvironment('AZURE_AI_API_KEY', defaultValue: '');
  static String modelDeployment = "gpt-5-mini";

  /// Queries Azure AI Foundry with agricultural, graph topology, and deterministic NASA predictions.
  static Future<String> askIvy({
    required String userQuery,
    required Map<String, dynamic> farmData,
    required Map<String, dynamic> nasaData,
    FarmPredictionsReport? predictionsReport,
    SubplotGraph? graph,
    List<Map<String, dynamic>>? subplots,
  }) async {
    // If not supplied, generate predictions deterministically on the spot
    final report = predictionsReport ??
        AgroPredictionEngine.generateReport(
          farmData: farmData,
          nasaData: nasaData,
          graph: graph,
          subplots: subplots,
        );

    // If endpoint and credentials (bearerToken or apiKey) are provided, perform live Azure AI Foundry call
    final bool hasAuth = bearerToken.isNotEmpty || apiKey.isNotEmpty;
    if (endpoint.isNotEmpty && hasAuth) {
      try {
        final url = Uri.parse(endpoint);
        final systemPrompt = _buildSystemPrompt(
          farm: farmData,
          nasa: nasaData,
          report: report,
          graph: graph,
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
                // Note: gpt-5-mini requires max_completion_tokens instead of max_tokens
                'max_completion_tokens': 1000,
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
      } catch (e) {
        // Fall back to intelligent grounded response if Azure call fails or times out
      }
    }

    // Default grounded intelligent response for instant hackathon testing & offline demo
    return _generateGroundedDemoResponse(
      farm: farmData,
      nasa: nasaData,
      report: report,
      query: userQuery,
    );
  }

  static String _buildSystemPrompt({
    required Map<String, dynamic> farm,
    required Map<String, dynamic> nasa,
    required FarmPredictionsReport report,
    SubplotGraph? graph,
  }) {
    final topology =
        graph?.toIvyTopologyContext() ?? 'Topología espacial no configurada.';

    return '''
Eres Ivy, la asistente agroecológica experta de Eva-Bits para el NASA Space Apps Challenge (Field Shift: Adapting Farms with NASA Data).
Operas con el modelo gpt-5-mini de Azure AI Foundry.

Tu misión es aconsejar al agricultor sobre rotación de cultivos, salud del suelo, prevención de plagas y conservación hídrica utilizando observaciones satelitales de la NASA y el motor determinista de Eva-Bits.

=== PERFIL DE LA FINCA ===
- Finca: ${farm['name'] ?? 'Sin nombre'}
- Ubicación: ${farm['zone'] ?? 'Nicaragua'}
- Superficie: ${farm['total_surface']} ${farm['unit'] ?? 'ha'}

=== TOPOLOGÍA DE SUBLOTES (GRAFO ESPACIAL) ===
$topology

=== PREDICCIONES DETERMINISTAS DE LA FINCA (MOTOR EVA-BITS) ===
1. Gestor de Riego (7 Días):
   - Estado: ${report.irrigation.status.toUpperCase()} (${report.irrigation.actionTitle})
   - Humedad del suelo (SMAP proxy): ${report.irrigation.soilMoisturePct}%
   - Déficit hídrico semanal: ${report.irrigation.weeklyDeficitMm} mm
   - Días hasta estrés: ${report.irrigation.daysUntilStress} días
   - Lámina requerida: ${report.irrigation.recommendedWaterMm} mm
   - Recomendación: ${report.irrigation.actionRecommendation}

2. Simulador de Rotación:
   - Score de compatibilidad: ${report.rotation.score}% (${report.rotation.compatibilityLevel})
   - Cultivo sugerido: ${report.rotation.suggestedCrop}
   - Alternativas: ${report.rotation.alternativeCrops.join(', ')}
   - Riesgo de corredor de plagas: ${report.rotation.hasSpatialCorridorRisk ? 'SÍ (vecinos con misma familia botánica)' : 'NO'}
   - Diagnóstico: ${report.rotation.explanation}

3. Calendario Agrícola y GDD:
   - Estado de ventana: ${report.calendar.windowStatus} (Abierta: ${report.calendar.isWindowOpen ? 'SÍ' : 'NO'})
   - Rango recomendado: ${report.calendar.recommendedDateRange}
   - Suma térmica 7 días: ${report.calendar.accumulatedGdd7d} GDD
   - Días a floración estimados: ${report.calendar.estimatedDaysToFlowering} días
   - Consejo térmico: ${report.calendar.thermalAdvice}

4. Salud y Rendimiento (NDVI Proxy):
   - Estado: ${report.health.vigorStatus}
   - Proxy NDVI: ${report.health.estimatedNdviProxy}
   - Rendimiento relativo proyectado: ${report.health.expectedYieldRatioPct}%
   - Condición biomasa: ${report.health.biomassCondition}

5. Alertas Climáticas Extremas:
   - Tipo de alerta: ${report.risks.alertType} (Severidad: ${report.risks.severity})
   - Alerta: ${report.risks.headline}
   - Mitigación: ${report.risks.mitigationAdvice}

6. Balance Nutricional de Suelo:
   - Ganancia de Nitrógeno: ${report.nutrition.projectedNitrogenGainKgPerHa} kg N/ha
   - Ahorro estimado de urea comercial: ${report.nutrition.estimatedUreaSavingsKg} kg
   - Índice de regeneración del suelo: ${report.nutrition.soilHealthScore}/100
   - Diagnóstico: ${report.nutrition.regenerationDiagnosis}

Reglas de respuesta:
1. Responde de manera clara, práctica, empática y comprensible para el agricultor.
2. Cita datos exactos del reporte determinista y observaciones de la NASA (NASA POWER, SMAP L4).
3. Recomienda romper corredores biológicos de plagas en base al grafo de sublotes.
4. Mantén las recomendaciones adaptadas al tamaño y condiciones reales de la finca.
''';
  }

  static String _generateGroundedDemoResponse({
    required Map<String, dynamic> farm,
    required Map<String, dynamic> nasa,
    required FarmPredictionsReport report,
    required String query,
  }) {
    final farmName = farm['name'] ?? 'tu finca';
    final zone = farm['zone'] ?? 'Estelí';

    return '''
¡Hola! Soy **Ivy**, tu asistente agroecológica de **Eva-Bits** (optimizada con *gpt-5-mini*).

Analicé tu finca **$farmName** en **$zone** combinando las observaciones satelitales de la NASA con la topología de tus sublotes:

💧 **1. Diagnóstico Hídrico y Riego (NASA SMAP / POWER):**
• **Estado:** ${report.irrigation.actionTitle}
• **Humedad radicular actual:** ${report.irrigation.soilMoisturePct}%
• **Déficit a 7 días:** ${report.irrigation.weeklyDeficitMm} mm (${report.irrigation.daysUntilStress} días de reserva)
• **Recomendación:** ${report.irrigation.actionRecommendation}

🔄 **2. Compatibilidad de Rotación y Grafo Espacial:**
• **Compatibilidad:** **${report.rotation.score}%** (${report.rotation.compatibilityLevel})
• **Cultivo Óptimo Sugerido:** **${report.rotation.suggestedCrop}**
• **Riesgo de Corredor de Plagas:** ${report.rotation.hasSpatialCorridorRisk ? '⚠️ Detectada colindancia con parcelas de la misma familia. Rotar con leguminosas romperá el ciclo de plagas.' : '✅ Excelente aislamiento espacial entre sublotes.'}
• **Alternativas viables:** ${report.rotation.alternativeCrops.join(', ')}.

🌱 **3. Ventana de Siembra y Desarrollo Térmico (GDD):**
• **Estado:** ${report.calendar.windowStatus} (${report.calendar.recommendedDateRange})
• **Acumulación Térmica:** ${report.calendar.accumulatedGdd7d} GDD acumulados (floración proyectada en ~${report.calendar.estimatedDaysToFlowering} días).

🍃 **4. Vigor Vegetal y Rendimiento (NDVI Proxy):**
• **Índice de Vigor:** ${report.health.vigorStatus} (NDVI estimado: ${report.health.estimatedNdviProxy})
• **Rendimiento Proyectado:** ${report.health.expectedYieldRatioPct}% del potencial normal.

⚡ **5. Alerta de Riesgos Agroclimáticos:**
• **${report.risks.headline}**
• *Mitigación:* ${report.risks.mitigationAdvice}

🌍 **6. Balance Nutricional y Ahorro en Fertilizantes:**
• **Aporte Biológico de Nitrógeno:** ${report.nutrition.projectedNitrogenGainKgPerHa > 0 ? '+${report.nutrition.projectedNitrogenGainKgPerHa}' : '${report.nutrition.projectedNitrogenGainKgPerHa}'} kg N/ha.
• **Ahorro Estimado:** ${report.nutrition.estimatedUreaSavingsKg.toStringAsFixed(0)} kg de urea comercial en la finca.
• **Índice de Salud del Suelo:** ${report.nutrition.soilHealthScore}/100.

¿Deseas que simulemos un cultivo específico en alguno de tus sublotes o planifiquemos el calendario de labores?
''';
  }
}
