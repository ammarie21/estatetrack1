import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/utils/apartment_display.dart';
import 'package:estatetrack1/utils/report_period.dart';

class OutstandingBalanceRow {
  const OutstandingBalanceRow({
    required this.bookingId,
    required this.customerName,
    required this.apartmentLabel,
    required this.remaining,
    required this.status,
    required this.endDate,
  });

  final int bookingId;
  final String customerName;
  final String apartmentLabel;
  final double remaining;
  final String status;
  final DateTime endDate;
}

class ProfitRow {
  const ProfitRow({
    required this.id,
    required this.label,
    required this.revenue,
    required this.maintenance,
    required this.net,
  });

  final int id;
  final String label;
  final double revenue;
  final double maintenance;
  final double net;
}

class LabeledAmount {
  const LabeledAmount({required this.label, required this.amount});

  final String label;
  final double amount;
}

class OccupancyMonthPoint {
  const OccupancyMonthPoint({
    required this.label,
    required this.rate,
    required this.occupied,
    required this.total,
  });

  final String label;
  final double rate;
  final int occupied;
  final int total;
}

class LeaseExpiryRow {
  const LeaseExpiryRow({
    required this.contract,
    required this.customerName,
    required this.apartmentLabel,
    required this.daysUntilEnd,
  });

  final ContractModel contract;
  final String customerName;
  final String apartmentLabel;
  final int daysUntilEnd;
}

class RevenueMonthPoint {
  const RevenueMonthPoint({required this.label, required this.revenue});

  final String label;
  final double revenue;
}

class CustomerReliabilityRow {
  const CustomerReliabilityRow({
    required this.customerId,
    required this.name,
    required this.totalPaid,
    required this.totalRemaining,
    required this.problemBookings,
  });

  final int customerId;
  final String name;
  final double totalPaid;
  final double totalRemaining;
  final int problemBookings;
}

class ReportAnalyticsInput {
  const ReportAnalyticsInput({
    required this.transactions,
    required this.apartments,
    required this.buildings,
    required this.customers,
    required this.bookings,
    required this.contracts,
    required this.maintenance,
    required this.period,
    this.now,
  });

  final List<RentalTransactionModel> transactions;
  final List<ApartmentModel> apartments;
  final List<BuildingModel> buildings;
  final List<CustomerModel> customers;
  final List<RentalBookingModel> bookings;
  final List<ContractModel> contracts;
  final List<MaintenanceModel> maintenance;
  final ReportPeriodRange period;
  final DateTime? now;
}

int? parseMaintenanceApartmentId(String value) => int.tryParse(value.trim());

List<RentalTransactionModel> transactionsInPeriod(
  List<RentalTransactionModel> transactions,
  ReportPeriodRange period,
) {
  return transactions
      .where((t) => period.contains(t.updatedTransactionDate))
      .toList();
}

List<MaintenanceModel> maintenanceInPeriod(
  List<MaintenanceModel> maintenance,
  ReportPeriodRange period,
) {
  return maintenance.where((m) {
    final date = parseReportDate(m.date);
    return date != null && period.contains(date);
  }).toList();
}

Map<int, RentalBookingModel> bookingMap(List<RentalBookingModel> bookings) {
  return {for (final b in bookings) b.bookingId: b};
}

String customerName(int customerId, List<CustomerModel> customers) {
  return customers.where((c) => c.customerId == customerId).firstOrNull?.name ??
      'Customer #$customerId';
}

List<OutstandingBalanceRow> computeOutstandingBalances(
  ReportAnalyticsInput input,
) {
  final bookings = bookingMap(input.bookings);
  final rows = <OutstandingBalanceRow>[];

  for (final tx in input.transactions) {
    if (tx.totalRemaining <= 0) continue;
    if (tx.transactionStatus == 'Closed' || tx.transactionStatus == 'Paid') {
      continue;
    }

    final booking = bookings[tx.bookingId];
    if (booking == null) continue;

    rows.add(
      OutstandingBalanceRow(
        bookingId: tx.bookingId,
        customerName: customerName(booking.customerId, input.customers),
        apartmentLabel: apartmentDisplayLabelById(
          booking.apartmentId,
          input.apartments,
          input.buildings,
        ),
        remaining: tx.totalRemaining,
        status: tx.transactionStatus,
        endDate: booking.endDate,
      ),
    );
  }

  rows.sort((a, b) => b.remaining.compareTo(a.remaining));
  return rows;
}

