import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/services/agro_prediction_engine.dart';
import 'package:flutter_eva_bits/services/nasa_power_service.dart';
import 'package:flutter_eva_bits/languages/app_strings.dart';

void main() {
  final sampleFarm = {
    'name': 'Finca San José',
    'zone': 'Matagalpa, Nicaragua',
    'total_surface': 5.0,
    'unit': 'ha',
  };

  final sampleNasa = NasaPowerService.getFallbackData();

  test('AgroPredictionEngine generates Spanish localized messages when Spanish is selected', () {
    final report = AgroPredictionEngine.generateReport(
      farmData: sampleFarm,
      nasaData: sampleNasa,
      strings: AppLanguage.spaInstance,
      targetCrop: 'Maíz',
      targetSoilType: 'Franco',
    );

    // Irrigation
    expect(report.irrigation.actionTitle, isIn([
      'Riego Urgente Requerido',
      'Humedad Moderada - Monitorear',
      'Nivel Hídrico Óptimo',
    ]));
    expect(report.irrigation.actionRecommendation.toLowerCase(), contains('suelo'));

    // Rotation
    expect(report.rotation.compatibilityLevel, isIn([
      'Alta Compatibilidad',
      'Media Compatibilidad',
      'Desaconsejada',
    ]));
    expect(report.rotation.explanation, contains('secuencia sugerida'));

    // Planting Calendar
    expect(report.calendar.windowStatus, isIn([
      'Ventana Óptima de Siembra',
      'Esperar Mayor Humedad',
    ]));

    // Crop Health
    expect(report.health.vigorStatus, isIn([
      'Vigor Excelente',
      'Vigor Normal',
      'Bajo Estrés Hídrico',
    ]));

    // Extreme Risks
    expect(report.risks.headline, isIn([
      'Alerta de Sequía Relámpago (Flash Drought)',
      'Riesgo de Saturación y Asfixia Radicular',
      'Estrés Térmico por Golpe de Calor',
      'Sin Riesgos Climáticos Extremos Activos',
    ]));

    // Soil Nutrition
    expect(report.nutrition.regenerationDiagnosis, contains('rotación propuesta'));
  });

  test('AgroPredictionEngine generates English localized messages when English is selected', () {
    final report = AgroPredictionEngine.generateReport(
      farmData: sampleFarm,
      nasaData: sampleNasa,
      strings: AppLanguage.engInstance,
      targetCrop: 'Corn',
      targetSoilType: 'Loam',
    );

    // Irrigation
    expect(report.irrigation.actionTitle, isIn([
      'Urgent Irrigation Required',
      'Moderate Moisture - Monitor',
      'Optimal Water Level',
    ]));
    expect(report.irrigation.actionRecommendation, contains('soil'));

    // Rotation
    expect(report.rotation.compatibilityLevel, isIn([
      'High Compatibility',
      'Medium Compatibility',
      'Not Recommended',
    ]));
    expect(report.rotation.explanation, contains('suggested sequence'));

    // Planting Calendar
    expect(report.calendar.windowStatus, isIn([
      'Optimal Planting Window',
      'Wait for Higher Moisture',
    ]));

    // Crop Health
    expect(report.health.vigorStatus, isIn([
      'Excellent Vigor',
      'Normal Vigor',
      'Under Water Stress',
    ]));

    // Extreme Risks
    expect(report.risks.headline, isIn([
      'Flash Drought Alert',
      'Waterlogging & Root Asphyxia Risk',
      'Heat Stress Alert',
      'No Active Extreme Weather Risks',
    ]));

    // Soil Nutrition
    expect(report.nutrition.regenerationDiagnosis, contains('proposed'));
  });
}