import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/main.dart';
import 'package:flutter_eva_bits/screens/farm_info_screen.dart';

void main() {
  testWidgets('FarmInfoScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(FarmInfoScreen), findsOneWidget);
  });
}
