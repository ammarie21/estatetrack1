import 'package:flutter_test/flutter_test.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/utils/report_analytics.dart';
import 'package:estatetrack1/utils/report_period.dart';
import 'report_fixtures.dart';

void main() {
  final buildings = [
    const BuildingModel(
      buildingId: 1,
      name: 'Tower A',
      floorsCount: 5,
      constructionYear: 2020,
      totalApartments: 10,
      location: 'Downtown',
    ),
  ];

  final apartments = [
    const ApartmentModel(
      apartmentId: 1,
      buildingId: 1,
      typeId: 1,
      sizeM2: 80,
      number: '101',
      location: 'Floor 1',
      rentPricePerMonth: 1000,
      rentPricePerDay: 50,
      bedrooms: 2,
      bathrooms: 1,
      isAvailable: false,
      hasBalcony: true,
      furnished: true,
      hasInternet: true,
      parking: true,
      elevator: true,
    ),
    const ApartmentModel(
      apartmentId: 2,
      buildingId: 1,
      typeId: 1,
      sizeM2: 60,
      number: '102',
      location: 'Floor 1',
      rentPricePerMonth: 800,
      rentPricePerDay: 40,
      bedrooms: 1,
      bathrooms: 1,
      isAvailable: true,
      hasBalcony: false,
      furnished: false,
      hasInternet: true,
      parking: false,
      elevator: true,
    ),
  ];

  final customers = [
    const CustomerModel(
      customerId: 1,
      name: 'Alice',
      phone: '123',
      nationalNum: 'N1',
      numberOfRentedApartments: 1,
    ),
  ];

  final bookings = [
    RentalBookingModel(
      bookingId: 1,
      userId: 1,
      customerId: 1,
      apartmentId: 1,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 6, 30),
      initialTotalDueAmount: 5000,
      bookingType: 0,
      periodFee: 1000,
      rentalPrice: 2000,
    ),
  ];

  final transactions = [
    RentalTransactionModel(
      transactionId: 1,
      bookingId: 1,
      paidInitialTotalDueAmount: 2000,
      actualTotalDueAmount: 5000,
      totalRemaining: 3000,
      totalRefundedAmount: 0,
      transactionStatus: 'Partial',
      updatedTransactionDate: DateTime(2026, 6, 10),
    ),
  ];

  final contracts = [
    ContractModel(
      contractId: 1,
      customerId: 1,
      apartmentId: 1,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 6, 20),
      totalAmount: 5000,
      status: 'Active',
      bookingId: 1,
    ),
  ];

  final maintenance = [
    const MaintenanceModel(
      id: 1,
      apartmentId: '1',
      description: 'Paint',
      cost: 150,
      date: '2026-06-05',
    ),
  ];

  final input = ReportAnalyticsInput(
    transactions: transactions,
    apartments: apartments,
    buildings: buildings,
    customers: customers,
    bookings: bookings,
    contracts: contracts,
    maintenance: maintenance,
    period: reportPeriodRange('This Month', now: DateTime(2026, 6, 15)),
    now: DateTime(2026, 6, 15),
  );

  test('outstanding balances include partial bookings', () {
    final rows = computeOutstandingBalances(input);
    expect(rows, hasLength(1));
    expect(rows.first.remaining, 3000);
    expect(rows.first.customerName, 'Alice');
  });

  test('profit by apartment subtracts maintenance', () {
    final rows = computeProfitByApartment(input);
    expect(rows, hasLength(1));
    expect(rows.first.revenue, 2000);
    expect(rows.first.maintenance, 150);
    expect(rows.first.net, 1850);
  });

  test('vacancy loss sums vacant apartment rents', () {
    expect(computeVacancyLoss(apartments), 800);
  });

  test('collection rate uses paid over due', () {
    expect(computeCollectionRate(transactions), 40);
  });

  test('lease expiries include active contracts within 90 days', () {
    final rows = computeLeaseExpiries(input);
    expect(rows, hasLength(1));
    expect(rows.first.daysUntilEnd, 5);
  });

  test('profit by building aggregates apartment revenue', () {
    final rows = computeProfitByBuilding(input);
    expect(rows, hasLength(1));
    expect(rows.first.label, 'Tower A');
    expect(rows.first.net, 1850);
  });

  test('customer reliability ranks by remaining balance', () {
    final rows = computeCustomerReliability(input);
    expect(rows, hasLength(1));
    expect(rows.first.name, 'Alice');
    expect(rows.first.totalRemaining, greaterThan(0));
    expect(rows.first.problemBookings, 1);
  });

  test('revenue trend returns six monthly points', () {
    final points = computeRevenueTrend(input);
    expect(points, hasLength(6));
    expect(points.last.revenue, 2000);
  });

  test('occupancy trend returns six monthly points', () {
    final points = computeOccupancyTrend(input);
    expect(points, hasLength(6));
    expect(points.every((p) => p.total == 2), isTrue);
  });

  test('maintenance breakdown and top items respect period', () {
    final byApartment = maintenanceByApartment(input);
    final byBuilding = maintenanceByBuilding(input);
    final top = topMaintenanceItems(input);

    expect(byApartment, isNotEmpty);
    expect(byBuilding, isNotEmpty);
    expect(top, hasLength(1));
    expect(top.first.description, 'Paint');
  });

  test('revenue period comparison uses prior window', () {
    final compare = revenuePeriodComparison(
      kReportTransactions,
      reportPeriodRange('This Month', now: kReportNow),
    );
    expect(compare.current, 2000);
    expect(compare.previous, 500);
    expect(compare.changePct, 300);
  });

  test('transactions and maintenance in period filter correctly', () {
    final period = reportPeriodRange('This Month', now: kReportNow);
    expect(transactionsInPeriod(kReportTransactions, period), hasLength(1));
    expect(maintenanceInPeriod(kReportMaintenance, period), hasLength(1));
  });

  test('outstanding dedupes multiple transactions for same booking', () {
    final rows = computeOutstandingBalances(reportAnalyticsInput());
    expect(rows, hasLength(1));
    expect(rows.first.remaining, 3000);
  });
}
