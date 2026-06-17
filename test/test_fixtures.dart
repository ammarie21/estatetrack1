import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';

const testCustomer = CustomerModel(
  customerId: 1,
  name: 'Sara Al-Masri',
  phone: '+962 79 000 1111',
  nationalNum: '9900123456',
  numberOfRentedApartments: 1,
);

const testTenant = CustomerModel(
  customerId: 2,
  name: 'Omar Haddad',
  phone: '+962 78 222 3333',
  nationalNum: '8800654321',
  numberOfRentedApartments: 1,
);

const testBuilding = BuildingModel(
  buildingId: 1,
  name: 'Tower A',
  floorsCount: 10,
  constructionYear: 2020,
  totalApartments: 20,
  location: 'Amman',
);

const testApartmentOccupied = ApartmentModel(
  apartmentId: 1,
  buildingId: 1,
  typeId: 1,
  sizeM2: 80,
  rentPricePerMonth: 450,
  rentPricePerDay: 20,
  isAvailable: false,
  bedrooms: 2,
  bathrooms: 2,
  hasBalcony: true,
  furnished: true,
  hasInternet: true,
  parking: true,
  elevator: true,
  number: 'A-101',
  location: 'Floor 1',
);

const testApartmentVacant = ApartmentModel(
  apartmentId: 2,
  buildingId: 1,
  typeId: 1,
  sizeM2: 75,
  rentPricePerMonth: 420,
  rentPricePerDay: 18,
  isAvailable: true,
  bedrooms: 2,
  bathrooms: 1,
  hasBalcony: false,
  furnished: false,
  hasInternet: true,
  parking: false,
  elevator: true,
  number: 'A-102',
  location: 'Floor 1',
);

const testApartmentType = ApartmentTypeModel(
  typeId: 1,
  apartmentType: 'Standard',
);

ContractModel activeContractForCustomer({
  DateTime? endDate,
  int customerId = 1,
  int apartmentId = 1,
  int bookingId = 10,
}) {
  final start = DateTime.now().subtract(const Duration(days: 30));
  final end = endDate ?? DateTime.now().add(const Duration(days: 60));
  return ContractModel(
    contractId: bookingId,
    customerId: customerId,
    apartmentId: apartmentId,
    startDate: start,
    endDate: end,
    totalAmount: 500,
    status: 'Active',
    bookingId: bookingId,
  );
}

RentalBookingModel bookingForContract(
  ContractModel contract, {
  double rentalPrice = 300,
}) {
  return RentalBookingModel(
    bookingId: contract.bookingId,
    userId: 1,
    customerId: contract.customerId,
    apartmentId: contract.apartmentId,
    startDate: contract.startDate,
    endDate: contract.endDate,
    initialTotalDueAmount: contract.totalAmount,
    bookingType: 0,
    periodFee: contract.totalAmount,
    rentalPrice: rentalPrice,
  );
}

RentalTransactionModel transactionForBooking(
  RentalBookingModel booking, {
  double paid = 300,
  double remaining = 200,
}) {
  return RentalTransactionModel(
    transactionId: booking.bookingId,
    bookingId: booking.bookingId,
    paidInitialTotalDueAmount: paid,
    actualTotalDueAmount: booking.initialTotalDueAmount,
    totalRemaining: remaining,
    totalRefundedAmount: 0,
    transactionStatus: remaining > 0 ? 'Partial' : 'Paid',
    updatedTransactionDate: DateTime(2025, 3, 1),
  );
}

const testMaintenance = MaintenanceModel(
  id: 1,
  apartmentId: '1',
  description: 'Fix AC unit',
  cost: 150,
  date: '2025-03-10',
  status: 'Done',
);

AccountModel testAccount({bool admin = false}) => AccountModel(
  id: admin ? '1' : '2',
  name: admin ? 'Main Admin' : 'Default User',
  email: admin ? 'admin@estate.test' : 'user@estate.test',
  phone: admin ? '01000000001' : '01000000002',
  password: admin ? 'Admin@123' : 'User@1234',
  role: admin ? 'Admin' : 'Staff',
);
