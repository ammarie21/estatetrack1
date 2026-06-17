import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/utils/report_analytics.dart';
import 'package:estatetrack1/utils/report_period.dart';

void main() {
  test('previousPeriodRange mirrors selected period length', () {
    final period = ReportPeriodRange(
      DateTime(2025, 6, 10),
      DateTime(2025, 6, 17, 23, 59, 59),
    );
    final previous = previousPeriodRange(period);

    expect(previous.end.day, 9);
    expect(previous.start.day, 2);
  });

  test('revenuePeriodComparison compares current and prior period', () {
    final period = ReportPeriodRange(
      DateTime(2025, 6, 1),
      DateTime(2025, 6, 30, 23, 59, 59),
    );
    final compare = revenuePeriodComparison(
      const [],
      period,
    );

    expect(compare.current, 0);
    expect(compare.previous, 0);
    expect(compare.changePct, 0);
  });
}
