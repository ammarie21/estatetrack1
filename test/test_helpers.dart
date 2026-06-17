import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

Future<void> pumpBody(WidgetTester tester, Widget body) async {
  await pumpScreen(tester, Scaffold(body: body));
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  final listFinder = find.byType(Scrollable).first;
  for (var i = 0; i < 8; i++) {
    await tester.drag(listFinder, const Offset(0, -400));
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) return;
  }
}
