import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/screens/dashboard_screen.dart';
import 'package:flutter_eva_bits/screens/lots_screen.dart';
import 'package:flutter_eva_bits/widgets/bottom_nav_bar.dart';
import 'package:flutter_eva_bits/widgets/new_edit_plot.dart';
import 'package:flutter_eva_bits/languages/app_strings.dart';

void main() {
  final sampleLots = [
    {
      'id': 1,
      'farm_id': 1,
      'name': 'Lote 1 - Norte (Maíz y Frijol)',
      'surface': 2.5,
      'subplots': [
        {'id': 1, 'lot_id': 1, 'name': 'Subparcela A', 'surface': 1.5},
        {'id': 2, 'lot_id': 1, 'name': 'Subparcela B', 'surface': 1.0},
      ],
    },
    {
      'id': 2,
      'farm_id': 1,
      'name': 'Lote 2 - Sur (Frijolar)',
      'surface': 1.8,
      'subplots': [
        {'id': 3, 'lot_id': 2, 'name': 'Subparcela Principal', 'surface': 1.8},
      ],
    },
    {
      'id': 3,
      'farm_id': 1,
      'name': 'Lote 3 - Este (Rotación Crotalaria)',
      'surface': 3.0,
      'subplots': [],
    },
  ];

  testWidgets('CustomBottomNavBar includes Lots option and handles navigation',
      (WidgetTester tester) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              tappedIndex = index;
            },
          ),
        ),
      ),
    );

    final s = AppLanguage.strings;

    // Verify Lots option is present in the nav bar
    expect(find.text(s.kNavLots), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);

    // Tap on Lots option
    await tester.tap(find.text(s.kNavLots));
    await tester.pump();

    // Verify callback was called with index 1
    expect(tappedIndex, 1);
  });

  testWidgets('DashboardScreen navbar navigates to LotsScreen when Lots is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(
          farmName: 'Finca El Paraíso',
          location: 'Matagalpa, Nicaragua',
          surface: '5.0 ha',
        ),
      ),
    );

    final s = AppLanguage.strings;

    // Verify Dashboard is rendered and has Lots in the navbar
    expect(find.text(s.kNavLots), findsOneWidget);

    // Tap on Lots tab
    await tester.tap(find.text(s.kNavLots));
    await tester.pumpAndSettle();

    // Verify LotsScreen is pushed
    expect(find.byType(LotsScreen), findsOneWidget);
    expect(find.text(s.kLotsScreenTitle), findsOneWidget);
  });

  testWidgets(
      'LotsScreen renders title, search, filter chips, cards, pen icons and add buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LotsScreen(
          initialLots: sampleLots,
          surfaceUnit: 'ha',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // 1. Title and Subtitle
    expect(find.text(s.kLotsScreenTitle), findsOneWidget);
    expect(find.text(s.kLotsScreenSubtitle), findsOneWidget);

    // 2. Search Field
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(s.kSearchLotsHint), findsOneWidget);

    // 3. Plus icon to add new lots
    expect(find.byIcon(Icons.add_circle_rounded), findsOneWidget);
    expect(find.text(s.kAddLot), findsOneWidget);

    // 4. Priority filter chips (matches screenshot!)
    expect(find.text(s.kFilterPriorityTitle), findsOneWidget);
    expect(find.text(s.kFilterAll), findsOneWidget);
    expect(find.text(s.kFilterLargest), findsOneWidget);
    expect(find.text(s.kFilterSmallest), findsOneWidget);
    expect(find.text(s.kFilterWithSubplots), findsOneWidget);

    // 5. Registered lots section & cards
    expect(find.text(s.kRegisteredLotsTitle), findsOneWidget);
    expect(find.text('Lote 1 - Norte (Maíz y Frijol)'), findsOneWidget);
    expect(find.text('Lote 2 - Sur (Frijolar)'), findsOneWidget);
    expect(find.text('Lote 3 - Este (Rotación Crotalaria)'), findsOneWidget);

    // 6. Pen icon for editing on lot cards
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(3));

    // 7. Plant / Sprout circular icon badges on cards (as in screenshot)
    expect(find.byIcon(Icons.eco_rounded), findsNWidgets(3));

    // 8. Bottom action button "+ Agregar nuevo lote"
    expect(find.text(s.kAddNewLot), findsOneWidget);
  });

  testWidgets('LotsScreen search functionality filters lot cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LotsScreen(
          initialLots: sampleLots,
          surfaceUnit: 'ha',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially all 3 lots are displayed
    expect(find.text('Lote 1 - Norte (Maíz y Frijol)'), findsOneWidget);
    expect(find.text('Lote 2 - Sur (Frijolar)'), findsOneWidget);
    expect(find.text('Lote 3 - Este (Rotación Crotalaria)'), findsOneWidget);

    // Search for "Frijolar"
    await tester.enterText(find.byType(TextField), 'Frijolar');
    await tester.pumpAndSettle();

    expect(find.text('Lote 1 - Norte (Maíz y Frijol)'), findsNothing);
    expect(find.text('Lote 2 - Sur (Frijolar)'), findsOneWidget);
    expect(find.text('Lote 3 - Este (Rotación Crotalaria)'), findsNothing);

    // Search for a non-existent lot
    await tester.enterText(find.byType(TextField), 'NonExistentXYZ999');
    await tester.pumpAndSettle();

    final s = AppLanguage.strings;
    expect(find.text(s.kNoLotsFound), findsOneWidget);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Lote 1 - Norte (Maíz y Frijol)'), findsOneWidget);
    expect(find.text('Lote 2 - Sur (Frijolar)'), findsOneWidget);
    expect(find.text('Lote 3 - Este (Rotación Crotalaria)'), findsOneWidget);
  });

  testWidgets('LotsScreen filter chips filter and sort lots correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LotsScreen(
          initialLots: sampleLots,
          surfaceUnit: 'ha',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;

    // Tap "Con subparcelas" chip (Lot 3 has 0 subplots)
    await tester.tap(find.text(s.kFilterWithSubplots));
    await tester.pumpAndSettle();

    expect(find.text('Lote 1 - Norte (Maíz y Frijol)'), findsOneWidget);
    expect(find.text('Lote 2 - Sur (Frijolar)'), findsOneWidget);
    expect(find.text('Lote 3 - Este (Rotación Crotalaria)'), findsNothing);

    // Tap "Todos" chip again
    await tester.tap(find.text(s.kFilterAll));
    await tester.pumpAndSettle();

    expect(find.text('Lote 3 - Este (Rotación Crotalaria)'), findsOneWidget);
  });

  testWidgets('LotsScreen empty state renders when no lots exist',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LotsScreen(
          initialLots: [],
        ),
      ),
    );

    await tester.pumpAndSettle();

    final s = AppLanguage.strings;
    expect(find.text(s.kNoLotsRegistered), findsOneWidget);
    expect(find.text(s.kNoLotsYetSubtitle), findsOneWidget);
  });

  testWidgets('NewEditPlotSheet renders form inputs in create mode',
      (WidgetTester tester) async {
    bool savedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewEditPlotSheet(
            onSaved: () {
              savedCalled = true;
            },
            surfaceUnit: 'ha',
          ),
        ),
      ),
    );

    final s = AppLanguage.strings;

    expect(find.text(s.kAddNewLot), findsOneWidget);
    expect(find.text(s.kLotNameLabel), findsOneWidget);
    expect(find.text('${s.kLotSurfaceLabel} (ha)'), findsOneWidget);
    expect(find.text(s.kSaveLot), findsOneWidget);
    expect(savedCalled, isFalse);
  });

  testWidgets(
      'NewEditPlotSheet renders form inputs and pre-fills data in edit mode',
      (WidgetTester tester) async {
    final mockLot = {
      'id': 10,
      'farm_id': 1,
      'name': 'Lote El Roble',
      'surface': 3.75,
    };

    bool savedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewEditPlotSheet(
            lot: mockLot,
            onSaved: () {
              savedCalled = true;
            },
            surfaceUnit: 'ha',
          ),
        ),
      ),
    );

    final s = AppLanguage.strings;

    expect(find.text(s.kEditLot), findsOneWidget);
    expect(find.text('Lote El Roble'), findsOneWidget);
    expect(find.text('3.75'), findsOneWidget);
    expect(find.text(s.kSave), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(savedCalled, isFalse);
  });
}
