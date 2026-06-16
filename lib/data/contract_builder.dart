import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';

/// Maps backend booking + return state to UI contract status.
String contractStatusFor({
  required RentalBookingModel booking,
  required List<ApartmentReturnModel> returns,
}) {
  final hasReturn = returns.any((r) => r.bookingId == booking.bookingId);
  if (hasReturn || !booking.isActive) return 'Terminated';
  if (booking.endDate.isBefore(DateTime.now())) return 'Expired';
  return 'Active';
}

ContractModel contractFromBooking(
  RentalBookingModel booking, {
  required List<ApartmentReturnModel> returns,
}) {
  return ContractModel(
    contractId: booking.bookingId,
    customerId: booking.customerId,
    apartmentId: booking.apartmentId,
    startDate: booking.startDate,
    endDate: booking.endDate,
    totalAmount: booking.initialTotalDueAmount,
    status: contractStatusFor(booking: booking, returns: returns),
    bookingId: booking.bookingId,
    bookingType: booking.bookingType,
    notes: booking.initialCheckNotes,
  );
}

List<ContractModel> contractsFromBookings(
  List<RentalBookingModel> bookings,
  List<ApartmentReturnModel> returns,
) {
  return bookings.map((b) => contractFromBooking(b, returns: returns)).toList();
}
