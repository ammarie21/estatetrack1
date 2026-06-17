import 'package:estatetrack1/utils/report_analytics.dart';
import 'package:estatetrack1/utils/report_period.dart';
import 'package:estatetrack1/utils/report_snapshot.dart';

String buildReportCsv({
  required ReportAnalyticsInput input,
  required String periodLabel,
  ReportPeriodRange? period,
  ReportSnapshot? snapshot,
}) {
  final range = period ?? input.period;
  final snap =
      snapshot ??
      ReportSnapshot.compute(
        transactions: input.transactions,
        apartments: input.apartments,
        buildings: input.buildings,
        customers: input.customers,
        bookings: input.bookings,
        contracts: input.contracts,
        maintenance: input.maintenance,
        period: range,
      );

  final buffer = StringBuffer()
    ..writeln('EstateTrack Report,$periodLabel')
    ..writeln('Period,${formatReportPeriodRange(range)}')
    ..writeln('Generated,${DateTime.now().toIso8601String()}')
    ..writeln()
    ..writeln('Summary KPIs')
    ..writeln('Metric,Value')
    ..writeln('Revenue,${snap.totalRevenue.toStringAsFixed(2)}')
    ..writeln('Maintenance,${snap.totalMaintenance.toStringAsFixed(2)}')
    ..writeln('Net profit,${snap.netProfit.toStringAsFixed(2)}')
    ..writeln('Outstanding,${snap.outstandingTotal.toStringAsFixed(2)}')
    ..writeln(
      'Collection rate,${snap.collectionRate.toStringAsFixed(1)}%',
    )
    ..writeln('Vacancy loss/mo,${snap.vacancyLoss.toStringAsFixed(2)}')
    ..writeln(
      'Period revenue change,${snap.periodComparison.changePct.toStringAsFixed(1)}%',
    )
    ..writeln('Active leases,${snap.activeLeases}')
    ..writeln('Occupancy,${snap.occupancyRate.toStringAsFixed(1)}%')
    ..writeln()
    ..writeln('Outstanding balances')
    ..writeln('Booking,Customer,Apartment,Remaining,Status,Lease end');

  for (final row in snap.outstanding) {
    buffer.writeln(
      '${row.bookingId},'
      '"${row.customerName.replaceAll('"', '""')}",'
      '"${row.apartmentLabel.replaceAll('"', '""')}",'
      '${row.remaining.toStringAsFixed(2)},'
      '${row.status},'
      '${row.endDate.toIso8601String().split('T').first}',
    );
  }

  buffer
    ..writeln()
    ..writeln('Lease expiries (90 days)')
    ..writeln('Customer,Apartment,Days left,End date');

  for (final row in snap.leaseExpiries) {
    buffer.writeln(
      '"${row.customerName.replaceAll('"', '""')}",'
      '"${row.apartmentLabel.replaceAll('"', '""')}",'
      '${row.daysUntilEnd},'
      '${row.contract.endDate.toIso8601String().split('T').first}',
    );
  }

  buffer
    ..writeln()
    ..writeln('Customer reliability')
    ..writeln('Customer,Paid,Remaining,Problem bookings');

  for (final row in snap.customerReliability) {
    buffer.writeln(
      '"${row.name.replaceAll('"', '""')}",'
      '${row.totalPaid.toStringAsFixed(2)},'
      '${row.totalRemaining.toStringAsFixed(2)},'
      '${row.problemBookings}',
    );
  }

  buffer
    ..writeln()
    ..writeln('Profit by apartment')
    ..writeln('Apartment,Revenue,Maintenance,Net');

  for (final row in snap.profitByApartment) {
    buffer.writeln(
      '"${row.label.replaceAll('"', '""')}",'
      '${row.revenue.toStringAsFixed(2)},'
      '${row.maintenance.toStringAsFixed(2)},'
      '${row.net.toStringAsFixed(2)}',
    );
  }

  buffer
    ..writeln()
    ..writeln('Profit by building')
    ..writeln('Building,Revenue,Maintenance,Net');

  for (final row in snap.profitByBuilding) {
    buffer.writeln(
      '"${row.label.replaceAll('"', '""')}",'
      '${row.revenue.toStringAsFixed(2)},'
      '${row.maintenance.toStringAsFixed(2)},'
      '${row.net.toStringAsFixed(2)}',
    );
  }

  buffer
    ..writeln()
    ..writeln('Maintenance by apartment')
    ..writeln('Apartment,Cost');

  for (final row in snap.maintByApartment) {
    buffer.writeln(
      '"${row.label.replaceAll('"', '""')}",'
      '${row.amount.toStringAsFixed(2)}',
    );
  }

  return buffer.toString();
}

String buildReportSummaryText({
  required ReportSnapshot snapshot,
  required String periodLabel,
}) {
  final snap = snapshot;
  final compare = snap.periodComparison;
  final compareLabel = compare.changePct >= 0 ? '+' : '';

  return [
    'EstateTrack — $periodLabel',
    'Range: ${formatReportPeriodRange(snap.period)}',
    'Revenue: \$${snap.totalRevenue.toStringAsFixed(2)} '
        '($compareLabel${compare.changePct.toStringAsFixed(0)}% vs prior period)',
    'Maintenance: \$${snap.totalMaintenance.toStringAsFixed(2)}',
    'Net: \$${snap.netProfit.toStringAsFixed(2)}',
    'Outstanding: \$${snap.outstandingTotal.toStringAsFixed(2)} '
        '(${snap.outstanding.length} bookings)',
    'Collection rate: ${snap.collectionRate.toStringAsFixed(0)}%',
    'Vacancy loss: \$${snap.vacancyLoss.toStringAsFixed(2)}/mo',
    'This month: \$${snap.monthComparison.current.toStringAsFixed(2)}',
    'Occupancy: ${snap.occupancyRate.toStringAsFixed(0)}% '
        '(${snap.occupiedCount}/${snapshot.input.apartments.length})',
    'Active leases: ${snap.activeLeases}',
    'Leases expiring (90d): ${snap.leaseExpiries.length}',
  ].join('\n');
}
