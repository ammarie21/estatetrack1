import 'package:estatetrack1/data/contract_builder.dart';
import 'package:estatetrack1/data/rental_transaction_builder.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';

class DerivedEstateState {
  const DerivedEstateState({
    required this.contracts,
    required this.rentalTransactions,
  });

  final List<ContractModel> contracts;
  final List<RentalTransactionModel> rentalTransactions;
}

DerivedEstateState deriveEstateState({
  required List<RentalBookingModel> bookings,
  required List<ApartmentReturnModel> returns,
}) {
  return DerivedEstateState(
    contracts: contractsFromBookings(bookings, returns),
    rentalTransactions: buildTransactionsFromBookings(bookings, returns),
  );
}
