import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/main.dart';

void main() {
  testWidgets('Login screen shows EstateTrack', (WidgetTester tester) async {
    await tester.pumpWidget(const EstateTrackApp());

    expect(find.text('EstateTrack'), findsWidgets);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Login navigates to dashboard with bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const EstateTrackApp());
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Total Apartments'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Dashboard'),
      ),
      findsOneWidget,
    );
  });
}
