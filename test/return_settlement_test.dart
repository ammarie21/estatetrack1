import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/utils/return_settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prorates agreement rent for early checkout', () {
    final rent = proratedAgreementAmount(
      agreementTotal: 3000,
      agreementDays: 90,
      actualRentalDays: 30,
    );

    expect(rent, closeTo(1000, 0.01));
  });

  test('settlement computes refund after prorated rent and charges', () {
    final settlement = ReturnSettlement.compute(
      totalDueAmount: 1150,
      paidOnBooking: 3000,
    );

    expect(settlement.remaining, 0);
    expect(settlement.refunded, 1850);
  });

  test('settlement computes remaining when charges exceed refund', () {
    final settlement = ReturnSettlement.compute(
      totalDueAmount: 3500,
      paidOnBooking: 3000,
    );

    expect(settlement.remaining, 500);
    expect(settlement.refunded, 0);
  });

  test('return json uses paid on booking without double counting checkout', () {
    final model = ApartmentReturnModel(
      returnId: 0,
      bookingId: 12,
      actualReturnDate: DateTime(2026, 6, 28),
      actualRentalDays: 30,
      additionalCharges: 150,
      actualTotalDueAmount: 1150,
      totalRemaining: 0,
      totalRefundedAmount: 0,
      finalPaymentCollected: 0,
    );

    final json = encodeReturnForTest(
      model,
      userId: 1,
      paidOnBooking: 3000,
    );

    expect(json['totalRemaining'], 0);
    expect(json['totalRefundedAmount'], 1850);
    expect(json['additionalCharges'], 150);
    expect(json['actualTotalDueAmount'], 1150);
  });

  test('return json prefers form settlement for refund with charges', () {
    final model = ApartmentReturnModel(
      returnId: 0,
      bookingId: 12,
      actualReturnDate: DateTime(2026, 6, 28),
      actualRentalDays: 30,
      additionalCharges: 150,
      actualTotalDueAmount: 1150,
      totalRemaining: 0,
      totalRefundedAmount: 1850,
      finalPaymentCollected: 0,
    );

    final json = encodeReturnForTest(
      model,
      userId: 1,
      paidOnBooking: 2500,
    );

    expect(json['totalRefundedAmount'], 1850);
    expect(json['totalRemaining'], 0);
  });

  test('settlement with checkout payment included in form only', () {
    final settlement = ReturnSettlement.compute(
      totalDueAmount: 1150,
      paidOnBooking: 3000,
      finalPaymentCollected: 200,
    );

    expect(settlement.totalPaid, 3200);
    expect(settlement.remaining, 0);
    expect(settlement.refunded, 2050);
  });

  test('settlement is balanced when paid equals total due', () {
    final settlement = ReturnSettlement.compute(
      totalDueAmount: 1150,
      paidOnBooking: 1150,
    );

    expect(settlement.remaining, 0);
    expect(settlement.refunded, 0);
  });
}
