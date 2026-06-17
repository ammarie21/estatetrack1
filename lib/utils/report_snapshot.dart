import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/utils/report_analytics.dart';
import 'package:estatetrack1/utils/report_period.dart';

/// Pre-computed report metrics for a single period — avoids duplicate scans.
class ReportSnapshot {
  const ReportSnapshot({
    required this.input,
    required this.period,
    required this.filteredTransactions,
    required this.filteredMaintenance,
    required this.totalRevenue,
    required this.totalMaintenance,
    required this.netProfit,
    required this.outstandingTotal,
    required this.outstanding,
    required this.collectionRate,
    required this.vacancyLoss,
    required this.periodComparison,
    required this.monthComparison,
    required this.profitByApartment,
    required this.profitByBuilding,
    required this.maintByApartment,
    required this.maintByBuilding,
    required this.topMaintenance,
    required this.maintTrend,
    required this.occupancyTrend,
    required this.leaseExpiries,
    required this.revenueTrend,
    required this.customerReliability,
    required this.paymentStatusCounts,
    required this.occupiedCount,
    required this.occupancyRate,
    required this.averageRent,
    required this.activeLeases,
  });

  final ReportAnalyticsInput input;
  final ReportPeriodRange period;
  final List<RentalTransactionModel> filteredTransactions;
  final List<MaintenanceModel> filteredMaintenance;
  final double totalRevenue;
  final double totalMaintenance;
  final double netProfit;
  final double outstandingTotal;
  final List<OutstandingBalanceRow> outstanding;
  final double collectionRate;
  final double vacancyLoss;
  final ({double current, double previous, double changePct}) periodComparison;
  final ({double current, double previous, double changePct}) monthComparison;
  final List<ProfitRow> profitByApartment;
  final List<ProfitRow> profitByBuilding;
  final List<LabeledAmount> maintByApartment;
  final List<LabeledAmount> maintByBuilding;
  final List<MaintenanceModel> topMaintenance;
  final List<RevenueMonthPoint> maintTrend;
  final List<OccupancyMonthPoint> occupancyTrend;
  final List<LeaseExpiryRow> leaseExpiries;
  final List<RevenueMonthPoint> revenueTrend;
  final List<CustomerReliabilityRow> customerReliability;
  final Map<String, int> paymentStatusCounts;
  final int occupiedCount;
  final double occupancyRate;
  final double averageRent;
  final int activeLeases;

  int get expiringWithin7 =>
      leaseExpiries.where((r) => r.daysUntilEnd <= 7).length;

  int get expiringWithin30 =>
      leaseExpiries.where((r) => r.daysUntilEnd <= 30).length;

  factory ReportSnapshot.compute({
    required List<RentalTransactionModel> transactions,
    required List<ApartmentModel> apartments,
    required List<BuildingModel> buildings,
    required List<CustomerModel> customers,
    required List<RentalBookingModel> bookings,
    required List<ContractModel> contracts,
    required List<MaintenanceModel> maintenance,
    required ReportPeriodRange period,
  }) {
    final indexes = EstateIndexes.fromLists(
      customers: customers,
      buildings: buildings,
      apartments: apartments,
      bookings: bookings,
      transactions: transactions,
    );
    final input = ReportAnalyticsInput(
      transactions: transactions,
      apartments: apartments,
      buildings: buildings,
      customers: customers,
      bookings: bookings,
      contracts: contracts,
      maintenance: maintenance,
      period: period,
      indexes: indexes,
    );

    final filteredTransactions = transactionsInPeriod(transactions, period);
    final filteredMaintenance = maintenanceInPeriod(maintenance, period);
    final totalRevenue = filteredTransactions.fold(
      0.0,
      (sum, t) => sum + t.paidInitialTotalDueAmount,
    );
    final totalMaintenance = filteredMaintenance.fold(
      0.0,
      (sum, m) => sum + m.cost,
    );
    final outstanding = computeOutstandingBalances(input);
    final outstandingTotal = outstanding.fold(
      0.0,
      (sum, row) => sum + row.remaining,
    );

    final paymentStatusCounts = <String, int>{};
    for (final t in filteredTransactions) {
      paymentStatusCounts[t.transactionStatus] =
          (paymentStatusCounts[t.transactionStatus] ?? 0) + 1;
    }

    final occupiedCount = apartments.where((a) => !a.isAvailable).length;
    final occupancyRate = apartments.isEmpty
        ? 0.0
        : occupiedCount / apartments.length * 100;
    final averageRent = apartments.isEmpty
        ? 0.0
        : apartments.fold(0.0, (sum, a) => sum + a.rentPricePerMonth) /
              apartments.length;

    return ReportSnapshot(
      input: input,
      period: period,
      filteredTransactions: filteredTransactions,
      filteredMaintenance: filteredMaintenance,
      totalRevenue: totalRevenue,
      totalMaintenance: totalMaintenance,
      netProfit: totalRevenue - totalMaintenance,
      outstandingTotal: outstandingTotal,
      outstanding: outstanding,
      collectionRate: computeCollectionRate(filteredTransactions),
      vacancyLoss: computeVacancyLoss(apartments),
      periodComparison: revenuePeriodComparison(transactions, period),
      monthComparison: revenueMonthComparison(input),
      profitByApartment: computeProfitByApartment(input),
      profitByBuilding: computeProfitByBuilding(input),
      maintByApartment: maintenanceByApartment(input),
      maintByBuilding: maintenanceByBuilding(input),
      topMaintenance: topMaintenanceItems(input),
      maintTrend: maintenanceMonthlyTrend(input),
      occupancyTrend: computeOccupancyTrend(input),
      leaseExpiries: computeLeaseExpiries(input),
      revenueTrend: computeRevenueTrend(input),
      customerReliability: computeCustomerReliability(input),
      paymentStatusCounts: paymentStatusCounts,
      occupiedCount: occupiedCount,
      occupancyRate: occupancyRate,
      averageRent: averageRent,
      activeLeases: contracts.where((c) => c.status == 'Active').length,
    );
  }
}
