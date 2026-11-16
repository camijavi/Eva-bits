import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_eva_bits/screens/welcome_screen.dart';

void main() {
  final screenSizes = <String, Size>{
    'iPhone SE (Small Mobile)': const Size(320, 568),
    'Standard Phone (iPhone 14/15)': const Size(393, 852),
    'iPad 10th Gen (User Tablet Portrait)': const Size(820, 1180),
    'iPad Pro 12.9 (Large Tablet Portrait)': const Size(1024, 1366),
    'iPad Landscape': const Size(1180, 820),
    'Mobile Landscape': const Size(852, 393),
  };

  for (final entry in screenSizes.entries) {
    testWidgets('WelcomeScreen renders responsively on ${entry.key} with zero overflow', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(checkExisting: false),
        ),
      );
      await tester.pump();

      // Verify key elements are present and rendered
      expect(find.text('Eva Bits'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.textContaining('Eva Bits'), findsWidgets);

      // Verify no Flutter render overflow errors
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('WelcomeScreen scales up element sizes and utilizes screen height and width on iPad/Tablet', (tester) async {
    // 1. Render on Phone (393 x 852)
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(checkExisting: false),
      ),
    );
    await tester.pump();

    final phoneButtonBox = tester.getRect(find.byType(ElevatedButton));
    final phoneButtonHeight = phoneButtonBox.height;

    // 2. Render on Tablet (820 x 1180)
    tester.view.physicalSize = const Size(820, 1180);
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(checkExisting: false),
      ),
    );
    await tester.pump();

    final tabletButtonBox = tester.getRect(find.byType(ElevatedButton));
    final tabletButtonHeight = tabletButtonBox.height;
    final tabletButtonWidth = tabletButtonBox.width;

    // Tablet CTA button must be strictly larger than on phone (70px vs 52px)
    expect(tabletButtonHeight, greaterThan(phoneButtonHeight));
    expect(tabletButtonHeight, equals(70.0));

    // Tablet CTA button width must utilize screen width (at least 740px on 820px tablet)
    // to eliminate unnecessary space between content and sides of the screen
    expect(tabletButtonWidth, greaterThanOrEqualTo(750.0));

    // Tablet CTA button bottom must reach the lower screen region (at least > 1050 on an 1180px screen)
    // to ensure screen size is utilized to the maximum without a large blank void
    expect(tabletButtonBox.bottom, greaterThan(1050.0));
  });
}