List<ProfitRow> computeProfitByApartment(ReportAnalyticsInput input) {
  final periodTx = transactionsInPeriod(input.transactions, input.period);
  final periodMaint = maintenanceInPeriod(input.maintenance, input.period);
  final bookings = bookingMap(input.bookings);

  final revenue = <int, double>{};
  for (final tx in periodTx) {
    final aptId = bookings[tx.bookingId]?.apartmentId;
    if (aptId == null) continue;
    revenue[aptId] = (revenue[aptId] ?? 0) + tx.paidInitialTotalDueAmount;
  }

  final costs = <int, double>{};
  for (final m in periodMaint) {
    final aptId = parseMaintenanceApartmentId(m.apartmentId);
    if (aptId == null) continue;
    costs[aptId] = (costs[aptId] ?? 0) + m.cost;
  }

  final ids = <int>{...revenue.keys, ...costs.keys};
  final rows = <ProfitRow>[];

  for (final id in ids) {
    final apt = input.apartments.where((a) => a.apartmentId == id).firstOrNull;
    final rev = revenue[id] ?? 0;
    final maint = costs[id] ?? 0;
    rows.add(
      ProfitRow(
        id: id,
        label: apt == null
            ? 'Apartment #$id'
            : apartmentDisplayLabel(apt, input.buildings),
        revenue: rev,
        maintenance: maint,
        net: rev - maint,
      ),
    );
  }

  rows.sort((a, b) => b.net.compareTo(a.net));
  return rows;
}

List<ProfitRow> computeProfitByBuilding(ReportAnalyticsInput input) {
  final apartmentRows = computeProfitByApartment(input);
  final aptById = {for (final a in input.apartments) a.apartmentId: a};
  final revenue = <int, double>{};
  final costs = <int, double>{};

  for (final row in apartmentRows) {
    final buildingId = aptById[row.id]?.buildingId;
    if (buildingId == null) continue;
    revenue[buildingId] = (revenue[buildingId] ?? 0) + row.revenue;
    costs[buildingId] = (costs[buildingId] ?? 0) + row.maintenance;
  }

  final ids = <int>{...revenue.keys, ...costs.keys};
  final rows = <ProfitRow>[];

  for (final id in ids) {
    final building = input.buildings
        .where((b) => b.buildingId == id)
        .firstOrNull;
    final rev = revenue[id] ?? 0;
    final maint = costs[id] ?? 0;
    rows.add(
      ProfitRow(
        id: id,
        label: building?.name ?? 'Building #$id',
        revenue: rev,
        maintenance: maint,
        net: rev - maint,
      ),
    );
  }

  rows.sort((a, b) => b.net.compareTo(a.net));
  return rows;
}

