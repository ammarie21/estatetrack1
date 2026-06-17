import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'report_fixtures.dart';
import 'test_helpers.dart';

Finder drillInkWellForSubtitle(String subtitle) {
  return find.ancestor(
    of: find.text(subtitle),
    matching: find.byType(InkWell),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('reports screen shows metrics and all drill-down cards', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, reportScreen());

    expect(find.text('Reports & analytics'), findsOneWidget);
    expect(find.text('Key metrics'), findsOneWidget);
    expect(find.text('Report drill-downs'), findsOneWidget);

    expect(find.text('Revenue'), findsWidgets);
    expect(find.text('Outstanding'), findsWidgets);
    expect(find.text('Collection rate'), findsWidgets);
    expect(find.text('Vacancy loss'), findsOneWidget);
    expect(find.text('Occupancy'), findsOneWidget);

    expect(find.text('Cash collection'), findsWidgets);
    expect(find.text('Lease expiries'), findsWidgets);
    expect(find.text('Customer reliability'), findsWidgets);
    expect(find.text('Trends'), findsWidgets);
    expect(find.text('Profit by apartment'), findsWidgets);
    expect(find.text('Profit by building'), findsWidgets);
    expect(find.text('Maintenance analysis'), findsOneWidget);
    expect(find.text('Maintenance log'), findsOneWidget);

    expect(find.text('Average rent'), findsOneWidget);
    expect(find.byTooltip('Copy summary'), findsOneWidget);
    expect(find.byTooltip('Export CSV'), findsOneWidget);
    expect(find.text('Partial: 1'), findsOneWidget);
  });

  testWidgets('reports screen opens cash collection drill-down', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, reportScreen());

    await tapVisible(
      tester,
      drillInkWellForSubtitle('Outstanding balances and collection rate'),
    );

    expect(find.text('Outstanding balances'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.textContaining('Booking #1'), findsOneWidget);
  });

  testWidgets('reports screen opens trends drill-down with charts', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, reportScreen());

    await tapVisible(tester, drillInkWellForSubtitle('Revenue, occupancy, and revenue vs expenses'));

    expect(find.text('Revenue trend'), findsOneWidget);
    expect(find.text('Occupancy trend'), findsOneWidget);
    expect(find.text('Revenue vs maintenance expenses'), findsOneWidget);
  });

  testWidgets('reports screen opens profit by apartment drill-down', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, reportScreen());

    await tapVisible(
      tester,
      drillInkWellForSubtitle('Revenue minus maintenance per unit'),
    );

    expect(find.textContaining('Revenue \$'), findsWidgets);
    expect(find.textContaining('\$1850'), findsOneWidget);
  });

  testWidgets('reports metric tap opens cash collection from outstanding', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, reportScreen());

    await tapVisible(
      tester,
      find.ancestor(
        of: find.text('\$3000'),
        matching: find.byType(InkWell),
      ),
    );

    expect(find.text('Outstanding balances'), findsOneWidget);
  });

  testWidgets('reports outstanding row invokes navigation callback', (
    WidgetTester tester,
  ) async {
    int? openedBooking;
    String? openedStatus;

    await pumpBody(
      tester,
      reportScreen(
        onOpenOutstandingBooking: (bookingId, status) {
          openedBooking = bookingId;
          openedStatus = status;
        },
      ),
    );

    await tapVisible(
      tester,
      drillInkWellForSubtitle('Outstanding balances and collection rate'),
    );
    await tapVisible(tester, find.text('Alice'));

    expect(openedBooking, 1);
    expect(openedStatus, 'Partial');
  });

  testWidgets('reports empty data shows zero-friendly metrics', (
    WidgetTester tester,
  ) async {
    await pumpBody(tester, emptyReportScreen());

    expect(find.text('Reports & analytics'), findsOneWidget);
    expect(find.text('\$0'), findsWidgets);
    expect(find.text('0%'), findsWidgets);
  });
}
