import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/constants/agricultural_locations.dart';
import 'package:flutter_eva_bits/languages/app_strings.dart';
import 'package:flutter_eva_bits/screens/new_farm_info_screen.dart';

void main() {
  setUp(() {
    AppLanguage.setLanguage(AppLanguageType.spanish);
  });

  group('FarmInfoScreen - NASA Presets and Progress Line UI Tests', () {
    testWidgets('Renders header, space above progress line, and linear progress indicator',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmInfoScreen(checkExisting: false),
        ),
      );
      await tester.pump();

      final s = AppLanguage.strings;

      // 1. Verify header (AppBar)
      expect(find.text(s.kFarmInfoTitle), findsOneWidget);

      // 2. Verify step indicator with all 3 steps
      expect(find.text(s.kStep1Title), findsOneWidget);
      expect(find.text(s.kStep2Title), findsOneWidget);
      expect(find.text(s.kStep3Title), findsOneWidget);

      // 3. Verify the Progress Line (LinearProgressIndicator) inside the step indicator
      final progressFinders = find.byType(LinearProgressIndicator);
      expect(progressFinders, findsWidgets);

      // 4. Verify step progress text & percentage
      expect(find.text('Paso 1 de 3'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
    });

    testWidgets('Dropdown ONLY includes NASA presets and no GPS connection elements',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmInfoScreen(checkExisting: false),
        ),
      );
      await tester.pump();

      // 1. Verify GPS elements are completely removed
      expect(find.text('Obtener ubicación GPS actual'), findsNothing);
      expect(find.text('Obteniendo ubicación GPS...'), findsNothing);
      expect(find.byIcon(Icons.my_location), findsNothing);
      expect(find.byIcon(Icons.gps_fixed), findsNothing);
      expect(find.text('Otra región / Coordenadas mundiales'), findsNothing);

      // 2. Verify NASA Telemetry Card is displayed
      expect(find.text('Sincronización Satelital NASA'), findsOneWidget);
      expect(find.text('NASA POWER'), findsOneWidget);
      expect(find.byIcon(Icons.satellite_alt_rounded), findsWidgets);

      // 3. Verify coordinates of default preset (Estelí, Nicaragua)
      final defaultPreset = AgriculturalLocation.presets.firstWhere(
        (p) => p.id == 'nic_esteli',
        orElse: () => AgriculturalLocation.presets.first,
      );
      expect(find.textContaining(defaultPreset.latitude.toStringAsFixed(4)), findsWidgets);
      expect(find.textContaining(defaultPreset.longitude.toStringAsFixed(4)), findsWidgets);
    });

    testWidgets('Responsive layouts across iPhone SE, iPhone 14, and iPad 10th Gen have zero overflow',
        (WidgetTester tester) async {
      final viewports = [
        const Size(375, 667),   // iPhone SE
        const Size(390, 844),   // iPhone 14/15
        const Size(810, 1080),  // iPad 10th Gen
      ];

      for (final viewport in viewports) {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: FarmInfoScreen(checkExisting: false),
          ),
        );
        await tester.pump();

        // Verify zero overflow errors
        expect(tester.takeException(), isNull,
            reason: 'Overflow on viewport ${viewport.width}x${viewport.height}');

        // Verify key widgets are present
        expect(find.text(AppLanguage.strings.kFarmInfoTitle), findsOneWidget);
        expect(find.text('Paso 1 de 3'), findsOneWidget);
      }
    });

    testWidgets('iPad tablet displays unified single-column layout with scaled elements across Step 1, 2, and 3',
        (WidgetTester tester) async {
      // iPad 10th Gen portrait (810x1080)
      tester.view.physicalSize = const Size(810, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmInfoScreen(checkExisting: false),
        ),
      );
      await tester.pump();

      final s = AppLanguage.strings;

      // --- STEP 1 on Tablet ---
      // 1. Verify single column header in Step 1
      expect(find.text(s.kGeneralInfoSection), findsOneWidget);

      // 2. Verify all elements exist within the unified single column
      expect(find.text(s.kFarmNameLabel), findsOneWidget);
      expect(find.text('Región Agrícola (NASA)'), findsOneWidget);
      expect(find.text('Sincronización Satelital NASA'), findsOneWidget);
      expect(find.text(s.kSurfaceUnitLabel), findsOneWidget);
      expect(find.text(s.kQuickStartWholeFarm), findsOneWidget);

      // 3. Verify agroecological tip is rendered on tablet
      expect(find.textContaining('Consejo agroecológico'), findsOneWidget);

      // 4. Fill in Farm Name and Surface
      await tester.enterText(find.byType(TextFormField).first, 'Finca Santa Elena');
      await tester.enterText(find.widgetWithText(TextFormField, '${s.kTotalSurfaceLabel} (ha)'), '25.5');
      await tester.pump();

      // --- STEP 2 on Tablet ---
      // Tap "Siguiente paso" to advance to Step 2
      await tester.tap(find.text(s.kNextStep));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Paso 2 de 3'), findsOneWidget);

      // Verify Step 2 tablet single column elements: Allocation Card + Lots Header + Lots List
      expect(find.text(s.kAllocatedSurface), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // --- STEP 3 on Tablet ---
      // Tap "Siguiente paso" to advance to Step 3
      await tester.tap(find.text(s.kNextStep));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Paso 3 de 3'), findsOneWidget);

      // Verify Step 3 tablet single column elements: Farm Summary Card + NASA Environmental Card
      expect(find.text(s.kSummaryTitle), findsOneWidget);
      expect(find.text('Finca Santa Elena'), findsOneWidget);
      expect(find.text(s.kNasaDataReady), findsOneWidget);
      expect(find.text('NASA POWER'), findsWidgets);
    });

    testWidgets('Zero overflow on iPad Pro landscape (1366x1024)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FarmInfoScreen(checkExisting: false),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(AppLanguage.strings.kFarmInfoTitle), findsOneWidget);
      expect(find.text(AppLanguage.strings.kGeneralInfoSection), findsOneWidget);
    });
  });
}