List<LabeledAmount> maintenanceByApartment(ReportAnalyticsInput input) {
  final periodMaint = maintenanceInPeriod(input.maintenance, input.period);
  final totals = <String, double>{};

  for (final m in periodMaint) {
    final aptId = parseMaintenanceApartmentId(m.apartmentId);
    final label = aptId == null
        ? 'Apartment ${m.apartmentId}'
        : apartmentDisplayLabelById(aptId, input.apartments, input.buildings);
    totals[label] = (totals[label] ?? 0) + m.cost;
  }

  final rows =
      totals.entries
          .map((e) => LabeledAmount(label: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
  return rows;
}

List<LabeledAmount> maintenanceByBuilding(ReportAnalyticsInput input) {
  final periodMaint = maintenanceInPeriod(input.maintenance, input.period);
  final aptById = {for (final a in input.apartments) a.apartmentId: a};
  final totals = <String, double>{};

  for (final m in periodMaint) {
    final aptId = parseMaintenanceApartmentId(m.apartmentId);
    final buildingId = aptId == null ? null : aptById[aptId]?.buildingId;
    final label = buildingId == null
        ? 'Unknown building'
        : input.buildings
                  .where((b) => b.buildingId == buildingId)
                  .firstOrNull
                  ?.name ??
              'Building #$buildingId';
    totals[label] = (totals[label] ?? 0) + m.cost;
  }

  final rows =
      totals.entries
          .map((e) => LabeledAmount(label: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
  return rows;
}

List<MaintenanceModel> topMaintenanceItems(
  ReportAnalyticsInput input, {
  int limit = 5,
}) {
  final periodMaint = maintenanceInPeriod(input.maintenance, input.period)
    ..sort((a, b) => b.cost.compareTo(a.cost));
  return periodMaint.take(limit).toList();
}

List<RevenueMonthPoint> maintenanceMonthlyTrend(
  ReportAnalyticsInput input, {
  int months = 6,
}) {
  final now = input.now ?? DateTime.now();
  final points = <RevenueMonthPoint>[];

  for (var i = months - 1; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final total = input.maintenance
        .where((m) {
          final date = parseReportDate(m.date);
          if (date == null) return false;
          return !date.isBefore(month) && !date.isAfter(monthEnd);
        })
        .fold(0.0, (sum, m) => sum + m.cost);

    points.add(RevenueMonthPoint(label: _monthLabel(month), revenue: total));
  }

  return points;
}

List<OccupancyMonthPoint> computeOccupancyTrend(
  ReportAnalyticsInput input, {
  int months = 6,
}) {
  final now = input.now ?? DateTime.now();
  final total = input.apartments.length;
  final points = <OccupancyMonthPoint>[];

  for (var i = months - 1; i >= 0; i--) {
    final monthStart = DateTime(now.year, now.month - i, 1);
    final monthEnd = DateTime(
      monthStart.year,
      monthStart.month + 1,
      0,
      23,
      59,
      59,
    );

    var occupied = 0;
    for (final apt in input.apartments) {
      final leased = input.contracts.any((contract) {
        if (contract.apartmentId != apt.apartmentId) return false;
        return !contract.endDate.isBefore(monthStart) &&
            !contract.startDate.isAfter(monthEnd);
      });
      if (leased) occupied++;
    }

    points.add(
      OccupancyMonthPoint(
        label: _monthLabel(monthStart),
        rate: total == 0 ? 0 : occupied / total * 100,
        occupied: occupied,
        total: total,
      ),
    );
  }

  return points;
}

List<LeaseExpiryRow> computeLeaseExpiries(
  ReportAnalyticsInput input, {
  int withinDays = 90,
}) {
  final now = input.now ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final rows = <LeaseExpiryRow>[];

  for (final contract in input.contracts) {
    if (contract.status != 'Active') continue;
    final days = contract.endDate.difference(today).inDays;
    if (days < 0 || days > withinDays) continue;

    rows.add(
      LeaseExpiryRow(
        contract: contract,
        customerName: customerName(contract.customerId, input.customers),
        apartmentLabel: apartmentDisplayLabelById(
          contract.apartmentId,
          input.apartments,
          input.buildings,
        ),
        daysUntilEnd: days,
      ),
    );
  }

  rows.sort((a, b) => a.daysUntilEnd.compareTo(b.daysUntilEnd));
  return rows;
}

List<RevenueMonthPoint> computeRevenueTrend(
  ReportAnalyticsInput input, {
  int months = 6,
}) {
  final now = input.now ?? DateTime.now();
  final points = <RevenueMonthPoint>[];

  for (var i = months - 1; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final total = input.transactions
        .where((tx) {
          final date = tx.updatedTransactionDate;
          return !date.isBefore(month) && !date.isAfter(monthEnd);
        })
        .fold(0.0, (sum, tx) => sum + tx.paidInitialTotalDueAmount);

    points.add(RevenueMonthPoint(label: _monthLabel(month), revenue: total));
  }

  return points;
}

({double current, double previous, double changePct}) revenueMonthComparison(
  ReportAnalyticsInput input,
) {
  final now = input.now ?? DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);
  final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

  double sumRange(DateTime start, DateTime end) {
    return input.transactions
        .where((tx) {
          final date = tx.updatedTransactionDate;
          return !date.isBefore(start) && !date.isAfter(end);
        })
        .fold(0.0, (sum, tx) => sum + tx.paidInitialTotalDueAmount);
  }

  final current = sumRange(thisMonthStart, thisMonthEnd);
  final previous = sumRange(lastMonthStart, lastMonthEnd);
  final changePct = previous <= 0
      ? (current > 0 ? 100.0 : 0.0)
      : ((current - previous) / previous * 100);

  return (current: current, previous: previous, changePct: changePct);
}

double computeCollectionRate(List<RentalTransactionModel> transactions) {
  final due = transactions.fold(
    0.0,
    (sum, tx) => sum + tx.actualTotalDueAmount,
  );
  if (due <= 0) return 0;
  final paid = transactions.fold(
    0.0,
    (sum, tx) => sum + tx.paidInitialTotalDueAmount,
  );
  return paid / due * 100;
}

List<CustomerReliabilityRow> computeCustomerReliability(
  ReportAnalyticsInput input,
) {
  final bookings = bookingMap(input.bookings);
  final byCustomer = <int, CustomerReliabilityRow>{};

  for (final tx in input.transactions) {
    final customerId = bookings[tx.bookingId]?.customerId;
    if (customerId == null) continue;

    final existing = byCustomer[customerId];
    final isProblem =
        tx.transactionStatus == 'Pending' || tx.transactionStatus == 'Partial';
    final next = CustomerReliabilityRow(
      customerId: customerId,
      name: customerName(customerId, input.customers),
      totalPaid: (existing?.totalPaid ?? 0) + tx.paidInitialTotalDueAmount,
      totalRemaining: (existing?.totalRemaining ?? 0) + tx.totalRemaining,
      problemBookings: (existing?.problemBookings ?? 0) + (isProblem ? 1 : 0),
    );
    byCustomer[customerId] = next;
  }

  final rows = byCustomer.values.toList()
    ..sort((a, b) {
      final risk = b.totalRemaining.compareTo(a.totalRemaining);
      if (risk != 0) return risk;
      return b.problemBookings.compareTo(a.problemBookings);
    });
  return rows;
}

double computeVacancyLoss(List<ApartmentModel> apartments) {
  return apartments
      .where((a) => a.isAvailable)
      .fold(0.0, (sum, a) => sum + a.rentPricePerMonth);
}

String _monthLabel(DateTime month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${names[month.month - 1]} ${month.year % 100}';
}
