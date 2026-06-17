import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/utils/report_period.dart';
import 'package:estatetrack1/utils/report_snapshot.dart';
import 'report_fixtures.dart';

void main() {
  final period = reportPeriodRange('This Month', now: kReportNow);

  test('snapshot aggregates revenue maintenance and net profit', () {
    final snap = ReportSnapshot.compute(
      transactions: kReportTransactions,
      apartments: kReportApartments,
      buildings: kReportBuildings,
      customers: kReportCustomers,
      bookings: kReportBookings,
      contracts: kReportContracts,
      maintenance: kReportMaintenance,
      period: period,
    );

    expect(snap.totalRevenue, 2000);
    expect(snap.totalMaintenance, 150);
    expect(snap.netProfit, 1850);
    expect(snap.outstandingTotal, 3000);
    expect(snap.outstanding, hasLength(1));
    expect(snap.collectionRate, 40);
    expect(snap.vacancyLoss, 800);
    expect(snap.activeLeases, 1);
    expect(snap.occupiedCount, 1);
    expect(snap.occupancyRate, 50);
    expect(snap.averageRent, 900);
  });

  test('snapshot includes trend and reliability collections', () {
    final snap = ReportSnapshot.compute(
      transactions: kReportTransactions,
      apartments: kReportApartments,
      buildings: kReportBuildings,
      customers: kReportCustomers,
      bookings: kReportBookings,
      contracts: kReportContracts,
      maintenance: kReportMaintenance,
      period: period,
    );

    expect(snap.revenueTrend, hasLength(6));
    expect(snap.occupancyTrend, hasLength(6));
    expect(snap.maintTrend, hasLength(6));
    expect(snap.profitByApartment, isNotEmpty);
    expect(snap.profitByBuilding, isNotEmpty);
    expect(snap.customerReliability, isNotEmpty);
    expect(snap.leaseExpiries, hasLength(1));
    expect(snap.expiringWithin7, 1);
    expect(snap.paymentStatusCounts['Partial'], 1);
  });

  test('snapshot filters maintenance and transactions by period', () {
    final snap = ReportSnapshot.compute(
      transactions: kReportTransactions,
      apartments: kReportApartments,
      buildings: kReportBuildings,
      customers: kReportCustomers,
      bookings: kReportBookings,
      contracts: kReportContracts,
      maintenance: kReportMaintenance,
      period: period,
    );

    expect(snap.filteredTransactions, hasLength(1));
    expect(snap.filteredMaintenance, hasLength(1));
    expect(snap.filteredMaintenance.first.description, 'Paint');
  });
}
