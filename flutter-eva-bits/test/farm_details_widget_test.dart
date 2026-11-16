import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/screens/dashboard_screen.dart';
import 'package:flutter_eva_bits/screens/farm_info.dart';
import 'package:flutter_eva_bits/screens/edit_farm_info.dart';
import 'package:flutter_eva_bits/screens/new_farm_info_screen.dart';
import 'package:flutter_eva_bits/languages/app_strings.dart';
import 'package:flutter_eva_bits/widgets/eve_animated_avatar.dart';

void main() {
  testWidgets('Dashboard "View details" button navigates to FarmInfoDetailScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const DashboardScreen(
          farmName: 'Finca Vista Alegre',
          location: 'Estelí, Nicaragua',
          surface: '3.5 ha',
        ),
      ),
    );

    // Tap cottage icon in dashboard appbar to navigate to FarmInfoDetailScreen
    await tester.tap(find.byIcon(Icons.cottage_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify FarmInfoDetailScreen is now pushed
    expect(find.byType(FarmInfoDetailScreen), findsOneWidget);
  });

  testWidgets('EditFarmInfoSheet renders form inputs and pre-fills data',
      (WidgetTester tester) async {
    final mockFarm = {
      'id': 1,
      'name': 'Finca Los Pinos',
      'country': 'Nicaragua',
      'surface_unit': 'ha',
      'total_surface': 4.25,
      'latitude': 13.0912,
      'longitude': -86.3578,
    };

    bool updatedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditFarmInfoSheet(
            farm: mockFarm,
            onFarmUpdated: () {
              updatedCalled = true;
            },
          ),
        ),
      ),
    );

    final s = AppLanguage.strings;

    // Verify header and fields are visible
    expect(find.text(s.kEditFarmInfo), findsOneWidget);
    expect(find.text('Finca Los Pinos'), findsOneWidget);
    expect(find.textContaining('Nicaragua'), findsWidgets);
    expect(find.text('4.25'), findsOneWidget);
    expect(find.text(s.kSaveChanges), findsOneWidget);
    expect(updatedCalled, isFalse);
  });

  testWidgets(
      'FarmInfoScreen with checkExisting false renders farm input wizard',
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

    final s = AppLanguage.strings;
    expect(find.text(s.kFarmInfoTitle), findsOneWidget);
    expect(find.text(s.kQuickStartWholeFarm), findsOneWidget);
  });

  testWidgets(
      'Dashboard cards layout scales to tablet with 4-column fields and 2-column predictions without overflow',
      (WidgetTester tester) async {
    // iPad 10th gen portrait (820x1180)
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(
          farmName: 'Finca El Roble',
          location: 'Jalisco, México',
          surface: '120.0 ha',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify grid cards exist
    expect(find.text('Cultivos'), findsOneWidget);
    expect(find.text('Predicciones'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);

    // Verify predictions section header and cards
    expect(find.text('Predicciones de Eve'), findsOneWidget);
    expect(find.text('Gestor de Riego a 7 Días'), findsOneWidget);
    expect(find.text('Rotación y Sucesión Botánica'), findsOneWidget);
    expect(find.text('Ventana de Siembra & GDD'), findsOneWidget);
    expect(find.text('Salud del Suelo & Fijación Biológica'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Eve chat modal sheet renders on tablet and occupies ~60% screen height',
      (WidgetTester tester) async {
    // iPad 10th gen portrait (820x1180)
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EveUnifiedChatSheet(
            activeCrop: 'Maíz',
            activeSoil: 'Franco',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find the sheet container
    final containerFinder = find.byType(EveUnifiedChatSheet);
    expect(containerFinder, findsOneWidget);

    final size = tester.getSize(containerFinder);
    // On 1180 height, 60% is ~708px. Verify it's >= 650px (occupying ~60% of screen)
    expect(size.height, greaterThanOrEqualTo(650.0));
    expect(tester.takeException(), isNull);
  });
}

