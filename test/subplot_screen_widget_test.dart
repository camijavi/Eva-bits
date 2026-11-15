import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/screens/lots_screen.dart';
import 'package:flutter_eva_bits/screens/subplot_screen.dart';
import 'package:flutter_eva_bits/widgets/new_edit_subplot.dart';
import 'package:flutter_eva_bits/languages/app_strings.dart';

void main() {
  final sampleLot = {
    'id': 1,
    'farm_id': 1,
    'name': 'Lote 1 - Norte (Maíz y Frijol)',
    'surface': 2.5,
    'subplots': [
      {'id': 101, 'lot_id': 1, 'name': 'Subparcela A - Maíz blanco', 'surface': 1.5},
      {'id': 102, 'lot_id': 1, 'name': 'Subparcela B - Frijol rojo', 'surface': 0.8},
    ],
  };

  testWidgets('LotsScreen navigates to SubplotScreen when lot card is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LotsScreen(
          initialLots: [sampleLot],
          surfaceUnit: 'ha',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify lot card is present
    expect(find.text('Lote 1 - Norte (Maíz y Frijol)'), findsOneWidget);

    // Tap on lot card (drill-down into details & subplots)
    await tester.tap(find.text('Lote 1 - Norte (Maíz y Frijol)'));
    await tester.pumpAndSettle();

    // Verify SubplotScreen is pushed
    expect(find.byType(SubplotScreen), findsOneWidget);
    expect(find.text('Lote 1 - Norte (Maíz y Frijol)'), findsWidgets);
  });

  testWidgets('SubplotScreen renders lot hero card, allocation bar, and subplots',
      (WidgetTester tester) async {
    final subplotsList = [
      {'id': 101, 'lot_id': 1, 'name': 'Subparcela A - Maíz blanco', 'surface': 1.5, 'soil_type': 'franco'},
      {'id': 102, 'lot_id': 1, 'name': 'Subparcela B - Frijol rojo', 'surface': 0.8, 'soil_type': 'arcilloso'},
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SubplotScreen(
          lot: sampleLot,
          surfaceUnit: 'ha',
          initialSubplots: subplotsList,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // 1. Lot Overview & Allocation
    expect(find.text(s.kLotAllocation), findsOneWidget);
    expect(find.text(s.kAllocatedToSubplots), findsOneWidget);
    expect(find.text(s.kUnallocatedFromLot), findsOneWidget);
    expect(find.text('2.30 ha'), findsOneWidget); // 1.5 + 0.8 = 2.30 ha allocated
    expect(find.text('0.20 ha'), findsOneWidget); // 2.5 - 2.3 = 0.20 ha unallocated

    // 2. Soil Composition Section
    expect(find.text(s.kSoilComposition), findsOneWidget);
    expect(find.textContaining(s.kSoilLoam), findsWidgets);
    expect(find.textContaining(s.kSoilClay), findsWidgets);

    // 3. Subplots Header
    expect(find.text(s.kSubplotsTitle), findsOneWidget);
    expect(find.text('2'), findsWidgets); // 2 subplots count
    expect(find.text(s.kAddNewSubplot), findsOneWidget);

    // 4. Subplot Cards
    expect(find.text('Subparcela A - Maíz blanco'), findsOneWidget);
    expect(find.text('Subparcela B - Frijol rojo'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsWidgets);
  });

  testWidgets('SubplotScreen renders empty state when lot has no subplots',
      (WidgetTester tester) async {
    final emptySubplotsLot = {
      'id': 2,
      'farm_id': 1,
      'name': 'Lote 2 - Sin Subparcelas',
      'surface': 1.0,
      'subplots': [],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: SubplotScreen(
          lot: emptySubplotsLot,
          surfaceUnit: 'ha',
          initialSubplots: const [],
        ),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // Verify empty state is displayed
    expect(find.text(s.kNoSubplotsYet), findsOneWidget);
    expect(find.text(s.kNoSubplotsSubtitle), findsOneWidget);
    expect(find.text(s.kAddNewSubplot), findsWidgets);
  });

  testWidgets('NewEditSubplotSheet renders form inputs in create mode',
      (WidgetTester tester) async {
    bool savedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewEditSubplotSheet(
            lotId: 1,
            lotSurface: 2.5,
            currentOtherSubplotsSurface: 0.0,
            surfaceUnit: 'ha',
            onSaved: () {
              savedCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    expect(find.text(s.kAddNewSubplot), findsOneWidget);
    expect(find.text(s.kSubplotNameLabel), findsOneWidget);
    expect(find.text('${s.kSubplotSurfaceLabel} (ha)'), findsOneWidget);
    expect(find.text(s.kSoilTypeLabel), findsOneWidget);
    expect(find.text(s.kSaveSubplot), findsOneWidget);
    expect(find.text(s.kCancel), findsOneWidget);
    expect(savedCalled, isFalse);
  });

  testWidgets('NewEditSubplotSheet renders pre-filled data and delete button in edit mode',
      (WidgetTester tester) async {
    final mockSubplot = {
      'id': 55,
      'lot_id': 1,
      'name': 'Subparcela Experimental',
      'surface': 0.75,
      'soil_type': 'arcilloso',
    };

    bool savedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewEditSubplotSheet(
            lotId: 1,
            lotSurface: 2.5,
            currentOtherSubplotsSurface: 1.0,
            subplot: mockSubplot,
            surfaceUnit: 'ha',
            onSaved: () {
              savedCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    expect(find.text(s.kEditSubplot), findsOneWidget);
    expect(find.text('Subparcela Experimental'), findsOneWidget);
    expect(find.text('0.75'), findsOneWidget);
    expect(find.text(s.kSave), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(savedCalled, isFalse);
  });
}
