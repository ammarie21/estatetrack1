import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/screens/reports/reports_screen.dart';
import 'package:estatetrack1/utils/report_analytics.dart';
import 'package:estatetrack1/utils/report_period.dart';

/// Fixed "now" for deterministic report tests.
final DateTime kReportNow = DateTime(2026, 6, 15);

final kReportBuildings = [
  const BuildingModel(
    buildingId: 1,
    name: 'Tower A',
    floorsCount: 5,
    constructionYear: 2020,
    totalApartments: 10,
    location: 'Downtown',
  ),
];

final kReportApartments = [
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

final kReportCustomers = [
  const CustomerModel(
    customerId: 1,
    name: 'Alice',
    phone: '123',
    nationalNum: 'N1',
    numberOfRentedApartments: 1,
  ),
];

final kReportBookings = [
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

final kReportTransactions = [
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
  RentalTransactionModel(
    transactionId: 2,
    bookingId: 1,
    paidInitialTotalDueAmount: 500,
    actualTotalDueAmount: 5000,
    totalRemaining: 2500,
    totalRefundedAmount: 0,
    transactionStatus: 'Partial',
    updatedTransactionDate: DateTime(2026, 5, 25),
  ),
];

final kReportContracts = [
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

final kReportMaintenance = [
  const MaintenanceModel(
    id: 1,
    apartmentId: '1',
    description: 'Paint',
    cost: 150,
    date: '2026-06-05',
  ),
  const MaintenanceModel(
    id: 2,
    apartmentId: '1',
    description: 'Plumbing',
    cost: 75,
    date: '2026-05-20',
  ),
];

ReportAnalyticsInput reportAnalyticsInput({
  ReportPeriodRange? period,
  DateTime? now,
}) {
  return ReportAnalyticsInput(
    transactions: kReportTransactions,
    apartments: kReportApartments,
    buildings: kReportBuildings,
    customers: kReportCustomers,
    bookings: kReportBookings,
    contracts: kReportContracts,
    maintenance: kReportMaintenance,
    period: period ?? reportPeriodRange('This Month', now: now ?? kReportNow),
    now: now ?? kReportNow,
  );
}

ReportsScreen reportScreen({
  void Function(int bookingId, String status)? onOpenOutstandingBooking,
  void Function(int customerId)? onOpenCustomer,
}) {
  return ReportsScreen(
    rentalTransactions: kReportTransactions,
    apartments: kReportApartments,
    buildings: kReportBuildings,
    customers: kReportCustomers,
    bookings: kReportBookings,
    contracts: kReportContracts,
    maintenance: kReportMaintenance,
    onOpenOutstandingBooking: onOpenOutstandingBooking,
    onOpenCustomer: onOpenCustomer,
  );
}

ReportsScreen emptyReportScreen() {
  return const ReportsScreen(
    rentalTransactions: [],
    apartments: [],
    buildings: [],
    customers: [],
    bookings: [],
    contracts: [],
    maintenance: [],
  );
}
