import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/screens/dashboard_screen.dart';
import 'package:flutter_eva_bits/screens/farm_info.dart';
import 'package:flutter_eva_bits/screens/edit_farm_info.dart';
import 'package:flutter_eva_bits/languages/app_strings.dart';

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

    // Verify Dashboard shows the view details button
    final s = AppLanguage.strings;
    expect(find.text(s.kDashboardViewDetails), findsOneWidget);

    // Tap "View details"
    await tester.tap(find.text(s.kDashboardViewDetails));
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
    expect(find.text('Nicaragua'), findsOneWidget);
    expect(find.text('4.25'), findsOneWidget);
    expect(find.text(s.kSaveChanges), findsOneWidget);
    expect(updatedCalled, isFalse);
  });
}

