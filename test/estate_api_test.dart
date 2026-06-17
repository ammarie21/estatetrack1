import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('apartment type json round trip', () {
    const original = ApartmentTypeModel(typeId: 4, apartmentType: 'Duplex');
    final json = encodeApartmentTypeForTest(original);
    expect(json['typeID'], 4);
    expect(json['apartmentType'], 'Duplex');

    final decoded = decodeApartmentTypeForTest(json);
    expect(decoded.typeId, original.typeId);
    expect(decoded.apartmentType, original.apartmentType);
  });

  test('customer json round trip', () {
    const original = CustomerModel(
      customerId: 7,
      name: 'Ahmad',
      phone: '0599000000',
      nationalNum: '123456789',
      numberOfRentedApartments: 2,
    );
    final json = encodeCustomerForTest(original);
    final decoded = decodeCustomerForTest(json);

    expect(decoded.customerId, 7);
    expect(decoded.name, 'Ahmad');
    expect(decoded.phone, '0599000000');
    expect(decoded.nationalNum, '123456789');
    expect(decoded.numberOfRentedApartments, 2);
    expect(decoded.idNumber, '123456789');
  });

  test('booking json round trip preserves payment fields', () {
    final original = RentalBookingModel(
      bookingId: 12,
      userId: 1,
      customerId: 3,
      apartmentId: 8,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      initialTotalDueAmount: 500,
      bookingType: 1,
      periodFee: 500,
      rentalPrice: 150,
      paymentDetails: 'cash + transfer',
      isActive: true,
      initialCheckNotes: 'checked in',
    );

    final json = encodeBookingForTest(original);
    expect(json['bookingID'], 12);
    expect(json['rentalPrice'], 150);
    expect(json['paymentDetails'], 'cash + transfer');

    final decoded = decodeBookingForTest(json);
    expect(decoded.bookingId, 12);
    expect(decoded.rentalPrice, 150);
    expect(decoded.paymentDetails, 'cash + transfer');
    expect(decoded.startDate, original.startDate);
    expect(decoded.isActive, isTrue);
  });

  test('return json decodes booking link and amounts', () {
    final decoded = decodeReturnForTest({
      'returnID': 5,
      'bookingID': 12,
      'actualReturnDate': '2026-06-28T00:00:00',
      'actualRentalDays': 0,
      'additionalCharges': 25,
      'actualTotalDueAmount': 525,
      'totalRemaining': 375,
      'totalRefundedAmount': 0,
      'finalCheckNotes': 'minor cleaning',
    });

    expect(decoded.returnId, 5);
    expect(decoded.bookingId, 12);
    expect(decoded.actualTotalDueAmount, 525);
    expect(decoded.additionalCharges, 25);
    expect(decoded.finalCheckNotes, 'minor cleaning');
  });

  test('user json round trip', () {
    const original = UserModel(
      userId: 1,
      name: 'Main Admin',
      phone: '01000000001',
      password: 'Admin@123',
    );
    final json = encodeUserForTest(original);
    final decoded = decodeUserForTest(json);

    expect(decoded.userId, 1);
    expect(decoded.name, 'Main Admin');
    expect(decoded.phone, '01000000001');
  });
}
