import 'package:estatetrack1/utils/payment_details_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsePaymentDetails splits multi-line notes', () {
    const raw = r'''
$120 cash on check-in
$40 card on 2026-05-18
''';

    final lines = parsePaymentDetails(raw);

    expect(lines.length, 2);
    expect(lines.first.text, r'$120 cash on check-in');
    expect(lines.first.amount, 120);
    expect(lines.last.amount, 40);
  });

  test('summarizePaymentDetails joins multiple lines', () {
    const raw = 'cash\nbank transfer';

    expect(summarizePaymentDetails(raw), 'cash · bank transfer');
    expect(summarizePaymentDetails('cash only'), 'cash only');
    expect(summarizePaymentDetails(null), '');
  });
}
