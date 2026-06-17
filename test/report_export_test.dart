import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/utils/report_export.dart';
import 'package:estatetrack1/utils/report_period.dart';
import 'package:estatetrack1/utils/report_snapshot.dart';
import 'report_fixtures.dart';

void main() {
  late ReportSnapshot snapshot;

  setUp(() {
    snapshot = ReportSnapshot.compute(
      transactions: kReportTransactions,
      apartments: kReportApartments,
      buildings: kReportBuildings,
      customers: kReportCustomers,
      bookings: kReportBookings,
      contracts: kReportContracts,
      maintenance: kReportMaintenance,
      period: reportPeriodRange('This Month', now: kReportNow),
    );
  });

  test('csv includes all report sections and fixture rows', () {
    final csv = buildReportCsv(
      input: snapshot.input,
      periodLabel: 'This Month',
      snapshot: snapshot,
    );

    expect(csv, contains('EstateTrack Report,This Month'));
    expect(csv, contains('Summary KPIs'));
    expect(csv, contains('Outstanding balances'));
    expect(csv, contains('Lease expiries (90 days)'));
    expect(csv, contains('Customer reliability'));
    expect(csv, contains('Profit by apartment'));
    expect(csv, contains('Profit by building'));
    expect(csv, contains('Maintenance by apartment'));
    expect(csv, contains('Alice'));
    expect(csv, contains('Tower A'));
    expect(csv, contains('Revenue,2000.00'));
    expect(csv, contains('Net profit,1850.00'));
    expect(csv, contains('Outstanding,3000.00'));
  });

  test('summary text includes kpis and period comparison', () {
    final text = buildReportSummaryText(
      snapshot: snapshot,
      periodLabel: 'This Month',
    );

    expect(text, contains('EstateTrack — This Month'));
    expect(text, contains('Range:'));
    expect(text, contains('Revenue: \$2000.00'));
    expect(text, contains('vs prior period'));
    expect(text, contains('Outstanding: \$3000.00'));
    expect(text, contains('Collection rate: 40%'));
    expect(text, contains('Active leases: 1'));
    expect(text, contains('Leases expiring (90d): 1'));
  });
}
